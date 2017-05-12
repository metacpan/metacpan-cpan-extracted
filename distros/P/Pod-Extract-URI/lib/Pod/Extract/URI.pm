package Pod::Extract::URI;

use strict;
use warnings;
use Carp;
use URI::Find;
use URI::Find::Schemeless;
use Pod::Escapes;

use base qw(Pod::Parser);

our $VERSION = '0.3';

=pod

=begin comment

General approach:
* create a Pod::Parser subclass which has, amongst other things, 
  a reference to a URI::Find object
* set up handlers for various POD events
* have those handlers call _process() method on their text
  if we want their URIs
* the finder object calls _register_uri() method when it finds
  URIs, which we stash in the Pod::Extract::URI object to return 
  after parsing

=end comment


=head1 NAME

Pod::Extract::URI - Extract URIs from POD


=head1 SYNOPSIS

  use Pod::Extract::URI;

  # Get a list of URIs from a file
  my @uris = Pod::Extract::URI->uris_from_file( $file );

  # Or filehandle
  my @uris = Pod::Extract::URI->uris_from_filehandle( $filehandle );

  # Or the full OO
  my $parser = Pod::Extract::URI->new();
  $parser->parse_from_file( $file );
  my @uris = $parser->uris();
  my %uri_details = $parser->uri_details();


=head1 DESCRIPTION

This module parses POD and uses C<URI::Find> or C<URI::Find::Schemeless>
to extract any URIs it can.


=head1 METHODS

=over 4

=item new()

Create a new C<Pod::Extract::URI> object.

C<new()> takes an optional hash of options, whose names correspond to
object methods described in more detail below.

=over 4

=item schemeless (boolean, default 0)

Should the parser try to extract schemeless URIs (using C<URI::Find::Schemeless>)?

=item L_only (boolean, default 0)

Should the parser only look for URIs in LE<lt>E<gt> sequences?

=item textblock (boolean, default 1)

=item verbatim (boolean, default 1)

=item command (boolean, default 1)

Should the parser look in POD text paragraph, verbatim blocks, or commands?

=item schemes (arrayref)

Restrict URIs to the schemes in the arrayref.

=item exclude_schemes (arrayref)

Exclude URIs with the schemes in the arrayref.

=item stop_uris (arrayref)

An arrayref of patterns to ignore.

=item stop_sub (coderef)

A reference to a subroutine to run for each URI to see if the URI should
be ignored.

=item use_canonical (boolean, default 0)

Convert the URIs found to their canonical form.

=item strip_brackets (boolean, default 1)

Strip extra brackets which may appear around the URL returned by L<URI::Find>.
See method below for more details.

=back

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %args = @_;

    # default arguments
    my %my_args = (
        schemeless      => 0,
        L_only          => 0,
        want_textblock  => 1,
        want_verbatim   => 1,
        want_command    => 1,
        schemes         => [],
        exclude_schemes => [],
        stop_uris       => [],
        stop_sub        => sub { return 0 },
        use_canonical   => 0,
        strip_brackets  => 1,
    );

    # override defaults
    for my $arg ( keys %my_args ) {
        if ( exists $args{ $arg } ) {
            $my_args{ $arg } = $args{ $arg };
            # remove arguments - anything left will be passed
            # to Pod::Parser
            delete $args{ $arg };
        }
    }
    
    # instantiate Pod::Parser object
    # pass any leftover arguments
    my $self = $class->SUPER::new( %args );

    $self->{ URIS } = {}; # URI details
    $self->{ URI_LIST } = []; # ordered URI list

    my $find_class = "URI::Find";
    if ( $my_args{ schemeless } ) {
        $find_class = "URI::Find::Schemeless";
    }
    delete $my_args{ schemeless }; # no schemeless() method

    # instantiate finder object with callback closure
    my $finder = $find_class->new( sub {
                                         $self->_register_uri( @_ );
                                       } );
    $self->_finder( $finder );

    # call methods for remaining arguments
    for my $arg ( keys %my_args ) {
        $self->$arg( $my_args{ $arg } );
    }

    return $self;
}

# process
# Use the URI::Find object to find URIs. The URI::Find object has a callback
# which will record any URIs it finds

sub _process {
    my ( $self, $text ) = @_;
    $self->_finder->find( \$text );
}

# textblock
# Overrides Pod::Parser method, handling POD textblock events

sub textblock {
    my ( $self, $text, $line, $para ) = @_;
    $self->_current_line( $line, $para ); # stash current line info for callback
    if ( $self->want_textblock() ) {
        # interpolate to get interior sequence expansion
        $text = $self->interpolate( $text, $line );
        if ( ! $self->L_only ) {
            # interpolate() will sort out extraction for L<> if L_only is true
            $self->_process( $text, $line );
        }
    }
}

# verbatim
# Overrides Pod::Parser method, handling POD verbatim events

sub verbatim {
    my ( $self, $text, $line, $para ) = @_;
    $self->_current_line( $line, $para );
    if ( $self->want_verbatim() && ! $self->L_only() ) {
        # L<> not valid in verbatim blocks
        $self->_process( $text );
    }
}

# command
# Overrides Pod::Parser method, handling POD command events

sub command {
    my ( $self, $cmd, $text, $line, $para ) = @_;
    $self->_current_line( $line, $para );
    if ( $cmd eq "for" && index( $text, "stop_uris" ) == 0 ) {
        # We have a stop_uris directive - add them to the
        # list
        my @stop = @{ $self->stop_uris };
        $text = substr( $text, 10 );
        push @stop, split /\n/, $text;
        $self->stop_uris( \@stop );
    } elsif ( $self->want_command() ) {
        # same logic as for textblock()
        $self->interpolate( $text, $line );
        if ( ! $self->L_only() ) {
            $self->_process( $text );
        }
    }
}

# interior_sequence
# Overrides Pod::Parser method, handling POD interior_sequence events
# Only gets called if we call interpolate() on the containing paragraph

sub interior_sequence {
    my ( $self, $seq_cmd, $seq_arg, $pod_seq ) = @_;
    if ( $seq_cmd eq "L" && $self->L_only ) {
        # if we have an L<> sequence, process it
        $self->_process( $seq_arg );
    } elsif ( $seq_cmd eq "E" ) {
        return Pod::Escapes::e2char( $seq_arg );
    }
    return $seq_arg;
}

# _register_uri
# Handle a URI when we find it

sub _register_uri {
    my ( $self, $uri, $original_text ) = @_;

    my $text = $original_text;
    if ( $self->strip_brackets ) {
        $text =~ s/^<(URL:)?(.*)>$/$2/;
    }
    my $test_text = $text;
    my $uri_str = $text;
    if ( $self->use_canonical ) {
        # force to canonical form
        $uri = $uri->canonical; # looks like URI::Find already does this
        $uri_str = $uri->as_string;
        $test_text = $uri_str;
    }

    my $scheme = $uri->scheme();
    
    # check the scheme and URL against the various discriminators

    my $include = $self->schemes;
    if ( scalar @$include && ! grep { $scheme eq $_ } @$include ) {
        return $text;
    }

    my $exclude = $self->exclude_schemes;
    if ( scalar @$exclude && grep { $scheme eq $_ } @$exclude ) {
        return $text;
    }

    my $stop = $self->stop_uris;
    if ( scalar @$stop && grep { $test_text =~ $_ } @$stop ) {
        return $text;
    }

    if ( $self->_check_stop_sub( $uri, $text ) ) {
        return $text;
    }

    my ( $line, $para ) = $self->_current_line();

    if ( ! exists $self->{ URIS }->{ $uri_str } ) {
        $self->{ URIS }->{ $uri_str } = [];
    }
    push @{ $self->{ URIS }->{ $uri_str } }, { 
                                         uri           => $uri, 
                                         text          => $text, 
                                         original_text => $original_text, 
                                         line          => $line,
                                         para          => $para, 
                                       };
    push @{ $self->{ URI_LIST } }, $uri_str;
    return $text;
}

# _current_line
# Store the current line and Pod::Paragraph object, as passed to the
# Pod::Parser methods, so that _register_uri() can store them if
# necessary.
# Returns the current line in scalar context, and the current line and
# Pod::Paragraph object in list context.

sub _current_line {
    my ( $self, $line, $para ) = @_;
    if ( defined $line ) {
        $self->{ CURRENT_LINE } = $line;
        if ( defined $para ) {
            $self->{ CURRENT_PARA } = $para;
        } else {
            delete $self->{ CURRENT_PARA };
        }
    }
    if ( wantarray ) {
        return ( $self->{ CURRENT_LINE }, $self->{ CURRENT_PARA } );
    } else {
        return $self->{ CURRENT_LINE };
    }
}

# _finder
# Get/set the URI finder object

sub _finder {
    my ( $self, $finder ) = @_;
    if ( defined $finder ) {
        $self->{ FINDER } = $finder;
    }
    return $self->{ FINDER };
}
    
=head2 L_only()

Get/set the L_only flag. Takes one optional true/false argument to 
set the L_only flag. Defaults to false.

If true, C<Pod::Extract::URI> will look for URIs only in C<LE<lt>E<gt>>
sequences, otherwise it will look anywhere in the POD.

=cut

sub L_only {
    my ( $self, $l_only ) = @_;
    if ( defined $l_only ) {
        $self->{ L_ONLY } = $l_only;
    }
    return $self->{ L_ONLY };
}

=head2 want_command()

Get/set the want_command flag. Takes one optional true/false argument to 
set the want_command flag. Defaults to true.

If true, C<Pod::Extract::URI> will look for URIs in command blocks (i.e.
C<=head1>, etc.).

=cut

sub want_command {
    my ( $self, $command ) = @_;
    if ( defined $command ) {
        $self->{ WANT_COMMAND } = $command;
    }
    return $self->{ WANT_COMMAND };
}

=head2 want_textblock()

Get/set the want_textblock flag. Takes one optional true/false argument to 
set the want_textblock flag. Defaults to true.

If true, C<Pod::Extract::URI> will look for URIs in textblocks (i.e.
paragraphs).

=cut

sub want_textblock {
    my ( $self, $textblock ) = @_;
    if ( defined $textblock ) {
        $self->{ WANT_TEXTBLOCK } = $textblock;
    }
    return $self->{ WANT_TEXTBLOCK };
}

=head2 want_verbatim()

Get/set the want_verbatim flag. Takes one optional true/false argument to 
set the want_verbatim flag. Defaults to true.

If true, C<Pod::Extract::URI> will look for URIs in verbatim blocks (i.e.
code examples, etc.).

=cut

sub want_verbatim {
    my ( $self, $verbatim ) = @_;
    if ( defined $verbatim ) {
        $self->{ WANT_VERBATIM } = $verbatim;
    }
    return $self->{ WANT_VERBATIM };
}

=head2 schemes()

    $peu->schemes( [ 'http', 'ftp' ] );

Get/set the list of schemes to search for. Takes an optional arrayref of
schemes to set.

If there are no schemes, C<Pod::Extract::URI> will look for all schemes.

=cut

sub schemes {
    my ( $self, $schemes ) = @_;
    if ( defined $schemes ) {
        if ( ref $schemes eq "ARRAY" ) {
            $self->{ SCHEMES } = $schemes;
        } else {
            carp "Argument to schemes() must be an arrayref";
        }
    }
    return $self->{ SCHEMES };
}

=head2 exclude_schemes()

    $peu->exclude_schemes( [ 'mailto', 'https' ] );

Get/set the list of schemes to ignore. Takes an optional arrayref of
schemes to set.

=cut

sub exclude_schemes {
    my ( $self, $schemes ) = @_;
    if ( defined $schemes ) {
        if ( ref $schemes eq "ARRAY" ) {
            $self->{ EXCLUDE_SCHEMES } = $schemes;
        } else {
            carp "Argument to exclude_schemes() must be an arrayref";
        }
    }
    return $self->{ EXCLUDE_SCHEMES };
}

=head2 stop_uris()

    $peu->stop_uris( [
                       qr/example\.com/,
                       'foobar.com'
                     ] );  

Get/set a list of patterns to apply to each URI to see if it should be
ignored. Takes an optional arrayref of patterns to set. Strings in the list
will be automatically converted to patterns (using qr//).

The URIs will be checked against the canonical URI form if C<use_canonical>
has been specified. Otherwise, they will be checked against the URI as it
appears in the POD. If C<strip_brackets> is specified, the brackets (and 
"URL:" prefix, if present) will be removed before testing.

Any URI that matches a pattern will be ignored.

=cut

sub stop_uris {
    my ( $self, $urls ) = @_;
    if ( defined $urls ) {
        if ( ref $urls eq "ARRAY" ) {
            my @urls = map { UNIVERSAL::isa( $_, "Regexp" ) ? $_ : qr/$_/ } @$urls;
            $self->{ STOP_URLS } = \@urls;
        } else {
            carp "Argument to stop_uris() must be an arrayref";
        }
    }
    return $self->{ STOP_URLS };
}

=head2 stop_sub()

    sub exclude {
        my $uri = shift;
        return ( $uri->host =~ /example\.com/ ) ? 1 : 0;
    }
    $peu->stop_sub( \&exclude );

Get/set a subroutine to check each URI found to see if it should be ignored.
Takes an optional coderef to set.

The subroutine will be passed a reference to the C<URI> object, the text found
by C<URI::Find>, and a reference to the C<Pod::Extract::URI> object. If it
returns true, the URI will be ignored.

=cut
        
sub stop_sub {
    my ( $self, $sub ) = @_;
    if ( defined $sub ) {
        if ( ref $sub eq "CODE" ) {
            $self->{ STOP_SUB } = $sub;
        } else {
            carp "Argument to stop_sub() must be a coderef";
        }
    }
    return $self->{ STOP_SUB };
}

# _check_stop_sub
# Call the stop sub with the right arguments

sub _check_stop_sub {
    my ( $self, $uri, $text ) = @_;
    my $sub = $self->{ STOP_SUB };
    return &$sub( $uri, $text, $self );
}

=head2 use_canonical()

Get/set the use_canonical flag. Takes one optional true/false argument to 
set the use_canonical flag. Defaults to false.

If true, C<Pod::Extract::URI> will store the URIs it finds in the canonical
form (as returned by C<URI->canonical()>. The original URI and text will
still be available via C<uri_details()>.

=cut

sub use_canonical {
    my ( $self, $use ) = @_;
    if ( defined $use ) {
        $self->{ USE_CANONICAL } = $use;
    }
    return $self->{ USE_CANONICAL };
}

=head2 strip_brackets()

Get/set the strip_brackets flag. Takes one optional true/false argument to 
set the strip_brackets flag. Defaults to true.

RFC 2396 Appendix E suggests the form C<E<lt>http://www.example.com/E<gt>>
or C<E<lt>URL:http://www.example.com/E<gt>> when embedding URLs in plain text.
C<URI::Find> includes these in the URLs it returns. If C<strip_brackets> is
true, this extra stuff will be removed and won't appear in the URIs returned
by C<Pod::Extract::URI>.

=cut

sub strip_brackets {
    my ( $self, $strip ) = @_;
    if ( defined $strip ) {
        $self->{ STRIP_BRACKETS } = $strip;
    }
    return $self->{ STRIP_BRACKETS };
}

=head2 parse_from_file()

    $peu->parse_from_file( $filename );

Parses the POD from the specified file and stores the URIs it finds for later 
retrieval.

=head2 parse_from_filehandle()

    $peu->parse_from_filehandle( $filehandle );

Parses the POD from the filehandle and stores the URIs it finds for later
retrieval.

=head2 uris_from_file()

    my @uris = $peu->uris_from_file( $filename );

A shortcut for C<parse_from_file()> then C<uris()>.

=cut

sub uris_from_file {
    my ( $self, $file ) = @_;
    if ( ! ref $self ) {
        $self = $self->new();
    }
    $self->parse_from_file( $file );
    return $self->uris;
}

=head2 uris_from_filehandle()

    my @uris = $peu->uris_from_filehandle( $filename );

A shortcut for C<parse_from_filehandle()> then C<uris()>.

=cut

sub uris_from_filehandle {
    my ( $self, $file ) = @_;
    if ( ! ref $self ) {
        $self = $self->new();
    }
    $self->parse_from_filehandle( $file );
    return @{ $self->{ URI_LIST } };
}

=head2 uris()

    my @uris = $peu->uris();

Returns a list of the URIs found from parsing.

=cut

sub uris {
    my $self = shift;
    return @{ $self->{ URI_LIST } };
}

=head2 uri_details()

    my %details = $peu->uri_details();

Returns a hash of data about the URIs found.

The keys of the hash are the URIs (which match those returned by C<uris()>).

The values of the hash are arrayrefs of hashrefs. Each hashref contains

=over 4

=item uri

The URI object returned by C<URI::Find>.

=item text

The text returned by C<URI::Find>, which will have the brackets stripped
from it if C<strip_brackets> has been specified.

=item original_text

The original text returned by C<URI::Find>.

=item line

The initial line number of the paragraph in which the URI was found.

=item para

The C<Pod::Paragraph> object corresponding to the paragraph where the URI
was found.

=back

=cut

sub uri_details {
    my $self = shift;
    return %{ $self->{ URIS } };
}

=head1 STOP URIS

You can specify URIs to ignore in your POD, using a C<=for stop_uris>
command, e.g.

    =for stop_uris www.foobar.com

These will be converted to patterns as if they had been passed in via
C<stop_uris()> directly, and will apply from the point of the command
onwards.


=head1 AUTHOR

Ian Malpass (ian-cpan@indecorous.com)


=head1 COPYRIGHT

Copyright 2007, Ian Malpass

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 SEE ALSO

L<URI::Find>, L<URI::Find::Schemeless>, L<URI>.

=cut

1;


=head1 NAME

REST::Utils - Utility functions for REST applications

=head1 SYNOPSIS

    use REST::Utils qw( :all );

=cut

package REST::Utils;

use base qw( Exporter );
use warnings;
use strict;
use Carp qw( croak );
use Scalar::Util qw( looks_like_number );
use constant NOT_FIT         => -1;
use constant HUNDRED_PERCENT => 100;
use constant TEN_PERCENT     => 10;
use constant POST_UNLIMITED  => -1;

=head1 VERSION

This document describes REST::Utils Version 0.6

=cut

our $VERSION = '0.6';

=head1 DESCRIPTION

This module contains some functions that are useful for implementing REST
applications.

=cut

our @EXPORT_OK = qw/  best_match get_body fitness_and_quality_parsed
  media_type parse_media_range parse_mime_type quality quality_parsed
  request_method /;

our %EXPORT_TAGS = ( 'all' => [@EXPORT_OK] );

=head2 FUNCTIONS

The following functions are available. None of them are exported by default.
You can give the tag :all to the C<use REST::Utils> statement to import all
the functions at once.

=head3 best_match(\@supported, $header)

Takes an arrayref of supported MIME types and finds the best match for
all the media-ranges listed in $header. The value of $header must be a
string that conforms to the format of the HTTP Accept: header. The
value of @supported is a list of MIME types.  If no type can be matched,
C<undef> is returned.

Example:

    print best_match(['application/xbel+xml', 'text/xml'],
        'text/*;q=0.5,*/*; q=0.1');
    # text/xml

=cut

sub best_match {
    my ( $supported, $header ) = @_;
    my @parsed_header = map { [ parse_media_range($_) ] } split /,/msx, $header;
    my @weighted_matches =
      sort { $a->[0][0] <=> $b->[0][0] || $a->[0][1] <=> $b->[0][1] }
      map { [ [ fitness_and_quality_parsed( $_, @parsed_header ) ], $_ ] }
      @{$supported};
    return $weighted_matches[-1][0][1] ? $weighted_matches[-1][1] : undef;
}

=head3 get_body($cgi)

This function takes a L<CGI|CGI> or compatible object as its first parameter.

It will retrieve the body of an HTTP request regardless of the request method.

If the body is larger than L<CGI|CGI>.pms' POST_MAX variable allows or if
C<$ENV{CONTENT_LENGTH}> reports a bigger size than is actually available,
get_body() will return undef.

If there is no body or if C<$ENV{CONTENT_LENGTH}> is undefined, it will
return an empty string.

Otherwise it will return a scalar containing the body as a sequence of bytes
up to the size of C<$ENV{CONTENT_LENGTH}>

It is up to you to turn the bytes returned by get_body() into something
useful.

=cut

# bits of this taken from derby http://www.perlmonks.org/?node_id=609632
sub get_body {
    my ($cgi) = @_;

    my $content = undef;
    my $method  = request_method($cgi);

    my $len = $ENV{CONTENT_LENGTH} || 0;

    if ( $CGI::POST_MAX != POST_UNLIMITED && $len > $CGI::POST_MAX ) {
        return;
    }

    if ( defined $cgi->param('POSTDATA') ) {
        $content = $cgi->param('POSTDATA');
    }
    elsif ( defined $cgi->param('PUTDATA') ) {
        $content = $cgi->param('PUTDATA');
    }
    else {

        # we may not get all the data we want with a single read on large
        # POSTs as it may not be here yet! Credit Jason Luther for patch
        # CGI.pm < 2.99 suffers from same bug -- derby
        while ( sysread STDIN, ( my $buffer ), $len ) {
            $content .= $buffer;
        }
    }

    # To make sure it is not undef at this point.
    return defined $content ? $content : q{};
}

=head3 fitness_and_quality_parsed($mime_type, @parsed_ranges)

Find the best match for a given mime-type against a list of media_ranges that
have already been parsed by parse_media_range(). Returns a list of the fitness
value and the value of the 'q' quality parameter of the best match, or (-1, 0)
if no match was found. Just as for quality_parsed(), @parsed_ranges must be a
list of parsed media ranges.

=cut

sub fitness_and_quality_parsed {
    my ( $mime_type, @parsed_ranges ) = @_;
    my $best_fitness = NOT_FIT;
    my $best_fit_q   = 0;
    my ( $target_type, $target_subtype, $target_params ) =
      parse_media_range($mime_type);
    while ( my ( $type, $subtype, $params ) = @{ shift @parsed_ranges || [] } )
    {
        $subtype = defined $subtype ? $subtype : q{};
        if (
            ( $type eq $target_type || $type eq q{*} || $target_type eq q{*} )
            && (   $subtype eq $target_subtype
                || $subtype eq q{*}
                || $target_subtype eq q{*} )
          )
        {
            my $param_matches = scalar grep {
                     $_ ne 'q'
                  && exists $params->{$_}
                  && $target_params->{$_} eq $params->{$_}
              }
              keys %{$target_params};
            my $fitness =
              $type eq $target_type
              ? HUNDRED_PERCENT
              : 0;
            $fitness +=
              $subtype eq $target_subtype
              ? TEN_PERCENT
              : 0;
            $fitness += $param_matches;
            if ( $fitness > $best_fitness ) {
                $best_fitness = $fitness;
                $best_fit_q   = $params->{q};
            }
        }
    }

    return $best_fitness, $best_fit_q;
}

=head3 media_type($cgi, \@types)

This function takes a L<CGI|CGI> or compatible object as its first parameter
and a reference to a list of MIME media types as the second parameter.  It
returns the member of the list most preferred by the requestor.

Example:

    my $preferred = media_type($cgi, ['text/html', 'text/plain', '*/*']);

If the incoming request is a C<HEAD> or C<GET>, the function will return 
the member of the C<types> listref which is most preferred based on the 
C<Accept> HTTP headers sent by the requestor. If the requestor wants a 
type which is not on the list, the function will return C<undef>. (HINT: 
you can specify ' */*' to match every MIME media type.)

For C<POST> or C<PUT> requests, the function will compare the MIME media 
type in the C<Content-type> HTTP header provided by the requestor with 
the list and return that type if it matches a member of the list or 
C<undef> if it doesn't.

For other HTTP requests (such as C<DELETE>) this function will always return
an empty string.

=cut

sub media_type {
    my ( $cgi, $types ) = @_;

    # Get the preferred MIME media type. Other HTTP verbs than the ones below
    # (and DELETE) are not covered. Should they be?
    my $req        = request_method($cgi);
    my $media_type = undef;
    if ( $req eq 'GET' || $req eq 'HEAD' ) {
        $media_type = best_match( $types, $cgi->http('accept') );
    }
    elsif ( $req eq 'POST' || $req eq 'PUT' ) {
        $media_type = best_match( $types, $cgi->content_type );
    }
    else {
        $media_type = q{};
    }

    return $media_type;
}

=head3 parse_media_range($range)

Carves up a media range and returns a list of the C<($type, $subtype,\%params)>
where %params is a hash of all the parameters for the media range.

For example, the media range 'application/*;q=0.5' would get
parsed into:

    ('application', '*', { q => 0.5 })

In addition this function also guarantees that there is a value for 'q' in the
%params hash, filling it in with a proper default if necessary.

=cut

sub parse_media_range {
    my ($range) = @_;
    my ( $type, $subtype, $params ) = parse_mime_type($range);

    if (   !exists $params->{q}
        || !$params->{q}
        || !looks_like_number( $params->{q} )
        || $params->{q} > 1
        || $params->{q} < 0 )
    {
        $params->{q} = 1;
    }
    return $type, $subtype, $params;
}

=head3 parse_mime_type($mime_type)

Carves up a MIME type and returns a list of the ($type, $subtype,
\%params) where %params is a hash of all the parameters for the media range.

For example, the media range 'application/xhtml;q=0.5' would get parsed into:

    ('application', 'xhtml', { q => 0.5 })

=cut

sub parse_mime_type {
    my ($mime_type) = @_;

    my @parts = split /;/msx, $mime_type;
    my %params =
      map { _strip($_) } map { split /=/msx, $_, 2 } @parts[ 1 .. $#parts ];
    my $full_type = _strip( $parts[0] );

    # Java URLConnection class sends an Accept header that includes a single
    # "*" Turn it into a legal wildcard.

    if ( $full_type eq q{*} ) {
        $full_type = q{*/*};
    }
    my ( $type, $subtype ) = split m{/}msx, $full_type;
    return _strip($type), _strip($subtype), \%params;
}

=head3 quality($mime_type, $ranges)

Returns the quality 'q' of a MIME type when compared against the
media-ranges in $ranges. For example:

    print quality('text/html', 'text/*;q=0.3, text/html;q=0.7, text/html;level
    # 0.7

=cut

sub quality {
    my ( $mime_type, $ranges ) = @_;
    my @parsed_ranges = map { [ parse_media_range($_) ] } split /,/msx, $ranges;
    return quality_parsed( $mime_type, @parsed_ranges );
}

=head3 quality_parsed($mime_type, @parsed_ranges)

Find the best match for a given MIME type against a list of media_ranges
that have already been parsed by parse_media_range(). Returns the 'q'
quality parameter of the best match, 0 if no match was found. This
function behaves the same as quality() except that @parsed_ranges must
be a list of parsed media ranges.

=cut

sub quality_parsed {
    my (@args) = @_;

    return ( fitness_and_quality_parsed(@args) )[1];
}

=head3 request_method($cgi)

This function returns the query's HTTP request method.

Example 1:

    my $method = request_method($cgi);
    
This function takes a L<CGI|CGI> or compatible object as its first parameter.

Because many web sites don't allow the full set of HTTP methods needed 
for REST, you can "tunnel" methods through C<GET> or C<POST> requests in 
the following ways:

In the query with the C<_method> parameter.  This will work even with C<POST> 
requests where parameters are usually passed in the request body.

Example 2:

    http://localhost/index.cgi?_method=DELETE

Or with the C<X-HTTP-Method-Override> HTTP header.

Example 3:

    X-HTTP-METHOD-OVERRIDE: PUT
    
if more than one of these are present, the HTTP header will override the query
parameter, which will override the "real" method.

Any method can be tunneled through a C<POST> request.  Only C<GET> and C<HEAD> 
can be tunneled through a C<GET> request.  You cannot tunnel through a 
C<HEAD>, C<PUT>, C<DELETE>, or any other request.  If an invalid tunnel is 
attempted, it will be ignored.

=cut

sub request_method {
    my ($cgi) = @_;

    my $real_method = uc( $cgi->request_method() || q{} );
    my $tunnel_method =
      uc(    $cgi->http('X-HTTP-Method-Override')
          || $cgi->url_param('_method')
          || $cgi->param('_method')
          || q{} )
      || undef;

    return $real_method if !defined $tunnel_method;

    # POST can tunnel any method.
    return $tunnel_method if $real_method eq 'POST';

    # GET can only tunnel GET/HEAD
    if ( $real_method eq 'GET'
        && ( $tunnel_method eq 'GET' || $tunnel_method eq 'HEAD' ) )
    {
        return $tunnel_method;
    }

    return $real_method;
}

# utility function
sub _strip {
    my $s = shift;
    $s =~ s/^\s*//msx;
    $s =~ s/\s*$//msx;
    return $s;
}

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rest::Utils
    
You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=REST-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/REST-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/REST-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/REST-Utils/>

=back

=head1 BUGS

There are no known problems with this module.

Please report any bugs or feature requests to
C<bug-rest-Utils at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=REST-Utils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 THANKS

MIME type parsing code borrowed from MIMEParser.pm by:
  Joe Gregorio C<< joe at bitworking.org >>
  Stanis Trendelenburg C<< stanis.trendelenburg at gmail.com >>
  (L<http://code.google.com/p/mimeparse/>)

=head1 AUTHOR

Jaldhar H. Vyas, C<< <jaldhar at braincells.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Consolidated Braincells Inc. All rights reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version, or

b) the Artistic License version 2.0.

The full text of the license can be found in the LICENSE file included
with this distribution.

=cut

1;    # End of REST::Utils

__END__


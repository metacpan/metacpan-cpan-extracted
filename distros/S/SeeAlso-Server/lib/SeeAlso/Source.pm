use strict;
use warnings;
package SeeAlso::Source;
{
  $SeeAlso::Source::VERSION = '0.71';
}
#ABSTRACT: Provides OpenSearch Suggestions reponses

use Carp qw(croak);
use SeeAlso::Response;
use SeeAlso::Server;

use base 'Exporter';
our @EXPORT_OK = qw(expand_from_config serve);


sub new {
    my $class = shift;
    my ($callback, $cache);

    $callback = shift
        if ref($_[0]) eq 'CODE' or UNIVERSAL::isa($_[0],'SeeAlso::Source');
    $cache = shift if UNIVERSAL::isa($_[0], 'Cache');
    shift if not defined $_[0];

    my (%params) = @_;
    expand_from_config( \%params, 'Source' );

    my $self = bless { }, $class;

    $callback = $params{callback} unless defined $callback;
    $cache = $params{cache} unless defined $cache;

    $self->callback( $callback ) if $callback;
    $self->cache( $cache ) if $cache;
    $self->description( %params ) if %params;

    return $self;
}


sub callback {
    my $self = shift;

    if ( scalar @_ ) {
        my $callback = $_[0];

        croak('callback parameter must be a code reference or SeeAlso::Source')
            if defined $callback and ref( $callback ) ne 'CODE'
               and not UNIVERSAL::isa( $callback, 'SeeAlso::Source' );

        $self->{callback} = $callback;
    }

    return unless defined $self->{callback};
    return $self->{callback} if ref($self->{callback}) eq 'CODE';
    return sub { $self->{callback}->query( $_[0] ) };
}


sub cache {
    my $self = shift;

    if ( scalar @_ ) {
        croak 'Cache must be a Cache object' 
            unless not defined $_[0]
                   or UNIVERSAL::isa( $_[0], 'Cache' )
                   or UNIVERSAL::isa( $_[0], 'SeeAlso::Source' );
        $self->{cache} = $_[0];
    }

    return $self->{cache};
}


sub query {
    my ($self, $identifier, %params) = @_;

    $identifier = SeeAlso::Identifier->new( $identifier )
        unless UNIVERSAL::isa( $identifier, 'SeeAlso::Identifier' );

    my $key = $identifier->hash;

    if ( $self->{cache} and not $params{force} ) {
        if ( UNIVERSAL::isa( $self->{cache}, 'Cache' ) ) {
            my $response = $self->{cache}->thaw( $key );
            return $response if defined $response;
        } else {
            my $response = $self->{cache}->query( $identifier );
            return $response if $response->size;
        }
    }

    my $response = $self->query_callback( $identifier );

    $response = SeeAlso::Response->new( $identifier )
        unless UNIVERSAL::isa( $response, 'SeeAlso::Response' );

    if ( $self->{cache} ) {
        if ( UNIVERSAL::isa( $self->{cache}, 'Cache' ) ) {
            $self->{cache}->freeze( $key, $response );
        } else {
            $self->{cache}->update( $response );
        }
    }

    return $response;
}


sub query_callback {
    my ($self, $identifier) = @_;
    return $self->{callback} ?
           $self->callback->( $identifier ) :
           SeeAlso::Response->new( $identifier );
}


sub description {
    my $self = shift;
    my $key = $_[0];

    if (scalar @_ > 1) {
        my %param = @_;
        foreach my $key (keys %param) {
            my $value = defined $param{$key} ? $param{$key} : '';
            if ($key =~ /^Examples?$/) {
                $value = [ $value ] unless ref($value) eq "ARRAY";
                # TODO: check examples (must be an array of a hash)
                $key = "Examples";
            } else {
                $value =~ s/\s+/ /g;  # to string
            }
            if ($self->{description}) {
                $self->{description}{$key} = $value;
            } else {
                my %description = ($key => $value);
                $self->{description} = \%description;
            }
        }
    } elsif ( $self->{description} ) {
        return $self->{description}{$key} if defined $key;
        return $self->{description};
    } else { # this is needed if no description was defined
        return if defined $key;
        my %hash;
        return \%hash;
    }
}


sub about {
    my $self = shift;

    my $name        = $self->description("ShortName");
    my $description = $self->description("Description");
    my $url         = $self->description("BaseURL");

    $name = "" unless defined $name;
    $description = "" unless defined $description;
    $url = "" unless defined $url;

    return ($name, $description, $url); 
}


sub serve {
    my ($source, $query, $config);
    if ( UNIVERSAL::isa( $_[0], 'SeeAlso::Source' ) ) {
        ($source, $config) = @_;
    } else {
        $query = shift if ref($_[0]) eq 'CODE';
        $config = shift;
        $source = SeeAlso::Source->new( $query, config => $config ); 
    }

    my $server = SeeAlso::Server->new( config => $config );

    binmode \*STDOUT, ":encoding(UTF-8)";
    print $server->query( $source );
    exit;
}


sub load_config {
    my $file = shift;
    open(my $fh, "<", $file);
    my $config = eval { JSON->new->relaxed->utf8->decode(join('',<$fh>)); };
    close $fh;
    return $config || { };
}


sub expand_from_config {
    my ($config, $section) = @_;
    return unless defined $config->{config};

    my $cfg = $config->{config};
    if ( ref($cfg) eq 'HASH' ) {
        $cfg = $cfg->{$section};
    } else {
        $cfg = { };
        my $file = $config->{config};
        if ( $file =~ /\.ini$/ ) {
            eval {
                require Config::IniFiles;
                my $ini = Config::IniFiles->new( -file => $config->{config}, -allowcontinue => 1 );
                foreach my $hash ( $ini->Parameters($section) ) {
                    $cfg->{$hash} = $ini->val($section,$hash);
                }
            };
        } elsif ( $file =~ /\.y[a]?ml$/ ) {
            eval {
                require YAML::Any;
                my $config = YAML::Any::LoadFile( $file );
                $cfg = $config->{$section};
            };
        } elsif ( $file =~ /\.json$/ ) {
            eval {
                open(my $fh, "<", $file);
                my $config = JSON->new->relaxed->utf8->decode(join('',<$fh>));
                close $fh;
                $cfg = $config->{$section};
            };
        } else {
            croak "Unknown configuration file type $file";
        }
        croak "Failed to read configuration file $file: $@" if $@;
    }
    return unless ref($cfg) eq 'HASH';
    foreach my $hash ( keys %{ $cfg } ) {
        $config->{$hash} = $cfg->{$hash} unless defined $config->{$hash};
    }
}

1;

__END__
=pod

=head1 NAME

SeeAlso::Source - Provides OpenSearch Suggestions reponses

=head1 VERSION

version 0.71

=head1 SYNOPSIS

  $source = SeeAlso::Source->new;
  $source = SeeAlso::Source->new( sub { ... } );
  $source = SeeAlso::Source->new( callback => sub { ... } );
  ...
  $source->description( "ShortName" => "My source" ... );
  ...
  $response = $source->query( $identifier );

=head2 new ( [ $callback ] [ $cache ] [ %parameters ] )

Create a new source. If the first parameter is a code reference or another
L<SeeAlso::Source> parameter, it is used as C<callback> parameter. If the
first or second parameter is a L<Cache> object, it is used as C<cache>
parameter.

=over 4

=item cache

L<Cache> or L<SeeAlso::DBI> object to be used as cache.

=item config

Configuration settings as hash reference or as configuration file that will
be read into a hash reference. Afterwarrds the The C<Source> section of the
configuration is added to the other parameters (existing parameters are not 
overridden).

=item other parameters

Are passed to the description method.

=back

=head2 callback ( [ $code | $source | undef ] )

Get or set a callback method or callback source.

=head2 cache ( [ $cache | undef ] )

Get or set a cache for this source. The parameter must be a L<Cache> object,
a L<SeeAlso::Source> object or undef. Undef disables caching and is the 
default. Returns the cache object or undef.

=head2 query ( $identifier [, force => 1 ] )

Given an identifier (either a L<SeeAlso::Identifier> object or just
a plain string) returns a L<SeeAlso::Response> object by calling the
query callback method or fetching the response from the cache unless
the $force parameter is specified.

=head2 query_callback ( $identifier )

Internal core method that maps a L<SeeAlso::Identifier> to a
L<SeeAlso::Response>. Clients should not call this metod but the
'query' method that includes type-checking and caching. Subclasses
should overwrite this method instead of the 'query' method.

=head2 description ( [ $key ] | $key => $value, $key => $value, ... )

Returns additional description about this source in a hash (no key provided)
or a specific element of the description. The elements are defined according
to elements in an OpenSearch description document. Up to now they are:

=over

=item ShortName

A short name with up to 16 characters.

=item LongName

A long name with up to 48 characters.

=item Description

A description with up to 1024 characters.

=item BaseURL

URL of the script. Will be set automatically via L<CGI> if not defined.

=item DateModified

Qualified Dublin Core element Date.Modified.

=item Source

Source of the data (dc:source)

=item Example[s]

An example query (a hash of 'id' and optional 'response').

=back

=head2 about ( )

Return ShortName, Description, and BaseURL from the description of this
Source. Undefined fields are returned as empty string.

=head2 serve ( [ $query | $source ] [ $config ] )

Serve a SeeAlso request via L<SeeAlso::Server>C<::query> and exit.
This method can also be exported and used as function.

=head1 INTERNAL FUNCTIONS

=head2 load_config ( $filename )

Load a configuration file (relaxed JSON format) and return a hash reference.
On error the hash reference is empty.

=head2 expand_from_config ( $hashref, $section )

Expand a hash with config parameters from another hash or from a configuration
file. This function can read INI files (if L<Config::IniFiles> is installed),
YAML files (if L<YAML::Any> is installed), and JSON files.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


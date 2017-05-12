use strict;
use warnings;
package SeeAlso::Client;
{
  $SeeAlso::Client::VERSION = '0.71';
}
#ABSTRACT: SeeAlso Linkserver Protocol Client

use Carp qw(croak);
use JSON::XS '2.0' ;
use LWP::Simple qw(get);
use URI '1.35';
use Data::Validate::URI qw(is_web_uri);

use SeeAlso::Identifier;
use SeeAlso::Response;

use base qw( SeeAlso::Source );
our @EXPORT = qw( seealso_request );


sub new {
    my $class = shift;
    my (%description, $baseurl);

    if (@_ % 2) {
        ($baseurl, %description) = @_;
    } else {
        %description = @_;
        $baseurl = $description{BaseURL};
    }

    croak "Please specify a baseurl" unless defined $baseurl;

    my $self = bless {
        'is_simple' => 0 # unknown or no
    }, $class;

    $self->description( %description );
    $self->baseURL( $baseurl );

    return $self;
}


sub query {
    my ($self, $identifier) = @_;

    # TOOD: on failure catch/throw error(s)

    my $url = $self->queryURL( $identifier );
    my $json = get($url);

    if (defined $json) {
        return SeeAlso::Response->fromJSON( $json ); # may also croak
    } else {
        croak("Failed to query $url");
    }
}


sub baseURL {
    my ($self, $url) = @_;
    return $self->description("BaseURL") unless defined $url;

    $url = URI->new( $url ) unless UNIVERSAL::isa( $url, "URI" );
    croak("The specified URL is not valid")
        unless defined $url and is_web_uri($url->as_string());

    my %query = $url->query_form();
    croak("The specified URL must not contain id or callback parameter")
        if defined $query{'id'} or defined $query{'callback'};
    $self->{is_simple} = defined $query{'format'};
    $self->{baseurl} = $url;
    $url = $url->canonical()->as_string();
    $self->description("BaseURL",$url);

    return $url;
}


sub queryURL {
    my ($self, $identifier, $callback) = @_;
    $identifier = $identifier->normalized()
        if UNIVERSAL::isa($identifier,"SeeAlso::Identifier");
    $identifier = "" unless defined $identifier;

    my $url = URI->new( $self->{baseurl} );
    my %query = $url->query_form();

    $query{'format'} = "seealso" unless $self->{is_simple};
    $query{'id'} = $identifier;

    if (defined $callback) {
        $callback =~ /^[a-zA-Z0-9\._\[\]]+$/ or
            croak ( "Invalid callback name" );
        $query{callback} = $callback;
    }
    $url->query_form( %query );

    return $url->canonical();
}


sub getFormats {
    my ($self) = @_;
    return $self->{formats} if exists $self->{formats};

    my $formats = {};
    my $url = $self->baseURL();
    my $xml = get($url);
    if ($xml) {
        # dump parser (not really XML)
        my %matches = ( $xml =~ m/<format name="([^"]+)" type="([^"]+)"/gm );
        $formats = { 
            map { $_, { type => $matches{$_} } } (keys %matches)
        };
    }
    $self->{formats} = $formats;
}


sub seealso_request {
    my ($baseurl, $identifier) = @_;
    my $response = eval { SeeAlso::Client->new($baseurl)->query($identifier); };
    return $response;
}


__END__
=pod

=head1 NAME

SeeAlso::Client - SeeAlso Linkserver Protocol Client

=head1 VERSION

version 0.71

=head1 SYNOPSIS

  $response = seealso_request ( $baseurl, $identifier );
  print $response->toJSON() . "\n" if ($response);

  $client = SeeAlso::Client->new( $baseurl, ShortName => "myClient" );
  $response = $client->query( $identifier );

=head1 DESCRIPTION

This class can be used to query a SeeAlso server. It can also be used
as L<SeeAlso::Source> to proxy another SeeAlso server, for instance to
wrap a SeeAlso Simple server as a SeeAlso Full server.

=head1 METHODS

=head2 new ( [ BaseURL => ] $BaseURL, [ %description ] ] )

Creates a new SeeAlso client. You must specify a BaseURL as string
or L<URI> object or this method will croak:

  $client = new SeeAlso::Client( $BaseURL );
  $client = new SeeAlso::Client( BaseURL => $BaseURL );

=head2 query ( $identifier )

Given an identifier (either a L<SeeAlso::Identifier> object or just a 
plain string) queries the SeeAlso Server of this client and returns a
L<SeeAlso::Response> object on success. On failure this method just 
croaks.

=head2 baseURL ( [ $url ] )

Get or set the base URL of the SeeAlso server to query by this client.

You can specify a string or a L<URI>/L<URI::http>/L<URI::https> object.
If the URL contains a 'format' parameter, it is treated as a SeeAlso Simple
server (plain JSON response), otherwise it is a SeeAlso Full server (unAPI
support and OpenSearch description). This method may croak on invalid URLs.

Returns the URL as string.

=head2 queryURL ( $identifier [, $callback ] )

Get the query URL with a given identifier and optionally callback parameter.
The query parameter can be a simple string or a L<SeeAlso::Identifier> object 
(its normalized representation is used). If no identifier is given, an empty
string is used. This method may croak if the callback name is invalid.

=head2 getFormats

Try to retrieve a list of formats via unAPI (experimental).

=head1 FUNCTIONS

=head2 seealso_request ( $baseurl, $identifier )

Quickly query a SeeAlso server an return the L<SeeAlso::Response>.
This is almost equivalent to

  SeeAlso::Client->new($baseurl)->query($identifier)

but in contrast seealso_request never croaks on errors (but may return undef).
This method is exportet by default.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


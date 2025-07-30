##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Scroll.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/08/03
## Modified 2023/08/03
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::CPAN::Scroll;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::CPAN::List );
    use vars qw( $VERSION );
    use Wanted;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{id}     = undef unless( CORE::exists( $self->{id} ) );
    $self->{size}   = undef unless( CORE::exists( $self->{size} ) );
    $self->{ttl}    = undef unless( CORE::exists( $self->{ttl} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub close
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{all} //= 0;
    my $uri = $self->uri;
    if( $opts->{all} )
    {
        # e.g.: /v1/author/_search/scroll -> /v1/author/_search/scroll/_all
        $uri->path( $uri->path . '/_all' );
    }
    my $id = $self->id ||
        return( $self->error( "No scroll ID was set to close." ) );
    my $hash = { scroll_id => [$id] };
    my $payload;
    local $@;
    # try-catch
    eval
    {
        $payload = $self->new_json->encode( $hash );
    };
    if( $@ )
    {
        return( $self->error( "An error occured while encoding JSON payload to remove scroller: $@" ) );
    }
    my $ua = $self->ua ||
        return( $self->error( "No HTTP::Promise object current set." ) );
    my $resp = $ua->delete( $uri,
        Content => $payload,
        Accept => 'application/json',
    ) || return( $self->pass_error( $ua->error ) );
    return( $resp );
}

# e.g.: cXVlcnlUaGVuRmV0Y2g7Mzs0MDE0MzQ1MTQ6N2NvRzNSdklTYkdiRmNPNi04VXFjQTs2NzEwNTc1NTE6OWtIOUE2b2xUaHk3cU5iWkl6ajZrUTsxMDcyNDY5OTMxOk1lZVhCR1J4VG1tT0QxWjRFd2J0Z2c7MDs=
# which is a base64 that translates to:
# queryThenFetch;3;401434514:7coG3RvISbGbFcO6-8UqcA;671057551:9kH9A6olThy7qNbZIzj6kQ;1072469931:MeeXBGRxTmmOD1Z4Ewbtgg;0;
sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub postprocess
{
    my $self = shift( @_ );
    my $ref = shift( @_ );
    my $id = $ref->{_scroll_id} || return( $self->error( "No scroll ID was returned by the MetaCPAN API" ) );
    $self->id( $id );
    return( $self );
}

sub time { return( shift->_set_get_scalar_as_object( 'ttl', @_ ) ); }

sub ttl { return( shift->_set_get_scalar_as_object( 'ttl', @_ ) ); }

sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

sub uri
{
    my $self = shift( @_ );
    my $uri = $self->SUPER::uri || return( $self->pass_error );
        # e.g.: /v1/author/_search -> /v1/author/_search/scroll
    $uri->path( $uri->path . '/scroll' );
    my $filter = $self->filter ||
        return( $self->error( "No search filter is set!" ) );
    my $size = $self->size // $filter->size;
    my $q = {};
    if( defined( my $ttl = $self->ttl ) )
    {
        $q->{scroll} = $ttl;
    }
    if( defined( $size ) )
    {
        $q->{size} = $size;
    }
    if( defined( my $id = $self->id ) )
    {
        $q->{scroll_id} = $id;
    }
    $uri->query_form( $q ) if( scalar( keys( %$q ) ) );
    return( $uri );
}

sub DESTROY
{
    my $self = shift( @_ );
    if( defined( my $id = $self->id ) )
    {
        $self->close;
    }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Scroll - Meta CPAN API Search Scroller

=head1 SYNOPSIS

    use Net::API::CPAN::Scroll;
    my $this = Net::API::CPAN::Scroll->new(
        time => '1m',
        size => 1000,
    ) || die( Net::API::CPAN::Scroll->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class is used to access a list of data like L<Net::API::CPAN::List> from which it inherits, but uses L<Elastic Search scroller|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html>. See the L<perl module|Search::Elasticsearch::Client::8_0::Scroll>

Note that with the scroll search, you can only scroll forward and not backward, which means you can only use L<next|Net::API::CPAN::List/next>, but not L<prev|Net::API::CPAN::List/prev>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or an hash reference of parameters and this will instantiate a new list object.

The valid parmeters that can be used are as below and can also be accessed with their corresponding method:

=over 4

=item * C<api>

An L<Net::API::CPAN> object.

=item * C<items>

An array reference of data.

=back

=head1 METHODS

=head2 close

    my $resp = $scroll->close; # returns an HTTP::Promise::Response object

If a scroll ID is set, this will issue a C<DELETE> C<HTTP> query to clear the scroll, and return the resulting L<HTTP::Promise::Response>, or, upon error, this will set an L<error object|Net::API::CPAN::Exception> and return C<undef> in scalar context, or an empty list in list context.

The C<HTTP> payload would look like something this:

    {
        "scroll_id" : ["c2Nhbjs2OzM0NDg1ODpzRlBLc0FXNlNyNm5JWUc1"]
    }

Alternatively, if you pass the option C<all> with a true value, this will issue an C<HTTP> query to clear all scroll.

See also L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#_clear_scroll_api>

=head2 id

Sets or gets the scroll ID as returned by the MetaCPAN API in the C<_scroll_id> property.

It returns a regular string representing the scroll ID, or C<undef> if none were set.

=head2 postprocess

This method is called by L</load> with the hash reference of data received from the MetaCPAN API, for possible post processing.

It returns the current object for chaining, or upon error, sets an L<error|Net::API::CPAN::Exception> and returns C<undef> in scalar context or an empty list in list context.

=head2 size

Sets or gets the size of the data to be returned by the Elastic Search.

Returns a L<number object|Module::Generic::Number>, or C<undef> if an L<error|Net::API::CPAN::Exception> occurred.

=head2 time

Same as L</ttl>

=head2 ttl

    $scroll->ttl( '1m' );
    my $time = $scroll->ttl;

Sets or gets the value for L<how long the data should be kept alive by Elastic Search|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context>.

Possible unit to use next to the integer are:

=over 4

=item  * C<y> Year

=item  * C<M> Month

=item  * C<w> Week

=item  * C<d> Day

=item  * C<h> Hour

=item  * C<m> Minute

=item  * C<s> Second

=item  * C<ms> Milli-second 

=back

See L<Elastic Search documentation on valid units|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/common-options.html#time-units>

Returns a L<scalar object|Module::Generic::Scalar> upon success, or sets an error L<Net::API::CPAN::Exception> and returns C<undef> in scalar context, or an empty list in list context.

=head2 uri

Returns the L<URI> to use for the scroll search, which will contain some query string even if the query is using C<HTTP> C<POST> method. For example:

    POST /v1/author/_search?scroll=1m
    {
      "size": 100,
      "query": {
        "match": {
          "message": "foo"
        }
      }
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html>

L<StackOverflow|https://stackoverflow.com/questions/46604207/elasticsearch-scroll>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

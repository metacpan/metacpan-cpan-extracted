package Search::Typesense::Role::Request;

use v5.16.0;
use Moo::Role;
use Search::Typesense::Types qw(
  Enum
  compile
);

our $VERSION = '0.06';

requires qw(
  _ua
  _url_base
);

sub _url {
    my ( $self, $path ) = @_;
    return $self->_url_base->clone->path( '/' . join( '/' => @$path ) );
}

sub _GET {
    my ( $self, %arg_for ) = @_;
    my $request = $arg_for{request};
    my @args    = $request ? ( form => $request ) : ();
    return $self->_handle_request( \%arg_for, \@args );
}

sub _DELETE {
    my ( $self, %arg_for ) = @_;
    return $self->_handle_request( \%arg_for );
}

sub _POST {
    my ( $self, %arg_for ) = @_;
    my $request = $arg_for{request};
    my @args    = ref $request ? ( json => $request ) : $request;
    return $self->_handle_request( \%arg_for, \@args );
}

sub _PATCH {
    my ( $self, %arg_for ) = @_;
    my $request = $arg_for{request};
    my @args    = ref $request ? ( json => $request ) : $request;
    return $self->_handle_request( \%arg_for, \@args );
}

sub _handle_request {
    my ( $self, $arg_for, $args ) = @_;

    # We must only be called by methods like _GET, _POST, _DELETE, and so on.
    # We strip the package name and leading underscore
    # (Search::Typesense::_GET becomes GET) and then we call lc() on what's
    # left. That becomes our HTTP verb and the $check verifies that this is an
    # allowed verb.
    my ( undef, undef, undef, $method ) = caller(1);
    $method =~ s/^.*::_//;
    state $check = compile( Enum [qw/get delete post patch/] );
    ($method) = $check->( lc $method );

    # make the actual request, passing a query string, if any, and passing any
    # args, if any (those can become part of a query string for GET, or part
    # of the body for other HTTP verbs
    my @args = $args ? @$args : ();
    my $url = $self->_url( $arg_for->{path} )->query( $arg_for->{query} || {} );
    my $tx  = $self->_ua->$method( $url, @args );
    my $res = $tx->res;

    # If the response is not succesful, return nothing if it's a 404.
    # Otherwise, croak()
    unless ( $res->is_success ) {
        return if ( $res->code // 0 ) == 404;
        my $message = $res->message // '';

        my $body   = $res->body;
        my $method = $tx->req->method;
        my $url    = $tx->req->url;
        croak("'$method $url' failed: $message. $body");
    }

    return $arg_for->{return_transaction} ? $tx : $tx->res->json;
} ## end sub _check_for_failure

1;

__END__

=head1 NAME

Search::Typesense::Role::Request - No user-serviceable parts inside.

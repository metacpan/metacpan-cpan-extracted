package RESTApp;
use strict;
use warnings;

use Plack::Request;
use Plack::Middleware::REST::Util;
use HTTP::Status qw(status_message);

sub new { 
    bless { hash => {}, count => 0 }, shift; 
}

## helper method

sub response {
    my $code = shift;
    my $body = @_ ? shift : status_message($code); 
    [ $code, [ 'Content-Type' => 'text/plain', @_ ], [ $body ] ];
}

## methods

sub resource {
    my ($self,$env) = @_;
    $self->{hash}->{ request_id($env) };
}

sub get {
    my ($self,$env) = @_;
    my $resource = $self->resource($env);
    return response(404) unless defined $resource;
    return response( 200 => ($env->{REQUEST_METHOD} eq 'GET' ? $resource : ''));
}

sub create {
    my ($self,$env) = @_;
    my ($resource, $type) = request_content($env);
    return response(400) unless defined $resource;

    my $id = ++$self->{count};
    $self->{hash}->{ $id } = $resource;

    my $uri = request_uri($env,$id);
    return response(201, $resource, Location => $uri); # or 204
}

sub update {
    my ($self,$env) = @_;
    
    return response(404) unless defined $self->resource($env);

    my ($resource, $type) = request_content($env);
    return response(400) unless defined $resource;

    $self->{hash}->{ request_id($env) } = $resource;
    return response(200,$resource); # or 204
}

sub delete {
    my ($self,$env) = @_;
    return (defined (delete $self->{hash}->{ request_id($env) })) 
        ? response(204,'') : response(404);
}

sub list {
    my ($self,$env) = @_;
    my @uris = map { request_uri($env,$_) } sort keys %{$self->{hash}}; 
    return response( 200 => '' ) if $env->{REQUEST_METHOD} eq 'HEAD';
    response(200, join "\n", @uris);
}

sub patch {
    my ($self,$env) = @_;
    
    return response(404) unless defined $self->resource($env);

    my ($resource, $type) = request_content($env);
    return response(400) unless defined $resource;

    $self->{hash}->{ request_id($env) } = $resource;
    return response(204,$resource);
}

1;

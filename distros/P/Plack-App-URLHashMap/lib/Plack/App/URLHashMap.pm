package Plack::App::URLHashMap;

use strict;
use warnings;

use parent 'Plack::Component';

our $VERSION = .1;

my $NOT_FOUND = [ 404, [ qw(Content-Type text/plain) ], [ 'Not Found' ] ];

sub map {
    my ( $self, $path, $app ) = @_;
 
    $self->{$path} = $app;
}

sub call {
    my ( $self, $env ) = @_;

    ( $_ = $self->{ $env->{PATH_INFO} } ) ? $_->($env) : $NOT_FOUND;
}

1;

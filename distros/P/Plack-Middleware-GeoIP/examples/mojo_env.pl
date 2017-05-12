#!/usr/bin/perl
use strict;
use warnings;
use Mojolicious::Lite;
use Plack::Builder;
use Data::Dump qw( dump );

get '/env' => sub {
    my $self = shift;
    my $text =  '<pre>' . dump( \%ENV ) . '<hr>' . dump( $self->req->env ) . '</pre>';
    $self->render(text => $text);
};

builder {
    enable sub {
        my $app = shift;
        sub { $_[0]->{GEO_TEST} = 'TEST VALUE'; $app->($_[0]) }; # set PSGI environment variable
    };
    app->start;
};

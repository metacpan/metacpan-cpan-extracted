#!/usr/bin/perl
use strict;
use warnings;
use Dancer;
use Data::Dump qw( dump );
use Plack::Builder;

get '/env' => sub {
    return '<pre>' . dump( \%ENV ) . '<hr>' . dump( request->env ) . '</pre>';
};

my $app = sub {
    my $env     = shift;
    my $request = Dancer::Request->new( env => $env );
    Dancer->dance($request);
};

builder {
    enable sub {
        my $app = shift;
        sub { $_[0]->{GEO_TEST} = 'TEST VALUE'; $app->($_[0]) }; # set PSGI environment variable
    };
    $app;
};

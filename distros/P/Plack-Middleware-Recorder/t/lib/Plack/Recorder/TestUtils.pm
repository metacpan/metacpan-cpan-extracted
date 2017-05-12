package Plack::Recorder::TestUtils;

use strict;
use warnings;

use HTTP::Request::Common;
use File::Temp;
use Plack::Builder;
use Plack::VCR;

sub import {
    my ( $class, @args ) = @_;

    my $pkg = caller;

    no strict 'refs';
    foreach my $sym (qw/GET POST/) {
        *{$pkg . '::' . $sym} = \&{__PACKAGE__ . '::' . $sym};
    }
}

sub get_app {
    my ( undef, %recorder_config ) = @_;

    my $tempfile = File::Temp->new;
    close $tempfile;

    return ( $tempfile->filename, builder {
        enable sub { # dummy middleware to hold a reference to $tempfile;
            my ( $app ) = @_;

            return sub {
                my ( $env ) = @_;

                ( undef) = $tempfile;

                return $app->($env);
            };
        };

        enable 'Recorder', output => $tempfile->filename, %recorder_config;
        sub {
            [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
        };
    } );
}

1;

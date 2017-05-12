package t::Util;
use strict;
use warnings;
use parent qw(Exporter);
use Test::More 0.98;
use File::Temp ();
use File::Spec;

our @EXPORT = qw(simple_app);

sub simple_app {
    return sub {
        my $env = shift;
        return [ '200', [ 'Content-Type' => 'text/plain' ], ["Hello World"] ];
    };
}

1;

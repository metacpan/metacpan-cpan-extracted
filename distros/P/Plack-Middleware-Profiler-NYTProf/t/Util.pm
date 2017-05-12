package t::Util;
use strict;
use warnings;
use parent qw(Exporter);
use Test::More 0.98;
use File::Temp ();
use File::Spec;

our @EXPORT = qw(simple_app tempdir path);

sub simple_app {
    return sub {
        my $env = shift;
        return [ '200', [ 'Content-Type' => 'text/plain' ], ["Hello World"] ];
    };
}

sub tempdir {
    return File::Temp::tempdir( CLEANUP => 1 );
}

sub path {
    File::Spec->catfile(@_);
}

1;

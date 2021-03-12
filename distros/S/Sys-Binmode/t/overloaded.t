#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp;

use Test::More;
use Test::FailWarnings;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $e_down = "é";

open my $wfh, '>', "$dir/$e_down";

my $destroyed;

my $path_obj = MyName->new("$dir/$e_down", \$destroyed);

do {
    use Sys::Binmode;

    open my $rfh, '<', $path_obj or do {
        diag "open failed: $!";
    };
    ok( fileno($rfh), 'open() with upgraded string' );
};

is( $path_obj->fetched_times(), 1, 'only fetched overload once' );

ok("$path_obj", 'no excess decref');

undef $path_obj;

ok($destroyed, 'no leak');

done_testing;

#----------------------------------------------------------------------

package MyName;

use overload (
    q<""> => sub {
        $_[0][2]++;

        my $v = $_[0][0];
        utf8::upgrade($v);
        $v;
    },
);

sub new {
    my ($class, $v, $destroy_sr) = @_;

    bless [$v, $destroy_sr, 0], $class;
}

sub fetched_times { $_[0][2] }

sub DESTROY {
    ${ $_[0][1] } = 1;
}

1;

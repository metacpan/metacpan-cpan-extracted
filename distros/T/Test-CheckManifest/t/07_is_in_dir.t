#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Test::More;
use Test::CheckManifest;

use Cwd;

my $sub = Test::CheckManifest->can('_is_in_dir');
ok $sub;

my $dir   = Cwd::realpath( dirname __FILE__ );
$dir      =~ s{.t\z}{};
my $t_dir = File::Spec->catdir( $dir, 't' );
my $abs_t_file = File::Spec->rel2abs( __FILE__ );

my @tests = (
    [ '/t/test.txt', '/t', 1 ],
    [ '/t/sub/test.txt', '/t', 1 ],
    [ '/t/test.txt', '/t2', undef ],
    [ '', '/t2', undef ],
    [ '/t/test.txt', '', undef ],
    [ undef, '', undef ],
    [ undef, '/t', undef ],
    [ undef, undef, undef ],
    [ '/t/test.txt', undef, undef ],
    [ '', undef, undef ],
    [ '/t/sub/', '/t', 1 ],
    [ '/t/sub/test', '/t/sub/', 1 ],
    [ '/t/test', '/t/sub/', undef ],
    [ __FILE__, dirname( __FILE__ ), 1 ],
    [ $abs_t_file, $t_dir, 1 ],
);

for my $test ( @tests ) {
    my ($file, $excludes, $expected) = @{$test};
    my $result = $sub->( $file, [$excludes] );

    is $result, $expected, sprintf "%s -> %s",
        ( defined $file ? $file : '<undef>' ),
        ( defined $excludes ? $excludes : '<undef>' );
}

done_testing();

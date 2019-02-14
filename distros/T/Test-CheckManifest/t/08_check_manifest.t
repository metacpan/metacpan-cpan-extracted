#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Test::More;
use Test::CheckManifest;

use Cwd;

local $ENV{NO_MANIFEST_CHECK} = 1;

my $sub = Test::CheckManifest->can('_check_manifest');
ok $sub;

my $dir   = Cwd::realpath( dirname __FILE__ );
$dir      =~ s{.t\z}{};
my $t_dir = File::Spec->catdir( $dir, 't' );
my $abs_t_file = File::Spec->rel2abs( __FILE__ );

#    my ($existing_files, $manifest_files, $excluded, $msg) = @_;

my $cnt = 0;

{
    my @tests = (
        [ undef, undef, undef, 'test', 1 ],
        [ ['/t/test'], undef, undef, 'test', '' ],
        [ ['/t/test'], ['/t/test'], undef, 'test', 1 ],
        [ ['/t/test'], undef, {'/t/test' => 1}, 'test', 1 ],
        [ ['/t/test'], ['/test'], {'/t/test' => 1}, 'test', '' ],
        [ ['/t/test'], ['/t/test', '/t/test'], undef, 'test', '' ],
        [ ['/t/test','/t/test2'], ['/t/test'], undef, 'test', '' ],
    );

    for my $test ( @tests ) {
        my @params   = @{$test};
        my $expected = pop @params;

        my $result = $sub->( @params );

        is $result, $expected, "Test $cnt";
        $cnt++;
    }
}

{
    local $Test::CheckManifest::test_bool = 0;
    my @tests = (
        [ undef, undef, undef, 'test', 1 ],
        [ ['/t/test'], undef, undef, 'test', '' ],
        [ ['/t/test'], ['/t/test'], undef, 'test', 1 ],
        [ ['/t/test'], undef, {'/t/test' => 1}, 'test', 1 ],
        [ ['/t/test'], ['/test'], {'/t/test' => 1}, 'test', '' ],
        [ ['/t/test'], ['/t/test', '/t/test'], undef, 'test', '' ],
        [ ['/t/test','/t/test2'], ['/t/test'], undef, 'test', '' ],
    );

    for my $test ( @tests ) {
        my @params   = @{$test};
        my $expected = pop @params;

        my $result = $sub->( @params );
        $cnt++;
    }
}

{
    local $Test::CheckManifest::test_bool = 0;
    local $Test::CheckManifest::VERBOSE = 0;
    my @tests = (
        [ undef, undef, undef, 'test', 1 ],
        [ ['/t/test'], undef, undef, 'test', '' ],
        [ ['/t/test'], ['/t/test'], undef, 'test', 1 ],
        [ ['/t/test'], undef, {'/t/test' => 1}, 'test', 1 ],
        [ ['/t/test'], ['/test'], {'/t/test' => 1}, 'test', '' ],
        [ ['/t/test'], ['/t/test', '/t/test'], undef, 'test', '' ],
        [ ['/t/test','/t/test2'], ['/t/test'], undef, 'test', '' ],
    );

    for my $test ( @tests ) {
        my @params   = @{$test};
        my $expected = pop @params;

        my $result = $sub->( @params );
        $cnt++;
    }
}

{
    local $Test::CheckManifest::VERBOSE = 0;
    my @tests = (
        [ undef, undef, undef, 'test', 1 ],
        [ ['/t/test'], undef, undef, 'test', '' ],
        [ ['/t/test'], ['/t/test'], undef, 'test', 1 ],
        [ ['/t/test'], undef, {'/t/test' => 1}, 'test', 1 ],
        [ ['/t/test'], ['/test'], {'/t/test' => 1}, 'test', '' ],
        [ ['/t/test'], ['/t/test', '/t/test'], undef, 'test', '' ],
        [ ['/t/test','/t/test2'], ['/t/test'], undef, 'test', '' ],
    );

    for my $test ( @tests ) {
        my @params   = @{$test};
        my $expected = pop @params;

        my $result = $sub->( @params );
        $cnt++;
    }
}

done_testing();

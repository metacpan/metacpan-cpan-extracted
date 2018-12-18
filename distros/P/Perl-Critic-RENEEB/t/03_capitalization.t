#!perl

use strict;
use warnings;

use Perl::Critic;
use Perl::Critic::Utils qw{ :severities };
use Test::More;

use Data::Dumper;
use File::Basename;
use File::Spec;

use constant POLICY => 'Perl::Critic::Policy::Reneeb::Capitalization';

diag 'Testing *::Capitalization version ' . POLICY->VERSION();

my $cnt = 1;

{
    my $pc = Perl::Critic->new( -only => 1 );
    $pc->add_policy( -policy => POLICY );

    my @tests = (
        [ 'package Test;',                0 ],
        [ 'package Test::World;',         0 ],
        [ 'package Test::World::prove;',  1 ],
        [ 'package test;',                1 ],
        [ 'package main;',                0 ],
        [ 'package Test::Command::prove', 1 ],
        [ 'package Test::Command::Prove', 0 ],
    );

    for my $test ( @tests ) {
        my ($code, $expect_errors) = @{$test};
        my @violations = $pc->critique( \$code );

        $expect_errors ?
            (ok scalar( @violations ), "$cnt: $code") :
            (ok !@violations , "$cnt: $code");
    }

    $cnt++;
}

{
    my $pc = Perl::Critic->new( -only => 1 );
    $pc->add_policy( -policy => POLICY, -params => { full_qualified_package_exemptions => '(?:main|Test::Command::.*)' } );

    my @tests = (
        [ 'package Test;',                0 ],
        [ 'package Test::World;',         0 ],
        [ 'package Test::World::prove;',  1 ],
        [ 'package test;',                1 ],
        [ 'package main;',                0 ],
        [ 'package Test::Command::prove', 0 ],
        [ 'package Test::Command::Prove', 0 ],
    );

    for my $test ( @tests ) {
        my ($code, $expect_errors) = @{$test};
        my @violations = $pc->critique( \$code );

        $expect_errors ?
            (ok scalar( @violations ), "$cnt: $code") :
            (ok !@violations , "$cnt: $code");
    }

    $cnt++;
}

{
    my $pc = Perl::Critic->new( -only => 1 );
    $pc->add_policy( -policy => POLICY, -params => { package_exemptions => '(main|Test::Command::.*)' } );

    my @tests = (
        [ 'package Test;',                0 ],
        [ 'package Test::World;',         0 ],
        [ 'package Test::World::prove;',  1 ],
        [ 'package test;',                1 ],
        [ 'package main;',                0 ],
        [ 'package Test::Command::prove', 1 ],
        [ 'package Test::Command::Prove', 0 ],
    );

    for my $test ( @tests ) {
        my ($code, $expect_errors) = @{$test};
        my @violations = $pc->critique( \$code );

        $expect_errors ?
            (ok scalar( @violations ), "$cnt: $code") :
            (ok !@violations , "$cnt: $code");
    }

    $cnt++;
}


{
    my $pc = Perl::Critic->new( -only => 1 );

    my $error;
    eval {
        $pc->add_policy( -policy => POLICY, -params => { full_qualified_package_exemptions => '(?:' } );
        1;
    }
    or do { $error = $@; };

    like $error, qr/The value for the Reneeb::Capitalization "_full_qualified_package_exemptions" option \("\(\?:"\) is not a valid regular expression/;

    $cnt++;
}

done_testing();

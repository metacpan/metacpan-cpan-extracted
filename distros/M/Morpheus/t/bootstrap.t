#!/usr/bin/perl
package Morpheus::Test::Bootstrap;

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Symbol;

use Config;

$ENV{PERL5LIB} = defined $ENV{PERL5LIB} ? "lib:$ENV{PERL5LIB}" : "lib";
$ENV{MORPHEUS_BOOTSTRAP_PATH} = 'lib';
my $perl = $Config{perlpath};

sub xqx {
    my $cmd = shift;
    my $res = scalar(`$cmd`);
    die "$cmd failed: $?" if $?;
    return $res;
}

sub general : Test(4) {
    is(xqx(qq#$perl -e 'use Morpheus -defaults => { test_bootstrap => 1 }; print morph("test_bootstrap")'#), 1, "Deafults plugin loads");
    is(xqx(qq#$perl -e 'use Morpheus -overrides => { test_bootstrap => 2 }; print morph("test_bootstrap")'#), 2, "Overrides plugin loads");
    is(xqx(qq#MORPHEUS='test_bootstrap => 4' $perl -e 'use Morpheus -defaults => { test_bootstrap => 3 }; print morph("test_bootstrap")'#), 4,
        "Env plugin loads");
    is(xqx(qq#MORPHEUS='test_bootstrap => 4' $perl -e 'use Morpheus::Bootstrap -path => ["t/lib"]; use Morpheus -defaults => { test_bootstrap => 3 }; print morph("test_bootstrap")'#), 3,
        "Env plugin disabled by a specific bootstrapper");
}

__PACKAGE__->runtests;

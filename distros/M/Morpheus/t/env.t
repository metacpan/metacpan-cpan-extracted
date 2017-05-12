#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use lib 'lib';
use Morpheus;

use Config;

$ENV{PERL5LIB} = defined $ENV{PERL5LIB} ? "lib:$ENV{PERL5LIB}" : "lib";
$ENV{MORPHEUS_BOOTSTRAP_PATH} = 'lib';
my $perl = $Config{perlpath};

is(scalar(`MORPHEUS='"env_test_x" => "y"' $perl -e 'use Morpheus; print morph("env_test_x")'`), "y", 'Env: simple test');
is(scalar(`MORPHEUS='"env/test/x" => { y => "z" }' $perl -e 'use Morpheus; print morph("env/test/x/y")'`), "z", 'Env: keys are normalized');
is(scalar(`MORPHEUS='"env/test/x" => "y", "env/test/z" => "t"' $perl -e 'use Morpheus; print morph("env/test/x"), morph("env/test/z")'`), "yt", 'Env: multiple values via list');
is(scalar(`MORPHEUS='{"env/test/x" => "y", "env/test/z" => "t"}' $perl -e 'use Morpheus; print morph("env/test/x"), morph("env/test/z")'`), "yt", 'Env: multiple values via hash');
is(scalar(`MORPHEUS= $perl -e 'use Morpheus; print morph("env.test")'`), "", "Env: empty env");

$ENV{MORPHEUS} = '{"env/test/x" => ["a", "b"], "env/test/z/t" => "v"}';
is_deeply(morph("env/test"), {x => ["a", "b"], z => {t => "v"}}, "Env: cummulative test");


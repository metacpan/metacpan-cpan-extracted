#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use Config;
my $perl = $Config{perlpath};

use lib 'lib';
$ENV{PERL5LIB} = defined $ENV{PERL5LIB} ? "lib:$ENV{PERL5LIB}" : "lib";
$ENV{MORPHEUS_BOOTSTRAP_PATH} = 'lib';

my $use = 'use Morpheus -overrides => {"morpheus/plugin/file/options" => {path => ["t/etc/"] }};';
my $env = 'use Morpheus; "cross/test" => { x4 => morph("cross/test/x1") + 1, x2 => 1 }';

is(`MORPHEUS='$env' $perl -e '$use; print morph("cross/test/x1")'`, 1, 'cross: File value');
is(`MORPHEUS='$env' $perl -e '$use; print morph("cross/test/x2")'`, 1, 'cross: Env value');
is(`MORPHEUS='$env' $perl -e '$use; print morph("cross/test/x3")'`, 2, 'cross: File may depend on Env');
is(`MORPHEUS='$env' $perl -e '$use; print morph("cross/test/x4")'`, 2, 'cross: Env may depend on File');
is(`MORPHEUS='$env' $perl -e '$use; print morph("cross/test/x\$_") for (1,2,3,4)'`, "1122", 'cross: cummulative test 1');
is(`MORPHEUS='$env' $perl -e '$use; print morph("cross/test/x\$_") for (4,3,2,1)'`, "2211", 'cross: cummulative test 2');


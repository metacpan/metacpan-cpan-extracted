#!/usr/bin/perl -w
use strict;

use Test::More tests => 16;
use File::Spec::Functions;

use lib 't';
use_ok('TestNonOOOverride');
use Module::Bundled::Files qw{:all};
my $o = new TestNonOOOverride;
ok($o,'new test object');
isa_ok($o,'TestNonOOOverride');
isa_ok($o,'TestNonOO');

cmp_ok($o->donothing,'eq','nothing done','own sub');

my $isvalid;

my $invalid = catfile('..','..','..','etc','hosts');
eval{$isvalid = mbf_validate($invalid);};
is($isvalid,undef,'mbf_valildate invalid');

my $valid = 'non-existant';
eval{$isvalid = mbf_validate($valid);};
ok($isvalid,'mbf_validate valid');

my $dir;
eval{$dir = mbf_dir($o);};
cmp_ok($dir,'eq',catdir('t','TestNonOOOverride'),'mbf_dir');

my $exists;
eval{$exists = mbf_exists($o,$valid);};
ok(!$exists,'mbf_exists non-existant');

my $filename = 'data.txt';
eval{$exists = mbf_exists($o,$filename);};
ok($exists,'mbf_exists existant');

my $fullpath;
eval{$fullpath = mbf_path($o,$filename);};
cmp_ok($fullpath,'eq',catfile('t','TestNonOOOverride','data.txt'),'mbf_path');

{
    my $fh;
    eval{$fh = mbf_open($o,$filename);};
    ok($fh,'mbf_open');
    # autoclose file on scope exit
}

my $data;
eval{$data = mbf_read($o,$filename);};
like($data,qr/content of the file/,'mbf_read data.txt 1');
like($data,qr/second line/,'mbf_read data.txt 2');
like($data,qr/t-TestNonOO-Override-data.txt/,'mbf_read data.txt 3');

$data = undef;
my $inherited = 'testnonoo.txt';
eval{$data = mbf_read($o,$inherited);};
like($data,qr/t-TestNonOO-testnonoo.txt/,'mbf_read inherited');
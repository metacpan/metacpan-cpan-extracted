#!/usr/bin/perl -w
use strict;

use Test::More tests => 17;
use File::Spec::Functions;

use lib 't';
use_ok('TestOOOverride');
my $o = new TestOOOverride;
ok($o,'new test object');
isa_ok($o,'TestOOOverride');
isa_ok($o,'TestOO');
isa_ok($o,'Module::Bundled::Files');

cmp_ok($o->donothing,'eq','nothing done','own sub');

my $isvalid;

my $notvalid = catfile('..','..','..','etc','hosts');
eval{$isvalid = $o->mbf_validate($notvalid);};
is($isvalid,undef,'mbf_valildate invalid');

my $valid = 'non-existant';
eval{$isvalid = $o->mbf_validate($valid);};
ok($isvalid,'mbf_validate valid');

my $dir;
eval{$dir = $o->mbf_dir();};
cmp_ok($dir,'eq',catdir('t','TestOOOverride'),'mbf_dir');

my $exists;
eval{$exists = $o->mbf_exists($valid);};
ok(!$exists,'mbf_exists non-existant');

my $filename = 'data.txt';
eval{$exists = $o->mbf_exists($filename);};
ok($exists,'mbf_exists existant');

my $fullpath;
eval{$fullpath = $o->mbf_path($filename);};
cmp_ok($fullpath,'eq',catfile('t','TestOOOverride','data.txt'),'mbf_path');

{
    my $fh;
    eval{$fh = $o->mbf_open($filename);};
    ok($fh,'mbf_open');
    # autoclose file on scope exit
}

my $data;
eval{$data = $o->mbf_read($filename);};
like($data,qr/content of the file/,'mbf_read data.txt 1');
like($data,qr/second line/,'mbf_read data.txt 2');
like($data,qr/t-TestOO-Override-data.txt/,'mbf_read data.txt 3');

$data = undef;
my $inherited = 'testoo.txt';
eval{$data = $o->mbf_read($inherited);};
like($data,qr/t-TestOO-testoo.txt/,'mbf_read inherited');
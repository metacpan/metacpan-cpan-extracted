#!perl -w
use strict;
use warnings;
use utf8;
use Test::More;

use Script::Ichigeki::Hissatsu;
use File::Temp qw/tempdir/;
use Path::Class qw/dir file/;

my $dir = dir(tempdir(CLEANUP => 1));
my $script_name = 'test_ichigeki.pl';
my $file = $dir->file($script_name);
$file->openw->print(do{local $/;<DATA>});

my $hissatsu = new_ok 'Script::Ichigeki::Hissatsu' => [script => $file];
ok $hissatsu->_log_file;
ok ! -f $hissatsu->_log_file;

ok system($^X, $file) == 0, 'running ok';
ok -f $hissatsu->_log_file;
like $hissatsu->_log_file->slurp, qr/ichigekiiiiiiiiiiiiiii/;
ok system($^X, $file) != 0, 'rerunning propery failing';

done_testing;
__DATA__
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Script::Ichigeki ();

Script::Ichigeki->hissatsu(confirm_dialog => 0);
print "ichigekiiiiiiiiiiiiiii\n";

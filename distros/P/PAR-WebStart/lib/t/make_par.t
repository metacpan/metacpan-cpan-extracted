#!/usr/bin/perl
use strict;
use warnings;
use Test;
use File::Spec;
use File::Basename;
use File::Which;
use Cwd;
BEGIN {plan tests => 5};
use PAR::WebStart::Util qw(make_par verifyMD5);
use constant WIN32 => PAR::WebStart::Util::WIN32;

my $cwd = getcwd;
my $name = 'MyPar';
my $src_dir = File::Spec->catdir($cwd, '../ex', 'D');
my $dst_dir = File::Spec->catdir($cwd, 't');
my ($dst_par, $cs) = make_par(src_dir => $src_dir, dst_dir => $dst_dir,
                              name => 'MyPar', no_sign => 1);
ok(-f $dst_par);
ok(-f $cs);
my $basename = basename($dst_par, qr{\.par});
ok($basename, $name . '.par');
my $rc = verifyMD5(md5 => $cs, file => $dst_par);
ok($rc, 1);

my $par_command = WIN32 ? which('par') : which('par.pl');
if ($par_command) {
  my @args = ($par_command, $dst_par);
  $rc = system(@args);
  ok($rc, 0);
}
else {
  skip(1);
}
my $manifest = File::Spec->catfile($src_dir, 'MANIFEST');
unlink($dst_par, $cs, $manifest);


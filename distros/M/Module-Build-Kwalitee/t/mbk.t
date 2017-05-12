#!perl
use warnings;
use strict;

use Test::More tests => 30;
use Config;
use FindBin qw($Bin);
use Cwd qw( abs_path );
use File::Spec::Functions;
use IPC::Open3;

my $perl = $Config{perlpath};
my $prove = $perl;
$prove =~ s/perl$/prove/;

my @perl = ($perl, map { "-I".abs_path($_) } @INC);
my @prove = ($prove, '-l', map { "-I".abs_path($_) } @INC);

chdir(catdir($Bin, qw(.. tests fail_compile)));

sub run_cmd {
  my ($should_pass, @cmd) = @_;
  my $pid = open3(my ($in, $out, undef), "@cmd");
  last if wait == -1;
  ok ( ($should_pass && ! $?) || (!$should_pass && $?), ($should_pass ? "passed " : "failed ") . $cmd[-1] ) or do {
    read($out, my $error, 9999) or die "could not read from file: $!";
    diag $error;
  }
}

run_cmd(1, @perl, "Build.PL");
run_cmd(1, @perl, "Build");
run_cmd(0, @prove, catfile('t', '000compile.t'));
run_cmd(1, @prove, catfile('t', '001pragmas.t'));
run_cmd(1, @prove, catfile('t', '003pod.t'));
run_cmd(1, @prove, catfile('t', '004uselib.t'));

chdir(catdir($Bin, qw(.. tests fail_compilebin)));
run_cmd(1, @perl, "Build.PL");
run_cmd(1, @perl, "Build");
run_cmd(0, @prove, catfile('t', '000compile.t'));
run_cmd(1, @prove, catfile('t', '001pragmas.t'));
run_cmd(1, @prove, catfile('t', '003pod.t'));
run_cmd(1, @prove, catfile('t', '004uselib.t'));

chdir(catdir($Bin, qw(.. tests fail_pragmas)));
run_cmd(1, @perl, "Build.PL");
run_cmd(1, @perl, "Build");
run_cmd(1, @prove, catfile('t', '000compile.t'));
run_cmd(0, @prove, catfile('t', '001pragmas.t'));
run_cmd(1, @prove, catfile('t', '003pod.t'));
run_cmd(1, @prove, catfile('t', '004uselib.t'));


chdir(catdir($Bin, qw(.. tests fail_pod)));
run_cmd(1, @perl, "Build.PL");
run_cmd(1, @perl, "Build");
run_cmd(1, @prove, catfile('t', '000compile.t'));
run_cmd(1, @prove, catfile('t', '001pragmas.t'));
run_cmd(0, @prove, catfile('t', '003pod.t'));
run_cmd(1, @prove, catfile('t', '004uselib.t'));

chdir(catdir($Bin, qw(.. tests fail_uselib)));
run_cmd(1, @perl, "Build.PL");
run_cmd(1, @perl, "Build");
run_cmd(1, @prove, catfile('t', '000compile.t'));
run_cmd(1, @prove, catfile('t', '001pragmas.t'));
run_cmd(1, @prove, catfile('t', '003pod.t'));
run_cmd(0, @prove, catfile('t', '004uselib.t'));

#!/usr/bin/perl -w
#
# Tests ProjectBuilder::Base functions

use strict;
use ProjectBuilder::Base;
use ProjectBuilder::Conf;
use ProjectBuilder::Distribution;

eval
{
	require Test::More;
	Test::More->import();
	my ($tmv,$tmsv) = split(/\./,$Test::More::VERSION);
	if ($tmsv lt 87) {
		die "Test::More is not available in an appropriate version ($tmsv)";
	}
};

# Test::More appropriate version not found so no test will be performed here
if ($@) {
	require Test;
	Test->import();
	plan(tests => 1);
	print "# Faking tests as Test::More is not available in an appropriate version\n";
	ok(1,1);
	exit(0);
}

my $nt = 0;

$ENV{'TMPDIR'} = "/tmp";
pb_temp_init();

pb_conf_init("test");
open(FILE,"> $ENV{'TMPDIR'}/conf.pb") || die "Unable to create $ENV{'TMPDIR'}/conf.pb";
# should be in alphabetic order
print FILE "truc mageia-4-x86_64 = la tete a toto\n";
print FILE "yorro mageia-3-x86_64 = tartampion\n";
print FILE "zz mageia-3-x86_64 = yy\n";
close(FILE);
my $cnt = pb_get_content("$ENV{'TMPDIR'}/conf.pb");

my %h;
my $h = \%h;
$h = pb_conf_cache("$ENV{'TMPDIR'}/conf.pb",$h);
pb_conf_write("$ENV{'TMPDIR'}/test.pb",$h);
my $content = pb_get_content("$ENV{'TMPDIR'}/test.pb");
is($cnt, $content, "pb_conf_write Test");
$nt++;
unlink("$ENV{'TMPDIR'}/conf.pb");
unlink("$ENV{'TMPDIR'}/test.pb");

done_testing($nt);

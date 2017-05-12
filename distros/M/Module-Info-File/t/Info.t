#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Test::More;
use File::Basename;

use Env qw($TEST_VERBOSE);

if ($TEST_VERBOSE) {
    diag 'These test are of the super class Module::Info, if they fail, Module::Info::File is obsolete';
}

#test 1
use_ok('Module::Info');

my $path = 'lib/Module/Info/File.pm';
my $module = Module::Info->new_from_file($path);

#test 2
isa_ok($module, 'Module::Info');

#test 3
is($module->name, '', 'Testing the name');

if ($module->name) {
	diag qq[\nIf test 3 failed, Module::Info::File is probably obsolete and can
be discontinued, please inform the author at jonasbn\@cpan.org and include the information
 below\n];
    diag "Name = ".$module->name."\n";
}

#test 4
like($module->version, qr/\d+\.\d+/, 'Testing the version');
diag "Version = ".$module->version."\n" if $TEST_VERBOSE;

#test 5
my ($name,$v,$suffix) = fileparse($path,"\.pm");
fileparse_set_fstype($^O);

like($module->file, qr/$name$suffix/, 'Testing the file');
diag "File = ".$module->file."\n" if $TEST_VERBOSE;

#test 6
is($module->inc_dir, '', 'Testing the dir');

if ($module->inc_dir) {
	diag qq[\nIf test 6 failed, Module::Info::File is probably obsolete and can
be discontinued, please inform the author at jonasbn\@cpan.org and include the information
 below\n];
    diag "Dir = ".$module->inc_dir."\n";
}

diag Dumper $module if $TEST_VERBOSE;

done_testing();

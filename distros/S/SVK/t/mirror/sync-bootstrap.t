#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
eval { require SVN::Dump; 1 } or plan skip_all => 'require SVN::Dump';
plan tests => 8;

my ($xd, $svk) = build_test('test', 'm2', 'm3');

our $output;

my $tree = create_basic_tree($xd, '/test/');
my $depot = $xd->find_depot('test');

my $uri = uri($depot->repospath);

my $dump = File::Temp->new;
dump_all($depot => $dump);
close $dump;

is_output($svk, mirror => ['//m', $uri],
          ["Mirror initialized.  Run svk sync //m to start mirroring."]);

is_output($svk, mirror => ['/m2/m', $uri],
          ["Mirror initialized.  Run svk sync /m2/m to start mirroring."]);
$svk->sync('/m2/m');

is_output($svk, mirror => ['--bootstrap='.$dump, '//m', $uri],
	  ['Bootstrapping mirror from dump',
	   'Mirror path \'//m\' synced from dumpfile.']);

# compare normal mirror result and bootstrap mirror result
my ($exp_mirror, $boot_mirror);
open my $exp, '>', \$exp_mirror;
open my $boot, '>', \$boot_mirror;
dump_all($xd->find_depot('') => $boot);
dump_all($xd->find_depot('m2') => $exp);
$exp_mirror =~ s/UUID: .*//;
$boot_mirror =~ s/UUID: .*//;
# remove first svn-date (initial mirro)
# 2007-08-09T14:43:18.137165Z
$exp_mirror =~ s/\d{4}-\d{2}-\d{2}T[\d:.]+Z//;
$boot_mirror =~ s/\d{4}-\d{2}-\d{2}T[\d:.]+Z//;

is($boot_mirror, $exp_mirror, 'UUID should be the same'); # do something with UUID, they should be identical

# now try with mirror, sync in single bootstrap command

# try feed with incorrect file 
is_output($svk, mirror => ['--bootstrap=./no-such-file', '/m3/m', $uri],
          ["No such dump file: ./no-such-file."]);
# this is real test
is_output($svk, mirror => ['--bootstrap',$dump->filename, '/m3/m', $uri],
	  ['Mirror initialized.  Run svk sync /m3/m to start mirroring.',
	   'Bootstrapping mirror from dump',
	   "Mirror path '/m3/m' synced from dumpfile."]);

# compare UUID

my ($boot_mirror2);
open my $boot2, '>', \$boot_mirror2;
dump_all($xd->find_depot('m3') => $boot2);
$boot_mirror2 =~ s/UUID: .*//;
# remove first svn-date (initial mirro)
# 2007-08-09T14:43:18.137165Z
$boot_mirror2 =~ s/\d{4}-\d{2}-\d{2}T[\d:.]+Z//;

is($boot_mirror, $boot_mirror2, 'UUID should be the same');
is($exp_mirror, $boot_mirror2, 'UUID should be the same');

sub dump_all {
    my ($depot, $output) = @_;
    my $repos = $depot->repos;
    SVN::Repos::dump_fs2($repos, $output, undef, 1, $repos->fs->youngest_rev, 0, 0, undef, undef);
}

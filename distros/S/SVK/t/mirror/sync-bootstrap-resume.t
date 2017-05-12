#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
eval { require SVN::Dump; 1 } or plan skip_all => 'require SVN::Dump';
plan tests => 7;

my ($xd, $svk) = build_test('test', 'm2', );

our $output;

my $tree = create_basic_tree($xd, '/test/');
my $depot = $xd->find_depot('test');

my $uri = uri($depot->repospath);

my $dump = File::Temp->new;
dump_all($depot => $dump);
close $dump;

my $dump_Part = File::Temp->new;
dump_N($depot => $dump_Part, 1 );
close $dump_Part;

is_output($svk, mirror => ['//m', $uri],
          ["Mirror initialized.  Run svk sync //m to start mirroring."]);

is_output($svk, mirror => ['--bootstrap='.$dump, '//m', $uri],
	  ['Bootstrapping mirror from dump',
	   'Mirror path \'//m\' synced from dumpfile.']);

is_output($svk, mirror => ['/m2/m', $uri],
          ["Mirror initialized.  Run svk sync /m2/m to start mirroring."]);

is_output($svk, mirror => ['--bootstrap='.$dump_Part, '/m2/m', $uri],
	  ['Bootstrapping mirror from dump',
	   'Mirror path \'/m2/m\' synced from dumpfile.']);

# compare normal mirror result and bootstrap mirror result
my ($exp_mirror, $boot_mirror);
open my $exp, '>', \$exp_mirror;
open my $boot, '>', \$boot_mirror;
dump_N($xd->find_depot('') => $boot, 1);
dump_all($xd->find_depot('m2') => $exp);
$exp_mirror =~ s/UUID: .*//;
$boot_mirror =~ s/UUID: .*//;
# remove first svn-date (initial mirro)
# 2007-08-09T14:43:18.137165Z
$exp_mirror =~ s/\d{4}-\d{2}-\d{2}T[\d:.]+Z//;
$boot_mirror =~ s/\d{4}-\d{2}-\d{2}T[\d:.]+Z//;

is($boot_mirror, $exp_mirror, 'UUID should be the same'); # do something with UUID, they should be identical

close $exp;
close $boot;
# now try with mirror, sync in single bootstrap command

is_output($svk, mirror => ['--bootstrap='.$dump, '/m2/m', $uri],
	  ['Bootstrapping mirror from dump',
	   'Skipping dumpstream up to revision 1',
	   'Mirror path \'/m2/m\' synced from dumpfile.']);

open $exp, '>', \$exp_mirror;
open $boot, '>', \$boot_mirror;
dump_all($xd->find_depot('') => $boot);
dump_all($xd->find_depot('m2') => $exp);
$exp_mirror =~ s/UUID: .*//;
$boot_mirror =~ s/UUID: .*//;
# remove first svn-date (initial mirro)
# 2007-08-09T14:43:18.137165Z
$exp_mirror =~ s/\d{4}-\d{2}-\d{2}T[\d:.]+Z//;
$boot_mirror =~ s/\d{4}-\d{2}-\d{2}T[\d:.]+Z//;

close $exp;
close $boot;

is($boot_mirror, $exp_mirror, 'UUID should be the same'); # do something with UUID, they should be identical

sub dump_N {
    my ($depot, $output, $N) = @_;
    my $repos = $depot->repos;
    my $rev = ($N >= $repos->fs->youngest_rev) ? $repos->fs->youngest_rev : $repos->fs->youngest_rev - $N;
    SVN::Repos::dump_fs2($repos, $output, undef, 1, $rev , 0, 0, undef, undef);
}

sub dump_all {
    my ($depot, $output) = @_;
    dump_N ($depot, $output, $depot->repos->fs->youngest_rev);
}


#!/usr/bin/perl -w
use Test::More tests => 15;
use strict;
use SVK::Test;
use SVK::Util 'IS_WIN32';
require Storable;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath ('cleanup');

my ($repospath) = $xd->find_repos ('//');

$xd->{svkpath} = $repospath;
$xd->{statefile} = __("$repospath/svk.config");
$xd->{giantlock} = __("$repospath/svk.giant");

$xd->giant_lock;
SKIP: {
skip 'lock prevents file being read on win32', 1 if IS_WIN32;
is_file_content ($xd->{giantlock}, $$, 'giant locked');
}
ok ($xd->{giantlock_handle}, 'giant locked');
$xd->store;
ok ($xd->{updated}, 'marked as updated');
ok (!$xd->{giantlock_handle}, 'giant unlocked');
$xd->giant_lock;
$svk->checkout ('//', $copath);
ok (!$xd->{giantlock_handle}, 'giant unlocked after command invocation');
is_output_like ($svk, 'cleanup', [$copath], qr'not locked');
$xd->giant_lock;
$xd->lock ($corpath);
is ($xd->{checkout}->get ($corpath)->{lock}, $$, 'copath locked');
# fake lock by other process
$xd->{checkout}->store ($corpath, {lock => $$+1});
$xd->store;
$xd->load;
is_output_like ($svk, 'update', [$copath],
		qr'already locked', 'command not allowed when copath locked');
chdir ($copath);
is_output_like ($svk, 'cleanup', [], qr'Cleaned up stalled lock');
is ($xd->{checkout}->get ($corpath)->{lock}, undef,  'unlocked');

$xd->{checkout}->store ($corpath, {lock => $$+1});
$xd->store;
$xd->load;
is_output_like ($svk, 'cleanup', ['-a'], qr'Cleaned up all stalled lock');
is_output ($svk, 'update', [],
	   ["Syncing //(/) in $corpath to 0."]);

my $tree = create_basic_tree ($xd, '//');

my $output2 = '';
$svk->up;
$xd->store;

# concurrency
$xd->load;
$xd->lock(__("$corpath/A"));
$xd->store;
$xd->{checkout}->store(__("$corpath/A"), { revision => 1});

my $xd2 = Storable::dclone($xd);
my $svk2 = SVK->new(xd=> $xd2, output => \$output2);
{ local $$ = $$+1;
  $xd2->load;
  $xd2->lock(__("$corpath/B"));
  $xd2->{checkout}->store(__("$corpath/B"), { revision => 1});
  $xd2->store;
}
$xd->store;
$xd->load;

eval { $xd2->load };
ok ($@ =~ qr'Another svk', 'command not allowed when giant locked');

$xd->giant_unlock;
$xd2->load;
$xd2->giant_unlock;

is($xd->{checkout}->get(__("$corpath/B"))->{revision}, 1);
is($xd2->{checkout}->get(__("$corpath/A"))->{revision}, 1);

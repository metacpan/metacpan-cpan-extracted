#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;
use SVK::Test;
use SVN::Ra;
use SVK::Mirror::Backend::SVNSync;

my ($xd, $svk) = build_test('test');
my $depot = $xd->find_depot('test');

my ($copath, $corpath) = get_copath();
our $output;

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/A', 1);
my $tree = create_basic_tree($xd, '/test/');

my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

is_output($svk, mirror => ['//A', $uri],
          ["Mirror initialized.  Run svk sync //A to start mirroring."]);
waste_rev($svk, '/test/useless');

$svk->co('/test/', $copath);

append_file("$copath/A/Q/qu", "edited");
$svk->ci(-m => 'change A qu', $copath);

is_output($svk, sync => ['//A'],
          ['Syncing '.$uri,
	   'Retrieving log information from 1 to 5',
	   'Committed revision 2 from revision 1.',
	   'Committed revision 3 from revision 2.',
	   'Committed revision 4 from revision 5.']);


my $path = SVK::Path->real_new( { depot => $depot, path => '/A'})->refresh_revision;
{
    my $pool = SVN::Pool->new;
    my ($editor) =
	$path->get_editor( callback => sub { ok(1, 'committed with api') },
			   author => 'svktest', message => 'creating copy with revhole');
    my $rb = $editor->open_root($path->revision);
    $editor->close_file( $editor->add_file('qu-from-a', $rb, "/A/Q/qu", 4), undef);
    $editor->close_directory($rb);
    $editor->close_edit;
}

is_output($svk, sync => ['//A'],
          ['Syncing '.$uri,
	   'Retrieving log information from 6 to 6',
	   'Committed revision 5 from revision 6.']);



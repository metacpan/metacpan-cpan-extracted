#!/usr/bin/perl -w
use strict;
use SVK::Test;
use SVK::Util qw($EOL uri_escape);
plan tests => 3;
our $output;

my ($xd, $svk) = build_test('test');

my $depotpath = '/test/';
my $pool = SVN::Pool->new_default;
my ($depot, $path) = $xd->find_depotpath($depotpath);
{
    local $/ = $EOL;
    my $edit = get_editor ($depot->repospath, $path, $depot->repos);
    $edit->open_root ();

    $edit->add_directory ('/B and K');
    $edit->add_directory ('/B and K/A');
    $edit->add_directory ('/B and K/A/N P1');
    $edit->add_directory ('/B and K/A/N P1/trunk');
    $edit->add_directory ('/B and K/A/N P1/trunk/doc');
    $edit->modify_file (
	$edit->add_file ('/B and K/A/N P1/trunk/doc/ReadMe.txt'),
			"first line in pe$/2nd line in pe$/");
    $edit->add_directory ('/B and K/A/N P1/trunk/src');
    $edit->add_directory ('/B and K/A/N P1/trunk/data');
    $edit->add_directory ('/B and K/A/N P1/branches');
    $edit->add_directory ('/B and K/A/N P1/tags');
    $edit->close_edit ();
}
my $uri = uri($depot->repospath);
my $uri_trunk = $uri.'/B and K/A/N P1/trunk';
my $uri_trunk_escape = uri_escape($uri_trunk);

$svk->mirror('//mirror/BK', $uri_trunk);

is_output ($svk, 'mirror', ['--list'], [
    "Path          Source",
    qr"=========+",
    "//mirror/BK   $uri/B and K/A/N P1/trunk"]);

is_output ($svk, 'sync', ['//mirror/BK'], [
    "Syncing $uri/B and K/A/N P1/trunk",
    "Retrieving log information from 1 to 1",
    "Committed revision 2 from revision 1."]);

# detach and try with snapshot sync
$svk->mirror ('-d','//mirror/BK');

$svk->mirror('//mirror/BK2', $uri_trunk);

is_output ($svk, 'sync', [-s => 'HEAD', '//mirror/BK2'],
          [(map { qr'.*'} (1..8)),
	   'Syncing '.$uri_trunk_escape,
	   'Retrieving log information from 1 to 1',
	   'Committed revision 5 from revision 1.',
	   'Syncing '.$uri_trunk]);

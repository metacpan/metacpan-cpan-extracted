#!/usr/bin/perl

use strict;
use Test::More tests => 8;
use File::Path;
use File::Spec;

BEGIN {
require_ok 'SVN::Core';
require_ok 'SVN::Repos';
require_ok 'SVN::Fs';
require_ok 'SVN::Simple::Edit';
}

local $/;

my $repospath = "t/repos";
rmtree ([$repospath]) if -d $repospath;

$ENV{SVNFSTYPE} ||= (($SVN::Core::VERSION =~ /^1\.0/) ? 'bdb' : 'fsfs');

my $repos = SVN::Repos::create($repospath, undef, undef, undef,
			       {'fs-type' => $ENV{SVNFSTYPE}})
    or die "failed to create repository at $repospath";

my $uri = File::Spec->rel2abs( $repospath ) ;
$uri =~ s{^|\\}{/}g if ($^O eq 'MSWin32');
$uri = "file://$uri";

ok($repos);

my $fs = $repos->fs;

sub committed {
    diag "committed ".join(',',@_);
}

my $edit;

sub new_edit {
    my ($check) = @_;
    my $base = $fs->youngest_rev;
    $edit = SVN::Simple::Edit->
	new(_editor => [SVN::Repos::get_commit_editor
			($repos, $uri,
			 '/', 'root', 'FOO', \&committed)],
	    pool => SVN::Pool->new,
	    missing_handler => ($check ?
	    (&SVN::Simple::Edit::check_missing ($fs->revision_root ($base))) :
	    sub {
		my ($edit, $path) = @_;
		diag "build missing directory for $path";
		$edit->add_directory ($path);
	    }));
    $edit->open_root ($base);
    return $edit;
}

$edit = new_edit;

$edit->add_file ('trunk/deep/more/gfilea');
$edit->add_file ('trunk/deep2/more/gfileb');

$edit->add_file ('filea');

my $text = "FILEA CONTENT";
$edit->modify_file ('filea', $text);


$edit->add_file ('fileb');
open my ($fh), $0;
$edit->modify_file ('fileb', $fh);

$edit->close_edit();

cmp_ok($fs->youngest_rev, '==', 1);

my $filea = SVN::Fs::file_contents($fs->revision_root (1), 'filea');
is(<$filea>, $text, "content from string verified");
my $fileb = SVN::Fs::file_contents($fs->revision_root (1), 'fileb');
seek $fh, 0, 0;
is(<$fileb>, <$fh>, "content from stream verified");

$edit = new_edit;

$edit->modify_file($edit->open_file ('fileb'), 'foo');

$edit->close_edit;

$edit = new_edit(1);

#$edit->open_directory ('trunk');
#$edit->open_directory ('trunk/deep');
$edit->delete_entry ('trunk/deep/more');

$edit->close_edit;

$edit = new_edit;

$edit->open_directory ('trunk');
$edit->open_directory ('trunk/deep');

$edit->close_edit;

#! /usr/bin/perl -w

# This file is used by makepbs.bat as the source for pbs.exe.
#
# Retrieves PBS (_pbs.exe) from a server ($src) and runs it.
#
# The PBSLib and Plugins directories are extracted from _pbs.exe and copied to
# a local cache ($cache_dir).

use strict;
use warnings;

use File::Spec;
use Win32::Job;

# 10.19.9.2 is kurdamir
my $src = 'http://10.19.9.2/Athena/_pbs.exe';

my $cache_dir = '_pbs_cache';
my $dst = File::Spec->catfile($cache_dir, '_pbs.exe');

my @dirs_to_extract = map
	{
		$_->{path} = File::Spec->rel2abs($_->{name}, $cache_dir);
		$_;
	}
	(
		{ name => 'PBSLib', env_var => 'PBS_LIB_PATH' },
		{ name => 'Plugins', env_var => 'PBS_PLUGIN_PATH' }
	);

use constant UPDATED => 0;
use constant UNCHANGED => 1;


CreateCacheDirectory($cache_dir);

if (MirrorFile($src, $dst) == UPDATED)
{
	ExtractFiles($dst, @dirs_to_extract);
}

SetEnvVars(@dirs_to_extract);

# A simple 'system' does not get the file handles right for stdout and stderr,
# shell redirection and pipe does not work. Win32::Job seems to work better.
my $job = Win32::Job->new;
my $pid = $job->spawn($dst, join(' ', $dst, @ARGV), {stdout => *STDOUT, stderr => *STDERR});
unless (defined $pid) { die "Could not launch $dst"; }
$job->run(0);


#------------------------------------------------------------------------------

sub CreateCacheDirectory
{
	my $cache_dir = shift;

	mkdir $cache_dir, 0777;
	if (! -d $cache_dir)
	{
		die "Cannot create cache directory '$cache_dir'!";
	}
}

sub MirrorFile
{
	use LWP::Simple qw(mirror is_success status_message $ua);
	
	my ($src, $dst) = @_;

	$ua->timeout(5);
	my $status = mirror($src, $dst);

	if ($status == LWP::Simple::RC_OK)
	{
		print STDERR "Updated '$dst' from '$src'.\n";
		return UPDATED;
	}
	elsif ($status == LWP::Simple::RC_NOT_MODIFIED)
	{
		return UNCHANGED;
	}
	elsif (!is_success($status))
	{
		die "Cannot mirror '$src' to '$dst', message: '" . status_message($status) . "'";
	}
}

sub ExtractFiles
{
	my ($zipfile, @dirs) = @_;
	
	use Archive::Zip qw(:ERROR_CODES);
	my $zip = Archive::Zip->new();

	if ((my $status = $zip->read($zipfile)) != AZ_OK)
	{
		die "Cannot read '$zipfile', error code: $status!";
	}

	for my $dir (@dirs)
	{
		if ((my $status = $zip->extractTree($dir->{name}, $dir->{path})) != AZ_OK)
		{
			die "Cannot extract '$dir->{name}' from '$zipfile', error code: $status!";
		}
		print STDERR "Extracted '$dir->{path}' from '$zipfile'\n";
	}
}

sub SetEnvVars
{
	my (@dirs) = @_;
	
	for my $dir (@dirs)
	{
		my $old = $ENV{$dir->{env_var}};
		$ENV{$dir->{env_var}} = ($old ? "$old;" : '') . $dir->{path};
	}
}

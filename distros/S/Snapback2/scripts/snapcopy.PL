#!/usr/bin/perl
##!~_~perlpath~_~

=head1 NAME

snapcopy -- copy Snapback directories efficiently

=head1 SYNOPSIS

 snapcopy [-v] [-R rsync] [-r path] srcdir [srcdir2 ..] targdir

=head1 DESCRIPTION

When you want to maintain a disk backup created by snapback, you
may find that trying to copy the directory structure to another
disk doesn't work very well. The L<cp> command doesn't know how
to find the hard links which make L<snapback2> work so well, and
the space savings will be lost.

This script efficiently does a copy to another disk via rsync. It
scans a tree with L<File::Find>, grabs the hourly/daily/weekly/monthly
directory names, and checks their time stamp. It copies the earliest
one first (no matter its name) and then uses L<rsync(1)> and its
--link-dest option to avoid using disk space on a copy of identical
files.

Note that some permissions may not be preserved.

=cut

use Getopt::Std;
use File::Path;

use strict;

my $prog = $0;
$prog =~ s:.*/::;

my %opt;
getopts('dvM:R:r:s:', \%opt);

my $rsync = $opt{r} || 'rsync';

my @paths = split /:/, $ENV{PATH};

for(@paths) {
	next unless -x "$_/rsync";
	$rsync = "$_/rsync";
	last;
}

if($rsync eq 'rsync') {
	warn "rsync not found in PATH, prepare for death.\n";
}

my $USAGE = <<EOF;
$prog -- copy Snapback directories without increasing size

usage: $prog [-v] [-R rsync] [-r path] srcdir [srcdir2 ..] targdir

	-h             Show this message
	-s snapshot.n  Transfer only this snapshot directory (i.e. monthly.2)
	-v             Show some progress
	-r /path/to/rm Remove leading path from source directories
	-R /path/to    Program calls simpy 'rsync' by default
EOF

=head1 OPTIONS

=over 4

=item -d

Show what would be done by echoing the commands as they would be
run. (Though this script uses File::Path and its C<mkpath()> routine
to avoid dependence on a specific L<mkdir(1)>, it echos the command
as if it was using mkdir.)

No file system modification of any kind is done, but the paths
are traversed to find .

=item -v

Verbose, passed as -v flag to rsync and mkpath().

=item -r /path/to/rm

The easiest way to run snapcopy is to change directory to the root of
the tree you want to copy and specify directories as a relative path.
But if you want to specify the source directories as absolute paths, you
may want to trim off a leading path component. The C<-r> argument will
be removed from the front of the target directory fragment that goes
after the base target directory.

=item -R /path/to/rsync

Normally the first "rsync" found in your path is used as the rsync
command. If your rsync lives somewhere outside your path, specify it
here.

=back

=head1 EXAMPLES

If you have a backup volume mounted at C</mnt/backup1>, and you wish to
copy some web server backups to C</mnt/backup2> so you can do maintenance
on the disk at C</mnt/backup1>, you can run from the command line:

	% cd /mnt/backup1
	% snapcopy www.perusion.com www.icdevgroup.org /mnt/backup2

You will find the copies in C</mnt/backup2/www.perusion.com>, etc.

If you want to do the same thing without changing directory, you
can do:

	% snapcopy /mnt/backup1/www.perusion.com \
			   /mnt/backup1/www.icdevgroup.org /mnt/backup2
	
That will, however, create the directories:

	/mnt/backup2/mnt/backup1/www.perusion.com
	/mnt/backup2/mnt/backup1/www.icdevgroup.org

You can match the behavior of the first example with:

	% snapcopy -r /mnt/backup1 /mnt/backup1/www.perusion.com \
			   /mnt/backup1/www.icdevgroup.org /mnt/backup2

=cut

my $targdir = pop @ARGV;

my $ssh;
my $host;
my $hostbase;

if($targdir =~ m{:/}) {
	warn "Assuming $targdir is an SSH host with key access, and that only one hourly.0 is to be transferred.\n";
	$ssh = 1;
	($host,$hostbase) = split /:/, $targdir;
}
else {
	-d $targdir or die "$targdir: not a directory.\n$USAGE";
}

my @sources;

for(@ARGV) {
	-d $_ or die "$_: not a directory.\n$USAGE";
	push @sources, $_;
}

use File::Find;

my %base;

my $wanted = sub {
	return unless -d $_;
	return unless /^(hourly|daily|monthly|weekly)\.\d+$/;
	$File::Find::prune = 1;
	my $type = $1;
	my @stat = stat(_);
	my $mtime = $stat[9];
	my $dref = $base{$File::Find::dir} ||= {};
	$dref->{$_} = $mtime;
};

File::Find::find($wanted, @sources);

my @dirs = keys %base;

## Here we remove a leading path if it is passed to us
my $remove_regex;
if($opt{r}) {
	$remove_regex = qr{^$opt{r}/};
}

for my $basedir (@dirs) {
	my $dref = $base{$basedir};
	my $cpdir = $basedir;
	$remove_regex and $cpdir =~ s{$remove_regex}{};

	$cpdir =~ s{^\./}{};

	my @mkcmd = 'mkdir';
	push @mkcmd, '-p';
	push @mkcmd, '-v' if $opt{v};

	my $mkdir = $basedir;
	if($ssh) {
		unshift @mkcmd, $host ;
		unshift @mkcmd, 'ssh';
		$hostbase and $mkdir = "$hostbase/$mkdir";
	}
	push @mkcmd, $mkdir;

	if($opt{d}) {
		print join " ", @mkcmd;
		print "\n";
	}
	elsif($ssh) {
		system @mkcmd;
	}
	else {
		File::Path::mkpath($basedir, $opt{v});
	}

	if($?) {
		die "Couldn't make directory $basedir: $!\n";
	}

	my @order = sort { $dref->{$a} <=> $dref->{$b} } keys %$dref;
	if($opt{s}) {
		@order = grep $_ eq $opt{s}, @order;
	}

	if(! @order) {
		warn "Unable to find snapshot $opt{s} for $basedir, skipping.\n";
		next;
	}

	if($ssh) {
		my $last = pop @order;
		@order = ($last);
	}
	for (my $i = 0; $i < @order; $i++) {
		my @args = $rsync;
		my $fromdir = "$basedir/$order[$i]/";
		my $todir = "$targdir/$cpdir/$order[$i]/";
		if($ssh) {
			$todir = "$targdir/$cpdir/";
		}
		push @args, '-a';
		push @args, '-v' if $opt{v};
		push @args, qq{--link-dest=$targdir/$cpdir/$order[$i - 1]} if $i > 0;
		push @args, $fromdir;
		push @args, $todir;

		my @mkcmd = 'mkdir';
		push @mkcmd, '-p';
		push @mkcmd, '-v' if $opt{v};
		push @mkcmd, $todir;

		if($opt{d}) {
			print join " ", @mkcmd;
			print "\n";
		}
		else {
			File::Path::mkpath($todir, $opt{v});
		}

		if($opt{d}) {
			print join " ", @args;
			print "\n";
		}
		else {
			system @args;
		}

		if($?) {
			warn "rsync had an error: $!\n";
		}
	}
}

=head1 BUGS

Probably some. Permissions may not be totally preserved depending on
your original options to Snapback when you ran it.

No provision for sending to a remote system with SSH.

=head1 AUTHOR

Mike Heins, Perusion, <snapback@perusion.org>.



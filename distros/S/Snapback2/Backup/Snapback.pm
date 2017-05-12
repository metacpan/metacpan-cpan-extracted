#!/usr/local/bin/perl

# Backup::Snapback - routines for Snapback2 rsync backup system
#
# $Id: Snapback.pm,v 1.5 2006/08/23 14:58:10 mike Exp $
#
# Copyright (C) 2004 Mike Heins, Perusion <snapback2@perusion.org>
# Copyright (C) 2002 Art Mulder
# Copyright (C) 2002-2003 Mike Rubel
#
# This program was originally based on Mike Rubel's rsync snapshot
# research and Art Mulder's snapback perl script
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA  02111-1307  USA.

package Backup::Snapback;
use Sys::Hostname;
use File::Path;
use File::Temp;
use Config::ApacheFormat;
use Symbol;
use Data::Dumper;
$Data::Dumper::Terse = 1;
use Carp;
use POSIX qw/strftime/;
use strict;

use vars qw/$VERSION $ERROR $errstr %Defaults/;
no warnings qw/ uninitialized /;

$VERSION = '1.001';

=head1 NAME

Backup::Snapback - routines for support of rsync-based snapshot backup

=head1 SYNOPSIS

  use Backup::Snapback;
  my $backup = new Backup::Snapback %opts;

=head1 DESCRIPTION

Snapback2 does backup of systems via ssh and rsync. It creates rolling "snapshots"
based on hourly, daily, weekly, and monthly rotations. When it runs for
some period of time, you will end up with a target backup directory
that looks like:

	drwx--x--x   81 106      staff    4096 Jan  1 05:54 daily.0
	drwx--x--x   81 106      staff    4096 Dec 31 05:55 daily.1
	drwx--x--x   81 106      staff    4096 Dec 30 05:55 daily.2
	drwx--x--x   81 106      staff    4096 Dec 29 05:54 daily.3
	drwx--x--x   81 106      staff    4096 Dec 28 05:53 daily.4
	drwx--x--x   81 106      staff    4096 Dec 27 05:53 daily.5
	drwx--x--x   81 106      staff    4096 Dec 26 05:53 daily.5
	drwx--x--x   81 106      staff    4096 Jan  1 05:54 hourly.0
	drwx--x--x   81 106      staff    4096 Dec 31 17:23 hourly.1
	drwx--x--x   81 106      staff    4096 Jan  1 05:54 monthly.0
	drwx--x--x   81 106      staff    4096 Dec  1 05:54 monthly.1
	drwx--x--x   81 106      staff    4096 Dec 28 05:53 weekly.0
	drwx--x--x   81 106      staff    4096 Dec 21 05:53 weekly.1
	drwx--x--x   81 106      staff    4096 Dec 14 05:53 weekly.2
	drwx--x--x   81 106      staff    4096 Dec  7 05:53 weekly.3

You might think this would take up lots of space. However, snapback2
hard-links the files to create the images. If the file doesn't change,
only a link is necessary, taking very little space. It is possible to
create a complete yearly backup in just over 2x the actual
storage space consumed by the image. 

=head1 METHODS

The Backup::Snapback module is designed to be front-ended by a script
such as the included C<snapback2>. Its methods are:

=over 4

=cut

my %Locale;

%Defaults = (
	AlwaysEmail => 'No',
	ChargeFile => $> == 0 ? '/var/log/snapback.charges' : "$ENV{HOME}/.snapback/snapback.charges",
	Compress => 1,
	cp => "/bin/cp",
	CreateDir => 'Yes',
	DailyDir => 'daily',
	HourlyDir => 'hourly',
	logfile => $> == 0 ? '/var/log/snapback' : "$ENV{HOME}/.snapback/snapback.log",
	MonthlyDir => 'monthly',
	MustExceed => '5 minutes',
	mv => "/bin/mv",
	Myhost => hostname(),
	RsyncShell        => 'ssh',
	IgnoreVanished    => 'No',
	Rsync        => 'rsync',
	RsyncVerbose => 0,
	RetainPermissions => 1,
	rm => "/bin/rm",
	RsyncOpts => "-a --force --delete-excluded  --one-file-system --delete",
	sendmail => "/usr/sbin/sendmail",
	WeeklyDir => 'weekly',
);

my %None = qw(
	Logfile         1
	ChargeFile	    1
	AdminEmail	    1
	DestinationList 1
	PingCommand     1
);

my %Boolean = qw(
	RsyncStats        1
	RsyncVerbose      1
	AlwaysEmail       1
	AutoTime		  1
	IgnoreVanished	  1
	Compress          1
	CreateDir         1
	LiteralDirectory  1
	ManyFiles         1
	RetainPermissions 1
);

my @reset_backup = qw/
						_directory
						_directories
						_client_config
						_client_cfg
					/;

for(grep /[A-Z]/, keys %Defaults) {
	$Defaults{lc $_} = $Defaults{$_};
}

for(grep /[A-Z]/, keys %Boolean) {
	$Boolean{lc $_} = $Boolean{$_};
}

for(grep /[A-Z]/, keys %None) {
	$None{lc $_} = $None{$_};
}

## Where log entries go
my @log;

my @config_tries = qw(
	/etc/snapback2.conf
	/etc/snapback/snapback2.conf
	/etc/snapback.conf
	/etc/snapback/snapback.conf
);

if($> != 0) {
	unshift @config_tries, "$ENV{HOME}/.snapback/snapback.conf";
}

=item new

Constructs a new Backup::Snapback object. Accepts any Snapback config
file option, plus the special option C<configfile>, which supplies the
configuration file to read. If the passed C<configfile> is not set,
the standard locations are scanned.

Standard locations are C<$HOME/.snapback/snapback.conf> if not executing
as root, otherwise always in order:

	/etc/snapback2.conf
	/etc/snapback/snapback2.conf
	/etc/snapback.conf
	/etc/snapback/snapback.conf

Returns the snapback object. If the constructor fails, C<undef> will be
returned and the error will be available as C<$Backup::Snapback::errstr>.

Called as usual for a perl object:

	## classic constructor
	my $snap = new Backup::Snapback configfile => '/tmp/snap.conf';

	## standard constructor
	my $snap = Backup::Snapback->new( ChargeFile => '/tmp/snap.charges') ;

=cut

sub new {
	my $class = shift;
	my %opt;
	if(ref $_[0] eq 'HASH') {
		%opt = %{shift(@_)};
	}
	else {
		%opt = @_;
	}

	my $configfile = delete $opt{configfile};
	if(! $configfile) {
		for(@config_tries) {
			next unless -e $_;
			$configfile = $_;
			last;
		}
	}

	my $maincfg = new Config::ApacheFormat
					 duplicate_directives => 'combine',
					 root_directive => 'SnapbackRoot',
					;

	$maincfg->read($configfile);

#print "maincfg=$maincfg\n";
	my $self = bless {
						_maincfg => $maincfg,
						_config => {},
						_log => [],
					};

	$self->{_cfg} = $self->{_maincfg};

	for(keys %opt) {
		$self->config($_, $opt{$_});
	}

	if($self->config(-debug)) {
		my $debuglog = $self->config(-debuglog) 
			|| $self->config(-debugfile) ### deprecated, remove in 2011
			;
		my $debugtag = $self->config(-debugtag);
		$self->{debugtag} = $debugtag ? "$debugtag: " : '';
		
		my $sym = gensym();
		if($debuglog) {
			open $sym, ">> $debuglog"
				or die "Can't append debug log $debuglog: $!\n";
		}
		else {
			open $sym, ">&STDERR";
		}
		$self->{_debug} = $sym;
	}

	return bless $self, $class;
}

sub DESTROY {
	my $self = shift;
	my $ary = $self->{_tmpfiles};
	unlink @$ary if $ary;
}

sub time_to_seconds {
    my($str) = @_;
    my($n, $dur);

    ($n, $dur) = ($str =~ m/(\d+)[\s\0]*(\w+)?/);
    return undef unless defined $n;
    if (defined $dur) {
        local($_) = $dur;
        if (m/^s|sec|secs|second|seconds$/i) {
        }
        elsif (m/^m|min|mins|minute|minutes$/i) {
            $n *= 60;
        }
        elsif (m/^h|hour|hours$/i) {
            $n *= 60 * 60;
        }
        elsif (m/^d|day|days$/i) {
            $n *= 24 * 60 * 60;
        }
        elsif (m/^w|week|weeks$/i) {
            $n *= 7 * 24 * 60 * 60;
        } 
        else {
            return undef; 
        }
    }

    $n;
}

# =item error
# 
# Sets the last error, with sprintf if more than one param. An internal method.
# 
# 	$self->error('It failed! Problem was %s', $problem);
# 
# or as a class method:
# 
# 	Backup::Snapback::error('It failed! Problem was %s', $problem);
# 
# Returns the formatted error.
# 
# =cut

sub error {
	my $self = shift;
	my ($msg, @args);
	if(ref $self) {
		($msg, @args) = @_;
	}
	else {
		($msg, @args) = ($self, @_);
		undef $self;
	}

	$msg = sprintf($msg, @args) if @args;

	$ERROR = $errstr = $msg;
	if($self) {
		$self->{_errstr} = $msg;
	}
	return $msg;
}

=item errstr

Called as either an object method:

	$self->errstr;

or as a class method:

	Backup::Snapback::errstr;

Returns the most recent error text.

=cut

sub errstr {
	my $self = shift;
	$self and return $self->{_errstr};
	return $errstr;
}

## Internal
sub is_yes {
	my $val = shift;
	$val = lc $val;
	$val =~ s/\W+//g;
	my %true = qw(
		y      1
		yes    1
		on     1
		true   1
		1      1
	);
	$val = $true{$val} || 0;
	return $val;
}

=item config

Gets or sets configuration parameters. The base is set in hardcoded
program defaults; it then is overlayed with the configuration file results.
If a configuration block is entered, those settings override the parent
configuration block. Finally, internal setting can be done, temporarily
overriding configuration file settings (because of option dependencies).

    my $compress = $snap->config(-Compress);

	# turn off compression
	$snap->config( Compress => No);

Some options are boolean, and some accept the special value 'none' to
set them empty.

Parameter names are not case-sensitive.

=cut

sub config {
	my $self = shift;
	my $parm = shift;
	my $value = shift;

	$parm = lc $parm;
	$parm =~ s/^-//;

	my $sc  = $self->{_client_config} || $self->{_config};
	my $cfg = $self->{_cfg}           || $self->{_maincfg};

	if(defined $value) {
		$sc->{$parm} = $value;
		return $value;
	}

	my @vals;

	if(defined $sc->{$parm}) {
		if(ref $sc->{$parm} eq 'ARRAY') {
			@vals = @{$sc->{parm}};
		}
		else {
			@vals = $sc->{$parm};
		}
	}
	else {
		@vals = $cfg->get($parm);
	}

	my $num = scalar(@vals);
	my $val;

	if($num == 0) {
		$val = $Defaults{$parm};
	}
	elsif(@vals == 1) {
		$val = $vals[0];
	}
	elsif(wantarray) {
		return @vals;
	}
	else {
		$val = \@vals;
	}

	if($Boolean{$parm}) {
		$val = is_yes($val);
	}
	elsif($None{$parm} and lc($val) eq 'none') {
		$val = '';
	}
	return $val;
}

sub build_rsync_opts {
	my $self = shift;
	my @opts;
	my $main_opts = $self->config(-RsyncOpts);

    # If user supplies their own -RsyncOpts config returns and array
    # that needs to be turned into a scalar
    # -- patch from Jay Strauss
    if (ref $main_opts eq 'ARRAY') {
			$main_opts = join " ", @$main_opts;
    }

    push @opts, $main_opts;

	my $rsync_sh = $self->config(-RsyncShell);
	$self->log_debug("rsync shell=$rsync_sh");
	$rsync_sh =~ s/'/\\'/g;

	if($rsync_sh and lc($rsync_sh) ne 'none' and lc($rsync_sh) ne 'rsync' ) {
		unshift @opts, "-e '$rsync_sh'";
	}

	if($self->config(-chargefile) and ! $self->config(-RsyncVerbose)) {
		push @opts, '--stats' unless $main_opts =~ /--stats\b/;
	}

	my $compress = $self->config(-Compress);
	$self->log_debug("compress=$compress");
	unshift @opts, "-z" if $compress;

	my $verbose = $self->config(-RsyncVerbose);
	$self->log_debug("rsync verbose=$verbose");
	unshift @opts, "-v" if $verbose;

	my $opts = join " ", @opts;
    $self->log_debug("build_rsync_opts: $opts");
	return $opts;
}

sub output_timestamp {
	my $self = shift;
	my $fh = shift;

	# retrieve and print the current time stamp to the log file
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	printf $fh "%4d-%02d-%02d %02d:%02d:%02d  ",
	        $year+1900,$mon+1,$mday,$hour,$min,$sec;
}

#---------- ---------- ---------- ---------- ---------- ----------
# Set up logging

sub log_arbitrary {
	my ($self, $file, $msg) = @_;
	return unless $file;
	my $fha = $self->{_fd} ||= {};
	if(! $fha->{$file}) {
		my $sym = gensym();
		open $sym, ">> $file"
			or croak("log_arbitrary: cannot log to file $file: $!\n");
		$fha->{$file} = $sym;
	}
	my $fh = $fha->{$file};
	$self->output_timestamp($fh);
	print $fh $msg;
}

=item log_error

Logs an error message to the configured log file. If no log file is
specified (default is /var/log/snapback or $HOME/.snapback/snapback.log
depending on user ID), then no error is logged.

Formats messages with sprintf() if appropriate.

	$snap->log_error("Backup failed for client: %s.", $client);

=cut

sub log_error {
	my ($self, $msg, @args) = @_;

	my $long = length($msg) > 400;
	$msg = sprintf($msg, @args) if @args;
	$msg =~ s/[\r\n]*$/\n/ unless $long;

	$self->{_errors}++;
	push @{$self->{_log}}, $msg;

	my $logfile = $self->config(-logfile)
		or return $msg;
	$self->log_arbitrary($logfile, $msg);
	return $msg;
}

=item file_handle

Returns the file handle of a file already opened with log_arbitrary
or log_error. To open a new file, do $self->log_arbitrary($file);

=cut 

sub file_handle {
	my ($self, $file) = @_;
	return $self->{_fd}{$file};
}

=item get_tmpfile

Get a temporary file name which will be unlinked when the object
is destroyed.

=cut

sub get_tmpfile {
	my $self = shift;
	$self->{_tmpfiles} ||= [];
	my $name = File::Temp::tmpnam();
	push @{$self->{_tmpfiles}}, $name;
	return $name;
}

sub log_debug {
	my $self = shift;
	my $fh;
	return unless $fh = $self->{_debug};
	my $msg = shift;
	$msg =~ s/\n*$/\n/;

	$self->output_timestamp($fh);

	print $fh "$self->{debugtag}$msg";
}

=item backups

Returns the name of all of the backup blocks active in the current
configuration file.

If the file had:

	<Backup foo.perusion.org>
		Directory /home/foo
	</Backup>
	<Backup pseudo>
		BackupHost foo.perusion.org>
		Directory /home/baz
	</Backup>
	<Backup bar.perusion.org>
		Directory /home/bar
	</Backup>

The call C<$snap->backups()> would return:

	('foo.perusion.org', 'pseudo', 'bar.perusion.org')

Returns a reference or list based on call context.

=cut

sub backups {
	my $self = shift;
	my @blocks = $self->{_maincfg}->get('backup');
	my @backups;
	for(@blocks) {
		push @backups, $_->[1];
	}

	$self->{_debug} and $self->log_debug("backups=" . Dumper(\@backups));

	return wantarray ? @backups : \@backups;
}

=item set_backup

Sets a particular block active as the current backup. Returns
the passed parameter.

=cut

sub set_backup {
	my ($self, $client) = @_;
	for(@reset_backup) {
		delete $self->{$_};
	}
	$self->{_cfg} = $self->{_client_cfg} = $self->{_maincfg}->block('backup', $client);
	return $self->{_client} = $client;
}

=item directories

Returns the name of all of the backup blocks active in the current
configuration file.

Must be preceded by a C<$snap->set_backup($client)> call.

If the file had:

	<Backup foo.perusion.org>
		Directory /home/foo
		Directory /home/baz
		Directory /home/bar
		<Directory /home/buz>
			Hourlies 2
		</Directory>
	</Backup>

The call sequence:

	$snap->set_backup('foo.perusion.org')
		or die "No backup configuration!";
	my @dirs = $snap->directories();

would return:

	('/home/foo', '/home/baz', '/home/bar', '/home/buz')

Returns a reference or list based on call context.

=cut

sub directories {
	my $self = shift;
	my @dirs = $self->config(-directory);
	my %dir;
	my @out;
	my $literal = $self->config(-literaldirectory);
	for(@dirs) {
		my $dirname;
		unless( ref($_) ) {
			$dirname = $_;
			$dirname =~ s:/+$:: unless $literal;
			$dir{$dirname} = $_;
			push @out, $dirname;
		}
		else {
			$dirname = $_->{_block_vals}[0];
			$dirname =~ s:/+$:: unless $literal;
			$dir{$dirname} = $_;
			push @out, $dirname;
		}
	}

	$self->{_directories} = \%dir;

	$self->{_debug} and $self->log_debug("directories=" . Dumper(\@out));

	return wantarray ? @out : \@out;
}


=item set_directory 

Sets a particular directory as active for backup. Must have set $snap->set_backup()
previously, returns undef on error.

=cut

sub set_directory {
	my ($self, $directory) = @_;
	my $cfg = $self->{_cfg} = $self->{_client_cfg}
		or do {
			$self->log_error("Can't set directory without client.");
			$self->error("Can't set directory without client.");
			return undef;
		};

	my $literal = $self->config(-literaldirectory);
	$directory =~ s:/+$:: unless $literal;
	my $dhash = $self->{_directories};
	unless($dhash) {
		$self->directories();
		$dhash = $self->{_directories};
	}

	my $d = $dhash->{$directory}
		or return undef;

	if(ref $d) {
		$self->{_cfg} = $d;
	}

	$self->{_directory} = "$directory/" unless $literal;
	return $self->{_directory};
}

sub rotate {
	my $self = shift;
	if($self->config(-ManyFiles)) {
		return $self->do_rotate_reuse(@_);
	}
	else {
		return $self->do_rotate(@_);
	}
}

## ---------- ---------- ---------- ---------- ---------- ----------
# Age/rotate the old backup directories.
# -- the backup dirs are named like: back.0, back.1, back.2
# -- so the count is 3 (3 backups)
# -- we deleted the oldest (back.2) and move the next-oldest up
#    so back.2 becomes back.3, back.1 becomes, back.2, etc.
# -- then make a hard link from back.0 to back.1
# $maxbackups = number of copies they keep,  we count from Zero,
# so for 4 copies, we'd have 0,1,2,3.  In the comments below
# we'll give examples assuming a $maxbackup of 4.

sub do_rotate {
	my ($self, $maxbackups, $dir, $rotate_all) = @_;
	
	## Step 1: nothing to do if they're only keeping 1 copy
	if (($maxbackups == 1) && ($rotate_all==0)) { return ; }

	## Step 2: delete the oldest copy.  (eg: $dir.3)
	my $count = $maxbackups - 1;
	my $countplus = $maxbackups - 1;

	my $rm = $self->config(-rm);
	my $mv = $self->config(-mv);
	my $cp = $self->config(-cp);

	if (-d "$dir.$count") {
		$self->log_debug("$rm -rf $dir.$count\n");
		system("$rm -rf $dir.$count") == 0
			or die "FAILED: $rm -rf $dir.$count";
	}
	$count--;

	## Step 3: rotate/rename the "middle" copies (eg: $dir.1,2,3)
	## DO NOTHING with the most recent backup (eg: $dir.0) of hourlies.
	## Rotate same as the rest for dailies/weeklies/etc.

	my $smallest;

	if ($rotate_all) { $smallest = 0 } else {$smallest = 1};

	while ($count >= $smallest) {
		if (-d "$dir.$count") { 
			$self->log_debug("$mv  $dir.$count $dir.$countplus\n");
			system("$mv $dir.$count $dir.$countplus" ) == 0
				or die "FAILED: $mv $dir.$count $dir.$countplus";
		}
		$count--; $countplus--;
	}
}

sub do_rotate_reuse {
	my ($self, $maxbackups, $dir, $rotate_all) = @_;
  
	## Step 1: nothing to do if they're only keeping 1 copy
	if (($maxbackups == 1) && ($rotate_all==0)) { return ; }

	## Step 2: move the oldest copy to .TMP.  (eg: $dir.3)
	my $count = $maxbackups - 1;
	my $countplus = $maxbackups - 1;

	my $rm = $self->config(-rm);
	my $mv = $self->config(-mv);
	my $cp = $self->config(-cp);

	if (-d "$dir.TMP") {
		$self->log_error("$dir.TMP directory existed, removing.\n");
		$self->log_debug("$rm -rf $dir.TMP\n");
		system("$rm -rf $dir.TMP") == 0
			or die "FAILED: $rm -rf $dir.$count";
	}

	$self->log_debug("called do_rotate with maxbackups=$maxbackups rotate_all=$rotate_all");

	## Now using John Pelan's suggestion to rotate least-recent to
	## .0 for hourlies
	if(-d "$dir.$count") {
		  if (! $rotate_all) {
			  $self->log_debug("$mv $dir.$count $dir.TMP\n");
			  system("$mv $dir.$count $dir.TMP") == 0
				or die "FAILED: $mv $dir.$count $dir.TMP";
		  }
		  else {
			  $self->log_debug("$rm -rf $dir.$count\n");
			  system("$rm -rf $dir.$count") == 0
				  or die "FAILED: $rm -rf $dir.$count";
		  }
	}
	$count--;

	## Step 3: rotate/rename the "middle" copies (eg: $dir.1,2,3)
	## Now using Jean Phelan's suggestion to move an expired 
	## copy to .0 so linking is reduced.

	my $smallest = 0;

	while ($count >= $smallest) {
	  $self->log_debug("do_rotate count=$count countplus=$countplus");
	  if (-d "$dir.$count") { 
		$self->log_debug("$mv  $dir.$count $dir.$countplus\n");
		system("$mv $dir.$count $dir.$countplus" ) == 0
		  or die "FAILED: $mv $dir.$count $dir.$countplus";
	  }
	  $count--; $countplus--;
	}

	if(! $rotate_all) {
	  if(-d "$dir.TMP") {
		  $self->log_debug("$mv $dir.TMP $dir.0\n");
		  system("$mv $dir.TMP $dir.0") == 0
			or die "FAILED: $mv $dir.TMP $dir.0";
	  }
	  elsif (-d "$dir.1") { 
		## 3.2: Hard link from the newest backup: 
		  $self->log_debug("Hard Link newest backup: $cp -al $dir.1 $dir.0\n");
		  system("$cp -al $dir.1 $dir.0") == 0
			or die "FAILED: $cp -al $dir.0 $dir.1";
	  }
	}

}

=item backup_directory 

Performs a directory backup after C<set_backup> 
and C<set_directory> have been called.

=cut

sub backup_directory {
	my($self, $dir, %opt) = @_;		## Long form of hostname

	my $client  = $self->{_client};
	my $host    = $self->config(-backuphost) || $client;
	$dir        ||= $self->{_directory};
	my @excl    = $self->config(-exclude);

	my $rsh = lc $self->config(-RsyncShell);

	my $spacer = '';

	if($dir !~ m{^/}) {
		$spacer = '/' if $rsh eq 'rsync';
	}

	$self->log_debug("directory=$dir host=$host client=$client");
	my $rotate_all = 0;	## flag for do_rotate routine
	my $hr_dir = $self->config(-HourlyDir);
	my $daily_dir = $self->config(-DailyDir);
	my $weekly_dir = $self->config(-WeeklyDir);
	my $monthly_dir = $self->config(-MonthlyDir);

    my $hr_backup = $self->config(-Hourlies);

	if($hr_backup == 1) {
		$self->log_error("Hourly backup must be zero or two, one is not valid.");
		return;
	}

	if(! $hr_backup) {
		$hr_dir = $self->config(-DailyDir);
	}

	my $dest;
	my @destlist =  $self->config(-DestinationList);

	if( @destlist = $self->config(-DestinationList)
		and $destlist[0]
		and lc($destlist[0]) ne 'none'
		)
	{
		$self->log_debug("DestinationList is " . join(" ", @destlist));
		my $pdir = $dir;
		$pdir = "/$pdir" unless $pdir =~ m{^/};
		my %dest;
		foreach my $prospect (@destlist) {
			my $prefix = $prospect . "/" . $client . $pdir ;
			my $backupdir = $prefix . $hr_dir;
			my $mtime = (stat "$backupdir.0")[9] || 0;
			$dest{$prospect} = $mtime;
		}

		my $actual;
		my $min;
		for (keys %dest) {
			if(! defined $min) {
				$min = $dest{$_};
				$actual = $_;
			}
			elsif($min > $dest{$_}) {
				$min = $dest{$_};
				$actual = $_;
			}
		}
		$dest = $actual;
		$self->log_debug("Selected DestinationList destination $dest");
	}
	else {
		$dest = $self->config(-Destination);
		$self->log_debug("destination from Destination is $dest");
	}

	if(! $dest) {
		$self->log_error("Refuse to do backup for %s%s without destination.", $client, $dir);
		return;
	}

	my $prefix = $dest . "/" . $client . $spacer . $dir ;
	my $backupdir = $prefix . $hr_dir;

	## ----------
	## STEP 1: check the clock and verify if we are just doing 
	##  the hourly backups, or also the daily/weekly/monthlies.

	## If the timestamp on the current backup dir does not match
	## todays date, then this must be the first run after midnight,
	## so we  check the dailies/weeklies/monthlies also.
	## Not very efficient, since we check this for each backup set
	## that we run, instead of just once for all.  Oh well.

	## Regularize hourly directories to check for holes if necessary
	if($hr_backup > 0) {
		for my $x (0 .. ($hr_backup - 1) ) {
			next if -d "$backupdir.$x";
			last if $x >= $hr_backup;
			for my $y (($x + 1) .. $hr_backup) {
				next unless -d "$backupdir.$y";
				$self->log_debug(qq{rename $backupdir.$y --> $backupdir.$x to plug hole.});
				rename "$backupdir.$y", "$backupdir.$x"
					or warn "Tried to rename $backupdir.$y --> $backupdir.$x: $!\n";
				last;
			}
		}
	}

	## Check the directories
	## - hourly backup
	my $mtime = (stat "$backupdir.0")[9] || 0;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
	my $backup_date = $yday;
	## - weekly backup
        my $backupdir_weekly = $prefix . $weekly_dir;
	my $mtime_weekly = (stat "$backupdir_weekly.0")[9] || 0;
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime_weekly);
	my $backup_date_weekly = $yday;
	## - monthly backup
        my $backupdir_monthly = $prefix . $monthly_dir;
	my $mtime_monthly = (stat "$backupdir_monthly.0")[9] || 0;
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime_monthly);
	my $backup_date_monthly = $yday;

	## Check to see if we have a Before statement and don't backup
	## if it is not in that time
	my $between;
	if(! $self->config(-force)
		and
		( $self->config(-Before) or $self->config(-After) )
	   )
	{
		my $before =  $self->config(-Before);
		my $after =  $self->config(-After);
		for(\$before, \$after) {
			my $hr;
			my $min;
			my $adder = 0;
			my $orig = $$_;
			next unless $$_;
			$$_ =~ s/[\s.]+//g;
			if($$_ =~ s/([ap])m?$//i) {
				my $mod = $1;
				$adder = 12 if $mod =~ /p/;
			}
			if($$_ =~ /:/) {
				($hr, $min) = split /:/, $$_;
				$hr =~ s/^0+//;
				$min =~ s/^0+//;
			}
			else {
				$$_ =~ s/\D+//g;
				if($$_ =~ /^(\d\d?)(\d\d)$/) {
					$hr = $1;
					$min = $2;
				}
				elsif($$_ =~ /^(\d\d?)$/) {
					$hr = $1;
					$min = 0;
				}
				else {
					my $msg = sprintf(
						"Time of %s not parseable for Before or After",
						$orig);
					$self->log_debug($msg);
					$$_ = '';
				}
			}
			$hr += $adder;
			$$_ = sprintf('%02d:%02d', $hr, $min);
		}

		my $current = strftime('%H:%M', localtime());
		my $stop;

		my @msg;
		if($after) {
			$stop = 1 unless $current ge $after;
		}
		if($before) {
			$stop = 1 unless $current lt $before;
		}

		if($stop) {
			my $constr = '';
			if($before) {
				$constr = "before $before";
			}
			if($after) {
				$constr .= ' or ' if $constr;
				$constr .= "after $after";
			}
			my $msg = sprintf(	
						"Skipping backup of %s%s%s, must be %s.",
						$client, ($rsh eq 'rsync' ? '::' : ''), $dir, $constr,
					  );
			$self->log_debug($msg);
			return;
		}
	}

	## This mode doesn't back up unless the formula
	## 
	##    (24 / $hr_backup - 1) * 60 * 60 > time() - $mtime
	## 
	## is satisfied.
	if(! $self->config(-force) and $self->config(-AutoTime)) {
		my $must_hours = ( 24 / ($hr_backup || 1) ) - 0.5;
		my $must_exceed = $must_hours * 60 * 60;
		if(my $min_exceed = $self->config(-MustExceed)) {
			$min_exceed = time_to_seconds($min_exceed);
			if($min_exceed > $must_exceed) {
				$must_hours = sprintf "%.1f", $min_exceed / 60 / 60;
				$must_exceed = $min_exceed;
				$self->log_debug("Setting minimum exceed time $must_hours hours.");
			}
		}
		my $interval = time() - $mtime;
		unless ($interval > $must_exceed) {
			my $real_hours = sprintf "%.1f", $interval / 60 / 60;
			my $msg = sprintf(	
						"Skipping backup of %s%s%s, only %s hours old, want %s hours",
						$client, ($rsh eq 'rsync' ? '::' : ''), $dir, $real_hours, $must_hours,
					  );
			$self->log_debug($msg);
			return;
		}
	}

	if(my $pc = $self->config(-pingcommand)) {
		if(ref $pc eq 'ARRAY') {
			$pc = join " ", @$pc;
		}
		# Command should return 0 to allow backup
		$pc =~ s/\%h/$host/g;
		$pc =~ s/\%d/$dir/g;
		$pc =~ s/\%c/$client/g;
		system $pc;
		if($?) {
			$self->log_debug("Ping command '$pc' returned false, skipping.");
			return;
		}
	}

    $self->log_debug("backup_date=$backup_date dir=$backupdir\n");

	## Check the clock
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

	$self->log_debug("yday=$yday dir=$backupdir\n");

    ## we assume (dangerous I know) that if the timestamp on the directory
    ## is not the same date as today, then it must be yesterday.  In any
    ## case, this is then the first run after midnight today.
    my ($do_dailies, $do_weeklies, $do_monthlies );
	$self->log_debug("backup_date: $backup_date");
	if ($backup_date != $yday)  {
		if($hr_backup) {
			$do_dailies = 1;	
			$self->log_debug("do_dailies=true");
		}
		else {
			$hr_backup = $self->config(-Dailies);
		}
		
		## do weekly backup if
		## - the last one is more than 7 days in the past
		##	yday(today) - yday(last weekly backup) > 7
		## - check for turn of the year
		##	yday(today) - yday(last weekly backup) < 0 &&
		##	yday(today)+365 - yday(last weekly backup) > 7
		$self->log_debug("backup_date_weekly: $backup_date_weekly");
		if (($yday - $backup_date_weekly) > 7 ||
		    (($yday - $backup_date_weekly) < 0 &&
		     ($yday+365 - $backup_date_weekly) > 7)
		   ) {
		    $do_weeklies = 1;
		    $self->log_debug("do_weeklies=true");
 		}

		## do monthly backup if
		## - the last one is more than 30 days in the past
		##	yday(today) - yday(last monthly backup) > 30
		## - check for turn of the year
		##	yday(today) - yday(last weekly backup) < 0 &&
		##	yday(today)+365 - yday(last weekly backup) > 30
		$self->log_debug("backup_date_monthly: $backup_date_monthly");
		if (($yday - $backup_date_monthly) > 30 ||
		    (($yday - $backup_date_monthly) < 0 &&
		     ($yday+365 - $backup_date_monthly) > 30)
		   ) {
		    $do_monthlies = 1;
		    $self->log_debug("do_monthlies=true");
		}
	}

    ## ----------
    ## STEP 2: housekeeping - is the backup destination directory 
    ##  set up? Make it if CreateDir option is set.
	unless (-d $prefix) {
		if (-e $prefix) {
			die "Destination $prefix is not a directory\n";
		}
		elsif( $self->config(-CreateDir) ) {
			File::Path::mkpath($prefix)
				or die "Unable to make directory $prefix";
		}
		else {
			die "Missing destination $prefix\n";
		}
	}

	## Process the exclusions
	my $e_opts = '';
	if(@excl) {
		my @e;
		for(@excl) {
			next unless $_;
			push @e, qq{--exclude="$_"};
		}
		$e_opts = join " ", @e;
	}

	my $cp = $self->config(-cp);
	my $rsync = $self->config(-rsync);

	## ----------
	## STEP 3: Process Hourly backups

	## Figure out which rotation method
	my $many_files = $self->config(-ManyFiles);
	my $retain;

	if($self->config(-RetainPermissions)) {
		## This puts the kibosh on ManyFiles
		if($many_files) {
			$self->log_error(
				"%s and %s are mutually exclusive, unsetting %s",
				'RetainPermissions', 
				'ManyFiles', 
				'RetainPermissions', 
			);
		}
		else {
			$retain = 1;
			$rotate_all = 1;
		}
	}

	## 3.1: Rotate older backups

	$self->log_debug("do_rotate($hr_backup,$backupdir)");
	
	$self->rotate($hr_backup, $backupdir, $rotate_all);

	## 3.2: Hard link from the newest backup: 
	if (! $many_files and ! $retain and -d "$backupdir.0") { 
		$self->log_debug("Hard Link newest backup\n");
		system("$cp -al $backupdir.0 $backupdir.1") == 0
			or die "FAILED: $cp -al $backupdir.0 $backupdir.1";
	} 	

	my $extra_ropts = '';
	if($retain and -d "$backupdir.1") {
		my $bdir = "$backupdir.1";
		$bdir =~ s:.*/::;
		$e_opts .= " --link-dest=../$bdir";
	}

	## Get the rsync options
	my $r_opts = $self->build_rsync_opts();

	my $xfer_dir;
	if (! $rsh or $rsh eq 'none') {
		$xfer_dir = $dir;
	}
    elsif ($rsh eq 'rsync' and $host =~ /:\d+$/) { 
        $xfer_dir = "rsync://$host/$dir"; 
    }
	elsif ($rsh eq 'rsync') {
		$xfer_dir = "${host}::$dir";
	}
	else {
		$xfer_dir = "$host:$dir";
	}

	my $rsync_log = $self->config(-commandlog);
	if(! $rsync_log) {
		$rsync_log = $self->get_tmpfile;
		$self->config(-commandlog, $rsync_log);
	}

	## 3.3:
	## Now rsync from the client dir into the latest snapshot 
	## (notice that rsync behaves like cp --remove-destination by
	## default, so the destination is unlinked first.  If it were not
	## so, this would copy over the other snapshot(s) too!

	my $command_line = "$rsync $r_opts $e_opts $xfer_dir $backupdir.0";
	$self->log_debug("$command_line\n");
	$self->log_arbitrary($rsync_log, "client $client\n");
	$self->log_arbitrary($rsync_log, "--\n$command_line\n\n"); 

	# Cheat and get file handle to avoid subroutine overhead
	my $fh = $self->file_handle($rsync_log);

	# Prep for logging to charge file if necessary
	my $clog = $self->config(-chargefile);
	my ($finished, $bytes_read, $bytes_written, $total_size, $xfer_rate);

	open BCOMMAND, "$command_line |"
		or die "Cannot fork '$command_line': $!\n";
	while(<BCOMMAND>) {
		print $fh $_;
		next unless $clog;
		if(m/
				^   wrote \s+ (\d+) \s+ bytes
				\s+ read  \s+ (\d+) \s+ bytes
				\s+ (.+)  \s+ bytes.sec \s* $
			/xi
			)
		{
			$bytes_written = $1;
			$bytes_read    = $2;
			$xfer_rate     = $3;
			$finished = 1;
		}
		next unless $finished;
		if(/^total size is (\d+)/) {
			$total_size = $1;
			undef $finished;
		}
	}

	close BCOMMAND
	  or do {
	  		my $stat = $? >> 8;
            unless ($self->config(-IgnoreVanished) && $stat == 24) {
				my $msg = $self->log_error("FAILED with status %s: %s\ncommand was: %s",
					$stat,
					$!,
					$command_line,
				);
				$self->error($msg);
				return undef;
        	}
		};

	if($clog) {
		my $bdate = strftime('%Y%m%d', localtime());
		my $line = join ":",
					$client,
					$bdate,
					$bytes_read,
					$bytes_written,
					$xfer_rate,
					$total_size,
					$xfer_dir;
		$self->log_arbitrary($clog, "$line\n");
	}

	# update the mtime of hourly.0 to reflect the snapshot time
	system ("touch $backupdir.0");

	## ----------
	## STEP 4: Process Daily/Weekly/Monthly backups
	## -- simpler than above, the rsync is already done.  We just need
	## to "rotate" the old backups, and then hard link to the
	## newest hourly backup from yesterday.  NOTE that will be the
	##  .1 version, not the .0 version -- the .0 version is from today.

	my $yesterdays_hourly = "$backupdir.0";
	$rotate_all=1;	## flag for do_rotate routine

	## Daily Backups - similar steps to above, rotate, hard link
	if ($do_dailies) {
	  $backupdir = $prefix . $daily_dir;
	  $self->rotate($self->config(-Dailies), $backupdir, $rotate_all);

	  ## No rsync necessary, just hard-link from the most-recent hourly.
	  if (-d "$yesterdays_hourly") { 
		system("$cp -al $yesterdays_hourly $backupdir.0") == 0
		or die "FAILED: $cp -al $yesterdays_hourly $backupdir.0";
	  } 	
	}

  ## Weekly Backups
  if ($do_weeklies) {
    $backupdir = $prefix . $weekly_dir;
    $self->rotate($self->config(-Weeklies), $backupdir, $rotate_all);
    if (-d "$yesterdays_hourly") { 
      system("$cp -al $yesterdays_hourly $backupdir.0") == 0
      or die "FAILED: $cp -al $yesterdays_hourly $backupdir.0";
    } 	
  }

  ## Monthly Backups
  if ($do_monthlies) {
    $backupdir = $prefix . $monthly_dir;
    $self->rotate($self->config(-Monthlies), $backupdir, $rotate_all);
    if (-d "$yesterdays_hourly") { 
      system("$cp -al $yesterdays_hourly $backupdir.0") == 0
      or die "FAILED: $cp -al $yesterdays_hourly $backupdir.0";
    } 	
  }
}

=item backup_all

Iterates through all C<Backup> blocks in turn, backing up all directories.

=cut

sub backup_all {
	my $self = shift;
	my @bu = $self->backups();
	for my $b ( $self->backups() ) {
		$self->set_backup($b);
		for my $d ($self->directories()) {
			$self->set_directory($d);
			$self->backup_directory();
		}
	}
	return 1;
}

=head1 CONFIGURATION

See L<snapback2>.

=head1 SEE ALSO

snapback2(1), snapback_loop(1), snap_charge(1)

See http://www.mikerubel.org/computers/rsync_snapshots/ for detailed
information on the principles used.

=cut



1;

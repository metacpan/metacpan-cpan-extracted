#!/usr/local/bin/perl
##!~_~perlpath~_~

## ---------- ---------- ---------- ---------- ---------- ----------
## snapback2 -- 1.Jan.2004 -- Mike Heins
## - rsync and hard-link backup script, enhanced
## - based on research by Mike Rubel, see it at
##   http://www.mikerubel.org/computers/rsync_snapshots/
## - based on original snapback by Art Mulder
##
## ---------- ---------- ---------- ---------- ---------- ----------
## snapback -- 15.May.2002 -- Art Mulder
## - rsync and hard-link backup script
## - based on research by Mike Rubel
##   www.http://www.mikerubel.org/computers/rsync_snapshots/
##
## ---------- ---------- ---------- ---------- ---------- ----------
## Logic Layout:
##  - startup, usage, read config file
##  - rotate the snapshot directories
##  - rsync the client/backup directories
##  - create daily/wkly/monthly backup-link directories if needed
##  - notify admin's of log results.  (flag errors?)
## ---------- ---------- ---------- ---------- ---------- ----------
## TODO: Is there a better way of catching the cp/rsync errors?

## ---------- ---------- ---------- ---------- ---------- ----------
## Variables and other Setups

use Getopt::Std;        ## standard command-line processing functions
use Backup::Snapback;
use File::Path;
use POSIX qw/strftime/;
use strict;

my %localdef;

# $localdef{sendmail} = '~_~SENDMAIL~_~';
$localdef{sendmail} = '';
# $localdef{rsyncshell} = '~_~RSYNCSHELL~_~';
$localdef{rsyncshell} = '';
# $localdef{rsync} = '~_~RSYNC~_~';
$localdef{rsync} = '';
# $localdef{rm} = '~_~RM~_~';
$localdef{rm} = '';
# $localdef{mv} = '~_~MV~_~';
$localdef{mv} = '';
# $localdef{cp} = '~_~CP~_~';
$localdef{cp} = '';

for(keys %localdef) {
	next unless $localdef{$_};
	$Backup::Snapback::Defaults{$_} = $localdef{$_};
}

use vars qw/$VERSION/;

$VERSION = '1.001';

=head1 NAME

snapback2 - rsync and hard-link backup script

=head1 SYNOPSIS

  snapback2 [-c configfile] [-df] [-p PAT] [-P PAT] [configfile-base]

=cut

## more docs at end


## Where log entries go
my @log;

my $myname = $0;
my $progname = $myname;
$progname =~ s:.*/::;

my %opt;
#---------- ---------- ---------- ---------- ---------- ----------
# Process command-line Arguments + Options
getopts('c:dfl:p:P:', \%opt) ||  die usage();

if($opt{h}) {
	usage();
	exit 2;
}

my $debug = 0;

my @configs; 

for(@ARGV) {
	if(-f "/etc/snapback/$_.conf") {
		push @configs, "/etc/snapback/$_.conf";
	}
	elsif(-f "/etc/snapback/$_") {
		push @configs, "/etc/snapback/$_";
	}
	
}

unshift @configs, $opt{c} if $opt{c};
@configs = '' unless @configs;

my $myhost;

for my $configfile (@configs) {
	my $snap = new Backup::Snapback
					configfile => $configfile,
					debug => $opt{d},
					commandlog => $opt{l},
				;

	$myhost = $snap->config(-myhost);

	$debug = 1 if $snap->config(-debug);

	my @backups = $snap->backups();

	#print Dumper(\@backups);

	my $client_re;
	## Check if we have a pattern of clients to apply to
	if($opt{p}) {
		$client_re = qr/$opt{p}/
			or die "Bad regex in -p option '$opt{p}'.\n";
	}

	my $dir_re;
	## Check if we have a pattern of client directories to apply to
	if($opt{P}) {
		$dir_re = qr/$opt{P}/
			or die "Bad regex in -P option '$opt{P}'.\n";
	}

	for my $bu (@backups) {
		if($client_re) {
			next unless $bu =~ $client_re;
		}
		my $cl = $snap->set_backup($bu);
		my @dirs = $snap->directories();

		if($dir_re) {
			@dirs = grep $_ =~ $dir_re, @dirs;
		}
		
		for my $d (@dirs) {
			my $dir = $snap->set_directory($d)
				or die "bad directory $d.\n";
			$snap->backup_directory($dir);
		}

	}

	my $email;
	unless($email = $snap->config(-AdminEmail)) {
		$snap->log_debug("No email sent, AdminEmail set to none.");
		next;
	}
	my $logfile = $snap->config(-commandlog);
	my $subject;
	my $opt;
	if($snap->{_errors}) {
		$subject = "$myhost snapback2 results on error";
	}
	elsif ( $snap->config(-AlwaysEmail) ) {
		$subject = "$myhost snapback2 results on success";
	}
	next unless $subject;
	my $sendmail = $snap->config(-sendmail) || '/usr/sbin/sendmail';
	my %opt = (
		sendmail => $sendmail,
		subject => $subject,
		to => $email,
	);

	my $log_ary = $snap->{_log} || [];
	if (open CMDLOG, $logfile) {
		send_mail( join("", @$log_ary, <CMDLOG>), \%opt);
		close CMDLOG;
	}

}

sub send_mail {
    my($body, $opt) = @_;

	$opt ||= {};

	$opt->{to} ||= 'root';

	$opt->{subject} ||= "Snapback results for $myhost";

	my %non_header = qw( sendmail  1 );
	my @headers;
    
	for(keys %$opt) {
		my $hdr = $_;
		next if $non_header{$_};
		$hdr =~ s/_+/-/g;
		$hdr =~ s/-+/-/g;
		$hdr =~ s/(\w+)/\u$1/g;
		push @headers, "$hdr: $opt->{$_}";
	}
	warn("send_mail: to=$opt->{to} subj=$opt->{subject}\n") if $opt{d};

    my $ok = 0;
    my $none;
    my $using = $opt->{sendmail};

    if($using =~ /^(none|Net::SMTP)$/i) {
        $none = 1;
        $ok = 1;
    }

    SEND: {
        last SEND if $none;
        open(MVMAIL,"|$using -t") or last SEND;
        my $mime = '';
        for(@headers) {
            s/\s*$/\n/;
            print MVMAIL $_
                or last SEND;
        }
		print MVMAIL "\n";
        print MVMAIL $body
            or last SEND;
		close MVMAIL or last SEND;
        $ok = ($? == 0);
    }

	if (!$ok) {
        my $msg = sprintf(
						"Unable to send mail using %s\nTo: %s\nSubject: %s\n\n%s",
						$using,
						$opt->{to},
						$opt->{subject},
						$body,
					);
        warn($msg);
    }

	return $ok;
}

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

See http://www.mikerubel.org/computers/rsync_snapshots/ for detailed
information on the principles used.

The script works on a I<pull> basis. The backup server runs this script
and initiates rsync connections (usually via SSH) to the client
machine(s) to backup the requested directories.

Apache-style configuration files are used. A configuration file for
a basic backup might look like

	Hourlies    4
	Dailies     7
	Weeklies    4
	Monthlies  12
	AutoTime   Yes

	AdminEmail mikeh@perusion.com

	LogFile    /var/log/snapback.log
	Exclude *debug
	Exclude core.*
	SnapbackRoot /etc/snapback

	Destination /mnt/backup1

	<Backup mike.perusion.com>
		Destination /space
		Hourlies 2
		Directory /home/mike/
		Directory /etc/
		Directory /var/lib/mysql/
		Directory /var/lib/pgsql/
		<Directory /home/work/>
			Hourlies 4
		</Directory>
	</Backup>

	<Backup jean.perusion.com>
		Hourlies 2
		Directory /home/jean/
		Directory /var/mail/
	</Backup>

The above configuration will be discussed in detail below.

=head2 Pre-requisites

This script is only tested on Linux at this point, but should operate
on any UNIX-based computer with the following:

	Gnu toolset, including cp, rm, and mv
	rsync 2.5.7 or higher
	ssh
	Perl 5.8 or higher
	Perl module Config::ApacheFormat

=head1 CONFIGURATION

The configuration directives use Apache format, thanks to the Config::ApacheFormat
module.

Inheritance is on -- a sub-block inherits all configuration directives
above it. You can override any configuration directive within the block
container.

If not specified with the C<-c> command line option, the following
files are checked for existence in order and the first one found is
used:

	/etc/snapback2.conf
	/etc/snapback/snapback2.conf
	/etc/snapback.conf
	/etc/snapback/snapback.conf

=head2 Block directives

There are two blocks supported:

=over 4

=item Backup

This specifies the host computer which will be backed up, and it is given
an internet address as a parameter (host name or IP address). Only one
block can be specified per hostname per configuration file, but it is
possible to make the parameter a pseudo-host by overriding the address
with the C<BackupHost> directive.

For example:

	<Backup pseudo>
		BackupHost jean.perusion.com
		Hourlies 2
		Directory /etc/
	</Backup>
 
	<Backup jean.perusion.com>
		Hourlies 4
		Directory /home/jean/
	</Backup>

Both backup configurations use C<jean.perusion.com> as the target machine.

=item Directory

This is contained within a C<Backup> block, and is an alternate method
of specifying a C<Directory>. The parameter is the directory name. The
use for this is specifying different backup parameters for that directory
only.

For example:

	## directives are not case-sensitive
	<backup perusion.com>
		Destination /mnt/backup1
		Hourlies 4
		Directory /etc/
		Directory /var/lib/mysql/
		<Directory /var/lib/catalogs/shop/orders>
			Destination /mnt/backup1/orders
			Hourlies 24
		</Directory>
	</backup>

This allows a real hourly backup of a directory where frequent backups
are needed, while cutting down the frequency of the main backup.

=back

=head2 Other directives

The rest of the directives control various facets of the backup.

=over 4

=item AdminEmail

Email address to mail errors (or results if AlwaysEmail is set).
Default blank.

=item After

If set to a valid time, the backup must be done after the time
specified. If the C<Before> directive is also specified, can also
be before that time.

Default is not set, allowing backup any time.

Times are local.

Examples:

	Before 7am
	After  6pm

Allows backup before 7am or after 6pm. The times of 0500 and
1800 would be equivalent.

	After  6pm

Only allows backup between 1800 and 2359.

=item AlwaysEmail

Always email results even if there is not an error. Target address is
set in C<AdminEmail>.

=item AutoTime

If set to yes, which is the default, the time of the previous backup
is checked and backup is only done if appropriate. The formula for
checking appropriateness is:

	(24 / Hourlies - 0.5) * 60 * 60 < now - mtime

where I<Hourlies> is the value of the C<Hourlies> directive, I<now> is
the current time in seconds since 1970, and I<mtime> is the modification
time in seconds since 1970.

For example, if C<Hourlies> is set to 4 and the script is called every
hour, it will only run the backup if the timestamp of the latest hourly
backup is more than 5.5 hours old. Obviously this means your backup
should take less than an hour to complete; if you have an extremely
extensive backup setup that could exceed an hour you will want to break
it up into separate runs or make the script call frequency greater.

=item Before

If set to a valid time, the backup must be done before the time
specified. If the C<After> directive is also specified, can also be
done After that time.

Default is not set, allowing backup any time.

Times are local.

Examples:

	Before 7am
	After  6pm

Allows backup before 7am or after 6pm. The times of 0500 and
1800 would be equivalent.

	Before  6am

Only allows backup to start between 0000 and 0559.

=item ChargeFile

The file where byte counts are logged in the format 

	host:YYYYMMDD:N

where YYYYMMDD is the date in quasi-ISO format and N is the number
of bytes read. This allows monitoring of bandwidth used for a particular
backup host, possibly for a bandwidth-based charging mechnism.

Unless C<RsyncVerbose> is set, also sets the C<--stats> option
so that transfer statistics can be captured.

=item Compress

The rsync program can compress its transfers. If the backup is going
over a high-speed internal network, this may not be a win. Set this
directive to I<No> to turn off compression:

	Compress No

Default is C<Yes>.

=item Cp

Full path to the GNU C<cp> program. Default is I</bin/cp>.

=item CreateDir

Controls whether Destination directories will be created automatically.
A Boolean (Yes/No) directive. Default is I<Yes>.

=item DailyDir

The root name of the daily backup directory, default I<daily>.
Not normally changed.

=item Debug

Sets debug output on. Equivalent to passing the C<-d> option
on the command line.

In the future, the debug level may vary with the number passed.
At the moment, there is only one debug level.

Example:

	Debug  4

=item DebugLog

Normally debug output goes to STDERR, but if you want it sent
to a file specify the file with this directive.

Example:

	DebugLog /tmp/snapback.debug

=item Destination

The destination directory for the backup. A subdirectory 
of the host address is created (providing CreateDir is yes, 
the default), and then the first part of the C<Directory>
is created. The hourly/daily/weekly directories are then
maintained there.

For example, this configuration:

	Destination /mnt/backup1
	<Backup perusion.com>
		Directory /var/lib/mysql/
		Directory /home/mike/
		Directory /home/work/
	</Backup>

will create the following directories on its first run:

	/mnt/backup1/perusion.com/var/lib/mysql/hourly.0
	/mnt/backup1/perusion.com/var/lib/mysql/daily.0
	/mnt/backup1/perusion.com/home/mike/hourly.0
	/mnt/backup1/perusion.com/home/mike/daily.0
	/mnt/backup1/perusion.com/home/work/hourly.0
	/mnt/backup1/perusion.com/home/work/daily.0

If the run was made on Sunday, a weekly.0 will be created. If the run
was made on the first day of the month, a monthly.0 will be created.

=item DestinationList

A list of destinations that will be checked for the proper
backup place. If this is in force, the C<Destination> directive
will be ignored.

Set to the places where you want backup to go, i.e.:

	DestinationList  /mnt/backup1 /mnt/backup2

It checks the timestamp of the hourly.0 directory at each
target, and selects the least-recently-used one for the target.

This allows spreading the backup over multiple disks for greater
reliablility.

If you want to set a single destination in a Backup sub-block,
overriding a global DestinationList, either set

	DestinationList none
	Destination     /real/destination

or just set the DestinationList directive to the single directory.

The number of Hourlies, Dailies, Weeklies, and Monthlies 
still applies at each target. 

For example, this configuration:

	DestinationList /mnt/backup1 /mnt/backup2
	Hourlies 2
	<Backup perusion.com>
		Directory /var/lib/mysql/
		Directory /home/mike/
	</Backup>

will create the following directories on its first run:

	/mnt/backup1/perusion.com/var/lib/mysql/hourly.0
	/mnt/backup1/perusion.com/var/lib/mysql/daily.0
	/mnt/backup1/perusion.com/home/mike/hourly.0
	/mnt/backup1/perusion.com/home/mike/daily.0

this on its second:

	/mnt/backup2/perusion.com/var/lib/mysql/hourly.0
	/mnt/backup2/perusion.com/var/lib/mysql/daily.0
	/mnt/backup2/perusion.com/home/mike/hourly.0
	/mnt/backup2/perusion.com/home/mike/daily.0

and this on its third:

	/mnt/backup1/perusion.com/var/lib/mysql/hourly.0
	/mnt/backup1/perusion.com/var/lib/mysql/hourly.1
	/mnt/backup1/perusion.com/var/lib/mysql/daily.0
	/mnt/backup1/perusion.com/home/mike/hourly.0
	/mnt/backup1/perusion.com/home/mike/hourly.1
	/mnt/backup1/perusion.com/home/mike/daily.0

etc.

=item Directory

The directory to be backed up. It will be created on the C<Destination>,
and hourly.N, daily.N, weekly.N, and monthly.N directories will be
maintained there. See also C<Directory>.

Only valid within a <Backup host> block.

This directive is a multiple directive, and it can be set as many
times as needed.

A trailing slash is always added if necessary unless LiteralDirectory
is set to yes (which it should not be unless you are an rsync expert).

=item Exclude

File patterns to be excluded. Passed to C<rsync> with the --exclude-pattern
option. See the documentation for C<rsync>.

It is normal to exclude core files, for example:

	Exclude core
	Exclude core.*

This directive is a multiple directive, and it can be set as many
times as needed.

=item HourlyDir

The root name of the hourly backup directory, default I<hourly>.
Not normally changed.

=item IgnoreVanished

Ignore errors from rsync when the error code is only "file has
vanished". This error usually happens when a PID or other transient file
goes away.

A yes/no directive, default No.

=item Include

Specify a file or directory to include from. If the specification
is a directory, it will include all files in the directory:

	Include clients

That is the equivalent of "Include clients/*", though that 
syntax is not supported due to Config::ApacheFormat limitations.

To include only a single file:

	Include clients/something.conf

The file specification is based in C<SnapbackRoot>.

=item LiteralDirectory

Normally snapback automatically appends a C</> to the source
directory name to make rsync work properly. If C<LiteralDirectory>
is set to C<Yes>, then it will not do that, with unpredictable
results.

Default is C<No>, and you should think long and hard before
changing it.  It is possible to construct useful backups without
a trailing slash, but you will have to be an rsync expert.

In other words, don't mess with this.

=item LogFile

The name of the file where backup runs are logged. Default
is I</var/log/snapback.log>.

=item ManyFiles

If the backup target has a large number of files, the backup
system overhead
to remove the outdated backup directory and hard-link the new backup directory
will be considerable.

This option, when set to I<Yes> in the C<Backup> container (or globally)
will cause the outdated backup directory to be moved to the prospective
next backup directory. Rsync then operates on that directory, and while
transfer bandwidth might be greater, overall system overhead will be
much less.

To set in your C<snapback.conf>:

	ManyFiles Yes

Once again, this is usually in the individual backup container.

The C<ManyFiles> directive is not compatible with C<RetainPermissions>
and sets it off if active.

You should choose this option when you have a large number
of small files and you don't have an overriding need to retain
ownership and permissions on the old backups.

=item MonthlyDir

The root name of the monthly backup directory, default I<monthly>.
Not normally changed.

=item Mv

Full path to the GNU C<mv> program. Default is I</bin/mv>.

=item MyHost

The name of the backup host itself, used only for reporting purposes.
Default is the result of Sys::Hostname::hostname().

=item MustExceed

The amount of time the current time must exceed the previous backup
modification time before a backup will be done, when C<AutoTime> is
on. Default is C<5 minutes>.

=item PingCommand

A shell command which is run to determine whether the target
host is up and running. A true (zero) exit status indicates that
backup should be done, a non-true exit status indicates that the
backup should be skipped.

The following strings are substituted for:

	%h     Host name of backup
	%d     Directory name being backed up
	%c     Client name

Example:

	PingCommand  "ping -c 1 -q %h >/dev/null"

=item RetainPermissions

Normally C<snapback2> changes the permissions and ownership of backed-up
files in the newest backup to match the current state of the file
system. Should you need to restore an earlier backup, those settings
might have been changed.

When C<RetainPermissions> is active, the rsync program will be called
with the C<--link-dest> option (providing there is a previous backup to
link to). It will not link files where ownership and permissions have
changed. It will copy locally and change the permissions.

This is the default, and to turn it off you must set:

	RetainPermissions No

This option is automatically turned off when C<ManyFiles> is 
set, and this is the main time you will not want C<RetainPermissions>
active. It is recommended that you keep the default.

=item Rm

Full path to the GNU C<rm> program. Default is I</bin/rm>.

=item Rsync

Full path to the C<rsync> program. Default is I<rsync>.

=item RsyncOpts

The options for the rsync program. These are specified as
if they were on the command line.  Default is

   -a --force --delete-excluded  --one-file-system --delete

If you want to change or add your own, below is an example
RsyncOpts entry in the config file

  RsyncOpts --rsync-path="ssh target_machine rsync" -a --force \
            --delete-excluded  --one-file-system --delete

The following options are set by C<snapback2> options:

=over 4

=item -e

Set by the C<RsyncShell> directive. If C<RsyncShell> is I<none>, no
-e option is passed. In addition, if C<RsyncShell> is I<rsync>, the
host name is appended with C<::> instead of C<:> to use proper
rsync URLs.

=item --link-dest=DIR

Set when C<RetainPermissions> is active. The C<DIR> is usually
C<../hourly.1>.

=item --stats

Set by ChargeFile if -v is not in force, so that transfer stats can
be captured.

=item -v

Set by the C<RsyncVerbose> directive. 

=item -z

Set by the C<Compress> directive. 

=back

Play with C<RsyncOpts> at your own risk. 8-)

=item RsyncVerbose

Adds the C<-v> option to c<rsync>, which shows the detail on which
files were transferred. 

=item SendMail

Path to the sendmail program, used for emailing errors (or results with
C<AlwaysEmail>). Default is I</usr/sbin/sendmail>.

The program to use must accept the C<-t> option.

=item SnapbackRoot

The root directory where any Include directives will be based.
Default is I</etc/snapback>.

Example:

	SnapbackRoot  /opt/snapback

=item WeeklyDir

The root name of the weekly backup directory, default C<weekly>.
Not normally changed.

=back

=head1 OPTIONS

There are a few command line options that can be called:

=over 4

=item -c configfile

The complete path to the configuration file to use. If not specified,
defaults to:

	/etc/snapback2.conf
	/etc/snapback/snapback2.conf
	/etc/snapback.conf
	/etc/snapback/snapback.conf

Fails if one of those is not found.

=item -d 

Turns on debug output. If C<DebugLog> is set, will go there, otherwise
goes to the standard error output.

=item -l logfile

Normally snapback2 creates a temporary file named /tmp/rsyncNNNNN,
where NNNNN is the process ID. This parameter passes a log file
to use instead. It will be created if it does not exist, and appended to
if it does.

=item -p PATTERN

A pattern to apply to the <Backup foo> block. Only hosts matching
the pattern will be operated on.

To backup all hosts in the perusion.com domains, but not any others,
do:

	snapback2 -p perusion.com

=item -P PATTERN

A pattern to apply to any C<Directory>. Only directories matching the
pattern will be operated on.

To backup all /var/ diretories, do:

	snapback2 -P /var/

Other directories will be ignored.

To backup /var/ directories in the perusion.com domains, but not
any others, do:

	snapback2 -p perusion.com -P /var/

=back

=head1 AUTHOR AND CREDITS

Mike Heins, <mikeh@perusion.com>.

This script is heavily cribbed from the original snapback done by Art
Mulder. Some of the routines, particularly do_rotate() and do_backup(),
are much the same; the main program flow and configuration is
completely redone.

The initial principles were elucidated by Mike Rubel.

=cut


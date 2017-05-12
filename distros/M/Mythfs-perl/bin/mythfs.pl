#!/usr/bin/perl
 
=head1 NAME

mythfs.pl - Mount Fuse filesystem to display TV recordings managed by a MythTV backend

=head1 SYNOPSIS

 % mythfs.pl [options] <Hostname of Backend> <mount point>

Options:

  --pattern=<pattern>          filename pattern default ("%T/%S")
  --trim=<char>                 trim redundant occurrences of this character (no default)

  --mountpt=<path>              mountpoint/directory for locally stored recordings (no default)
  --Port=<port>                 HTTP request port on backend (6544)
  --cachetime=<time>            cache time for recording names (10 minutes)

  --unmount                     unmount the indicated directory
  --foreground                  remain in foreground (false)
  --nothreads                   disable threads (false)
  --debug=<1,2>                 enable debugging. Pass -d 2 to trace Fuse operations (verbose!!)

  --option=allow_other          allow other accounts to access filesystem (false)
  --option=default_permissions  enable permission checking by kernel (false)
  --option=fsname=name          set filesystem name (none)
  --option=use_ino              let filesystem set inode numbers (false)
  --option=nonempty             allow mounts over non-empty file/dir (false)

  --help                        this text
  --man                         full manual page

Options can be abbreviated to single letters. For example you can
abbreviate "--pattern=<pattern>" to "-p <pattern>".

=head1 DESCRIPTION

This script will create a virtual filesystem representing the
recordings made by a MythTV (www.mythtv.org) backend. You must provide
the name or IP address of the backend host, and the path to an empty
directory to mount the virtual filesystem on.

Filename patterns consist of regular characters and substitution
patterns beginning with a %. Slashes (\/) will delimit directories and
subdirectories. Empty directory names will be collapsed. The default
is "%T/%S", the recording title followed by the subtitle.  Run this
command with "-p help" to get a list of all the substitution patterns
recognized.

By default, files will be streamed as needed from the MythTV
backend. However, if the recording files are accessible directly from
the filesystem (e.g. via an NFS mount), you can provide the path to
this directory using the --mountpt option. The filenames will then be
presented as symbolic links.

Command line switches can abbreviated to single letters, so you can
use "-p %T/%S" instead of "--pattern=%T/%S".

If you request unmounting (using --unmount or -u), the first
non-option argument is interpreted as the mountpoint, not the backend
hostname.

=head1 MORE INFORMATION

This is a FUSE filesystem for MythTV (www.mythtv.org).  It uses the
Myth 0.25 API to mount the TV recordings known to a MythTV master
backend onto a virtual filesystem on the client machine for convenient
playback with mplayer or other video tools. Because it uses the MythTV
network protocol, the recordings do not need to be on a shared
NFS-mounted disk, nor does the Myth database need to be accessible
from the client.

=head2 Usage

To mount the recordings contained on the master backend "MyHost" onto
a local filesystem named "/tmp/mythfs" use this command:

 $ mkdir /tmp/mythfs
 $ mythfs.pl MyHost /tmp/mythfs

The script will fork into the background and should be stopped with
fusermount. The mounted /tmp/mythfs directory will contain a series of
human-readable recordings organized by title (directory) and subtitle
(file). 

To unmount:

 $ fusermount -u /tmp/mythfs

or

 $mythfs.pl -u /tmp/mythfs

NOTE: Do NOT try to kill the mythfs.pl process. This will only cause a
hung filesystem that needs to be unmounted with fusermount.

There are a number of options that you can pass to mythfs.pl,
including the ability to customize the filesystem layout and set the
interval that the backend is checked for new and deleted
recordings. Call mythfs.pl with the -h option for the complete help
text.

=head2 Local Recordings

The default behavior of this filesystem is to use the Myth API to
stream recordings across the network when you attempt to read from
them. This is done in an efficient way that fetches just the portion
of the file you wish to read. However, if the underlying recording
files are directly accessible (either in a regular director or via an
NFS mount), you can get better performance by passing mythfs.pl the
--mountpt option with the path to the directory in which the
recordings can be found. The filesystem will then be set up as a set
of symbolic links that point from a human readable file name to the
recording file.

The main advantage of creating symbolic links is that NFSv4 can be
noticeably faster than the backend streaming protocol -- about a 25%
improvement on my local network. The main limitation is that this mode
does not understand storage groups, so all recordings need to be
located in a single storage group in a locally-accessible
directory. However if a recording file is not found in local
directory, then mythfs.pl will fall back to the streaming protocol, so
the recording is accessible one way or another.

=head2 The Default Directory Layout

Recordings that are part of a series usually have a title (the series
name) and subtitle (the episode name). Such recordings are displayed
using a two-tier directory structure in which the top-level directory
is the series name, and the contents are a series of recorded
episodes. The corresponding pattern (as described in the next section)
is "%T/%S".

For recordings that do not have a subtitle, typically one-off movie
showings, the recording is placed at the top level.

If needed for uniqueness, the channel number and time the recorded was
started is attached to the filename, along with an extension
indicating the recording type (.mpg or .nuv). The file create and
modification times correspond to the recording start time. For
directories, the times are set to the most recent recording contained
within the directory.

Here is an example directory listing:

 % ls -lR  /tmp/mythfs
 total 35
 -r--r--r-- 1 lstein lstein 12298756208 Dec 30 00:00 A Funny Thing Happened on the Way to the Forum.mpg
 -r--r--r-- 1 lstein lstein 14172577964 Dec 25 16:00 A Heartland Christmas.mpg
 dr-xr-xr-x 1 lstein lstein           5 Mar 11 03:00 Alfred Hitchcock Presents
 dr-xr-xr-x 1 lstein lstein           8 May  2 00:00 American Dad
 ...

 /home/lstein/Myth/Alfred Hitchcock Presents:
 total 3
 -r--r--r-- 1 lstein lstein 647625408 Dec 25 15:30 Back for Christmas.mpg
 -r--r--r-- 1 lstein lstein 647090360 Dec  7 00:00 Dead Weight.mpg
 -r--r--r-- 1 lstein lstein 660841056 Mar 11 03:00 Rose Garden.mpg
 -r--r--r-- 1 lstein lstein 647524452 Dec 25 00:00 Santa Claus and the 10th Ave. Kid.mpg
 -r--r--r-- 1 lstein lstein 649819932 Dec 27 00:00 The Contest of Aaron Gold.mpg

 /home/lstein/Myth/American Dad:
 total 4
 -r--r--r-- 1 lstein lstein 3512038152 Apr 24 00:00 Flirting With Disaster.mpg

The size of directories corresponds to the number of recordings (not
counting subdirectories) contained within it. The modification time of
directories is the start time of the most recent recording contained
within it.

Two automatically-created files are always present at the top level of
the directory. "STATUS" contains a human-readable description of what
happened the last time the script attempted to refresh the list of
recordings from the backend. It is useful in diagnosing connection
problems. ".fuse-mythfs" contains version and copyright information
for this script, and can be used to detect if the Myth filesystem is
mounted.

=head2 Customizing the Directory Listing

You may customize the directory listing by providing a pattern for
naming each recording using the -p option. For example:

 $ mythfs.pl -p '%C/%T:%S (%od-%ob-%oY)' mythbackend ~/Myth

This will create filenames that look like this:

 Sitcom/The Simpsons:The Food Wife (13-Nov-2011).mpg

Patterns contain a combination of constant strings plus substitution
patterns consisting of the "%" sign plus 1 to three characters. A
slash will be interpreted as a directory level: multiple levels are
allowed. 

Commonly-used substitution patterns are:

    %T   = Title (show name)
    %S   = Subtitle (episode name)
    %C   = Category
    %TC  = If part of a series, then Title, else Category
    %ST  = If part of a series, then SubTitle, else Title
    %cn  = Channel: channel number
    %cN  = Channel: channel name
    %y   = Recording start time:  year, 2 digits
    %Y   = Recording start time:  year, 4 digits
    %m   = Recording start time:  month, leading zero
    %b   = Recording start time:  abbreviated month name
    %B   = Recording start time:  full month name
    %d   = Recording start time:  day of month, leading zero
    %h   = Recording start time:  12-hour hour, with leading zero
    %H   = Recording start time:  24-hour hour, with leading zero
    %i   = Recording start time:  minutes
    %s   = Recording start time:  seconds
    %a   = Recording start time:  am/pm
    %A   = Recording start time:  AM/PM

A full list of patterns can be obtained by running "mythfs.pl -p
help".

Patterns are largely compatible with the excellent mythlink.pl
(http://www.mythtv.org/wiki/Mythlink.pl) script, but there are a small
number of enhancements, such as the ability to generate the month
name. Also, the patterns that generate the month name without a
leading zero are not supported.

You may wish to use a delimiter to separate fields of the recording
name, for example "%T:%S" to generate "Title:Subtitle". Occasionally a
recording field is empty, leading to names like "The Wild
Ones:.mpg". To avoid this, pass the --trim option with the delimiter
you use, and dangling/extra delimiters will be trimmed:

<pre>
 $ mythfs.pl -p '%T:%S' --trim=':' backend /tmp/myth
</pre>

If after applying the pattern to a recording the resulting path is not
unique, then this script will uniqueify the path by appending to it
the channel number and recording start time, for example:

 Masterpiece Classic/Downtown Abbey_17_1-2013-02-11T02:00.mpg
 Masterpiece Classic/Downtown Abbey_17_1-2013-03-10T06:00.mpg

=head2 Caching

New and updated recordings will appear in the filesystem after a
slight delay due to the manner in which the script caches the
recording list. By default the backend is only checked for updates
every 10 minutes, but you can adjust this using the --cachetime
option, which takes the interval in minutes at which the system
checks for new and updated recordings.

For example, this command will reduce the update interval to 2
minutes:

  $ mythfs.pl MyHost --cachetime=2 /tmp/mythfs

=head2 Fuse Notes

For best performance, you will need to run this filesystem using a
version of Perl that supports IThreads. Otherwise it will fall back to
non-threaded mode, which will introduce occasional delays during
directory listings and have notably slower performance when reading
from more than one file simultaneously.

If you are running Perl 5.14 or higher, you *MUST* use at least 0.15
of the Perl Fuse module. At the time this was written, the version of
Fuse 0.15 on CPAN was failing its regression tests on many
platforms. I have found that the easiest way to get a fully
operational Fuse module is to clone and compile a patched version of
the source, following this recipe:

 $ git clone git://github.com/isync/perl-fuse.git
 $ cd perl-fuse
 $ perl Makefile.PL
 $ make test   (optional)
 $ sudo make install

=head1 AUTHOR

Copyright 2013, Lincoln D. Stein <lincoln.stein@gmail.com>

=head1 LICENSE

This package is distributed under the terms of the Perl Artistic
License 2.0. See http://www.perlfoundation.org/artistic_license_2_0.

=cut

use strict;
use warnings;
use Net::MythTV::Fuse;
use File::Spec;
use Config;
use POSIX 'setsid';

use Getopt::Long qw(:config no_ignore_case bundling_override);
use Pod::Usage;

my (@FuseOptions,$CacheTime,$Debug,$NoDaemon,$Pattern,
    $LocalMount,$NoThreads,$Delimiter,
    $HTTPPort,$UnMount,
    $Help,$Man,
    $XMLDummyDataPath, # for debugging
    );

GetOptions(
    'help|h|?'     => \$Help,
    'man|m'        => \$Man,
    'option|o:s'   => \@FuseOptions,
    'cachetime|c=f'=> \$CacheTime,
    'foreground|f' => \$NoDaemon,
    'pattern|p=s'  => \$Pattern,
    'debug|d:i'    => \$Debug,
    'trim|t=s'     => \$Delimiter,
    'mountpt|m=s'  => \$LocalMount,
    'Port|P=i'     => \$HTTPPort,
    'nothreads|n'  => \$NoThreads,
    'unmount|u'    => \$UnMount,
    'XMLDummy|X=s' => \$XMLDummyDataPath,  # for debugging
 ) or pod2usage(-verbose=>2);

 pod2usage(1)                          if $Help;
 pod2usage(-exitstatus=>0,-verbose=>2) if $Man;

list_patterns_and_die() if $Pattern && $Pattern eq 'help';
$NoThreads  ||= check_disable_threads();
$Debug        = 1 if defined $Debug && $Debug==0;
$Debug      ||= 0;
$HTTPPort   ||= 6544;
$CacheTime  ||= 5;
$Pattern    ||= "%T/%S";

if ($UnMount) {
    my $mountpoint = shift;
    -e "$mountpoint/.fuse-mythfs" or die "Abort: A MythTV filesystem is not mounted at $mountpoint.\n";
    exec 'fusermount','-u',$mountpoint;
}

my $host       = shift or pod2usage(1);
my $mountpoint = shift or pod2usage(1);
$mountpoint    = File::Spec->rel2abs($mountpoint);

my $options  = join(',',@FuseOptions,'ro');

die "Myth filesystem is already mounted on $mountpoint. Use fusermount -u $mountpoint to unmount.\n"
    if -e "$mountpoint/".Net::MythTV::Fuse->marker_file;

become_daemon() unless $NoDaemon;

my $filesystem = Net::MythTV::Fuse->new(
    mountpoint      => $mountpoint,
    backend         => $host,
    port            => $HTTPPort,
    debug           => $Debug,
    threaded        => !$NoThreads,
    fuse_options    => $options,
    cachetime       => $CacheTime * 60,
    delimiter       => $Delimiter,
    pattern         => $Pattern,
    localmount      => $LocalMount,
    dummy_data_path => $XMLDummyDataPath,
    );
$filesystem->run();

exit 0;

sub check_disable_threads {
    unless ($Config{useithreads}) {
	warn "This version of perl is not compiled for ithreads. Running with slower non-threaded version.\n";
	return 1;
    }
    if ($] >= 5.014 && $Fuse::VERSION < 0.15) {
	warn "You need Fuse version 0.15 or higher to run under this version of Perl.\n";
	warn "Threads will be disabled. Running with slower non-threaded version.\n";
	return 1;
    }

    return 0;
}

sub become_daemon {
    fork() && exit 0;
    chdir ('/');
    setsid();
    open STDIN,"</dev/null";
    fork() && exit 0;
}

sub list_patterns_and_die {
    while (<DATA>) {
	print;
    }
    exit -1;
}

__END__
The following substitution patterns can be used in recording paths.

    %T   = Title (show name)
    %S   = Subtitle (episode name)
    %R   = Description
    %C   = Category
    %U   = RecGroup
    %TC  = If part of a series, then Title, else Category
    %ST  = If part of a series, then SubTitle, else Title
    %hn  = Hostname of the machine where the file resides
    %PI  = Program ID
    %SI  = Series ID
    %st  = Stars
    %c   = Channel:  MythTV chanid
    %cn  = Channel:  channum
    %cc  = Channel:  callsign
    %cN  = Channel:  channel name
    %y   = Recording start time:  year, 2 digits
    %Y   = Recording start time:  year, 4 digits
    %m   = Recording start time:  month, leading zero
    %b   = Recording start time:  abbreviated month name
    %B   = Recording start time:  full month name
    %d   = Recording start time:  day of month, leading zero
    %h   = Recording start time:  12-hour hour, with leading zero
    %H   = Recording start time:  24-hour hour, with leading zero
    %i   = Recording start time:  minutes
    %s   = Recording start time:  seconds
    %a   = Recording start time:  am/pm
    %A   = Recording start time:  AM/PM
    %ey  = Recording end time:  year, 2 digits
    %eY  = Recording end time:  year, 4 digits
    %em  = Recording end time:  month, leading zero
    %eb  = Recording end time:  abbreviated month name
    %eB  = Recording end time:  full month name
    %ej  = Recording end time:  day of month
    %ed  = Recording end time:  day of month, leading zero
    %eh  = Recording end time:  12-hour hour, with leading zero
    %eH  = Recording end time:  24-hour hour, with leading zero
    %ei  = Recording end time:  minutes
    %es  = Recording end time:  seconds
    %ea  = Recording end time:  am/pm
    %eA  = Recording end time:  AM/PM
    %py  = Program start time:  year, 2 digits
    %pY  = Program start time:  year, 4 digits
    %pm  = Program start time:  month, leading zero
    %pb  = Program start time:  abbreviated month name
    %pB  = Program start time:  full month name
    %pj  = Program start time:  day of month
    %pd  = Program start time:  day of month, leading zero
    %ph  = Program start time:  12-hour hour, with leading zero
    %pH  = Program start time:  24-hour hour, with leading zero
    %pi  = Program start time:  minutes
    %ps  = Program start time:  seconds
    %pa  = Program start time:  am/pm
    %pA  = Program start time:  AM/PM
    %pey = Program end time:  year, 2 digits
    %peY = Program end time:  year, 4 digits
    %pem = Program end time:  month, leading zero
    %peb = Program end time:  abbreviated month name
    %peB = Program end time:  full month name
    %pej = Program end time:  day of month
    %ped = Program end time:  day of month, leading zero
    %peh = Program end time:  12-hour hour, with leading zero
    %peH = Program end time:  24-hour hour, with leading zero
    %pei = Program end time:  minutes
    %pes = Program end time:  seconds
    %pea = Program end time:  am/pm
    %peA = Program end time:  AM/PM
    %oy  = Original Airdate:  year, 2 digits
    %oY  = Original Airdate:  year, 4 digits
    %om  = Original Airdate:  month, leading zero
    %ob  = Original Airdate:  abbreviated month name
    %oB  = Original Airdate:  full month name
    %oj  = Original Airdate:  day of month
    %od  = Original Airdate:  day of month, leading zero
    %%   = a literal % character

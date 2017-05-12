mythfs-perl
===========

This is a FUSE filesystem for MythTV (www.mythtv.org).  It uses the
Myth 0.25 API to mount the TV recordings known to a MythTV master
backend onto a virtual filesystem on the client machine for convenient
playback with mplayer or other video tools. Because it uses the MythTV
network protocol, the recordings do not need to be on a shared
NFS-mounted disk, nor does the Myth database need to be accessible
from the client.

Installation
============

Run the following commands from within the top-level directory of this
distribution:

 <pre> 
 $ <b> git clone git://github.com/lstein/mythfs-perl.git
 $ <b>cd mythfs-perl</b>
 $ <b>./Build.PL</b>
 $ <b>./Build test</b>
 $ <b>sudo ./Build install</b>
</pre>

If you get messages about missing dependencies, run:

<pre>
 $ <b>./Build installdeps</b>
</pre>

and then "sudo ./Build install". See Fuse Notes if you get
Fuse-related errors when attempting to install dependencies.

For best performance, Perl must have been compiled with support for
IThreads. In addition, you will need at Fuse version 0.15 to run
correctly under Perl version >= 5.14.  Threading will be automatically
disabled if not available. See Fuse Notes for additional information.

Usage
=====

To mount the recordings contained on the master backend "MyHost" onto
a local filesystem named "/tmp/mythfs" use this command:

<pre>
 $ <b>mkdir /tmp/mythfs</b>
 $ <b>mythfs.pl MyHost /tmp/mythfs</b>
</pre>

The script will fork into the background and should be stopped with
fusermount. The mounted /tmp/mythfs directory will contain a series of
human-readable recordings organized by title (directory) and subtitle
(file). 

To unmount:

<pre>
 $ <b>fusermount -u /tmp/mythfs</b>
</pre>

NOTE: Do NOT try to kill the mythfs.pl process. This will only cause a
hung filesystem that needs to be unmounted with fusermount.

There are a number of options that you can pass to mythfs.pl,
including the ability to customize the filesystem layout and set the
interval that the backend is checked for new and deleted
recordings. Call mythfs.pl with the -h option for the complete help
text.

Local Recordings
================

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

The Default Directory Layout
============================

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

<pre>
 % <b>ls -lR  /tmp/mythfs</b>
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
</pre>

The size of directories corresponds to the number of recordings (not
counting subdirectories) contained within it. The modification time of
directories is the start time of the most recent recording contained
within it.

Customizing the Directory Listing
=================================

You may customize the directory listing by providing a pattern for
naming each recording using the -p option. For example:

 $ mythfs.pl -p '%C/%T:%S (%od-%ob-%oY)' mythbackend ~/Myth

This will create filenames that look like this:

<pre>
 Sitcom/The Simpsons:The Food Wife (13-Nov-2011).mpg
</pre>

Patterns contain a combination of constant strings plus substitution
patterns consisting of the "%" sign plus 1 to three characters. A
slash will be interpreted as a directory level: multiple levels are
allowed. 

Commonly-used substitution patterns are:

    %T   = Title (show name)
    %S   = Subtitle (episode name)
    %C   = Category
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

Caching
=======

New and updated recordings will appear in the filesystem after a
slight delay due to the manner in which the script caches the
recording list. By default the backend is only checked for updates
every 10 minutes, but you can adjust this using the --cachetime
option, which takes the interval in minutes at which the system
checks for new and updated recordings.

For example, this command will reduce the update interval to 2
minutes:

  $ <b>mythfs.pl MyHost --cachetime=2 /tmp/mythfs</b>

Fuse Notes
==========

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

<pre>
 $ <b>git clone git://github.com/isync/perl-fuse.git</b>
 $ <b>cd perl-fuse</b>
 $ <b>perl Makefile.PL</b>
 $ <b>make test</b>   (optional)
 $ <b>sudo make install</b>
</pre>


Troubleshooting
===============

This script has not yet undergone diligent testing. Try running with
the -debug flag to see where the problems are occurring and report
issues to https://github.com/lstein/mythfs-perl.

Author
======

Copyright 2013, Lincoln D. Stein <lincoln.stein@gmail.com>

License
=======

This package is distributed under the terms of the Perl Artistic
License 2.0. See http://www.perlfoundation.org/artistic_license_2_0.

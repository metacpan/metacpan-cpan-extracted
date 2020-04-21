# ------------------------------------------------------------------------ #
# Quota.pm - Copyright (C) 1995-2020 T. Zoerner
# ------------------------------------------------------------------------ #
# This program is free software: you can redistribute it and/or modify
# it either under the terms of the Perl Artistic License or the GNU
# General Public License as published by the Free Software Foundation.
# (Either version 1 of the GPL, or any later version.)
# For a copy of these licenses see <http://www.opensource.org/licenses/>.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl Artistic License or GNU General Public License for more details.
# ------------------------------------------------------------------------ #

package Quota;

require Exporter;
use AutoLoader;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = ();

$VERSION = '1.8.1';

bootstrap Quota;

use Carp;
use strict;

##
##  Get block device for locally mounted file system
##  !! Do not use this to get the argument for the quota-functions in this
##  !! module, since not all operating systems use the device path for the
##  !! quotactl system call and e.g. Solaris doesn't even use a system call
##  !! Always use getqcarg() instead.
##

sub getdev {
  ($#_ > 0) && croak("Usage: Quota::getdev(path)");
  my($target) = (($#_ == -1) ? "." : $_[0]);
  my($dev) = (stat($target))[0];
  my($ret) = undef;
  my($fsname,$path);
 
  if(defined($dev) && ($target ne "") && !Quota::setmntent()) {
    while(($fsname,$path) = Quota::getmntent()) {
      ($ret=$fsname, last) if ($dev == (stat($path))[0]);
    }
    $! = 0;
  }
  Quota::endmntent();
  $ret;
}

##
##  Get "device" argument for this module's Quota-functions
##

sub getqcarg {
  ($#_ > 0) && croak("Usage: Quota::getqcarg(path)");
  my($target) = (($#_ == -1) ? "." : $_[0]);
  my($dev) = (stat($target))[0];
  my($ret) = undef;
  my($argtyp,$fsupp) = (Quota::getqcargtype() =~ /([^,]*)(,.*)?/);
  my($fsname,$path,$fstyp,$fsopt);

  if(defined($dev) && ($target ne "") && !Quota::setmntent()) {
    while(($fsname,$path,$fstyp,$fsopt) = Quota::getmntent()) {
      next if $fstyp =~ /^(lofs|ignore|auto.*|proc|rootfs)$/;
      my($pdev) = (stat($path))[0];
      if (defined($pdev) && ($dev == $pdev)) {
        if ($fsname =~ m|^[^/]+:/|) {
          $ret = $fsname;  #NFS host:/path
        } elsif (($fstyp =~ /^nfs/i) && ($fsname =~ m#^(/.*)\@([^/]+)$#)) {
          $ret = "$2:$1";  #NFS /path@host
        } elsif ($argtyp eq "dev") {
          if ($fsopt =~ m#(^|,)loop=(/dev/[^,]+)#) {
            $ret = $2;  # Linux mount -o loop
          } else {
            $ret = $fsname;
          }
        } elsif ($argtyp eq "qfile") {
          $ret = "$path/quotas";
        } elsif ($argtyp eq "any") {
          $ret = $target;
        } else { #($argtyp eq "mntpt")
          $ret = $path;
        }

        # XFS, VxFS and AFS quotas require separate access methods
        # (optional for VxFS: later versions use 'normal' quota interface)
        if   (($fstyp eq "xfs") && ($fsupp =~ /,XFS/)) { $ret = "(XFS)$ret" }
        elsif(($fstyp eq "vxfs") &&
              defined($fsupp) && ($fsupp =~ /,VXFS/)) { $ret = "(VXFS)$ret" }
        elsif((($fstyp eq "afs") || ($fsname eq "AFS")) &&
              ($fsupp =~ /,AFS/)) { $ret = "(AFS)$target"; }
        if   (($fstyp eq "jfs2") && ($fsupp =~ /,JFS2/)) { $ret = "(JFS2)$ret" }
        last;
      }
    }
    $! = 0;
  }
  Quota::endmntent();
  $ret;
}

package Quota; # return to package Quota so AutoSplit is happy
1;
__END__

=head1 NAME

Quota - Perl interface to file system quotas

=head1 SYNOPSIS

    use Quota;

    ($block_curr, $block_soft, $block_hard, $block_timelimit,
     $inode_curr, $inode_soft, $inode_hard, $inode_timelimit) =
    Quota::query($dev [,$uid [,kind]]);

    ($block_curr, $block_soft, $block_hard, $block_timelimit,
     $inode_curr, $inode_soft, $inode_hard, $inode_timelimit) =
    Quota::rpcquery($host, $path [,$uid [,kind]]);

    Quota::rpcpeer([$port [,$use_tcp [,timeout]]]);
    
    Quota::rpcauth([$uid [,$gid [,$hostname]]]);

    Quota::setqlim($dev, $uid, $block_soft, $block_hard,
                   $inode_soft, $inode_hard [,$tlo [,kind]]);

    Quota::sync([$dev]);

    $arg = Quota::getqcarg([$path]);

    Quota::setmntent();
    ($dev, $path, $type, $opts) = Quota::getmntent();
    Quota::endmntent();

=head1 DESCRIPTION

The B<Quota> module provides access to file system quotas.
The quotactl system call or ioctl is used to query or set quotas
on the local host, or queries are submitted via RPC to a remote host.
Mount tables can be parsed with B<getmntent> and paths can be
translated to device files (or whatever the actual B<quotactl>
implementations needs as argument) of the according file system.

=head2 Functions

=over 4

=item I<($bc,$bs,$bh,$bt, $ic,$is,$ih,$it) = Quota::query($dev, $uid, $kind)>

Get current usage and quota limits for a given file system and user.
The user is specified by its numeric uid; defaults to the process'
real uid.

The type of I<$dev> varies from system to system. It's the argument
which is used by the B<quotactl> implementation to address a specific
file system. It may be the path of a device file (e.g. F</dev/sd0a>)
or the path of the mount point or the quotas file at the top of
the file system (e.g. F</home.stand/quotas>). However you do not
have to worry about that; use B<Quota::getqcarg> to automatically
translate any path inside a file system to the required I<$dev> argument.

I<$dev> may also be in the form of C<"hostname:path">, which has the
module transparently query the given host via a remote procedure call
(RPC). In case you have B<NFS> (or similar network mounts), this type
of argument may also be produced by B<Quota::getqcarg>. Note: RPC
queries require I<rquotad(1m)> to be running on the target system. If
the daemon or host are down, the timeout is 12 seconds.

In I<$bc> and I<$ic> the current usage in blocks and inodes is returned.
I<$bs> and I<$is> are the soft limits, I<$bh> and I<$ih> hard limits. If the
soft limit is exceeded, writes by this user will fail for blocks or
inodes after I<$bt> or I<$it> is reached. These times are expressed
as usual, i.e. in elapsed seconds since 00:00 1/Jan/1970 GMT.

Note: When the quota limits are not exceeded, the timestamps
are meaningless and should be ignored.  When hard and soft limits are
both zero, this means there is no limit for that user. (On some
platforms the query may fail with error code I<ESRCH> in that case;
most however still report valid usage values.)

When I<$kind> is given and set to 1, the value in I<$uid> is taken as
gid and group quotas are queried. Group quotas may not be supported
across all platforms (e.g. Linux and other BSD based Unix variants,
OSF/1 and  AIX - check the quotactl(2) man page on your systems).

When I<$kind> is set to 2, project quotas are queried; this is
currently only supported for XFS. When unsupported, this flag is ignored.

=item I<Quota::setqlim($dev, $uid, $bs,$bh, $is,$ih, $tlo, $kind)>

Sets quota limits for the given user. Meanings of I<$dev>, I<$uid>,
I<$bs>, I<$bh>, I<$is> and I<$ih> are the same as in B<Quota::query>.

For file systems exceeding 2 TB: To allow passing block or inode
values larger or equal to 2^32 on 32-bit Perl versions, pass them
either as strings or floating point.

I<$tlo> decides how the time limits are initialized:
I<0>: The time limits are set to I<NOT STARTED>, i.e. the time limits
are not initialized until the first write attempt by this user.
This is the default.
I<1>: The time limits are set to I<7.0 days>.
More alternatives (i.e. setting a specific time) aren't available in
most implementations.

When I<$kind> is given and set to 1, I<$uid> is taken as gid and
group quota limits are set. This is not supported on all platforms
(see above). When I<$kind> is set to 2, project quotas are modified;
this is currently only supported for XFS. When unsupported, this
flag is ignored.

Note: if you want to set the quota of a particular user to zero, i.e.
no write permission, you must not set all limits to zero, since that
is equivalent to unlimited access. Instead set only the hard limit
to 0 and the soft limit for example to 1.

Note that you cannot set quotas via RPC.

=item I<Quota::sync($dev)>

Have the kernel update the quota file on disk or all quota files
if no argument given (the latter doesn't work on all systems,
in particular on I<HP-UX 10.10>).

The main purpose of this function is to check if quota is enabled
in the kernel and for a particular file system. Read the B<quotaon(1m)>
man page on how to enable quotas on a file system.

Note: on some systems this function always returns a success indication,
even on partitions which do not have quotas enabled (e.g. Linux 2.4).
This is not a bug in this module; it's a limitation in certain kernels.

=item I<($bc,$bs,$bh,$bt, $ic,$is,$ih,$it) =>

I<Quota::rpcquery($host,$path,$uid,$kind)>

This is equivalent to C<Quota::query("$host:$path",$uid,$kind)>, i.e.
query quota for a given user on a given remote host via RPC.
I<$path> is the path of any file or directory inside the
file system on the remote host.

Querying group quotas ($kind = 1) is only recently supported on some
platforms (e.g. on Linux via "extended" quota RPC, i.e. quota RPC
version 2) so it may fail due to lack of support either on client or
server side, or both.

=item I<Quota::rpcpeer($port,$use_tcp,timeout)>

Configure parameters for subsequent RPC queries; all parameters are
optional.  By default the portmapper on the remote host is used
(i.e. default port is 0, protocol is UDP)  The default timeout is
4 seconds.

=item I<Quota::rpcauth($uid,$gid,$hostname)>

Configure authorization parameters for subsequent RPC queries; 
all parameters are optional. By default uid and gid are taken from 
owner of the process and hostname is the host name of current machine.

=item I<$arg = Quota::getqcarg($path)>

Get the required I<$dev> argument for B<Quota::query> and B<Quota::setqlim>
for the file system you want to operate on. I<$path> is any path of an
existing file or directory inside that file system. The path argument is
optional and defaults to the current working directory.

The type of I<$dev> varies between operating systems, i.e. different
implementations of the quotactl functionality. Hence it's important for
compatibility to always use this module function and not really pass
a device file to B<Quota::query> (as returned by B<Quota::getdev>).
See also above at I<Quota::query>

=item I<$dev = Quota::getdev($path)>

Returns the device entry in the mount table for a particular file system,
specified by any path of an existing file or directory inside it. I<$path>
defaults to the working directory. This device entry need not really be
a device. For example on network mounts (B<NFS>) it's I<"host:mountpath">,
with I<amd(1m)> it may be something completely different.

I<NEVER> use this to produce a I<$dev> argument for other functions of
this module, since it's not compatible. On some systems I<quotactl>
does not work on devices but on the I<quotas> file or some other kind of
argument. Always use B<Quota::getqcarg>.

=item I<Quota::setmntent()>

Opens or resets the mount table. This is required before the first
invocation of B<Quota::getmntent>.

Note: on some systems there is no equivalent function in the C library.
But you still have to call this module procedure for initialization of
module-internal variables.

=item I<($dev, $path, $type, $opts) = Quota::getmntent()>

Returns the next entry in the system mount table. This table contains
information about all currently mounted (local or remote) file systems.
The format and location of this table (e.g. F</etc/mtab>) vary from
system to system. This function is provided as a compatible way to
parse it. (On some systems, like I<OSF/1>, this table isn't
accessible as a file at all, i.e. only via B<Quota::getmntent>).

=item I<Quota::endmntent()>

Close the mount table. Should be called after the last use of
B<Quota::getmntent> to free possibly allocated file handles and memory.
Always returns undef.

=item I<Quota::strerr()>

Translates C<$!> to a quota-specific error text. You should always
use this function to output error messages, since the normal messages
don't always make sense for quota errors
(e.g. I<ESRCH>: B<No such process>, here: B<No quota for this user>)

Note that this function only returns a defined result if you called a
Quota command directly before which returned an error indication.

=back

=head1 RETURN VALUES

Functions that are supposed return lists or scalars, return I<undef> upon
errors. As usual C<$!> contains the error code (see B<Quota::strerr>).

B<Quota::endmntent> always returns I<undef>.
All other functions return 0 upon success, non-zero integer otherwise.

=head1 EXAMPLES

An example for each function can be found in the test script
I<test.pl>. See also the contrib directory, which contains
some longer scripts, kindly donated by users of the module.

=head1 BUGS

With remote quotas we have to rely on the remote system to
state correctly which block size the quota values are
referring to. Old versions of the Linux rpc.rquotad
reported a block size of 4 kilobytes, which was wildly
incorrect. For more info on this and other Linux bugs please
see INSTALL.

=head1 AUTHORS

This module was created 1995 by T. Zoerner
(email: tomzo AT users.sourceforge.net)
and since then continually improved and ported to
many operating- and file-systems. Numerous people
have contributed to this process; for a complete
list of names please see the CHANGES document.

The quota module was in the public domain 1995-2001. Since 2001 it is
licensed under both the Perl Artistic License and version 1 or later of the
GNU General Public License as published by the Free Software Foundation.
For a copy of these licenses see <http://www.opensource.org/licenses/>.
The respective authors of the source code are it's owner in regard to
copyright.

A repository for sources of this module is at
<https://github.com/tomzox/Perl-Quota>. In April 2020 the module has
been ported to Python: <https://github.com/tomzox/Python-Quota>

=head1 SEE ALSO

perl(1), edquota(1m),
quotactl(2) or quotactl(7I),
mount(1m), mtab(4) or mnttab(4), quotaon(1m),
setmntent(3), getmntent(3) or getmntinfo(3), endmntent(3),
rpc(3), rquotad(1m).

=cut

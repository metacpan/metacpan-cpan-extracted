##- Nanar <nanardon@zarb.org>
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$

package RPM4;

use strict;
use warnings;

use DynaLoader;
use Exporter;

use RPM4::Header;
use RPM4::Transaction;
use RPM4::Header::Dependencies;
use RPM4::Header::Files;
use RPM4::Spec;

our $VERSION = '0.38';
our @ISA = qw(DynaLoader Exporter);
our @EXPORT = qw(moduleinfo
                 readconfig querytag tagName tagValue expand rpmvercmp
                 stream2header rpm2header
                 installsrpm
                 setverbosity setlogcallback format_rpmpb
                 rpmresign dumpmacros dumprc
                 newdb parserpms);
our %EXPORT_TAGS = (
    rpmlib => [qw(getosname getarchname dumprc dumpmacros rpmvercmp setverbosity setlogcallback
                  rpmlog)],
    macros => [qw(add_macros del_macros loadmacrosfile resetmacros)],
    build => [qw(headernew)],
    rpmdb => [qw(rpmdbverify rpmdbrebuild)],
);

bootstrap RPM4;

# I18N:
sub N {
    my ($msg, @args) = @_;
    sprintf($msg, @args);
}

sub compare_evr {
    my ($ae, $av, $ar) = $_[0] =~ /^(?:([^:]*):)?([^-]*)(?:-(.*))?$/;
    my ($be, $bv, $br) = $_[1] =~ /^(?:([^:]*):)?([^-]*)(?:-(.*))?$/;

    my $rc = 0;
    if (defined($ae) && ! defined($be)) {
        return 1;
    } elsif (!defined($ae) && defined($be)) {
        return -1;
    } else {
        $rc = RPM4::rpmvercmp($ae, $be) if defined($ae) && defined($be);
        if ($rc == 0) {
            $rc = RPM4::rpmvercmp($av, $bv);
            if ($rc == 0) {
                if (defined($ar) && !defined($br)) {
                    return 1;
                } elsif (!defined($ar) && defined($br)) {
                    return -1;
                } elsif (!defined($ar) &&  !defined($br)) {
                    return 0;
                } else {
                    return RPM4::rpmvercmp($ar, $br);
                }
            } else {
                return $rc;
            }
        } else {
            return $rc;
        }
    }
}

# parse* function
# callback => function
#   (
#       header => the header (undef on error)
#       file => actual source
#   )
# files => []
# flags => ??

sub parserpms {
    my (%options) = @_;
    my $db = newdb();
    $db->vsflags($options{checkrpms} ? [ "NOSIGNATURES" ] : [ qw(NOSIGNATURES NOPAYLOAD NODIGESTS) ]);
    foreach my $rpm (@{$options{rpms} || []}) {
        my $header = $db->rpm2header($options{path} ? "$options{path}/$rpm" : $rpm);
        defined($options{callback}) and
            $options{callback}->(
                header => $header,
                dir => $options{path} ? "$options{path}/" : "",
                rpm => $rpm,
            );
    }
}

sub format_rpmpb {
    my (@msgs) = @_;
    my @ret;
    foreach my $p (@msgs) {
        $p->{pb} eq "BADARCH" and do {
            push @ret, N("package %s is intended for a different architecture", $p->{pkg});
            next;
        };
        $p->{pb} eq "BADOS" and do {
            push @ret, N("package %s is intended for a different operating system", $p->{pkg});
            next;
        };
        $p->{pb} eq "PKG_INSTALLED" and do {
            push @ret, N("package %s is allready installed", $p->{pkg});
            next;
        };
        $p->{pb} eq "BADRELOCATE" and do {
            push @ret, N("path %s in package %s is not relocatable", $p->{path}, $p->{pkg});
            next;
        };
        $p->{pb} eq "NEW_FILE_CONFLICT" and do {
            push @ret, N("file %s conflicts between attempted installs of %s and %s", $p->{file}, $p->{pkg}, $p->{pkg2});
            next;
        };
        $p->{pb} eq "FILE_CONFLICT" and do {
            push @ret, N("file %s from install of %s conflicts with file from package %s", $p->{file}, $p->{pkg}, $p->{pkg2});
            next;
        };
        $p->{pb} eq "OLDPACKAGE" and do {
            push @ret, N("package %s (which is newer than %s) is already installed", $p->{pkg2}, $p->{pkg});
            next;
        };
        $p->{pb} eq "DISKSPACE" and do {
            push @ret, N("installing package %s needs %sB on the %s filesystem", $p->{pkg},
                ($p->{size} > 1024 * 1024
                    ? ($p->{size} + 1024 * 1024 - 1) / (1024 * 1024)
                    : ($p->{size} + 1023) / 1024) . 
                ($p->{size} > 1024 * 1024 ? 'M' : 'K'),
                $p->{filesystem});
            next;
        };
        $p->{pb} eq "DISKNODES" and do {
            push @ret, N("installing package %s needs %ld inodes on the %s filesystem", $p->{pkg}, $p->{nodes}, $p->{filesystem});
            next;
        };
        $p->{pb} eq "BADPRETRANS" and do {
            push @ret, N("package %s pre-transaction syscall(s): %s failed: %s", $p->{pkg}, $p->{syscall}, $p->{error});
            next;
        };
        $p->{pb} eq "REQUIRES" and do {
            push @ret, N("%s is needed by %s%s", $p->{pkg2},
                defined($p->{installed}) ? N("(installed) ") : "",
                $p->{pkg});
            next;
        };
        $p->{pb} eq "CONFLICT" and do {
            push @ret, N("%s conflicts with %s%s", $p->{pkg2},
                defined($p->{val2}) ? N("(installed) ") : "",
                $p->{pkg});
            next;
        };
    }
    @ret;
}

##########################
# Alias for compatiblity #
##########################

sub specnew { newspec(@_) }

sub add_macro { addmacro(@_) }

sub del_macro { delmacro(@_) }

1;

__END__

=head1 NAME

RPM4 - perl module to access and manipulate RPM files

=head1 SYNOPSIS

=head1 DESCRIPTION

This module allow to use API functions from rpmlib, directly or trough
perl objects.

=head1 FUNCTIONS

=head2 readconfig($rpmrc, $target)

Force rpmlib to re-read configuration files. If defined, $rpmrc is read.
If $target is defined, rpmlib will read config for this target. $target has
the form "CPU-VENDOR-OS".

    readconfig(); # Reread default configuration
    readconfig(undef, "i386-mandrake-linux"); # Read configuration for i386

=head2 setverbosity($level)

Set the rpmlib verbosity level. $level can be an integer (0 to 7) or a
verbosity level name.

  - EMERG    (0)
  - ALERT    (1)
  - CRIT     (2)
  - ERR      (3)
  - WARNING  (4)
  - NOTICE   (5)
  - INFO     (6)
  - DEBUG    (7)

=head2 setlogcallback(sub {})

Set a perl callback code for rpm logging/output system. When the callback is
set, rpm lets your code print error/information messages. The parameter passed
to the callback is a hash with log value:
    C<locode> => the rpm log code (integer),
    C<priority> => priority of the message (0 to 7),
    C<msg> => the formated string message.

To unset the callback function, passed an undef value as code reference.
 
Ex:
  setlogcallback( sub {
    my %log = @_;
    print "$log{priority}: $log{msg}\n";
  });

=head2 setlogfile(filename)

Redirect all rpm message into this file. Data will be append to the end of the
file, the file is created if it don't already exists. The old loging file is close.

To unset (and close) a pending loging file, passed an undef value.

=head2 lastlogmsg

Return an array about latest rpm log message information:
  - rpm log code,
  - rpm priority (0 to 7),
  - string message.

=head2 rpmlog($codelevel, $msg)

Send a message trougth the rpmlib logging system.
  - $codelevel is either an integer value between 0 and 7, or a level code string,
see setverbosity(),
  - $msg is the message to send.

=head2 format_rpmpb(@pb)

Some functions return an array of rpm transaction problem
(RPM4::Db->transpb()), this function return an array of human readable
string for each problem.
 
=head2 querytag

Returns a hash containing the tags known by rpmlib. The hash has the form
C< TAGNAME => tagvalue >. Note that some tags are virtual and do not have
any tag value, and that some tags are alias to already existing tags, so
they have the same value.

=head2 tagtypevalue($tagtypename)

Return the type value of a tag type. $tagtypename can be CHAR, INT8, INT16
INT32, STRING, ARRAY_STRING or I18NSTRING. This return value is usefull with
RPM4::Header::addtag() function.

=head2 tagName($tagvalue)

Returns the tag name for a given internal value.

    tagName(1000); return "NAME".

See: L<tagValue>.

=head2 tagValue($tagname)

Returns the internal tag value for C<$tagname>.

    tagValue("NAME"); return 1000.

See: L<tagName>.

=head2 expand($string)

Evaluate macros contained in C<$string>, like C<rpm --eval>.

    expand("%_var") return "/var".

=head2 addmacro("_macro value")

Define a macro into rpmlib. The macro is defined for the whole script. Ex:
C<addmacro("_macro value")>. Note that the macro name does have the prefix
"%", to prevent rpm from evaluating it.

=head2 del_macro("_macro")

Delete a macro from rpmlib. Exactly the reverse of addmacro().

=head2 loadmacrosfile($filename)

Read a macro configuration file and load macros defined within.
Unfortunately, the function returns nothing, even when file loading failed.

To reset macros loaded from file you have to re-read the rpm config file
with L<readconfig>.

=head2 resetmacros

Reset all macros defined with add_macro() functions.

This function does not reset macros loaded with loadmacrosfile().

=head2 getosname

Returns the operating system name of current rpm configuration.
Rpmlib auto-detects the system name, but you can force rpm to use
another system name with macros or using readconfig().

=head2 getarchname

Returns the arch name of current rpm configuration.
Rpmlib auto-detects the architecture, but you can force rpm to use
another architecture with macros or by using readconfig().

=head2 buildhost

Returns the BuildHost name of the current system, ie the value rpm will use
to set BuilHost tag in built rpm.

=head2 dumprc(*FILE)

Dump rpm configuration into file handle.
Ex:
    dumprc(*STDOUT);

=head2 dumpmacros(*FILE)

Dump rpm macros into file handle.
Ex:
    dumpmacros(*STDOUT);

=head2 rpmresign($passphrase, $rpmfile)

Resign a rpm using user settings. C<$passphrase> is the key's gpg/pgp
pass phrase.

Return 0 on success.
    
=head2 rpmvercmp(version1, version2)

Compare two version and return 1 if left argument is highter, -1 if
rigth argument is highter, 0 if equal.
Ex:
    rpmvercmp("1.1mdk", "2.1mdk"); # return -1.

=head2 compare_evr(version1, version2)

COmpare two rpm version in forms [epoch:]version[-release] and return
1 if left argument is highter, -1 if rigth argument is highter, 0 if
equal.
Ex:
    compare_evr("1:1-1mdk", "2-2mdk"); # return 1
    
=head2 installsrpm($filename)

Install a source rpm and return spec file path and its cookies.
Returns undef if install is impossible.

see L<RPM4::Spec>->new() for more information about cookies.

=head2 rpmdbinit(rootdir, permissions)

Create an empty rpm database located into I<%{_dbpath}> (useally /var/lib/rpm).
If set, rootdir is the root directory of system where rpm db should be
create, if set, theses permissions will be applied to files, default is 0644.

Directory I<%{_dbpath}> should exist.

Returns 0 on success.

Ex:
    rpmdbinit(); # Create rpm database on the system
    rpmdbinit("/chroot"); # Create rpm database for system located into /chroot.

=head2 rpmdbverify($rootdir)

Verify rpm database located into I<%{_dbpath}> (useally /var/lib/rpm).
If set, $rootdir is root directory of system to check.

Returns 0 on success.

=head2 rpmdbrebuild($rootdir)

Rebuild the rpm database located into I<%{_dbpath}> (useally /var/lib/rpm).
If set, $rootdir is the root directory of system.

Returns 0 on success.

=head2 rpmlibdep()

Create a RPM4::Header::Dependencies object about rpmlib
internals provides

=head1 SEE ALSO

L<rpm(8)>,

This aims at replacing part of the functionality provided by URPM.

=cut

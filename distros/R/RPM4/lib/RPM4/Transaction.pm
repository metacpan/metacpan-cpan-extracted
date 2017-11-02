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

use strict;
use warnings;
use RPM4::Transaction::Problems;

package RPM4::Transaction;

sub newspec {
    my ($self, $filename, %options) = @_;
    $options{transaction} = $self;
    RPM4::Spec->new(
        $filename,
        %options
    );  
}

sub transpbs {
    my ($self) = @_;
    return RPM4::Transaction::Problems->new($self);
}

1;

__END__

=head1 NAME

RPM4::Transaction

=head1 DESCRIPTION

This object allow to access to the rpm transaction packages and installing rpms on the
system.

=head1 METHODS

=head2 RPM4::Transaction->traverse_headers(sub)

Go through the rpm database and for each header run the callback passed as
argument.

Argument passed to the callback function is the current header as a Hdlist::Header object.

Ex:
    $db->traverse_headers( sub {
        my ($h) = @_;
        print $h->queryformat("%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}");
    });


=head2 RPM4::Transaction->injectheader($header)

Add the header into rpmdb. This is not installing a package, the function
only fill information into the rpmdb.

Return 0 on success.

=head2 RPM4::Transaction->deleteheader($index)

Remove header from rpmdb locate at $index. This is not uninstalling a package,
this function only delete information from rpmdb.

Return 0 on success
    
=head2 RPM4::Transaction->transadd(header, filename, upgrade, relocation, force)

Add rpm headers for next transaction. This means this rpm are going to be
installed on the system.

- header is an Hdlist::Header object,

- filename, if given, is the rpm file you want to install, and should
of course match the header,

- upgrade is a boolean flag to indicate whether the rpm is going to be upgraded
(1 by default).

Returns 0 on success.

See: $RPM4::Transaction->transcheck(), $RPM4::Transaction->transrun().

=head2 RPM4::Transaction->transremove(rpm_name)

Add rpm to remove for next transaction. This mean the rpm will be uninstalled
from the system.

Argument is the exact rpm name (%{NAME}) or a string as NAME(EPOCH:VERSION-RELEASE).

Returns the number of selected rpms for this transaction.

=head2 RPM4::Transaction->transcheck()

Check current transaction is possible.

Returns 0 on success, 1 on error during check.

=head2 RPM4::Transaction->transorder()

Call to rpmlib to order the transaction, aka sort rpm installation / 
desintallation.

Returns 0 on success.

=head2 RPM4::Transaction->transpb

Return an array of problem found during L<RPM4::Transaction->transcheck> or
L<RPM4::Transaction->transrun>

=head2 RPM4::Transaction->transrun($callback, $flags...)

Really run transaction and install/uninstall packages.

$callback can be:

- undef value, let rpm show progression with some default value.

- array ref: each value represent a rpm command line options:

    PERCENT: show percentage of progress (--percent)
    HASH: print '#' during progression (--hash)
    LABEL: show rpm name (--verbose)

- code ref: rpm is fully silent, the perl sub is called instead. Arguments
passed to the subroutine are in a hash:

    filename => opened filename
    header => current header in transaction
    what => current transaction process
    amount => amount of transaction
    total => number of transaction to do

flags: list of flags to set for transaction (see rpm man page):

I<From rpm Transaction flag>:

  - NOSCRIPTS: --noscripts
  - JUSTDB: --justdb
  - NOTRIGGERS: --notriggers
  - NODOCS: --excludedocs
  - ALLFILES: --allfiles
  - DIRSTASH: --dirstash
  - REPACKAGE: --repackage
  - NOTRIGGERPREIN: --notriggerprein
  - NOPRE: --nopre
  - NOPOST: --nopost
  - NOTRIGGERIN: --notriggerin
  - NOTRIGGERUN: --notriggerun
  - NOPREUN: --nopreun
  - NOPOSTUN: --nopostun
  - NOTRIGGERPOSTUN: --notriggerpostun
  - NOSUGGEST: --nosuggest
  - NOMD5: --nomd5
  - ADDINDEPS: --aid
  - noscripts: Do not running any scripts, neither triggers

I<From rpm prob filter>

  - IGNOREOS: --ignoreos
  - IGNOREARCH: --ignorearch
  - REPLACEPKG: --replacepkgs
  - REPLACENEWFILES: --replacefiles
  - REPLACEOLDFILES: --replacefiles
  - OLDPACKAGES: --oldpackage
  - DISKSPACE: --ignoresize
  - DISKNODE: --ignoresize

Returns 0 on success.

=head2 $db->transpbs

Return a RPM4::Transaction::Problems object containing problem found during
rpms installation/desinstallation.

See L<RPM4::Transaction::Problems>

=head1 SEE ALSO

L<Hdlist>

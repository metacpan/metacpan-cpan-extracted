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

package RPM4::Header::Dependencies;

use strict;
use warnings;

sub new {
    my ($class, $deptag, $initdep, @depdesc) = @_;
    my $dep = RPM4::Header::Dependencies->newsingle($deptag, @$initdep) or return;
    foreach (@depdesc) {
        $dep->add(@$_);
    }
    return $dep;
}

1;

__END__

=head1 NAME

Hdlist::Header::Dependencies - A set of dependencies

=head1 METHODS

=head2 Hdlist::Header::Dependencies->new($tagtype, $dep1, [$dep2, ...])

Create a new arbitrary dependencies set.
$tagtype is the rpm tag {PROVIDE/REQUIRE/CONFLICT/OBSOLETE/TRIGGER}NAME.

Next arguments are array ref for each dependancy to add in the dependencies set,
in form a name and optionnaly as sense flags and a version.

For example:

    $d = Hdlist::Header::Dependencies->new(
        "REQUIRENAME"
        [ "rpm" ],
        [ "rpm", 2, "4.0" ],
        [ "rpm", [ qw/LESS/ ], "4.0" ]
    );

=head2 $deps->count

Return the number of dependencies contained by this set.

=head2 $deps->move($index)

Move internal index to $index (0 by default).

=head2 $deps->init

Reset internal index and set it to -1, see L<next>

=head2 $deps->hasnext

Advance to next dependency in the set.
Return FALSE if no further dependency available, TRUE otherwise.

=head2 $deps->next

Advance to next dependency in the set.
Return -1 if no further dependency available, next index otherwise.

=head2 $deps->color

Return the 'color' of the current dependency in the depencies set.

=head2 $deps->overlap($depb)

Compare two dependency from two dependencies set and return TRUE if match.

=head2 $deps->info

Return information about current dependency from dependencies set.

=head2 $deps->tag

Return the type of the dependencies set as a rpmtag (PROVIDENAME, REQUIRENAME,
PROVIDENAME, OBSOLETENAME of TRIGGERNAME).

=head2 $deps->name

Return the name of dependency from dependencies set.

=head2 $deps->flags

Return the sense flag of dependency from dependencies set.

=head2 $deps->evr

Return the version of dependency from dependencies set.

=head2 $deps->nopromote($nopromote)

Set or return the nopromote flags of the dependencies set.

=head1 SEE ALSO

L<Hdlist>
L<Hdlist::Header>


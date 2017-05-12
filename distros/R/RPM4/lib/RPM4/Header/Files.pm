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

package RPM4::Header::Files;

use strict;
use warnings;

sub dircount {
    $_[0]->countdir();
}

1;

__END__

=head1 NAME

Hdlist::Header::Files - A set of files and directories

=head1 METHODS

=head2 count()

Return the number of files contained by this set.

=head2 countdir()

Return the number of directories contained by this set.

=head2 init()

Reset internal files index and set it to -1.

=head2 initdir()

Reset internal directories index and set it to -1.

=head2 next()

Set current file to the next one in the set.

=head2 nextdir()

Set current directory to the next one in the set.

=head2 move($index)

Move internal file index to $index (0 by default).

=head1 SEE ALSO

L<RPM4::Header>

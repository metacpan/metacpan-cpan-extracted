
#
# Copyright (C) 2003  Sam Horrocks
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#

package PersistentMake::perperl;

require '../src/PersistentMake.pl';
@ISA = 'PersistentMake';

sub my_name {'perperl'}
sub my_name_full {shift->my_name}
sub src_files_extra {qw(cb circ)}

sub remove_libs { my $class = shift;
    '../util/remove_libs';
}

PersistentMake::perperl->init->write_makefile;

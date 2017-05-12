
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

use strict;

package PersistentMake::perperl_dump;

require '../src/PersistentMake.pl';
use vars qw(@ISA);
@ISA = 'PersistentMake';

sub my_name {'perperl.ph'}
sub my_name_full {shift->my_name}
sub main_file {shift->my_name}
sub main_file_full {shift->my_name}
sub main_h {'perperl_main'}
sub src_files_o { (); }
sub src_files_c { (); }

# Get a list of our structs from our include files
sub structs { my $class = shift;
    my @list;
    foreach my $f ($class->allinc) {
	if (open(F, $f)) {
	    while (<F>) {
		chop;
		@_ = split;
		if ($_[0] eq 'typedef' && $_[2] =~ /^\w/ &&
		    ($_[1] eq 'struct' || $_[1] eq 'union' || $_[1] eq 'char'))
		{
		    push(@list, $_[2]);
		}
	    }
	    close(F);
	}
    }
    return @list;
}

sub makeaperl { my $class = shift;
    my $my_name = $class->my_name;
    my $ldopts = $class->get_ldopts;
    my $ccopts = $class->get_ccopts;
    my $struct_list = join(',', $class->structs);
    my $h = join(' ', map {"../src/$_"} $class->src_files_h);

    "
all :: ${my_name}

${my_name}: " . $class->allinc . " perperl.h
	rm -f ${my_name}; here=\`pwd\`; (c2ph CC=\$(CC) DEFINES=\"\`echo \$(INC) $ccopts | sed \\\"s^-I\\.^-I\$\${here}/.^g\\\"\`\" -s$struct_list perperl.h) >$my_name

    ";

}

PersistentMake::perperl_dump->init->write_makefile;

1;


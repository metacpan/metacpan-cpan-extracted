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

BEGIN {
    require '../src/PersistentMake.pl';
    import PersistentMake qw(@src_generated);
}

use strict;
use ExtUtils::MakeMaker;

my $gen = join(' ', @src_generated);

my $mm = MM->new({NAME=>'src'});

print "Writing Makefile for src\n";

open(M, ">Makefile");

print M $mm->constants(), $mm->tools_other(), <<END;

all: ${gen}

${gen}: optdefs optdefs.pl PersistentPerl.src
	\$(PERL) -w optdefs.pl \$(INSTALLBIN)

clean:
	\$(RM_F) ${gen} Makefile

test:

END
close(M);

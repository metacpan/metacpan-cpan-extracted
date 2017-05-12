
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

package PersistentMake::mod_persistentperl2;

use strict;
use ExtUtils::MakeMaker;
use vars qw(@ISA);


$main::do_not_write_makefile = 1;
require '../mod_persistentperl/Makefile.PL';
$main::do_not_write_makefile = 0;

@ISA = 'PersistentMake::mod_persistentperl';

sub inc {'apache2'}
sub main_file_full {'mod_persistentperl2'}
sub main_h {'mod_persistentperl'}
sub my_name_full {shift->main_file_full}
sub mod_persistentperl_out {'.libs/mod_persistentperl.so'}
sub mod_persistentperl_target {'mod_persistentperl.la'}
sub clean_files_extra {qw(.libs *.lo *.slo t mod_persistentperl.so)}
sub mod_persistentperl_cmds {'../src/mod_persistentperl2_cmds.c'}

# Need symlinks for tests.
symlink("../mod_persistentperl/t", "t") || die "Can't create symlinks for tests";

PersistentMake::mod_persistentperl2->init->write_makefile;

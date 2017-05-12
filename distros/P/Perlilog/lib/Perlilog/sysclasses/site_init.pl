#
# This file is part of the Perlilog project.
#
# Copyright (C) 2003, Eli Billauer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# A copy of the license can be found in a file named "licence.txt", at the
# root directory of this project.
#

# This class contains only one method -- init.
# It includes the initialization associated with this current
# site (application and user independent).

sub init {
  my $user_init_flag = 0;
  my $home = "${Perlilog::home}Perlilog/siteclasses/";

  &Perlilog::inherit('template', "${home}template.pl", 'verilog');
  &Perlilog::inherit('static', "${home}static.pl", 'verilog');
  &Perlilog::inherit('silos', "${home}silos.pl", 'root');
  
  &Perlilog::inherit('wbm', "${home}wbm.pl", 'port');
  &Perlilog::inherit('wbs', "${home}wbs.pl", 'port');
  &Perlilog::inherit('vars', "${home}vars.pl", 'port');
  
  &Perlilog::inherit('vars2vars', "${home}vars2vars.pl", 'interface');
  &Perlilog::interfaceclass('vars2vars');
  &Perlilog::inherit('wbsimple', "${home}wbsimple.pl", 'interface');
  &Perlilog::interfaceclass('wbsimple');
  &Perlilog::inherit('vars2wbm', "${home}vars2wbm.pl", 'interface');
  &Perlilog::interfaceclass('vars2wbm');
  &Perlilog::inherit('wbsingmaster', "${home}wbsingmaster.pl", 'interface');
  &Perlilog::interfaceclass('wbsingmaster');

  if (-e 'init.pl') { # Per-project init?
    &Perlilog::inherit('user_init','init.pl','PL_hardroot');
    $user_init_flag = 1;
  }
  $Perlilog::globalobject = global -> new(name => 'globalobject',
				beginend => 'noreg');
  $Perlilog::globalobject->set('filesdir','./PLverilog');
  $Perlilog::globalobject->set('MAX_INTERFACE_REC', 5); # Maximal recursion in interface search
  my $system = root -> new(name => 'systemobject');
  $Perlilog::globalobject -> const('system', $system);
  $system -> set('methods', qw(complete sanity generate instantiate headers epilogue files));
  $Perlilog::interface_rec = undef; # Just to be on the safe side
  
  user_init->init() if $user_init_flag;
}

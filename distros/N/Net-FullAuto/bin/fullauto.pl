#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2017  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or
#    modify it under the terms of the GNU Affero General Public License
#    as published by the Free Software Foundation, either version 3 of
#    the License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty
#    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################

use strict;
use warnings;

BEGIN {

   my $edit=0;my $earg='';my $cnt=-1;
   my $VERSION=0;my $version=0;my $tutorial=0;
   our $planarg=0;our $cronarg=0;my $admin=0;
   my $users=0;my $cat=0;my $carg='';my $figlet=0;
   foreach my $arg (@ARGV) {
      $cnt++;
      if ($arg=~/^--ed*i*t*$/) {
         $edit=1;
         if ($ARGV[$cnt+1] && $ARGV[$cnt+1]!~/^--/) {
            $earg=$ARGV[$cnt+1];last;
         } else { last }
      } elsif ($arg=~/^-[a-df-zA-Z]*e\s*(.*)/) {
         $earg=$1;
         $edit=1;
         chomp $earg; 
         $earg='' if $earg=~/^\s*$/;
      } elsif ($arg=~/^--cat$/) {
         $cat=1;
         if ($ARGV[$cnt+1]!~/^--/) {
            $carg=$ARGV[$cnt+1];
            last;
         } else { last }
      } elsif ($arg=~/^-[a-df-zA-UW-Z]*V/ ||
               $arg=~/^--VE*R*S*I*O*N*$/) {
         $VERSION=1;
      } elsif ($arg=~/^-[a-df-uw-zA-Z]*v/ ||
               $arg=~/^--ve*r*s*i*o*n*$/) {
         $version=1;
      } elsif ($arg=~/^--about$/) {
         $version=1;
      } elsif ($arg=~/^--plan$/) {
         $planarg=1;
      } elsif ($arg=~/^--cron$/) {
         $cronarg=1;
      } elsif ($arg=~/^--tutorial$/) {
         $tutorial=1;
      } elsif ($arg=~/^--users$/) {
         $users=1;
      } elsif ($arg=~/^--admin$/) {
         $admin=1; 
      } elsif ($arg=~/^--figlet$/) {
         $figlet=1;
      }
   }
   if ($edit) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::edit($earg);
      exit;
   } elsif ($cat) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::cat($carg);
      exit;
   } elsif ($VERSION) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::VERSION();
      exit;
   } elsif ($version) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::version();
      exit;
   } elsif ($tutorial) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::tutorial();
      exit;
   } elsif ($users) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::users();
      exit;
   } elsif ($admin) {
      require Net::FullAuto::FA_Core;
      $Net::FullAuto::FA_Core::admin_menu->();
      exit;
   } elsif ($figlet) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::figlet();
      exit;
   }

   # our $fa_custom_code='fa_code.pm';
   # our $fa_menu_config='fa_menu.pm';

}

use Net::FullAuto;

fa_login;

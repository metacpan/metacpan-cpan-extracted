package fa_host;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2020  Brian M. Kelly
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
require Exporter;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(@Hosts);

our @Hosts = (
#################################################################
##  Do NOT alter code ABOVE this block.
#################################################################
##  -------------------------------------------------------------
##  ADD HOST BLOCKS HERE:
##  -------------------------------------------------------------

       {
          'IP'             => '198.201.10.1',
          'HostName'       => 'computer_one',
          'Label'          => 'REMOTE COMPUTER ONE',
          #'LoginID'        => 'bkelly',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },
       {
          'IP'             => '198.201.10.2',
          'HostName'       => 'computer_two',
          'Label'          => 'REMOTE COMPUTER TWO',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },
       {
          'IP'             => '10.0.2.2',
          'Label'          => 'Laptop',
          'LoginID'        => 'KB06606',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },
       {
          'IP'             => '10.0.2.2',
          'Label'          => 'Solaris',
          'Su'             => 'root',
          'LoginID'        => 'opens',
          'sshport'        => '2223',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },
       {
          'IP'             => '10.0.2.2',
          'Label'          => 'Ubuntu',
          'LoginID'        => 'reedfish_laptop',
          'sshport'        => '2222',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },


#################################################################
##  Do NOT alter code BELOW this block.
#################################################################
);

## Important! The '1' at the Bottom is NEEDED!
1;

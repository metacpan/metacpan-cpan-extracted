#!/usr/bin/perl
#
# simple_dig.pl
#
my $version = sprintf("%0.2f",0.01);    # 10-4-11 Michael Robinton <michael@bizsystems.com>

#!/usr/bin/perl
#
# example simple 'dig.pl' script
#
use Net::DNS::Dig;

my ($name,$type);
   
while ( $_ = shift @ARGV ) {
    if ( $_ eq '-t' ) {
      $type = shift;
    } else {
      $name = $_;
    }
}

print Net::DNS::Dig->new()->for( $name, $type )->sprintf;

# end of script simple dig.pl

=pod

COPYRIGHT 2011 

Michael Robinton <michael@bizsystems.com>

All rights reserved.
  
This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.
  
You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the

        Free Software Foundation, Inc.
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA

or visit their web page on the internet at:

        http://www.gnu.org/copyleft/gpl.html.

=cut

1;

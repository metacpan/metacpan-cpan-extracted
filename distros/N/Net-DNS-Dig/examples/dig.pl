#!/usr/bin/perl
#
# dig.pl
#
my $version = sprintf("%0.2f",2.01);    # 10-4-11 Michael Robinton <michael@bizsystems.com>

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

# example complex 'dig.pl' script
#
use Net::DNS::Dig;


my($name, $type, $port, $server, $tcp, $time, $recurse);

unless (@ARGV) {
print qq|\nusage: $0 [options] name

	-t [type]               a, mx, etc...
	-p [port number]
	+tcp                    use TCP
	+norecursive
	+time=[seconds]         timeout

|;
  exit;
}

while ( $_ = shift @ARGV ) {
    if ( $_ eq '-t' ) {
      $type = shift;
    }
    elsif ( $_ eq '-p' ) {
      $port = shift;
    }
    elsif ( $_ =~ /^\@(.+)/ ) {
      $server = $1;
    }
    elsif ( lc $_ eq '\+tcp' ) {
      $tcp = 'tcp';
    }
    elsif ( $_ =~ /^\+time=(\d+)/ ) {
      $time = $1;
    }
    elsif ( $_ =~ /^\+norecursive/ ) {
      $recurse = 1;
    }
    else {
      $name = $_;
    }
}

my $config = {
        Timeout   => $time,
        PeerAddr  => $server,
        PeerPort  => $port,
        Proto     => $tcp,
        Recursion => $recurse,
};
        
print Net::DNS::Dig->new($config)->for($name,$type)->to_text->sprintf;

# end of script complex dig.pl

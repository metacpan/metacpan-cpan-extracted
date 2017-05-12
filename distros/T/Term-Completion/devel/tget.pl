#!/opt/perl_5.8.8/bin/perl -w

use strict;
#use Term::ReadKey;

#ReadMode 4; # Turn off controls keys

#while(my $key = ReadKey(0)) {
#  print "len=",length($key),"\n";
#  my $val = ord($key);
#  printf "Got 0x%02x %s\n",$val,($val>31 ? qq{"$key"} : '');
#}
#ReadMode 0; # Reset tty mode before exiting
#exit 0;

use Curses qw(raw);

my $win = Curses->new();
raw();
my $str = '';
while($win->getstr($str)==0) {
  print "len=",length($str)," ";
  foreach(split(//,$str)) {
    my $val = ord($_);
    printf "0x%02x%s",$val,($val>31 ? qq{"$_" } : ' ');
  }
  print "\r\n";
}

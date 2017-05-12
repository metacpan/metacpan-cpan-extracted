# STN a package for handling numbers represented as 
# strings of characters

package MusicRoom::STN;
use strict;
use warnings;

use Carp;

my %stn_digit;
my @stn_digit = ("0","1","2","3","4","5","6","7","8","9",
                  "a","b","c","e","f","g","h","j","k","m",
                  "n","p","q","r","s","t","u","v","w","x",
                  "y","z");

for(my $i=0;$i<=$#stn_digit;$i++)
  {
    $stn_digit{$stn_digit[$i]} = $i;
  }

sub to_num
  {
    my($stn) = @_;

    _init_stn() if(!%stn_digit);
    return 0 if($stn eq "");

    my $digit = $stn_digit{substr($stn,-1)};
    my $rest = stn2num(substr($stn,0,-1));
    return $digit + ($#stn_digit+1)*$rest;
  }

sub num_to
  {
    my($num,$width) = @_;
    _init_stn() if(!%stn_digit);

    my $ret = "";

    for(my $c=0;$c<$width;$c++)
      {
        $ret = $stn_digit[$num % ($#stn_digit+1)] . $ret;
        $num = int($num/($#stn_digit+1));
      }

    return $ret;
  }

sub unique
  {
    # Pick a suitable random id for an item that does not 
    # clash with any already being used
    my($hr,$width) = @_;

    _init_stn() if(!%stn_digit);
    my $range = ($#stn_digit+1)**$width;
    my $ret = "";
    my $max_tries = 1024;
    while($ret eq "" && $max_tries > 0)
      {
        my $val = "";
        for(my$i=0;$i<$width;$i++)
          {
            $val .= $stn_digit[rand($#stn_digit+1)];
          }

        $max_tries--;
        $ret = $val;
        $ret = ""
           if(defined $hr && defined $hr->{$ret});
      }

    if($max_tries <= 0)
      {
        carp("Too many failures in stn_rand");
      }
    return $ret;
  }

1;

use strict;
use warnings;

use String::Perl::Warnings qw(is_warning);

while(<>){
  chomp;
  print "'$_' looks like a warning\n" if is_warning($_);
}

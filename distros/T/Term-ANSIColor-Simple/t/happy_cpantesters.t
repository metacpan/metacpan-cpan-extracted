use strict;
use warnings;
use Test::More;

use Term::ANSIColor::Simple;

my $timtoady = <<'TIMTOADY';

#####  ###  #    #  #####   ###     #    ####   #   #  
  #     #   ##  ##    #    #   #   # #   #   #  #   #  
  #     #   # ## #    #    #   #  #   #  #   #   # #   
  #     #   #    #    #    #   #  #####  #   #    #    
  #     #   #    #    #    #   #  #   #  #   #    #    
  #    ###  #    #    #     ###   #   #  ####     #    
TIMTOADY

diag color($timtoady)->rainbow;

ok(1);

done_testing;

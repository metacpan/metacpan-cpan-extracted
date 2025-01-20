# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

#!/usr/bin/perl

use strict;
use warnings;
use Test2::V0;

our $VERSION = 0.01;

BEGIN {
  ok(eval 'use Music::Harmonica::TabsCreator; 1', 'use Music::Harmonica::TabsCreator');  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
}
{
  no warnings 'once';  ## no critic (ProhibitNoWarnings)
  note("Testing Music::Harmonica::TabsCreator $Music::Harmonica::TabsCreator::VERSION, Perl $], $^X");
}

done_testing;

# End of the template. You can add custom content below this line.

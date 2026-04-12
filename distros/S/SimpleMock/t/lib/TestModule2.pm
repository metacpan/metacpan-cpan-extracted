package TestModule2;
use strict;

# only used to test sub counting

# constants shouldn't get listed in the subs list (although they are subs)
use constant TEST_CONSTANT => 42;

sub one { 1 }
sub two { 2 }

1;

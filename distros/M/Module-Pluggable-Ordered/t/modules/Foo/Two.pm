package Foo::Two;

sub _order { 10 }

sub mycallback_order { 0 }
sub mycallback { Test::More::is($::order++, 1, "First plugin") }

1;

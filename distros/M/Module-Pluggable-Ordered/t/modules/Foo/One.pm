package Foo::One;

sub _order { 70 };

sub mycallback_order { 20 }
sub mycallback { Test::More::is($::order++, 2, "Second plugin") }

1;

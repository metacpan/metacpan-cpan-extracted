package t::lib::Child;

use t::lib::Parent;
our @ISA = qw(t::lib::Parent);

sub www { 2 }
sub xxx { 2 }

sub BUILD { 1 }

1;

package ExTest;
use parent 'Panda::Export';
use 5.012;

my %hash = map { ("CONST$_" => $_) } 1..10;
Panda::Export->import(\%hash);

sub folded () { 42 }
sub pizda {state $a = 10; return $a++; }

1;

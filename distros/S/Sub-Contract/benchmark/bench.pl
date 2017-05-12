use strict;
use warnings;
use lib "../lib/", "t/", "lib/",".";
use Benchmark qw(:all);

use Sub::Contract;
use ContractClosure;

sub is_integer {
    my $i = shift;
    return 0 if (!defined $i);
    return 0 if (ref $i ne "");
    return 0 if ($i !~ /^\d+$/);
    return 1;
}

sub foo1 { return $_[0] }

sub foo2 { return $_[0] }

sub foo3 {
    my $a = shift;
    is_integer($a);
    my $b = $a;
    is_integer($b);
    return $b;
}

Sub::Contract::contract('foo1')->in(\&is_integer)->out(\&is_integer)->enable;

ContractClosure::contract('foo2',
			  in => {
			      defined => 1,
			      check => [ \&is_integer ],
			  },
			  out => {
			      defined => 1,
			      check => [ \&is_integer ],
			  },
    );

timethese(1000000, {
    'Sub::Contract'   => sub { foo1(1) },
    'ContractClosure' => sub { foo2(1) },
    'Inline'          => sub { foo3(1) },
}
);

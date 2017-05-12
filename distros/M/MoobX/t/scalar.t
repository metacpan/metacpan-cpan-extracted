use Test::More;

use 5.20.0;

use MoobX;

observable( my $first_name = 'Bob' );

is $first_name => 'Bob', 'initialized correctly';

$first_name = undef;
observable my $last_name;
observable my $title;

my $address = observer {
    join ' ', $title || $first_name, $last_name;
};

is $address, ' ', "begin empty";

( $first_name, $last_name ) = qw/ Yanick Champoux /;

is $address => 'Yanick Champoux';

$title = 'Dread Lord';

is $address => 'Dread Lord Champoux';

$title = 'Mr';

is $address => 'Mr Champoux';

subtest 'autorun' => sub {
    plan tests => 3;
    my $foo :Observable = 'a';    
    my @expected = 'a'..'c';
    autorun {
        is $foo => shift @expected;
    };
    $foo = 'b';
    $foo = 'c';
};

done_testing;

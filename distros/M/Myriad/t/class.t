use strict;
use warnings;

use Test::More;
use Test::Fatal;

is(exception {
    eval <<'EOS' or die $@;
    package Example::Class;
    use Myriad::Class;
    has $something;
    method example { $self }
    1
EOS
}, undef, 'can create a class');
my $obj = new_ok('Example::Class');
is($obj->example, $obj, 'can call a method');

done_testing;



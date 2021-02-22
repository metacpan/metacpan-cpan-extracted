use strict;
use warnings;

use Test::More;

my %var = map { $_ => uc $_ } qw(foo bar baz qux);

my $in = q{
    %(foo) saw %(bar)
    with %(baz)
    in the %(qux).
};

my $out = q{
    FOO saw BAR
    with BAZ
    in the QUX.
};

plan tests => 3;

use_ok 'String::Expando';
my $exp = String::Expando->new;
ok $exp, 'instantiate';

is $exp->expand($in, \%var), $out, "multiline expando";

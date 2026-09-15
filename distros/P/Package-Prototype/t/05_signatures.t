use strict;
use warnings;
use Test::More;
use Package::Prototype;

BEGIN { plan skip_all => 'signatures require Perl 5.36' if $] < 5.036 }

my $ok = eval q{
    use feature 'signatures';
    my $obj = Package::Prototype->bless({
        add => sub ($self, $x, $y = 2) { $x + $y },
        context => sub ($self) { wantarray ? (1, 2) : 3 },
    });
    is $obj->add(4), 6, 'default argument';
    is $obj->add(4, 5), 9, 'explicit arguments';
    eval { $obj->add() };
    like $@, qr/Too few arguments/, 'missing required argument';
    eval { $obj->add(1, 2, 3) };
    like $@, qr/Too many arguments/, 'excess arguments';
    is scalar($obj->context), 3, 'scalar context reaches method';
    is_deeply [$obj->context], [1, 2], 'list context reaches method';
    $obj->prototype(add => sub ($self, $x) { $x * 2 });
    is $obj->add(4), 8, 'replacement retains signature';
    my $error = bless {}, 'SignatureError';
    $obj->prototype(fail => sub ($self) { die $error });
    eval { $obj->fail };
    is $@, $error, 'exception object propagates unchanged';
    1;
};
ok $ok, 'signature checks completed' or diag $@;
done_testing;

use strict;
use warnings;
use Test::More tests => 1;
use Test::Warnings 0.010 qw(:all :no_end_test);

{
    # role consumer
    package Foo::Bar;

    use strict;
    use Moo;

    with 'Regru::API::Role::Loggable';

    1;
}

subtest 'Loggable role' => sub {
    plan tests => 8;

    my $foo = new_ok 'Foo::Bar';

    isa_ok $foo, 'Foo::Bar';
    can_ok $foo, 'debug_warn';

    ok $foo->does('Regru::API::Role::Loggable'),        'Instance does the Loggable role';

    my $wrong   = 'wrong';
    my $ref1    = { -answer => 42 };
    my $ref2    = [ qw(Alice Bob) ];
    my $ref3    = bless {-de => 'ad' => -be => 'ef' }, 'Dead::Beef';

    my $sclr = warning { $foo->debug_warn('Foo:', 'bar', 'baz', 'quux') };
    like $sclr, qr/^Foo: bar baz quux at .*/,                                                   'Warn scalars okay';

    my $refs = warning { $foo->debug_warn($ref1, $ref2) };
    like $refs, qr/^\Q{"-answer": 42} ["Alice","Bob"]\E at .*/,                                 'Warn refs okay';

    my $mxd = warning { $foo->debug_warn('Got:', $ref1, $ref2, qw(something), 'went ' . $wrong, qw(!)) };
    like $mxd,  qr/^Got: \Q{"-answer": 42} ["Alice","Bob"]\E something went wrong ! at .*/,     'Warn mixed okay';

    my $blsd = warning { $foo->debug_warn($ref3) };
    like $blsd, qr/^\Qbless( {"-be": "ef","-de": "ad"}, 'Dead::Beef' )\E at .*/,                'Warn blessed okay';
};

1;

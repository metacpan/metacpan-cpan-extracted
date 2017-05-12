use strict;
use warnings;
use Test::More tests => 2;
use Test::Fatal;

{
    # role consumer
    package Foo::Bar;

    use strict;
    use Moo;

    with 'Regru::API::Role::UserAgent';

    1;
}

subtest 'UserAgent role' => sub {
    plan tests => 6;

    my $foo = new_ok 'Foo::Bar';

    isa_ok $foo, 'Foo::Bar';
    can_ok $foo, 'useragent';

    ok $foo->does('Regru::API::Role::UserAgent'), 'Instance does the UserAgent role';

    my $ua = $foo->useragent;

    isa_ok $ua, 'LWP::UserAgent';
    $foo->useragent->agent('bogus/0.1.2');
    is $ua->agent, 'bogus/0.1.2',               'got correct name of user agent';
};

subtest 'Bogus user agent' => sub {
    plan tests => 3;

    # wtf-useragent
    my $bogus = bless { -answer => 42 }, 'Bogus::UserAgent';

    my $foo;

    my $new_failed = exception { $foo = Foo::Bar->new(useragent => $bogus) };
    like $new_failed, qr/is not a LWP::UserAgent instance/,        'catch exception thrown on create object';

    # use defaults
    $foo = new_ok 'Foo::Bar';

    my $set_failed = exception { $foo->useragent($bogus) };
    like $set_failed, qr/is not a LWP::UserAgent instance/,        'catch exception thrown on change attribute';
};

1;

use strict;
use warnings;
use Test::More tests => 1;
use Test::Fatal;

{
    # role consumer
    package Foo::Bar;

    use strict;
    use Moo;

    with 'Regru::API::Role::Namespace';

    sub available_methods { [qw(foo bar)] }

    1;
}

my $unmet_requirements = qq{
    # invalid consumer
    package Foo::Baz;

    use strict;
    use Moo;

    with 'Regru::API::Role::Namespace';

    1;
};

subtest 'Namespace role' => sub {
    plan tests => 5;

    my $foo = new_ok 'Foo::Bar';

    isa_ok $foo, 'Foo::Bar';
    can_ok $foo, 'available_methods';

    ok $foo->does('Regru::API::Role::Namespace'),       'Instance does the Namespace role';

    my $failed = exception { eval "$unmet_requirements" || die $@ };
    like $failed, qr/^Can't apply .*::Role::Namespace to Foo::Baz/,     'Caught exception during apply role';
};

1;

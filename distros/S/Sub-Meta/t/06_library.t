use Test2::V0;

use Sub::Meta;
use Sub::Meta::Library;

sub hello { }
sub world { }

subtest 'register' => sub {
    my $meta = Sub::Meta->new(sub => \&hello);

    like dies { Sub::Meta::Library->register }, qr/^arguments required coderef and submeta/;
    like dies { Sub::Meta::Library->register(\&hello) }, qr/^arguments required coderef and submeta/;
    like dies { Sub::Meta::Library->register('hello', $meta) }, qr/^required coderef/;
    like dies { Sub::Meta::Library->register({}, $meta) }, qr/^required coderef/;
    like dies { Sub::Meta::Library->register(\&hello, 'meta') }, qr/^required an instance of Sub::Meta/;
    like dies { Sub::Meta::Library->register(\&hello, bless {}, 'Some') }, qr/^required an instance of Sub::Meta/;

    ok lives { Sub::Meta::Library->register(\&hello, $meta) }
};

subtest 'register_list' => sub {
    my $meta_hello = Sub::Meta->new(sub => \&hello);
    my $meta_world = Sub::Meta->new(sub => \&world);

    ok lives { Sub::Meta::Library->register_list([\&hello, $meta_hello], [\&world, $meta_world]) };
    ok lives { Sub::Meta::Library->register_list([ [\&hello, $meta_hello], [\&world, $meta_world] ] ) };
    ok dies { Sub::Meta::Library->register_list({ }) };
    ok dies { Sub::Meta::Library->register_list('hello', $meta_hello) };
};

subtest 'get' => sub {
    like dies { Sub::Meta::Library->get('hello') }, qr/^required coderef/;
    like dies { Sub::Meta::Library->get({}) }, qr/^required coderef/;
    is( Sub::Meta::Library->get(\&hello), Sub::Meta->new(sub => \&hello) );
    is( Sub::Meta::Library->get(\&world), Sub::Meta->new(sub => \&world) );
    is( Sub::Meta::Library->get(sub { }), undef );
};

done_testing;

use Test2::V0;
use feature 'signatures';
no warnings 'experimental::signatures';

use Mojo::ATProto::OAuth qw//;
use Mojo::ATProto::OAuth::SessionStore::Memory qw//;

# A fake store, living under the SessionStore:: namespace so short-name
# resolution finds it, that just records whatever positional args it was
# constructed with - used to verify the arrayref store => [Class, @args]
# form actually forwards @args, without depending on a real store's own
# constructor argument shape.
package
    Mojo::ATProto::OAuth::SessionStore::RecordsArgs;
use Mojo::Base -base, -signatures;
has 'received_args' => sub { [] };
sub new ($class, @args) {
    return bless {received_args => [@args]}, $class;
}
package main;

sub make_oauth (%extra) {
    return Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        %extra,
    );
}

subtest 'store is undef by default' => sub {
    my $oauth = make_oauth();
    is($oauth->store, undef);
};

subtest 'a store instance passed directly is returned unchanged' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    my $oauth = make_oauth(store => $store);
    is($oauth->store, $store, 'same reference, not a copy');
};

subtest q|store => 'Memory' resolves to Mojo::ATProto::OAuth::SessionStore::Memory| => sub {
    my $oauth = make_oauth(store => 'Memory');
    my $store = $oauth->store;
    isa_ok($store, ['Mojo::ATProto::OAuth::SessionStore::Memory']);
};

subtest 'resolution happens once and is cached - repeated ->store calls return the same instance' => sub {
    my $oauth  = make_oauth(store => 'Memory');
    my $first  = $oauth->store;
    my $second = $oauth->store;
    is($second, $first, 'same object both times, not a fresh instance per call');
};

subtest 'an unknown short name dies with a clear message rather than a bare Mojo::Loader error' => sub {
    my $oauth = make_oauth(store => 'NoSuchStore');
    like(dies { $oauth->store }, qr/could not load session store class Mojo::ATProto::OAuth::SessionStore::NoSuchStore/, 'names the class it tried to load');
};

subtest 'setting store after construction works the same way' => sub {
    my $oauth = make_oauth();
    is($oauth->store, undef, 'unset initially');

    $oauth->store('Memory');
    isa_ok($oauth->store, ['Mojo::ATProto::OAuth::SessionStore::Memory']);
};

subtest q|store => ['Memory'] (arrayref, no args) resolves the same as the flat string form| => sub {
    my $oauth = make_oauth(store => ['Memory']);
    isa_ok($oauth->store, ['Mojo::ATProto::OAuth::SessionStore::Memory']);
};

subtest q|store => ['RecordsArgs', @args] forwards @args to the resolved class's new| => sub {
    my $oauth = make_oauth(store => ['RecordsArgs', 'a', 'b', 'c']);
    my $store = $oauth->store;
    isa_ok($store, ['Mojo::ATProto::OAuth::SessionStore::RecordsArgs']);
    is($store->received_args, ['a', 'b', 'c'], 'positional args passed through to new() unchanged');
};

subtest q|store => ['Full::Class::Name', @args] - full names take args too, not just short names| => sub {
    my $oauth = make_oauth(store => ['Mojo::ATProto::OAuth::SessionStore::RecordsArgs', 'x', 'y']);
    is($oauth->store->received_args, ['x', 'y'], 'full class name in arrayref form also forwards args');
};

subtest 'an arrayref store spec is not mutated by resolution, so it is safe to reuse across instances' => sub {
    my $spec = ['RecordsArgs', 'shared-dsn'];

    my $first = make_oauth(store => $spec);
    $first->store;
    is($spec, ['RecordsArgs', 'shared-dsn'], 'spec unchanged after first use');

    my $second = make_oauth(store => $spec);
    my $store  = $second->store;
    isa_ok($store, ['Mojo::ATProto::OAuth::SessionStore::RecordsArgs']);
    is($store->received_args, ['shared-dsn'], 'second use still resolves correctly, args intact');
};

subtest 'a store value that is neither a scalar, an arrayref, nor an instance dies with a clear message' => sub {
    my $oauth = make_oauth(store => {not => 'valid'});
    like(dies { $oauth->store }, qr/store must be a scalar or arrayref/, 'rejects the wrong kind of ref rather than mistaking it for a store instance');
};

subtest 'setting store to an arrayref after construction works the same way' => sub {
    my $oauth = make_oauth();
    $oauth->store(['RecordsArgs', 'late-bound']);
    is($oauth->store->received_args, ['late-bound'], 'arrayref form works via the setter too, not just the constructor');
};

done_testing;

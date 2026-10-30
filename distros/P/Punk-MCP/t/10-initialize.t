#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPRpc;

sub init {
    my ($state, $version) = @_;
    my ($s, $bytes) = rpc_raw($state,
        req(1, 'initialize', { protocolVersion => $version // '2025-11-25',
                               capabilities => {},
                               clientInfo => { name => 't', version => '1' } }));
    return ($s, $bytes, jdec($bytes)->{result});
}

my ($s, $bytes, $r) = init({});
is($s, 200, 'initialize answers 200');
is_deeply($r->{capabilities}, {}, 'nothing declared, no capabilities');

# ---- capabilities follow the declarations and the transport --------------------------

(undef, undef, $r) = init({ tools => 1 });
is_deeply($r->{capabilities}, { tools => {} }, 'tools');

(undef, undef, $r) = init({ prompts => 1 });
is_deeply($r->{capabilities}, { prompts => {} }, 'prompts');

(undef, undef, $r) = init({ resources => 1 });
is_deeply($r->{capabilities}, { resources => {} },
    'resources without a way to notify: no subscribe');

(undef, undef, $r) = init({ resources => 1, notify => 1 });
ok($r->{capabilities}{resources}{subscribe}, 'resources with one: subscribe');
ok(JSON::PP::is_bool($r->{capabilities}{resources}{subscribe}),
    'and subscribe is a JSON boolean');

(undef, undef, $r) = init({ logging => 1 });
ok(!exists $r->{capabilities}{logging}, 'logging without a way to notify: absent');
(undef, undef, $r) = init({ logging => 1, notify => 1 });
is_deeply($r->{capabilities}{logging}, {}, 'logging with one: present');

($s, $bytes, $r) = init({ tools => 1, resources => 1, prompts => 1,
                          logging => 1, notify => 1 });
is_deeply([sort keys %{ $r->{capabilities} }],
    [qw(logging prompts resources tools)], 'all four together');
unlike($bytes, qr/listChanged/, 'and no listChanged anywhere (P6)');

# ---- instructions -------------------------------------------------------------------

(undef, undef, $r) = init({});
ok(!exists $r->{instructions}, 'no instructions unless given');
(undef, undef, $r) = init({ instructions => 'Search the catalogue.' });
is($r->{instructions}, 'Search the catalogue.', 'instructions when given');

# ---- serverInfo by version -------------------------------------------------------------

my %full = (name => 'acme', title => 'Acme', version => '1.10',
            description => 'The Acme catalogue.', website => 'https://acme.test',
            icons => [{ src => 'https://acme.test/i.png', mimeType => 'image/png' }]);

(undef, undef, $r) = init(\%full, '2025-03-26');
is_deeply($r->{serverInfo}, { name => 'acme', version => '1.10' },
    '2025-03-26: name and version only');

(undef, undef, $r) = init(\%full, '2025-06-18');
is_deeply($r->{serverInfo}, { name => 'acme', title => 'Acme', version => '1.10' },
    '2025-06-18: adds title');

(undef, undef, $r) = init(\%full, '2025-11-25');
is_deeply($r->{serverInfo}, {
    name => 'acme', title => 'Acme', version => '1.10',
    description => 'The Acme catalogue.', websiteUrl => 'https://acme.test',
    icons => [{ src => 'https://acme.test/i.png', mimeType => 'image/png' }],
}, '2025-11-25: adds description, websiteUrl and icons');

# A version given as a Perl number still goes out as a JSON string.
(undef, $bytes) = init({ name => 'acme', version => 2 });
like($bytes, qr/"version":"2"/, 'a numeric version is sent as a string');

(undef, undef, $r) = init({});
is($r->{serverInfo}{name}, 'punk', 'a default name until 04 supplies the class');

done_testing;

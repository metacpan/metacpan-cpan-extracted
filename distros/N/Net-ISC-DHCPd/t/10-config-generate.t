#!perl

use warnings;
use strict;
use lib q(lib);
use Benchmark;
use NetAddr::IP;
use Test::More;

my $count = 1;
my $text = do { local $/; <DATA> };

plan tests => 1 + 4 * $count + 3;

use_ok("Net::ISC::DHCPd::Config");

my $time = timeit($count, sub {
    my $config = Net::ISC::DHCPd::Config->new;

    is(ref $config, "Net::ISC::DHCPd::Config", "config object constructed");

    $config->add_keyvalue(
        name => 'ddns-update-style',
        value => 'none',
    );

    $config->add_optionspace('name' => 'foo');
    $config->add_optioncode('prefix' => 'foo', 'name' => 'bar', 'code' => 1, 'value' => 'ip-address');
    $config->add_optioncode('name' => 'foo-enc', 'code' => 122, 'value' => 'encapsulate foo');

    $config->add_function(
        name => "commit",
        keyvalues => [{ name => 'set', 'value' => 'leasetime = encode-int(lease-time, 32)' }],
    );
    $config->add_subnet(
        address => NetAddr::IP->new('10.0.0.96/27'),
        filenames => [{ file => 'pxefoo.0' }],
        options => [
            {
                name => 'routers',
                value => '10.0.0.97',
            },
        ],
        pools => [
            {
                ranges => [
                    {
                        upper => NetAddr::IP->new("10.0.0.116"),
                        lower => NetAddr::IP->new("10.0.0.126"),
                    },
                ],
            },
        ],
    );
    $config->add_host(
        name => 'foo',
        filenames => [{ file => 'pxelinux.0' }],
        keyvalues => [
            {
                name => 'fixed-address',
                value => '10.19.83.102',
            },
        ],
    );

    #print $config->generate;
    is($config->generate, $text, "config generated");

    eval { $config->hosts->[0]->add_filename({ file => 'bar!' }) };
    like($@, qr{Host cannot have more than one}, "Host cannot have more than one filename");

    eval { $config->subnets->[0]->add_filename({ file => 'bar!' }) };
    like($@, qr{Subnet cannot have more than one}, "Subnet cannot have more than one filename");
});

diag($count .": " .timestr($time));

{
    my $config = Net::ISC::DHCPd::Config->new;
    my $include_file = 't/data/foo-included.conf';
    my $include_text;

    {
        open my $INCLUDE, '<', $include_file or BAIL_OUT $!;
        local $/;
        $include_text = <$INCLUDE>;
        $include_text =~ s/^\n+//m;
        $include_text =~ s/\n+$//m;
        $include_text .= "\n";
    }

    $config->add_include(file => $include_file);

    is($config->generate, qq(include "$include_file";\n), 'include file generated');

    $config->includes->[0]->generate_with_include(1);
    like($config->generate, qr{forgot to parse}, 'include file content cannot be generated before parsed');

    $config->includes->[0]->parse;
    is($config->generate, "$include_text", 'include file content generated');
}

__DATA__
ddns-update-style none;
option space foo;
option foo.bar code 1 = ip-address;
option foo-enc code 122 = encapsulate foo;
on commit {
    set leasetime = encode-int(lease-time, 32);
}
subnet 10.0.0.96 netmask 255.255.255.224 {
    filename pxefoo.0;
    option routers 10.0.0.97;
    pool {
        range 10.0.0.126 10.0.0.116;
    }
}
host foo {
    filename pxelinux.0;
    fixed-address 10.19.83.102;
}

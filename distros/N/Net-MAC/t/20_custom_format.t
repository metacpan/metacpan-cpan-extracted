use Test::More tests => 6;
#use Test::More qw(no_plan);
BEGIN { use_ok('Net::MAC') };

# test class method
eval{ Net::MAC->set_format_for( 'Custom' ) };
like($@, qr/missing HASH ref custom format/, 'missing HASH ref custom format');

my $rc = eval{
    Net::MAC->set_format_for(
        Custom => {
            base => 16,
            bit_group => 16,
            delimiter => '~',
        },
    )
};
ok($rc, 'Class method set_format_for set the new format');

my $macaddr = '01ab~01ab~01ab';

#eval{ Net::MAC->new(mac => $macaddr) };
#like($@, qr/invalid MAC format/, 'unspecified custom format dies');

my $mac = eval{ Net::MAC->new(mac => $macaddr, format => 'Custom') };
isa_ok($mac, 'Net::MAC', 'known custom format succeeds');

is($mac->as_Cisco, '01ab.01ab.01ab', 'as_foo working from custom format');

is(Net::MAC->new(mac => '01ab.01ab.01ab')->as_Custom,
    '01ab~01ab~01ab', 'as_Custom working from Cisco format');


# Basic tests
my %t;
ok(%t = $obj->get(qw(PowerLevel Environment)));
ok($t{PowerLevel} eq 0xff);
ok($t{Environment} eq 0x00);

ok($obj->set(PowerLevel => 0xff,
	     Environment => 0x04)==0);

ok($t = $obj->getnodeaddress(serialnum => "00000000000003AF"));
ok($t->{node} == 4);

ok($t = $obj->get('ReaderVersion'));
is($t,'2.1.2');

# Generate some tags
my @tags = ((map { RFID::EPC::Tag->new(id => $_) } 
	     qw(c80507a8009609de)),
	    (map { RFID::Matrics::Tag->new(id => $_) }
	     qw(000000000176c402
		000000000176c002
		000000000176bc02
		000000000176bc02)));

isa_ok($_,'RFID::Tag','Tag isa')
    foreach @tags;

# Tests with reading mock tags
my @read;
ok(@read = $obj->readtags);
ok(@read == 5);

ok(tagcmp($tags[$_],$read[$_])==0,'Tag compare')
    foreach (0..$#tags);

1;

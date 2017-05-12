use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 49, 'Parsed 49 lines?');
is($config->classes->[0]->keyvalues->[1]->name, 'next-server', 'is class keyvalue 0 name == next-server');
is($config->classes->[5]->keyvalues->[0]->name, 'match', 'is class 5 keyvalue 0 name == match');
# wish we could drop all non-quoted whitespace.  In this case it would be safe to s/\s+//g but not always
is($config->classes->[5]->keyvalues->[0]->value, 'if (         not (             concat(                 "1:",binary-to-ascii(16,8,":",option agent.remote-id)             ) = binary-to-ascii(16,8,":",hardware)         )         and (             binary-to-ascii (16,8,":",option agent.remote-id) = "11:22:33:44:55:66"         )     )', 'is class 5 keyvalue 0 value == correct?');
is($config->subclasses->[2]->value, 'testbox 3', 'test value with spaces');
is($config->subclasses->[4]->value, 'testbox5', 'testing unquoted value');
is($config->subclasses->[5]->value, 'testvalue', 'testing unquoted name and value');
done_testing();


__DATA__
class "pxeclients" {
    match if substring(option vendor-class-identifier,0,9) ="PXEClient";
    next-server 10.201.214.90;
}

# these newlines are causing match failures
class "virtual-machines" {
    match if ((substring (hardware, 1, 3) = 00:0c:29)
        or (substring (hardware, 1, 3) = 00:50:56)
        or (substring (option dhcp-client-identifier, 0, 3) = "HPC"));
}

class "Cisco IP Phone 7905"
{
    match if (option vendor-class-identifier="Cisco Systems, Inc. IP Phone 7905");
}

class "consoles"
{
    match pick-first-value (option vendor-class-identifier, host-name);
}

class "DlinkATA"
{
    option tftp-server-name "test";
    match if (substring(binary-to-ascii (16,8,":", hardware), 2, 7)= "0:19:5b") or (substring(binary-to-ascii (16,8,":", hardware), 2, 7)= "0:17:9a");
}

class "cpe"
{
    match if (
        not (
            concat(
                "1:",binary-to-ascii(16,8,":",option agent.remote-id)
            ) = binary-to-ascii(16,8,":",hardware)
        )
        and (
            binary-to-ascii (16,8,":",option agent.remote-id) = "11:22:33:44:55:66"
        )
    );
}

subclass "consoles"
        "testbox";
subclass consoles "testbox2";
subclass con-soles "testbox 3";
subclass "Subclass with spaces" "testbox 4";
subclass "subclass-without-spaces" testbox5;
subclass test testvalue;

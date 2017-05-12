use lib './lib';
use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;
use strict;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 31, 'Parsed 31 lines?');
is(scalar(@{$config->groups}), 4, 'Checking number of groups found');
is($config->groups->[2]->hosts->[1]->name, 'box3-2', 'Checking random host name');
is($config->groups->[3]->keyvalues->[0]->name, 'next-server', 'Checking if next-server is first keyvalue');
is($config->optionspaces->[1]->name, 'cable-labs', 'Option space parsed correctly');
is($config->optioncodes->[1]->prefix, 'cable-labs', 'prefix parsed correctly?');
is($config->optioncodes->[1]->name, 'tsp-as-backoff-retry', 'name parsed correctly?');
is($config->optioncodes->[1]->code, 4, 'code parsed correctly?');
is($config->optioncodes->[1]->value, '{  unsigned integer 32, unsigned integer 32, unsigned integer 32 }', 'value parsed correctly');
is($config->optioncodes->[2]->value, '{  unsigned integer 32, unsigned integer 32, unsigned integer 32 }', 'value parsed correctly');
is($config->optioncodes->[2]->name, 'tsp-ap-backoff-retry', 'name parsed correctly?');

# I should note that I found that nested hosts break this.  It's an invalid
# config anyway, but it's not caught and shown as a parse error.  I think this
# is because the second host entry is treated as a keyvalue or block.
# it's seeing the opening brace as part of the (.*) capture and it doesn't see
# the close brace since it's on another line.

# here is a broken example:
# group { next-server 192.168.0.2; host box1 { host
# box1-2 {option host-name "box1-2"; hardware ethernet 66:55:44:33:22:11;
# fixed-address 192.168.0.2; } } }

# so the worst thing we can do is silently generate a bad config.  I consider
# this our failure even though it's garbage-in garbage-out.  Moving away from
# KeyValue to a point where we parse almost everything would allow us to fail
# this properly.

# because of KeyValue and Block I think you could type a letter to your
# parents and it would consider it a valid config as long as it ended with a
# semi-colon.  Not ideal, but again, make sure the input config passes dhcpd
# validation.

# as further proof that we validate almost anything, this was broken for a
# long time.
# host box1 { option host-name "box1" }
# when I was rewriting the parser it was failing on this entry.  I checked it
# with dhcpd and it won't allow an option without a semicolon even if it's the
# only thing in the braces.


done_testing();

__DATA__
option space foo;  option foo.bar code 1 = ip-address; option host-name "test host name"; option
domain-name-servers 192.168.1.5;
group { next-server 192.168.0.2; host box1 { option host-name "box1"; } host box1-2 {option host-name "box1-2"; hardware ethernet 66:55:44:33:22:11; fixed-address 192.168.0.2; } }

group "2" { next-server
   192.168.0.3;
   host box2-1 { }
   host box2-2 {option host-name "box 2"; hardware
   ethernet 66:55:44:33:22:11; fixed-address 192.168.0.3;
   }
} group "3" { next-server
   192.168.0.4;
   # a comment would be nice too
   host box3 {option host-name "box 4"; hardware ethernet 66:55:44:33:22:11; fixed-address 192.168.0.4;
   } host box3-2 { }
}

# totally ordinary stuff here
group {
   next-server 192.168.0.5;
   host box4 {
       option host-name "box 4";
       hardware ethernet 66:55:44:33:22:11;
       fixed-address 192.168.0.2;
   }
}

# These don't parse correctly so I need to test for them specificially
option space cable-labs;
option cable-labs.tsp-as-backoff-retry code 4 = { unsigned integer 32, unsigned integer 32, unsigned integer 32 };
option cable-labs.tsp-ap-backoff-retry code 5 = { unsigned integer 32, unsigned integer 32, unsigned integer 32 };

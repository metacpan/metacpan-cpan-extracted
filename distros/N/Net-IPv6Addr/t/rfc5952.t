# This tests the module's compliance with RFC 5952. The tests here are
# directly copy-pasted from the document itself. See
# https://tools.ietf.org/rfc/rfc5952.txt.  No alterations to the
# module were necessary, since it already complied with the
# requirements described.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Net::IPv6Addr ':all';


my @same = qw!

      2001:db8:0:0:1:0:0:1

      2001:0db8:0:0:1:0:0:1

      2001:db8::1:0:0:1

      2001:db8::0:1:0:0:1

      2001:0db8::1:0:0:1

      2001:db8:0:0:1::1

      2001:db8:0000:0:1::1

      2001:DB8:0:0:1::1
!;

my @same2 = qw!

      2001:db8:aaaa:bbbb:cccc:dddd:eeee:0001

      2001:db8:aaaa:bbbb:cccc:dddd:eeee:001

      2001:db8:aaaa:bbbb:cccc:dddd:eeee:01

      2001:db8:aaaa:bbbb:cccc:dddd:eeee:1
!;

my @same3 = qw!

      2001:db8:aaaa:bbbb:cccc:dddd::1

      2001:db8:aaaa:bbbb:cccc:dddd:0:1

!;

my @same4 = qw!

      2001:db8::aaaa:0:0:1

      2001:db8:0:0:aaaa::1

!;

my @same5 = qw!

      2001:db8:aaaa:bbbb:cccc:dddd:eeee:aaaa

      2001:db8:aaaa:bbbb:cccc:dddd:eeee:AAAA

      2001:db8:aaaa:bbbb:cccc:dddd:eeee:AaAa
!;

# Base for comparison.

for my $array (\@same, \@same2, \@same3, \@same4, \@same5) {
    my $comp;
    for my $ip (@$array) {
	my $ni = Net::IPv6Addr->new ($ip);
	my $s = $ni->to_string_preferred ();
	if (! $comp) {
	    $comp = $s;
	}
	else {
	    is ($s, $comp, "Identical outputs for $ip");
	}
    }
}

is (to_string_compressed ('2001:0db8::0001'), '2001:db8::1',
    "Section 4.1");

is (to_string_compressed ('2001:db8:0:0:0:0:2:1'), '2001:db8::2:1',
    "Section 4.2.1");

is (to_string_compressed ('2001:0:0:1:0:0:0:1'), '2001:0:0:1::1',
    "Section 4.2.3");

is (to_string_compressed ('2001:db8:0:0:1:0:0:1'), '2001:db8::1:0:0:1',
    "Section 4.2.3");

done_testing ();

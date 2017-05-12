use strict;
use warnings;
use Test::More tests => 2;
use Net::Drizzle;

my $dr = Net::Drizzle->new();
is $dr->escape(q{"}), q{\\"};
is $dr->hex_string("\x61"), q{61};


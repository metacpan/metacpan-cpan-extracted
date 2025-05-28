#!perl

use strict;
use warnings;

use Test::More tests => 1;

use Net::CIDR::Set;

my $priv = eval { Net::CIDR::Set->new("010.0.0.0/8") };

like $@, qr{Can't decode 010.0.0.0/8}, "parse error with octal";

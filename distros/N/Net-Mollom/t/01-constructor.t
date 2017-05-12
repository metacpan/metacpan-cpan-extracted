#!perl -T
use strict;
use warnings;
use Test::More (tests => 6);
BEGIN { use_ok( 'Net::Mollom' ); }

eval { Net::Mollom->new() };
ok($@);
like($@, qr/\(private_key\) is required/, 'private_key is required');
eval { Net::Mollom->new( private_key => 123 ) };
like($@, qr/\(public_key\) is required/, 'public_key is required');
my $mollom;
eval { $mollom = Net::Mollom->new( private_key => 123, public_key => 456 ) };
ok(!$@);
isa_ok($mollom, 'Net::Mollom');

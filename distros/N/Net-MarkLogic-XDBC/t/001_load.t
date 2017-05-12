# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Net::MarkLogic::XDBC' ); }

my $object = Net::MarkLogic::XDBC->new (host => "foo",
                                        port => "7999",
                                        username => "user",
                                        password => "pass",);
isa_ok ($object, 'Net::MarkLogic::XDBC');



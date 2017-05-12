#!perl -T
use strict;
use warnings;
use Test::More (tests => 11);
use Net::Mollom;
use Exception::Class::TryCatch qw(catch);

# bad public and private keys
my $mollom = Net::Mollom->new(
    private_key => '123',
    public_key => '456',
);
isa_ok($mollom, 'Net::Mollom');

SKIP: {
    my $result;
    eval { $result = $mollom->verify_key };
    ok(my $e = catch);
    ok($e);

    if( $e->isa('Net::Mollom::CommunicationException') ) {
        skip("Can't reach Mollom servers", 6);
    } else {
        like($e->mollom_desc, qr/could not find your public key/);
        is($e->mollom_code, 1000, 'correct error code from Mollom');

        # bad private key
        $mollom = Net::Mollom->new(
            private_key => '123',
            public_key  => '72446602ffba00c907478c8f45b83b03',
        );
        isa_ok($mollom, 'Net::Mollom');
        eval { $result = $mollom->verify_key };
        ok($e = catch);
        like($e->mollom_desc, qr/hash is incorrect/);
        is($e->mollom_code, 1000, 'correct error code from Mollom');

        # good public and private keys
        $mollom = Net::Mollom->new(
            private_key => '42d54a81124966327d40c928fa92de0f',
            public_key  => '72446602ffba00c907478c8f45b83b03',
        );
        isa_ok($mollom, 'Net::Mollom');
        $result = $mollom->verify_key();
        is($result, 1, 'key is verified');
    }
}

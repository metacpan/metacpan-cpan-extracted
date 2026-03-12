use v5.42.0;
use blib;
use Test2::V0;
use Noise;
use Crypt::PK::X25519;
#
subtest 'Generic Handshake XX' => sub {
    my $alice_s = Crypt::PK::X25519->new();
    $alice_s->generate_key();
    my $bob_s = Crypt::PK::X25519->new();
    $bob_s->generate_key();
    my $alice = Noise->new();
    $alice->initialize_handshake( pattern => 'XX', initiator => 1, s => $alice_s );
    my $bob = Noise->new();
    $bob->initialize_handshake( pattern => 'XX', initiator => 0, s => $bob_s );

    # Alice -> Bob (e)
    my $msg1 = $alice->write_message('Msg1 Payload');
    my $p1   = $bob->read_message($msg1);
    is $p1, 'Msg1 Payload', 'Bob decrypted Msg 1';

    # Bob -> Alice (e, ee, s, es)
    my $msg2 = $bob->write_message('Msg2 Payload');
    my $p2   = $alice->read_message($msg2);
    is $p2, 'Msg2 Payload', 'Alice decrypted Msg 2';

    # Alice -> Bob (s, se)
    my $msg3 = $alice->write_message('Msg3 Payload');
    my $p3   = $bob->read_message($msg3);
    is $p3, 'Msg3 Payload', 'Bob decrypted Msg 3';

    # Split
    my ( $alice_c1, $alice_c2 ) = $alice->split();
    my ( $bob_c1,   $bob_c2 )   = $bob->split();
    is unpack( 'H*', $alice_c1->k ), unpack( 'H*', $bob_c1->k ), 'Transport key 1 matches';
    is unpack( 'H*', $alice_c2->k ), unpack( 'H*', $bob_c2->k ), 'Transport key 2 matches';
};
subtest 'Generic Handshake NN' => sub {
    my $alice = Noise->new();
    $alice->initialize_handshake( pattern => 'NN', initiator => 1 );
    my $bob = Noise->new();
    $bob->initialize_handshake( pattern => 'NN', initiator => 0 );

    # Alice -> Bob (e)
    my $msg1 = $alice->write_message('Hey');
    my $p1   = $bob->read_message($msg1);
    is $p1, 'Hey', 'Bob decrypted NN Msg 1';

    # Bob -> Alice (e, ee)
    my $msg2 = $bob->write_message('Hi');
    my $p2   = $alice->read_message($msg2);
    is $p2, 'Hi', 'Alice decrypted NN Msg 2';
    my ( $a1, $a2 ) = $alice->split();
    my ( $b1, $b2 ) = $bob->split();
    is unpack( 'H*', $a1->k ), unpack( 'H*', $b1->k ), 'NN Transport key 1 matches';
};
subtest 'PSK Handshake XXpsk3' => sub {
    my $psk     = 'P' x 32;
    my $alice_s = Crypt::PK::X25519->new();
    $alice_s->generate_key();
    my $bob_s = Crypt::PK::X25519->new();
    $bob_s->generate_key();
    my $alice = Noise->new();
    $alice->initialize_handshake( pattern => 'Noise_XXpsk3_25519_ChaChaPoly_SHA256', initiator => 1, s => $alice_s, psks => [$psk] );
    my $bob = Noise->new();
    $bob->initialize_handshake( pattern => 'Noise_XXpsk3_25519_ChaChaPoly_SHA256', initiator => 0, s => $bob_s, psks => [$psk] );

    # Msg 1: -> e
    my $msg1 = $alice->write_message();
    $bob->read_message($msg1);

    # Msg 2: <- e, ee, s, es
    my $msg2 = $bob->write_message();
    $alice->read_message($msg2);

    # Msg 3: -> s, se, psk
    my $msg3 = $alice->write_message();
    $bob->read_message($msg3);
    my ( $a1, $a2 ) = $alice->split();
    my ( $b1, $b2 ) = $bob->split();
    is unpack( 'H*', $a1->k ), unpack( 'H*', $b1->k ), 'PSK Transport key 1 matches';
};
#
done_testing;

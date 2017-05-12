
use strict;
use Test;


# use a BEGIN block so we print our plan before Net::oRTP is loaded
BEGIN { plan tests => 11 }

# load Net::oRTP
use Net::oRTP;

# Module has loaded sucessfully 
ok(1);


# Create a send object
my $rtp = new Net::oRTP('SENDONLY');
ok( defined $rtp );


# Enable blocking mode
$rtp->set_blocking_mode( 1 );
ok( 1 );


# Set the remote address
ok($rtp->set_remote_addr( '127.0.0.1', 5004 ) == 0);

# Set the Payload Type 
ok($rtp->set_send_payload_type( 8 ) == 0);
ok($rtp->get_send_payload_type( ) == 8);

# Set the SSRC 
$rtp->set_send_ssrc( 450851100 );
ok($rtp->get_send_ssrc( ) == 450851100);

# Set the initial sequence number
$rtp->set_send_seq_number( 1287 );
ok($rtp->get_send_seq_number( ) == 1287);

# Send a packet (full of NULLs)
my $data = "\0" x 128;
ok( $rtp->send_with_ts( $data, 128 ) == 140 );


# Reset the session
$rtp->reset();
ok(1);

# Delete the Net::oRTP object
undef $rtp;
ok( 1 );



exit;


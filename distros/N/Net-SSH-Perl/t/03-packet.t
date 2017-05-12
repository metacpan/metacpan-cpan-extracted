#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    eval 'require String::CRC32';
    $@ and plan skip_all => 'Cannot do packet tests without String::CRC32';

	eval 'require Math::GMP';
	$@ and plan skip_all => 'Cannot test protocol 1 packets without Math::GMP';

	plan tests => 10;
}

use Net::SSH::Perl;
use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Constants qw( :msg PROTOCOL_SSH1 );

my $ssh = Net::SSH::Perl->new("dummy", _test => 1);
$ssh->set_protocol(PROTOCOL_SSH1);

## Okay, so you shouldn't ever be doing this,
## in real usage; override the socket with a
## special tied filehandle.
my $fh = do { local *FH; *FH };
tie *$fh, 'StringThing';
$ssh->{session}{sock} = $fh;

{
    ## Test basic functionality: send a packet with a string...
    my $packet = Net::SSH::Perl::Packet->new( $ssh, type => SSH_CMSG_USER );
    ok( $packet, 'created a packet' );
    $packet->put_str("foo");
    $packet->send;
}

{
    ## ... And read it back.
    my $packet = Net::SSH::Perl::Packet->read($ssh);
    ok( $packet, 'read a packet back' );
    is( $packet->type, SSH_CMSG_USER, 'packet type is SSH_CMSG_USER' );
    is( $packet->get_str, "foo", 'get_str returns "foo"' );
}

{
    ## Test read_expect. Send a SUCCESS message, expect a FAILURE
    ## message. This should croak.
    Net::SSH::Perl::Packet->new( $ssh, type => SSH_SMSG_SUCCESS )->send;
    eval { my $packet = Net::SSH::Perl::Packet->read_expect($ssh, SSH_SMSG_FAILURE) };
    ok( $@, 'sending success and expecting a failure message croaks' );

    my $expected = sprintf "type %s, got %s", SSH_SMSG_FAILURE, SSH_SMSG_SUCCESS;
    like( $@, qr/$expected/, 'check failure message' );
}

{
    ## That read_expect issued a fatal_disconnect, which sent a
    ## disconnect message. It also dropped the session socket, so we
    ## need to reinstate it.
    $ssh->{session}{sock} = $fh;
    eval { Net::SSH::Perl::Packet->read($ssh) };
    ok( $@, 'read fails after disconnect' );
    like( $@, qr/^Received disconnect.+Protocol error/,
          'error message on read after disconnect' );
}

{
    ## Now that we're back to normal...
    ## Test leftover functionality. Send two packets
    ## that will both get placed into the StringThing buffer...
    Net::SSH::Perl::Packet->new($ssh, type => SSH_SMSG_FAILURE)->send;
    Net::SSH::Perl::Packet->new($ssh, type => SSH_CMSG_EOF)->send;

    ## Reading the first packet will read the entire rest of the
    ## buffer: *both* packets. The internal leftover buffer should be
    ## split up based on the packet lengths.  First read reads entire
    ## buffer, grabs first packet...
    my $packet = Net::SSH::Perl::Packet->read($ssh);
    is( $packet->type, SSH_SMSG_FAILURE, 'packet type is SSH_SMSG_FAILURE' );

    ## ... Second read grabs leftover buffer, grabs second packet.
    $packet = Net::SSH::Perl::Packet->read($ssh);
    is( $packet->type, SSH_CMSG_EOF, 'second packet type is SSH_CMSG_EOF' );
}

{
    package StringThing;
    use strict;
    use Carp qw/croak/;

    sub TIEHANDLE { bless { buf => "", offset => 0 }, shift; }
    sub WRITE { $_[0]->{buf} .= $_[1] }
    # This needs to be reasonably high in order to avoid interfering
    # with real handles that might be open.  With Test::More in use
    # (which dups some handles), we're likely to have as many as 8
    # real handles open, if not more
	# However, too high and we run into problems with the shell
    sub FILENO { 24 }

    sub READ
    {
        croak "Nothing to read" unless $_[0]->{buf};
        $_[1] = substr $_[0]->{buf}, $_[0]->{offset}, $_[2];
        $_[0]->{offset} = _min(length $_[0]->{buf}, $_[0]->{offset} + $_[2]);
    }

    sub _min { $_[0] < $_[1] ? $_[0] : $_[1] }
}

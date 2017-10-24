package NWDemo;

use strict;
use warnings;
use autodie;

use HTTP::Request ();

use IO::SigGuard ();

use Net::WebSocket::Handshake::Server ();
use Net::WebSocket::Frame::close ();
use Net::WebSocket::PMCE::deflate::Server ();
use Net::WebSocket::HTTP_R ();

use constant MAX_CHUNK_SIZE => 64000;

use constant CRLF => "\x0d\x0a";

#Shortens the given text.
sub get_server_handshake_from_text {
    my $idx = index($_[0], CRLF . CRLF);
    return undef if -1 == $idx;

    my $hdrs_txt = substr( $_[0], 0, $idx + 2 * length(CRLF), q<> );

    die "Extra garbage! ($_[0])" if length $_[0];

    my $req = HTTP::Request->parse($hdrs_txt);

    my $pmd = Net::WebSocket::PMCE::deflate::Server->new();

    my $hsk = Net::WebSocket::Handshake::Server->new(
        extensions => [$pmd],
    );

    Net::WebSocket::HTTP_R::handshake_consume_request( $hsk, $req );

    my $pmd_data = $pmd->ok_to_use() && $pmd->create_data_object();

    return ($req, $hsk, $pmd_data || ());
}

sub handshake_as_server {
    my ($inet, $req_handler) = @_;

    my $buf = q<>;
    my ($req, $hsk, $pmd_data);

    my $count;
    while ( $count = IO::SigGuard::sysread($inet, $buf, MAX_CHUNK_SIZE, length $buf ) ) {
        ($req, $hsk, $pmd_data) = get_server_handshake_from_text($buf);
        last if $hsk;
    }

    die "read(): $!" if !defined $count;

    my $hdr_text = $hsk->to_string();

    my @extra_headers;
    if ($req_handler) {
        substr( $hdr_text, -2, 0 ) = $_ . CRLF for $req_handler->($req, $hsk);
    }

    print { $inet } $hdr_text or die "send(): $!";

    return $pmd_data;
}

use constant ERROR_SIGS => qw( INT HUP QUIT ABRT USR1 USR2 SEGV ALRM TERM );

sub set_signal_handlers_for_server {
    my ($inet) = @_;

    for my $sig (ERROR_SIGS()) {
        $SIG{$sig} = sub {
            my ($the_sig) = @_;

            my $code = ($the_sig eq 'INT') ? 'ENDPOINT_UNAVAILABLE' : 'INTERNAL_ERROR';

            my $frame = Net::WebSocket::Frame::close->new(
                code => $code,
            );

            print { $inet } $frame->to_bytes() or warn "send close: $!";

            $SIG{$the_sig} = 'DEFAULT';

            kill $the_sig, $$;
        };
    }

    return;
}

1;

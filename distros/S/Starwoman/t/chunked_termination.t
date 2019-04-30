use strict;

use Test::More;

{
    package Starwoman::Server;

    # Override the sysread method enabling it to read a stream of packages
    # from an arrayref instead of an file handle:
    use subs 'sysread';

    *Starwoman::Server::sysread = sub {
        if (ref $_[0] eq "ARRAY") {
            die "EWOULDBLOCK\n" unless @{ $_[0] };

            $_[1] = shift @{ $_[0] };
            return length $_[1];
        }

        return CORE::sysread($_[0], $_[1], $_[2]);
    };

}

use Starwoman::Server;

my $server = {
    server => {
        client => [
            "3\015\012foo\015\012", # Full chunk
            "3\015\012bar",         # Chunk missing terminating HTTP newline
            "\015\012",             # ... and then the termination
            "0\015\012",            # Empty chunk to mark end of stream
        ],
    }
};

my $env = {
    HTTP_TRANSFER_ENCODING => 'chunked',
};

my $blocked;
eval {
    Starwoman::Server::_prepare_env( $server, $env );
    1;
} or do {
    $blocked = 1 if $@ =~ /^EWOULDBLOCK$/;
};

ok( !$blocked, "Reading chunked encoding does not block on well-placed package borders" );

done_testing;

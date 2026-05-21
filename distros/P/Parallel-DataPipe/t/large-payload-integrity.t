use strict;
use warnings;

# Regression test for a bug where _get_data() ignores the return value of
# sysread(), corrupting the assembled buffer when a partial read occurs.
#
# The loop in _get_data uses a lvalue-substr assignment into a pre-allocated
# buffer and always advances $offset by the requested chunk size:
#
#   $fh->sysread(my $buf, $chunk_size);         # return value ignored
#   substr($data, $offset, $chunk_size) = $buf; # shrinks $data when buf < chunk_size
#   $offset += $chunk_size;                     # advances by requested, not actual
#
# When sysread() returns fewer bytes than requested (permitted by POSIX), the
# lvalue-substr shrinks the pre-allocated buffer. $offset then jumps past the
# new end of $data, and the next iteration extends it with NUL bytes instead of
# pipe data, producing a corrupt blob that thaw() rejects. The unread bytes
# left in the pipe are subsequently mis-parsed as a message header, causing the
# parent to block forever.  _put_data() has the same class of bug with syswrite().
#
# The test injects partial reads deterministically by overriding
# IO::Handle::sysread to return at most PARTIAL_READ_CAP bytes per call
# (half of PIPE_MAX_CHUNK_SIZE), so every chunk read in the parent is
# partial regardless of system load. The override applies only to the
# parent process; workers must read work items in full so they can produce
# results for the parent to receive.

use IO::Handle;
use Test::More;
use Digest::MD5 qw(md5_hex);
use POSIX ();
use Parallel::DataPipe;

unless ( eval { require Sereal; 1 } ) {
    plan( skip_all => 'Sereal not installed' );
}

# Half of PIPE_MAX_CHUNK_SIZE (16384), so every chunk read in _get_data
# returns fewer bytes than requested.
use constant PARTIAL_READ_CAP => 8192;

my $test_pid = $$;

{
    no warnings 'redefine';

    # $_[1] must not be copied to a local -- CORE::sysread writes into it via
    # alias and that alias must reach the caller's buffer.
    *IO::Handle::sysread = sub {
        if ( $$ == $test_pid ) {
            my $capped = $_[2] > PARTIAL_READ_CAP ? PARTIAL_READ_CAP : $_[2];
            return CORE::sysread( $_[0], $_[1], $capped, defined $_[3] ? $_[3] : 0 );
        }
        return defined $_[3]
          ? CORE::sysread( $_[0], $_[1], $_[2], $_[3] )
          : CORE::sysread( $_[0], $_[1], $_[2] );
    };
}

my $kb           = 1024;
my $PAYLOAD_SIZE = 20 * $kb;    # must serialise to > PIPE_MAX_CHUNK_SIZE bytes
my $NR_WORKERS   = 4;
my $NR_ITEMS     = 20;
my $TIMEOUT      = 30;

plan tests => $NR_ITEMS + 2;

$\ = "\n";

test_partial_sysread_handling();

exit 0;

sub test_partial_sysread_handling {
    note
      sprintf( "IO::Handle::sysread capped at %d bytes (PIPE_MAX_CHUNK_SIZE=16384);"
                    . " %d workers, %d KB payload, %d items.",
               PARTIAL_READ_CAP, $NR_WORKERS, $PAYLOAD_SIZE / $kb, $NR_ITEMS );

    my @input = map { _make_item($_) } 0 .. ( $NR_ITEMS - 1 );
    my @results;
    my $timed_out = 0;

    local $SIG{ALRM} = sub {
        $timed_out = 1;
        die "TIMEOUT after ${TIMEOUT}s: parent blocked waiting for pipe data\n";
    };

    alarm($TIMEOUT);

    my $ok = eval {
        Parallel::DataPipe::run {
            input   => [@input],
            process => sub {
                my $item = $_;
                return {
                         index      => $item->{index},
                         inbound_ok => md5_hex( $item->{payload} ) eq $item->{checksum} ? 1 : 0,
                         payload    => $item->{payload},
                         checksum   => $item->{checksum},
                };
            },
            output                    => sub { push @results, $_[0] },
            number_of_data_processors => $NR_WORKERS,
        };
        1;
    };

    my $err = $@;

    # A forked worker whose exception escaped DataPipe's worker loop must not
    # run assertions -- it would produce duplicate TAP output on shared STDOUT.
    POSIX::_exit(0) if $$ != $test_pid;

    alarm(0);

    ok( $ok, 'run() completed without exception' )
      or diag("Exception: $err");

    is( scalar @results, $NR_ITEMS, "received all $NR_ITEMS results" );

    my %by_index = map { $_->{index} => $_ } @results;
    for my $i ( 0 .. $NR_ITEMS - 1 ) {
        my $r = $by_index{$i};

        unless ($r) {
            fail("item $i: result missing");
            next;
        }

        is( md5_hex( defined( $r->{payload} ) ? $r->{payload} : '' ),
            $input[$i]->{checksum},
            "item $i: payload intact (inbound_ok=$r->{inbound_ok})" );
    }

    # POSIX::_exit bypasses DESTROY (_kill_data_processors / wait()) which
    # would deadlock if any worker is still blocked writing to the parent pipe.
    STDOUT->flush();
    STDERR->flush();
    POSIX::_exit( $timed_out ? 1 : 0 );
}

# Each item has distinct binary content so data-sharing between workers cannot
# mask corruption.  pack('C*',...) produces a byte string (UTF-8 flag off).
sub _make_item {
    my ($index) = @_;
    my $base = ( $index * 13 ) % 256;
    my $pattern = pack( 'C*', map { ( $base + $_ ) % 256 } 0 .. 255 );
    my $repeats = int( $PAYLOAD_SIZE / 256 );
    my $payload = ( $pattern x $repeats ) . substr( $pattern, 0, $PAYLOAD_SIZE % 256 );

    return {
             index    => $index,
             payload  => $payload,
             checksum => md5_hex($payload),
    };
}

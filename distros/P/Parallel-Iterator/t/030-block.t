# $Id: 030-block.t 2683 2007-10-04 12:35:06Z andy $
use strict;
use warnings;
use IO::Handle;
use POSIX qw(:errno_h);
use Test::More;
use Parallel::Iterator qw( iterate_as_array );

my $buffer_size = get_pipe_buffer_size();
plan 'skip_all' => "Can't calculate buffer size"
  unless defined $buffer_size;

plan tests => 1;

# diag "I/O buffer size: $buffer_size\n";

{
    # Random data
    my $data = join '', map chr rand 256, ( 1 .. $buffer_size * 2 );

    # Just in case someone decides to generate data by some other
    # means...
    die "Not enough data!" unless length $data > $buffer_size;

    my @input = (
        {
            type  => 'hash',
            value => $data,
        },
        [ 1, $data, 3 ],
        $data,
    );

    my @want = (
        {
            type  => 'hash',
            value => "$data!",
        },
        [ $data, $data ],
        $data . $data,
    );

    for ( 1 .. 4 ) {
        @input = ( @input, @input );
        @want  = ( @want,  @want );
    }

    my @got = iterate_as_array(
        { workers => 5, nowarn => 1 },
        sub {
            my ( $id, $job ) = @_;
            # Just munge the data in a predictable, detectable way...
            if ( ref $job ) {
                if ( 'HASH' eq ref $job ) {
                    $job->{value} .= '!';
                    return $job;
                }
                elsif ( 'ARRAY' eq ref $job ) {
                    return [ $data, $data ];
                }
            }
            else {
                return $job . $job;
            }
        },
        \@input
    );

    is_deeply \@got, \@want, "big data structure";
}

# Find out how much data we can write to a pipe...
sub get_pipe_buffer_size {
    my ( $in, $out ) = map IO::Handle->new, 1 .. 2;

    unless ( pipe $in, $out ) {
        diag "Can't make pipe ($!)\n";
        return;
    }

    unless ( defined $out->blocking( 0 ) ) {
        diag "Can't turn off blocking ($!)\n";
        return;
    }

    my $chunk = ' ' x ( 1024 * 4 );
    my $wrote = 0;

    CHUNK: while ( 1 ) {
        my $rc = $out->syswrite( $chunk, length $chunk );
        last CHUNK if !defined $rc && $! == EAGAIN;
        $wrote += $rc;
        last CHUNK if $rc != length $chunk;
    }

    close $_ for $in, $out;

    return $wrote;
}

1;
package Local::Fork;

=head1 NAME

Local::Fork - ad-hoc module to run arbitrary code in a subprocess

=cut

use strict;
use warnings;

use Carp;
use Exporter qw(import);
use JSON::PP;

our @EXPORT_OK = qw(run_fork);

=head2 run_fork { CODE ... }

Runs code in a subprocess and returns whatever was returned by it
via L<JSON::PP> serialization.

=cut

sub run_fork(&) { ## no critic 'prototypes'
    my $code = shift;

    pipe my $r, my $w
        or croak "pipe failed: $!";
    my $pid = fork;
    croak "Fork failed: $!" unless defined $pid;

    if ($pid) {
        # parent
        close $w;
        local $/;
        my $result = <$r>;
        waitpid( $pid, 0 );
        return decode_json($result);
    } else {
        # child
        close $r;
        my $result = $code->();
        print $w encode_json($result);
        close $w or croak "Failed to close(w) pipe: $!";
        exit;
    };
};

1;

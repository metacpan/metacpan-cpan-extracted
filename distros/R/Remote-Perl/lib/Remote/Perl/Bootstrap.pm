use v5.36;
package Remote::Perl::Bootstrap;
our $VERSION = '0.004';

use autodie qw(open close);
use File::Spec;
use Exporter 'import';
our @EXPORT_OK = qw(bootstrap_payload wait_for_ready READY_MARKER);

# The pre-protocol readiness marker the client sends after being eval'd.
use constant READY_MARKER    => "REMOTEPERL1\n";

# Sentinel that terminates the client code in the DATA section.
use constant BOOT_END        => '__REMOTE_PERL_BOOT_END__';

# The wrapper script sent as the "perl script" over the pipe.
# Remote perl compiles and runs this; it reads client code from <DATA>
# up to the sentinel, then eval's it.
# NOTE: the __END__ token here is intentional and parsed by the remote perl.
# NOTE: use strict/warnings explicitly rather than `use v5.36` so that no
# feature pragmas leak into eval'd user code via the outer bootstrap scope.
# NOTE: WRAPPER runs on the remote side and must stay compatible with Perl 5.10+.
use constant WRAPPER => <<'END_WRAPPER';
use strict; use warnings;
binmode(STDIN); binmode(STDOUT); $| = 1;
eval(do {
    my $c = '';
    while (defined(my $line = <DATA>)) {
        last if $line eq "__REMOTE_PERL_BOOT_END__\n";
        $c .= $line;
    }
    $c
}) or do { print STDERR "remperl bootstrap failed: $@\n"; exit 1 };
__END__
END_WRAPPER

# Return the complete payload to write to the remote perl's stdin.
# Structure: wrapper script + optional config block + client source + sentinel.
#
# Options:
#   serve => 0   (default) use remote @INC only; never send MOD_REQ
#   serve => 1   append an @INC hook that fetches missing modules from local
sub bootstrap_payload(%args) {
    my $serve  = $args{serve} ? 1 : 0;
    my $config = "\$Remote::Perl::Client::REMOTE_PERL_SERVE = $serve;\n";
    return WRAPPER . $config . _client_source() . "\n" . BOOT_END . "\n";
}

# Scan bytes from $fh (via sysread) until READY_MARKER is found.
# Startup noise before the marker is discarded.
# Returns any bytes already read that follow the marker -- these belong to the
# binary protocol layer and must be fed to the protocol parser by the caller.
# Dies on EOF without finding the marker.
sub wait_for_ready($fh) {
    my $buf = '';
    while (1) {
        my $data;
        my $n = sysread($fh, $data, 4096);
        die "remperl: EOF from remote before readiness marker\n" unless $n;
        $buf .= $data;
        # Remove everything up to and including the first marker occurrence.
        my $marker = READY_MARKER;
        if ($buf =~ s/\A.*?\Q$marker\E//s) {
            return $buf;   # leftover bytes (may be empty) belong to the protocol
        }
    }
}

sub _client_source() {
    my $dir    = (File::Spec->splitpath( File::Spec->rel2abs(__FILE__) ))[1];
    my $client = File::Spec->catfile($dir, 'Client.pm');
    open(my $fh, '<', $client);
    local $/;
    return scalar <$fh>;
}

1;

__END__

=head1 NAME

Remote::Perl::Bootstrap - bootstrap the remote protocol client (internal part of Remote::Perl)

=head1 DESCRIPTION

Serialises L<Remote::Perl::Client> into a sentinel-delimited block and writes it
over the pipe to the remote Perl process, then waits for the ready sentinel before
the connection is considered live.

=head1 INTERNAL

Not public API.  This is an internal module used by L<Remote::Perl>; its interface
may change without notice.

=cut

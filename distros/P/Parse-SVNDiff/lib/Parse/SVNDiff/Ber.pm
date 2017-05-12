
package Parse::SVNDiff::Ber;

use Carp;
use base qw(Exporter);

our @EXPORT_OK = qw(parse_ber);

sub parse_ber {
    my $fh   = shift;
    my $ber  = '';

    local $/ = \1;
    while (<$fh>) {
        $ber .= $_;
        ord($_) & 0b10000000 or last;  # partly tested condition
    }

    my $rv = unpack('w', $ber);
    defined($rv)
	or die "couldn't unpack ber from BER ".unpack("B*",$ber);
    return  $rv;
}

1;

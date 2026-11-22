package Mogura::Protocol;
use strict;
use warnings;
use Exporter 'import';
use POSIX qw(strftime);
our @EXPORT_OK = qw(random_id valid_id now artifact_name);

sub random_id {
    open my $fh, '<:raw', '/dev/urandom' or die "random: $!";
    read($fh, my $bytes, 16) == 16 or die 'Random source unavailable';
    return unpack('H*', $bytes);
}
sub now { strftime('%Y-%m-%dT%H:%M:%SZ', gmtime) }
sub valid_id { defined $_[0] && !ref($_[0]) && $_[0] =~ /\A[0-9a-f]{32}\z/ }

sub artifact_name {
    my %files = (
        syft => 'sbom.syft.json',
        cdx => 'sbom.cdx.json',
        grype => 'vulnerabilities.grype.json',
        log => 'scan.log'
    );
    return $files{$_[0] // ''};
}
1;

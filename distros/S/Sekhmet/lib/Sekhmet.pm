package Sekhmet;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.01';

use Exporter 'import';
our @EXPORT_OK = qw(
    ulid  ulid_binary
    ulid_monotonic  ulid_monotonic_binary
    ulid_time  ulid_time_ms
    ulid_to_uuid  uuid_to_ulid
    ulid_compare  ulid_validate
);

our %EXPORT_TAGS = (
    all      => \@EXPORT_OK,
    generate => [qw(ulid ulid_binary ulid_monotonic ulid_monotonic_binary)],
    util     => [qw(ulid_time ulid_time_ms ulid_to_uuid uuid_to_ulid
                     ulid_compare ulid_validate)],
);

require XSLoader;
XSLoader::load('Sekhmet', $VERSION);

sub include_dir {
    my $dir = $INC{'Sekhmet.pm'};
    $dir =~ s{Sekhmet\.pm$}{Sekhmet/include};
    return $dir;
}

1;

__END__

=head1 NAME

Sekhmet - Ultra-fast XS ULID generator built on Horus

=head1 SYNOPSIS

    use Sekhmet qw(:all);

    my $ulid = ulid();                    # "01HYXZ3QXB8P6DYZ2TV4BPJ0E7"
    my $bin  = ulid_binary();             # 16 raw bytes
    my $mono = ulid_monotonic();          # monotonic within same ms
    my $ts   = ulid_time($ulid);          # epoch seconds (NV)
    my $ms   = ulid_time_ms($ulid);       # epoch milliseconds (IV)
    my $uuid = ulid_to_uuid($ulid);       # UUID v7 string
    my $back = uuid_to_ulid($uuid);       # ULID string
    my $cmp  = ulid_compare($a, $b);      # -1, 0, 1
    my $ok   = ulid_validate($string);    # 1 or 0

=head1 DESCRIPTION

Sekhmet is an XS ULID (Universally Unique Lexicographically Sortable
Identifier) generator. It reuses Horus's C primitives for Crockford
base32 encoding, CSPRNG random bytes, and millisecond timestamps.

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

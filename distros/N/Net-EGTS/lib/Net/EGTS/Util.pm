use utf8;
use strict;
use warnings;

package Net::EGTS::Util;
use base qw(Exporter);

use Carp;
use Digest::CRC     qw();
use Date::Parse     qw();
use List::MoreUtils qw(natatime any);
use POSIX           qw();

our @EXPORT = qw(
    crc8 crc16
    str2time time2new new2time strftime
    dumper_bitstring
    usize
    lat2mod mod2lat
    lon2mod mod2lon
);

use constant TIMESTAMP_20100101_000000_UTC  => 1262304000;

=head2 crc8 $bytes

CRC8 with EGTS customization

=cut

sub crc8($) {
    use bytes;
    my $ctx = Digest::CRC->new(
        width   => 8,
        poly    => 0x31,
        init    => 0xff,
        xorout  => 0x00,
        check   => 0xf7,
    );
    $ctx->add($_[0]);
    return $ctx->digest;
}

=head2 crc16 $bytes

CRC16 with EGTS customization

=cut

sub crc16($) {
    use bytes;
    my $ctx = Digest::CRC->new(
        width   => 16,
        poly    => 0x1021,
        init    => 0xffff,
        xorout  => 0x0000,
        check   => 0x29b1,
    );
    $ctx->add($_[0]);
    return $ctx->digest;
}

=head2 strftime $format, time

Return formatted string.

=cut

sub strftime {
    POSIX::strftime @_;
}

=head2 str2time $str

Return timestamp from any time format

=cut

sub str2time($) {
    return undef unless defined $_[0];
    return undef unless length  $_[0];
    return $_[0] if $_[0] =~ m{^\d+$};
    return Date::Parse::str2time( $_[0] );
}

=head2 time2new [$time]

Return time from 2010 instead of 1970

=cut

sub time2new(;$) {
    my ($time) = @_;
    $time //= time;
    return ($time - TIMESTAMP_20100101_000000_UTC);
}

=head2 new2time [$time]

Return time from 1970 instead of 2010

=cut

sub new2time($) {
    my ($time) = @_;
    return ($time + TIMESTAMP_20100101_000000_UTC);
}

=head2 dumper_bitstring $bin, [$size]

Return bitstring from I<$bin> chanked by I<$size>

=cut

sub dumper_bitstring($;$) {
    my ($bin, $size) = @_;
    my @bytes = ((unpack('B*', $bin)) =~ m{.{8}}g);
    my $it = natatime( ($size || 4), @bytes );
    my @chunks;
    while (my @vals = $it->()) {
        push @chunks, join ' ', @vals;
    }
    return join "\n", @chunks;
}

=head2 usize $mask

Return size in bytes of pack/unpack mask

=cut

sub usize($) {
    my ($mask) = @_;
    use bytes;
    die 'Unknown "*" length' if $mask =~ m{^\w\*$};
    return length pack $mask => 0;
}

=head2 lat2mod $latitude

Module from latitude

=cut

sub lat2mod($) {
    return int( abs( $_[0] )  / 90  * 0xffffffff );
}

=head2 mod2lat $module, $sign

Latitude from module and sign

=cut

sub mod2lat($$) {
    my ($module, $sign) = @_;
    return $_[0] / 0xffffffff * 90 * ($sign ? -1 : 1);
}

=head2 lon2mod $longitude

Module from longitude

=cut

sub lon2mod($) {
    return int( abs( $_[0] )  / 180 * 0xffffffff );
}

=head2 mod2lon $module, $sign

Longitude from module and sign.

=cut

sub mod2lon($$) {
    my ($module, $sign) = @_;
    return $_[0] / 0xffffffff * 180 * ($sign ? -1 : 1);
}

1;

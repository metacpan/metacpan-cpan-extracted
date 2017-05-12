package Util;

use strict;
use warnings;

use Carp     qw[];
use IO::File qw[SEEK_SET];

BEGIN {
    our @EXPORT_OK  = qw[ fh_with_codepoints fh_with_octets
                          pack_utf8 pack_overlong_utf8 
                          slurp rewind
                          tmpfile ];
    our %EXPORT_TAGS = (
        all => [ @EXPORT_OK ],
    );

    require Exporter;
    *import = \&Exporter::import;
}

my @UTF8_MIN = (0x80, 0x800, 0x10000, 0x200000, 0x4000000, 0x80000000);
sub pack_utf8 ($;$) {
    my ($cp, $len) = @_;
    ($cp >= 0 && $cp < 0x80000000)
      || Carp::confess(qq/Cannot pack '$cp'/);
    (@_ == 1 || ($len > 0 && $len <= 6 && $cp < $UTF8_MIN[$len - 1]))
      || Carp::confess(qq/Cannot pack '$cp' to sequence length '$len'/);
    my @c = (0) x ($len || ($cp < 0x80      ? 1 : $cp < 0x800    ? 2
                          : $cp < 0x10000   ? 3 : $cp < 0x200000 ? 4
                          : $cp < 0x4000000 ? 5 :                  6));
    for (reverse @c[1..$#c]) {
        $_ = ($cp & 0x3F) | 0x80;
        $cp >>= 6;
    }
    $c[0] = $cp | (0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC)[$#c];
    return pack('C*', @c);
}

sub pack_overlong_utf8 ($) {
    my ($cp) = @_;
    ($cp >= 0 && $cp < 0x4000000)
      || Carp::confess(qq/Cannot pack '$cp'/);
    my @enc;
    for (my $i = 0; $i < 5; $i++) {
        next unless $cp < $UTF8_MIN[$i];
        push @enc, pack_utf8($cp, $i + 2);
    }
    return wantarray ? @enc : $enc[0];
}

sub rewind (*) {
    seek($_[0], 0, SEEK_SET)
      || die(qq/Couldn't rewind file handle: '$!'/);
}

sub tmpfile (;$) {
    my $fh = IO::File->new_tmpfile
      || die(qq/Couldn't create a new temporary file: '$!'/);

    binmode($fh)
      || die(qq/Couldn't binmode temporary file handle: '$!'/);

    if (@_) {
        print({$fh} @_)
          || die(qq/Couldn't write to temporary file handle: '$!'/);

        seek($fh, 0, SEEK_SET)
          || die(qq/Couldn't rewind temporary file handle: '$!'/);
    }

    return $fh;
}

sub slurp (*) {
    my ($fh) = @_;
    return do { local $/; <$fh> };
}

sub fh_with_octets ($;@) {
    my ($octets, @args) = @_;

    my $args = @args ? sprintf('(%s)', join ',', @args) : '';

    if (0) {
        open(my $fh, "<:utf8_strict${args}", \$octets)
          or die(qq/Couldn't open scalar fh: '$!'/);
        return $fh;
    }
    else {
        my $fh = tmpfile($octets);
        binmode($fh, ":utf8_strict${args}")
          or die(qq/Couldn't binmode :utf8_strict${args} '$!'/);
        return $fh;
    }
}

sub fh_with_codepoints ($;@) {
    my (@cp) = @_;
    return fh_with_octets(join '', map { pack_utf8($_) } @cp);
}

1;


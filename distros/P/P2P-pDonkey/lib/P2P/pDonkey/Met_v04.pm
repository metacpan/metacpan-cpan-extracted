# P2P::pDonkey::Met_v04.pm
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package P2P::pDonkey::Met_v04;

use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.05';

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use P2P::pDonkey ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    MT_PARTMET_v04

    unpackPartMet_v04 packPartMet_v04
	readPartMet_v04 writePartMet_v04

    unpackKnownMet_v04 packKnownMet_v04
	readKnownMet_v04 writeKnownMet_v04
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

use Data::Hexdumper;
use P2P::pDonkey::Meta ':all';
use P2P::pDonkey::Meta_v04 ':all';
use P2P::pDonkey::Met qw( readFile writeFile MT_KNOWNMET );

my $debug = 0;

use constant MT_PARTMET_v04 => 0xe0;

sub unpackPartMet_v04 {
    my $v = &unpackB;
    $v == MT_PARTMET_v04 or return;
    return &unpackFileInfo_v04;
}
sub packPartMet_v04 {
    return packB(MT_PARTMET_v04) . &packFileInfo_v04;
}

sub readPartMet_v04 {
    my ($fname) = @_;
    my ($off, $buf, $res);
    $buf = readFile($fname, MT_PARTMET_v04) or return;
    $off = 0;
    $res = unpackPartMet_v04($$buf, $off);
    $res->{Path} = $fname;
    print "$off ", length $$buf, "\n";
    if ($res && $off != length $$buf) {
        warn "Unhandled bytes at the end:\n", hexdump(data=>$$buf, start_position=>$off);
    }
    return $res;
}
sub writePartMet_v04 {
    my ($fname, $p) = @_;
    my $buf = packPartMet_v04($p);
    return writeFile($fname, \$buf);
}

sub unpackKnownMet_v04 {
    &unpackB == MT_KNOWNMET or return;
    return &unpackFileInfoList_v04;
}
sub packKnownMet_v04 {
    return packB(MT_KNOWNMET) . &packFileInfoList_v04;
}
sub readKnownMet_v04 {
    my ($fname) = @_;
    my ($off, $buf, $res);
    $buf = readFile($fname, MT_KNOWNMET) or return;
    $off = 0;
    $res = unpackKnownMet_v04($$buf, $off);
    if ($res && $off != length $$buf) {
        warn "Unhandled bytes at the end:\n", hexdump(data=>$$buf, start_position=>$off);
    }
    return $res;
}
sub writeKnownMet_v04 {
    my ($fname, $p) = @_;
    my $buf = packKnownMet_v04($p);
    return writeFile($fname, \$buf);
}

1;

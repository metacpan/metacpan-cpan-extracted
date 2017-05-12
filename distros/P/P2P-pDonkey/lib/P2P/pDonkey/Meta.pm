# P2P::pDonkey::Meta.pm
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package P2P::pDonkey::Meta;

use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.05';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = 
( 'all' => [ qw(
                MetaTagName

                DLS_HASHING
                DLS_QUEUED
                DLS_LOOKING
                DLS_DOWNLOADING
                DLS_PAUSED
                DLS_IDS
                DLS_NOSOURCES
                DLS_DONE
                DLS_HASHING2
                DLS_ERRORLOADING
                DLS_COMPLETING
                DLS_COMPLETE
                DLS_CORRUPTED
                DLS_ERRORHASHING
                DLS_TRANSFERRING
                FPRI_LOW
                FPRI_NORMAL
                FPRI_HIGH
                SPRI_LOW
                SPRI_NORMAL
                SPRI_HIGH

                SZ_FILEPART

                VT_STRING VT_INTEGER 
                ST_COMBINE ST_AND ST_OR ST_ANDNOT 
                ST_NAME 
                ST_META 
                ST_MINMAX ST_MIN ST_MAX

                TT_UNDEFINED
                TT_NAME TT_SIZE TT_TYPE TT_FORMAT TT_COPIED TT_GAPSTART TT_GAPEND
                TT_DESCRIPTION TT_PING TT_FAIL TT_PREFERENCE TT_PORT TT_IP TT_VERSION
                TT_TEMPFILE TT_PRIORITY TT_STATUS TT_AVAILABILITY

                packB unpackB 
                packW unpackW
                packD unpackD
                packF unpackF
                packS unpackS
                packSList unpackSList
                packHash unpackHash
                packHashList unpackHashList

                packMetaTagName unpackMetaTagName
                packMeta unpackMeta printMeta makeMeta sameMetaType
                packMetaList unpackMetaList printMetaList
                packMetaListU unpackMetaListU printMetaListU
                MetaListU2MetaList MetaList2MetaListU

                packInfo unpackInfo makeClientInfo makeServerInfo printInfo
                packInfoList unpackInfoList printInfoList
                
                packFileInfo unpackFileInfo makeFileInfo
                packFileInfoList unpackFileInfoList makeFileInfoList

                packSearchQuery unpackSearchQuery matchSearchQuery makeSQLExpr

                packAddr unpackAddr printAddr idAddr
                packAddrList unpackAddrList 
               ) ],
  'tags' => [ qw(
                SZ_FILEPART

                VT_STRING VT_INTEGER 
                ST_COMBINE ST_AND ST_OR ST_ANDNOT 
                ST_NAME 
                ST_META 
                ST_MINMAX ST_MIN ST_MAX

                TT_UNDEFINED
                TT_NAME TT_SIZE TT_TYPE TT_FORMAT TT_COPIED TT_GAPSTART TT_GAPEND
                TT_DESCRIPTION TT_PING TT_FAIL TT_PREFERENCE TT_PORT TT_IP TT_VERSION
                TT_TEMPFILE TT_PRIORITY TT_STATUS TT_AVAILABILITY
                ) ] 
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);


# Preloaded methods go here.

use Carp;
use File::Glob ':glob';
use Tie::IxHash;
use Digest::MD4 qw( md4_hex );
use File::Basename;
use File::Find;
use POSIX qw( ceil );
use P2P::pDonkey::Util qw( ip2addr );

#use Video::Info;

my $debug = 0;

my @MetaTagName;
sub MetaTagName {
    return $MetaTagName[$_[0]];
}

# --- Download status byte
use constant DLS_HASHING        => 0x00;
use constant DLS_QUEUED         => 0x01;
use constant DLS_LOOKING        => 0x02;
use constant DLS_DOWNLOADING    => 0x03;
use constant DLS_PAUSED         => 0x04;
use constant DLS_IDS            => 0x05;
use constant DLS_NOSOURCES      => 0x06;
use constant DLS_DONE           => 0x07;
use constant DLS_HASHING2       => 0x08;
use constant DLS_ERRORLOADING   => 0x09;
use constant DLS_COMPLETING     => 0x0a;
use constant DLS_COMPLETE       => 0x0b;
use constant DLS_CORRUPTED      => 0x0c;
use constant DLS_ERRORHASHING   => 0x0d;
use constant DLS_TRANSFERRING   => 0x0e;
# --- File priority
use constant FPRI_LOW           => 0x00;
use constant FPRI_NORMAL        => 0x01;
use constant FPRI_HIGH          => 0x02;
# --- Server priority
use constant SPRI_LOW           => 0x02;
use constant SPRI_NORMAL        => 0x00;
use constant SPRI_HIGH          => 0x01;

# --- known sizes of pieces
use constant SZ_FILEPART        => 9500*1024; # v 0.4.x
use constant SZ_B_FILEPART      => 9728000;
use constant SZ_S_FILEPART      => 486400;

# -- tag bytes in file info
use constant FI_DESCRIPTION     => 0x2;
use constant FI_PART_HASHES     => 0x1;

# --- value types
use constant VT_STRING          => 0x02;
use constant VT_INTEGER         => 0x03;
use constant VT_FLOAT           => 0x04;
# --- search query constants
# - search type
use constant ST_COMBINE         => 0x0;
use constant ST_NAME            => 0x1;
use constant ST_META            => 0x2;
use constant ST_MINMAX          => 0x3;
# - search logic op for combined
use constant ST_AND             => 0x0;
use constant ST_OR              => 0x1;
use constant ST_ANDNOT          => 0x2;
# - constants for ST_MINMAX
use constant ST_MIN             => 0x1;
use constant ST_MAX             => 0x2;
# --- tag types
use constant TT_UNDEFINED       => 0x00;
use constant TT_NAME            => 0x01;
use constant TT_SIZE            => 0x02;
use constant TT_TYPE            => 0x03;    # Audio, Video, Image, Pro, Doc, Col
use constant TT_FORMAT          => 0x04;    # file extension
use constant TT_COPIED          => 0x08;
use constant TT_GAPSTART        => 0x09;
use constant TT_GAPEND          => 0x0a;
use constant TT_DESCRIPTION     => 0x0b;
use constant TT_PING            => 0x0c;
use constant TT_FAIL            => 0x0d;
use constant TT_PREFERENCE      => 0x0e;
use constant TT_PORT            => 0x0f;
use constant TT_IP              => 0x10;
use constant TT_VERSION         => 0x11;
use constant TT_TEMPFILE        => 0x12;
use constant TT_PRIORITY        => 0x13;
use constant TT_STATUS          => 0x14;
use constant TT_AVAILABILITY    => 0x15;
$MetaTagName[TT_NAME]           = 'Name';
$MetaTagName[TT_SIZE]           = 'Size';
$MetaTagName[TT_TYPE]           = 'Type';
$MetaTagName[TT_FORMAT]         = 'Format';
$MetaTagName[TT_COPIED]         = 'Copied';
$MetaTagName[TT_GAPSTART]       = 'Gap start';
$MetaTagName[TT_GAPEND]         = 'Gap end';
$MetaTagName[TT_DESCRIPTION]    = 'Description';
$MetaTagName[TT_PING]           = 'Ping';
$MetaTagName[TT_FAIL]           = 'Fail';
$MetaTagName[TT_PREFERENCE]     = 'Preference';
$MetaTagName[TT_PORT]           = 'Port';
$MetaTagName[TT_IP]             = 'IP';
$MetaTagName[TT_VERSION]        = 'Version';
$MetaTagName[TT_TEMPFILE]       = 'Temp file';
$MetaTagName[TT_PRIORITY]       = 'Priority';
$MetaTagName[TT_STATUS]         = 'Status';
$MetaTagName[TT_AVAILABILITY]   = 'Availability';

# basic pack/unpack functions
sub unpackB {
    my $res;
    if (defined $_[1]) {
        $res = unpack("x$_[1] C", $_[0]);
        $_[1] += 1 if defined $res;
    } else {
        $res = unpack('C', $_[0]);
    }
    return $res;
}

sub unpackW {
    my $res;
    if (defined $_[1]) {
        $res = unpack("x$_[1] S", $_[0]);
        $_[1] += 2 if defined $res;
    } else {
        $res = unpack('S', $_[0]);
    }
    return $res;
}

sub unpackD {
    my $res;
    if (defined $_[1]) {
        $res = unpack("x$_[1] L", $_[0]);
        $_[1] += 4 if defined $res;
    } else {
        $res = unpack('L', $_[0]);
    }
    return $res;
}

sub unpackF {
    my $res;
    if (defined $_[1]) {
        $res = unpack("x$_[1] f", $_[0]);
        $_[1] += 4 if defined $res;
    } else {
        $res = unpack('f', $_[0]);
    }
    return $res;
}

sub unpackS {
    my ($res, $len);
    if (defined $_[1]) {
        defined($len = unpack("x$_[1] S", $_[0])) or return;
        defined($res = unpack("x$_[1] x2 a$len", $_[0])) or return;
        length($res) == $len or return;
        $_[1] += 2; 
        $_[1] += $len;
    } else {
        defined($len = unpack('S', $_[0])) or return;
        $res = unpack("x2 a$len", $_[0]);
    }
    return $res;
}

sub unpackSList {
    my (@res, $len, $s);
    @res = ();
    defined($len = &unpackW) or return;
    while ($len--) {
        defined($s = &unpackS) or return;
        push @res, $s;
    }
    return \@res;
}

sub unpackHash8 {
    my $res = unpack("x$_[1] H16", $_[0]);
    length($res) == 16 or return;
    $_[1] += 8;
    return $res;
}

sub unpackHash {
    my $res = unpack("x$_[1] H32", $_[0]);
    length($res) == 32 or return;
    $_[1] += 16;
    return $res;
}

sub unpackHashList {
    my ($n, @res, $hash);
    defined($n = &unpackW) or return;
    @res = ();
    while ($n--) {
        defined($hash = &unpackHash) or return;
        push @res, $hash;
    }
    return \@res;
}

#
sub packB {
    return pack('C', shift);
}
sub packW {
    return pack('S', shift);
}
sub packD {
    return pack('L', shift);
}
sub packF {
    return pack('f', shift);
}
sub packS {
    return pack('Sa*', length $_[0], $_[0]);
}
sub packSList {
    my ($l) = @_;
    my ($res, $s);
    $res = packW(scalar @$l);
    foreach $s (@$l) {
        $res .= packS($s);
    }
    return $res;
}
sub packHash8 {
    return pack('H16', $_[0]);
}
sub packHash {
    return pack('H32', $_[0]);
}
sub packHashList {
    my ($l) = @_;
    my ($res, $hash);
    $res = packW(scalar @$l);
    foreach $hash (@$l) {
        $res .= packHash($hash);
    }
    return $res;
}

# Meta Tag
sub makeMeta {
    my ($st, $value, $name, $vt) = @_;
    if ($st) {
        if ($st == TT_NAME || $st == TT_DESCRIPTION 
            || $st == TT_TYPE || $st == TT_FORMAT
            || $st == TT_TEMPFILE) {
            $vt = VT_STRING;
        } else {
            $vt = VT_INTEGER;
        }
    }
    confess "Value type is undefined" unless defined $vt;
    return {Type => $st, ValType => $vt, Value => $value, 
            Name => $st ? MetaTagName($st) : $name};
}

sub sameMetaType {
    my ($m1, $m2) = @_;
    return $m1 && $m2 && $m1->{ValType} == $m2->{ValType} 
        && ($m1->{Type} 
            ? $m1->{Type} == $m2->{Type}
            : $m1->{Name} eq $m2->{Name});
}

sub unpackMetaTagName {
    my ($name, $st, $len);

    defined($name = &unpackS) or return;
    ($len = length $name) or return;   # length is not 0
    $st = ord $name;

#    if ($st < _TT_LAST) {   # special tag
        if ($st == TT_GAPEND || $st == TT_GAPSTART) {
            $name = unpack('xa*', $name);
        } elsif ($len == 1) {
            $name = MetaTagName($st);
            $name = sprintf("Unknown(0x%x)", $st) if !$name;
        } else {
            $st = TT_UNDEFINED;
        }
#    } else {
#        $st = TT_UNDEFINED;
#    }
    return {Type => $st, Name => $name};
}
sub packMetaTagName {
    my ($meta) = @_;
    my ($st, $name) = ($meta->{Type}, $meta->{Name});

    if ($st == TT_GAPSTART || $st == TT_GAPEND) {
        $name = packB($st) . $name;
    } elsif ($st) {
        $name = packB($st);
    }
    return packS($name);
}

sub unpackMeta {
    my ($vt, $val, $meta);

    defined($vt = &unpackB) or return;
    $meta = &unpackMetaTagName or return;

    if ($vt == VT_STRING) {
        $val = &unpackS;
    } elsif ($vt == VT_INTEGER) {
        $val = &unpackD;
    } elsif ($vt == VT_FLOAT) {
        $val = &unpackF;
    } else {
        return;
    }
    defined($val) or return;

    $meta->{ValType} = $vt;
    $meta->{Value}   = $val;
    return $meta;
}
sub packMeta {
    my ($meta) = @_;
    my ($vt, $val) = ($meta->{ValType}, $meta->{Value});
    my $res = packB($vt) . packMetaTagName($meta);
    if ($vt == VT_STRING) {
        $res .=  packS($val);
    } elsif ($vt == VT_INTEGER) {
        $res .=  packD($val);
    } elsif ($vt == VT_FLOAT) {
        $res .=  packF($val);
    } else {
        confess "Incorrect meta tag value type!\n";
    }
    return $res;
}
sub printMeta {
    my ($m) = @_;
    print $m->{Name}, ': ', ($m->{Type} == TT_IP ? ip2addr($m->{Value}) : $m->{Value});
}

# list of references to meta tags
sub unpackMetaList {
    my ($ntags, @res, $meta);
    defined($ntags = &unpackD) or return;
    @res = ();
    while ($ntags--) {
        $meta = &unpackMeta or return;
        push @res, $meta;
    }
    return \@res;
}
sub packMetaList {
    my ($l) = @_;
    my ($res, $meta);
    $res = packD(scalar @$l);
    foreach $meta (@$l) {
        $res .= packMeta($meta);
    }
    return $res;
}
sub printMetaList {
    my ($l) = @_;
    foreach my $m (@$l) {
        print "\t";
        printMeta($m);
        print "\n";
    }
}

# hash of references to meta
sub unpackMetaListU {
    my ($ntags, %res, $meta);

    tie %res, "Tie::IxHash";
    defined($ntags = &unpackD) or return;
    %res = ();
    while ($ntags--) {
        $meta = &unpackMeta or return;
        $res{$meta->{Name}} = $meta;
    }
    return \%res;
}
sub packMetaListU {
    my ($res, $meta);
    my $ntags = 0;
    $res = '';
    while ((undef, $meta) = each %{$_[0]}) {
        $res .= packMeta($meta);
        $ntags++;
    }
    return packD($ntags) . $res;
}
sub printMetaListU {
    my ($l) = @_;
    foreach my $m (values %$l) {
        print "\t";
        printMeta($m);
        print "\n";
    }
}

sub MetaList2MetaListU {
    my ($l) = @_;
    my %res;
    tie %res, "Tie::IxHash";
    foreach my $meta (@$l) {
        $res{$meta->{Name}} = $meta;
    }
    return \%res;
}

sub MetaListU2MetaList {
    return [values %{$_[0]}];
}

# client, server or search result info
sub unpackInfo {
    my ($hash, $ip, $port, $meta);
    defined($hash = &unpackHash) or return;
    ($ip, $port) = &unpackAddr or return;
    $meta = &unpackMetaListU or return;
    return {Hash => $hash, IP => $ip, Port => $port, Meta => $meta};
}

sub packInfo {
    my ($d) = @_;
    return packHash($d->{Hash}) . packAddr($d) 
        . packMetaListU($d->{Meta});
}

sub unpackInfoList {
    my ($nres, @res, $info);
    defined($nres   = &unpackD) or return;
    @res = ();
    while ($nres--) {
        $info = &unpackInfo or return;
        push @res, $info;
    }
    return \@res;
}

sub packInfoList {
    my ($l) = @_;
    my ($res, $info);
    $res = packD(scalar @$l);
    foreach $info (@$l) {
        $res .= packInfo($info);
    }
    return $res;
}

sub printInfoList {
    foreach my $i (@{$_[0]}) {
        printInfo($i);
    }
}

sub makeClientInfo {
    my ($ip, $port, $nick, $version) = @_;
    my (%meta, $hash);;
    $hash = md4_hex($nick);
    tie %meta, "Tie::IxHash";
    $meta{Name}     = makeMeta(TT_NAME, $nick);
    $meta{Version}  = makeMeta(TT_VERSION, $version);
    $meta{Port}     = makeMeta(TT_PORT, $port);
    return {Hash => $hash, IP => $ip, Port => $port, Meta => \%meta};
}

sub makeServerInfo {
    my ($ip, $port, $name, $description) = @_;
    my (%meta, $hash);;
    $hash = md4_hex($name);
    tie %meta, "Tie::IxHash";
    $meta{Name}         = makeMeta(TT_NAME, $name);
    $meta{Description}  = makeMeta(TT_DESCRIPTION, $description);
    return {Hash => $hash, IP => $ip, Port => $port, Meta => \%meta};
}

sub printInfo {
    my ($info) = @_;
    $info or return;

    if (defined $info->{Date}) {
        print "Date: ", scalar(localtime($info->{Date})), "\n";
    }

    if (defined $info->{IP}) {
        print "Address: ";
        printAddr($info);
        print "\n";
    }

    if (defined $info->{Hash}) {
        print "Hash: $info->{Hash}\n";
    }

    if ($info->{Parts}) {
        print "Parts:\n";
        my $i = 0;
        foreach my $parthash (@{$info->{Parts}}) {
            print "\t$i: $parthash\n";
            $i++;
        }
    }

    if ($info->{Parts8}) {
        print "Parts8:\n";
        my $i = 0;
        foreach my $parthash (@{$info->{Parts8}}) {
            print "\t$i: $parthash\n";
            $i++;
        }
    }

    if ($info->{Gaps}) {
        print "Gaps:\n";
        my $gaps = $info->{Gaps};
        for (my $i = 0; $i < @$gaps/2; $i += 2) {
            print "\t$gaps->[$i] - $gaps->[$i+1]\n";
        }
    }

    if ($info->{Meta}) {
        my ($name, $meta);
        print "Meta:\n";
        while (($name, $meta) = each %{$info->{Meta}}) {
            print "\t$name: $meta->{Value}\n";
        }
    }
}

# file info
sub unpackFileInfo {
    my (%res, $metas, %tags, @gaps);
    my $bb;

    $bb = &unpackB;
    ($bb == FI_DESCRIPTION) or return;

    defined($res{Date}  = &unpackD) or return;
    defined($res{Hash}  = &unpackHash) or return;
    $metas      = &unpackMetaList or return;

    tie %tags, "Tie::IxHash";
    foreach my $meta (@$metas) {
        if ($meta->{Type} == TT_GAPSTART || $meta->{Type} == TT_GAPEND) {
            push @gaps, $meta->{Value};
        } else {
            $tags{$meta->{Name}} = $meta;
        }
    }
    $res{Gaps} = [sort {$a <=> $b} @gaps];
    $res{Meta} = \%tags;

    $bb = &unpackB;
    if ($bb == FI_PART_HASHES) {
        my $size = $tags{Size}{Value};
        if ($size >= SZ_B_FILEPART) {
            my @hashes;
            for (my $i = 0; $i < ceil($size / SZ_B_FILEPART); $i++) {
                push @hashes, &unpackHash;
            }
            $res{Parts} = \@hashes;
            (&unpackB == FI_PART_HASHES) or return;
        }
        if ($size >= SZ_S_FILEPART) {
            my @hashes8;
            for (my $i = 0; $i < ceil($size / SZ_S_FILEPART); $i++) {
                push @hashes8, &unpackHash8;
            }
            $res{Parts8} = \@hashes8;
        }
    } elsif ($bb == FI_DESCRIPTION) {
        if (defined $_[1]) {
            $_[1] -= 1;
        }
    }
    
    return \%res;
}

sub packFileInfo {
    my ($d) = @_;
    my ($res, $metas);
    $res = packB(FI_DESCRIPTION) . packD($d->{Date}) . packHash($d->{Hash});
    $metas = MetaListU2MetaList($d->{Meta});
    if ($d->{Gaps} and @{$d->{Gaps}}) {
        my $gaps = $d->{Gaps};
        my $ngaps = @$gaps / 2;
        for (my ($i, $n) = (0, 0); $i < $ngaps; $i += 2, $n++) {
            push @$metas, makeMeta(TT_GAPSTART, $gaps->[$i], $n);
        }
        for (my ($i, $n) = (0, 0); $i < $ngaps; $i += 2, $n++) {
            push @$metas, makeMeta(TT_GAPEND, $gaps->[$i+1], $i);
        }
    }
    $res .= packMetaList($metas);
    if ($d->{Parts} and @{$d->{Parts}}) {
        $res .= packB(FI_PART_HASHES);
        foreach my $h ($d->{Parts}) {
            $res .= packHash($h);
        }
    }
    if ($d->{Parts8} and @{$d->{Parts8}}) {
        $res .= packB(FI_PART_HASHES);
        foreach my $h8 ($d->{Parts8}) {
            $res .= packHash8($h8);
        }
    }
    $res .= packB(0x0);
    return $res;
}

sub unpackFileInfoList {
    my ($nres, @res, $info);
    defined($nres   = &unpackD) or return;
    @res = ();
    while ($nres--) {
        $info = &unpackFileInfo or return;
        push @res, $info;
    }
    return \@res;
}

sub packFileInfoList {
    my ($l) = @_;
    my ($res, $info);
    $res = packD(scalar @$l);;
    foreach $info (@$l) {
        $res .= packFileInfo($info);
    }
    return $res;
}

sub makeFileInfo {
    my ($path) = @_;
    my ($base, $ext);
    my ($context, %meta, $hash, $type);

    $path = bsd_glob($path, GLOB_TILDE);

    (-e $path && -r _) or return;

    print "Making info for $path\n" if $debug;

#    my $vinfo = Video::Info->new(-file => $path);
#    if ($vinfo->type()) {
#    print $vinfo->filename, "\n";
#    print $vinfo->filesize(), "\n";
#    print $vinfo->type(), "\n";
#    print $vinfo->duration(), "\n";
#    print $vinfo->minutes(), "\n";
#    print $vinfo->MMSS(), "\n";
#    print $vinfo->geometry(), "\n";
#    print $vinfo->title(), "\n";
#    print $vinfo->author(), "\n";
#    print $vinfo->copyright(), "\n";
#    print $vinfo->description(), "\n";
#    print $vinfo->rating(), "\n";
#    print $vinfo->packets(), "\n";
#    }

    ($base, undef, $ext) = fileparse($path, '\..*');
    $ext = unpack('xa*', $ext) if $ext; # skip first '.'
    if ($ext) {
        my %ft = qw(mp3 Audio avi Video gif Image iso Pro doc Doc);
        $type = $ft{lc $ext};
    }

    my ($size, $date);
    $size = (stat _)[7];
    $date = (stat _)[9];

    tie %meta, "Tie::IxHash";
    $meta{Name}   = makeMeta(TT_NAME, "$base.$ext");
    $meta{Size}   = makeMeta(TT_SIZE, $size);
    $meta{Type}   = makeMeta(TT_TYPE, $type) if $type;
    $meta{Format} = makeMeta(TT_FORMAT, $ext) if $ext;

    open(HANDLE, $path) or return;
    binmode(HANDLE);

    $context = new Digest::MD4;
    $context->addfile(\*HANDLE);
    $hash = $context->hexdigest;

    my $part;
    my @parts = ();
    if ($size > SZ_B_FILEPART) {
        seek(HANDLE, 0, 0);
        for (my $i = 0; $i < ceil($size / SZ_B_FILEPART); $i++) {
            read(HANDLE, $part, SZ_B_FILEPART);
            push @parts, md4_hex($part);
        }
    }
    my @parts8 = ();
    if ($size >= SZ_S_FILEPART) {
        seek(HANDLE, 0, 0);
        for (my $i = 0; $i < ceil($size / SZ_S_FILEPART); $i++) {
            read(HANDLE, $part, SZ_S_FILEPART);
            push @parts8, substr(md4_hex($part), 0, 16);
        }
    }
    
    close HANDLE;

    return {Date => $date, Hash => $hash, Parts => \@parts, Parts8 => \@parts8, Meta => \%meta, Path => $path};
}

sub makeFileInfoList {
    my (@res, $info);
    @res = ();
    foreach my $pattern (@_) {
        my $globbed = bsd_glob($pattern, GLOB_TILDE);
        print "ggg: $globbed\n";
        find { wanted => sub { push(@res, makeFileInfo($File::Find::name)) if -f $File::Find::name}, no_chdir => 1 }, 
            bsd_glob($pattern, GLOB_TILDE);
    }
    return \@res;
}

# search query
sub unpackSearchQuery {
    my ($t);
    defined($t = &unpackB) or return;

    if ($t == ST_COMBINE) {
        my ($op, $exp1, $exp2);
        defined($op = &unpackB) or return;
        $exp1 = &unpackSearchQuery or return;
        $exp2 = &unpackSearchQuery or return;
        return {Type => $t, Op => $op, Q1 => $exp1, Q2 => $exp2};

    } elsif ($t == ST_NAME) {
        my $str;
        defined($str = &unpackS) or return;
        return {Type => $t, Value => $str};

    } elsif ($t == ST_META) {
        my ($val, $metaname);
        defined($val = &unpackS) or return;
        $metaname = &unpackMetaTagName or return;
        return {Type => $t, Value => $val, MetaName => $metaname};

    } elsif ($t == ST_MINMAX) {
        my ($val, $metaname, $comp);
        defined($val      = &unpackD) or return;
        defined($comp     = &unpackB) or return;
        ($comp == ST_MIN || $comp == ST_MAX) or return;
        $metaname = &unpackMetaTagName or return; 
        return {Type => $t, Value => $val, Compare => $comp, MetaName => $metaname};

    } else {
        return;
    }
}
sub packSearchQuery {
    my ($d) = @_;
    my ($res, $t);
    $res = packB($t = $d->{Type});

    if ($t == ST_COMBINE) {
        return $res . packB($d->{Op}) 
            . packSearchQuery($d->{Q1})
            . packSearchQuery($d->{Q2});

    } elsif ($t == ST_NAME) {
        return $res . packS($d->{Value});

    } elsif ($t == ST_META) {
        return $res . packS($d->{Value}) . packMetaTagName($d->{MetaName});

    } elsif ($t == ST_MINMAX) {
        return $res . packD($d->{Value}) . packB($d->{Compare})
            . packMetaTagName($d->{MetaName});

    } else {
        confess "Incorrect search query type!\n";
    }
}

sub makeSQLExpr {
    my ($q, $ok, $fields) = @_;
    my $t = $q->{Type};
    my $nm;

    if ($t == ST_COMBINE) {
        my $op = $q->{Op};

        if ($op == ST_AND) {
            return makeSQLExpr($q->{Q1}, $ok, $fields) . ' AND ' . makeSQLExpr($q->{Q2}, $ok, $fields);
        } elsif ($op == ST_OR) {
            return '(' . makeSQLExpr($q->{Q1}, $ok, $fields) . ' OR ' . makeSQLExpr($q->{Q2}, $ok, $fields) . ')';
        } elsif ($op == ST_ANDNOT) {
            return makeSQLExpr($q->{Q1}, $ok, $fields) . ' AND NOT ' . makeSQLExpr($q->{Q2}, $ok, $fields);
        } else {
            $$ok = 0;
            return '';
        }

    } elsif ($t == ST_NAME) {
        my $nm = MetaTagName(TT_NAME);
        my $ft = $fields->{$nm};
        if (defined $ft && $ft == VT_STRING) {
            my $qval = $q->{Value};
            $qval =~ s/'/''/g;
            return "$nm LIKE '$qval'";
        } else {
            $$ok = 0;
            return '';
        }

    } elsif ($t == ST_META) {
        my $nm = $q->{MetaName}->{Name};
        my $ft = $fields->{$nm};
        if (defined $ft && $ft == VT_STRING) {
            my $qval = $q->{Value};
            $qval =~ s/'/''/g;
            return "$nm LIKE '$qval'";
        } else {
            $$ok = 0;
            return '';
        }

    } elsif ($t == ST_MINMAX) {
        my $nm = $q->{MetaName}->{Name};
        my $ft = $fields->{$nm};
        if (defined $ft && $ft == VT_INTEGER) {
            if ($q->{Compare} == ST_MIN) {
                return "$nm >= $q->{Value}";
            } elsif ($q->{Compare} == ST_MAX) {
                return "$nm <= $q->{Value}";
            } else {
                $$ok = 0;
                return '';
            }
        } else {
            $$ok = 0;
            return '';
        }

    } else {
        $$ok = 0;
        return '';
    }
}

sub matchSearchQuery {
    my ($q, $i) = @_;
    my $t = $q->{Type};

    if ($t == ST_COMBINE) {
        my $op = $q->{Op};

        if ($op == ST_AND) {
            return matchSearchQuery($q->{Q1}, $i) && matchSearchQuery($q->{Q2}, $i);
        } elsif ($op == ST_OR) {
            return matchSearchQuery($q->{Q1}, $i) || matchSearchQuery($q->{Q2}, $i);
        } elsif ($op == ST_ANDNOT) {
            return matchSearchQuery($q->{Q1}, $i) && !matchSearchQuery($q->{Q2}, $i);
        } else {
            return;
        }

    } elsif ($t == ST_NAME) {
        my ($mm, $qval);
        $qval = $q->{Value};
        $mm = $i->{Meta}->{Name};

        return ($mm && $mm->{Value} =~ /$qval/);

    } elsif ($t == ST_META) {
        my $mm = $i->{Meta}->{$q->{MetaName}->{Name}};

        return unless $mm && $mm->{ValType} == VT_STRING;

        return $mm->{Value} eq $q->{Value};

    } elsif ($t == ST_MINMAX) {
        my $mm = $i->{Meta}->{$q->{MetaName}->{Name}};

        return unless $mm && $mm->{ValType} == VT_INTEGER;

        if ($q->{Compare} == ST_MIN) {
            return $mm->{Value} >= $q->{Value};
        } elsif ($q->{Compare} == ST_MAX) {
            return $mm->{Value} <= $q->{Value};
        } else {
            return;
        }

    } else {
        return;
    }
}

# list (ip1 port1 ip2 port2 ..)
sub unpackAddrList {
    my ($snum, $ip, $port, @res);

    defined($snum = &unpackB) or return;
    @res = ();
    while ($snum--) {
        defined($ip   = &unpackD) or return;
        defined($port = &unpackW) or return;
        push @res, $ip, $port;
    }
    return \@res;
}
sub packAddrList {
    my $l = shift;
    my $n = @$l / 2;
    return pack('C', $n) . pack('LS' x $n, @$l);
}

sub unpackAddr {
    my ($ip, $port);
    defined($ip   = &unpackD) or return;
    defined($port = &unpackW) or return;
    return ($ip, $port);
}

sub packAddr {
    my ($p) = @_;
    if (ref $p) {
        return pack('LS', $p->{IP}, $p->{Port});
    } else {
        return pack('LS', @_);
    }
}

sub printAddr {
    my ($ip, $port) = @_;
    if (ref $ip && !defined $port) {
        print ip2addr($ip->{IP}), ':', $ip->{Port};
    } else {
        print ip2addr($ip), ':', $port;
    }
}

sub idAddr {
    my ($ip, $port) = @_;
    if (ref $ip && !defined $port) {
        return $ip->{IP}.':'.$ip->{Port};
    } else {
        return "$ip:$port";
    }
}

1;
__END__

=head1 NAME

P2P::pDonkey::Meta - Perl extension for handling meta data of eDonkey
peer2peer protocol. 

=head1 SYNOPSIS

  use P2P::pDonkey::Meta ':all';
  my $d = makeFileInfo('baby.avi');
  printInfo($d);

=head1 DESCRIPTION

The module provides functions and constants for creating, packing and 
unpacking meta data from packets of eDonkey peer2peer protocol.

=head2 EXPORT

None by default.

=head1 AUTHOR

Alexey Klimkin, E<lt>klimkin@mail.ruE<gt>

=head1 SEE ALSO

L<perl>.

eDonkey home:

=over 4

    <http://www.edonkey2000.com/>

=back

Basic protocol information:

=over 4

    <http://hitech.dk/donkeyprotocol.html>

    <http://www.schrevel.com/edonkey/>

=back

Client stuff:

=over 4

    <http://www.emule-project.net/>

    <http://www.nongnu.org/mldonkey/>

=back

Server stuff:

=over 4

    <http://www.thedonkeynetwork.com/>

=back

=cut

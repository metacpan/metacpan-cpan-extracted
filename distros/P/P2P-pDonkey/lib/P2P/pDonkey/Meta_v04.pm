# P2P::pDonkey::Meta_v04.pm
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package P2P::pDonkey::Meta_v04;

use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.05';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = 
( 'all' => [ qw(
                unpackFileInfo_v04 packFileInfo_v04 makeFileInfo_v04
                unpackFileInfoList_v04 packFileInfoList_v04
               ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

use File::Glob ':glob';
use File::Basename;
use P2P::pDonkey::Meta ':all';

my $debug = 0;

sub unpackFileInfo_v04 {
    my (%res, $metas, %tags, @gaps);
    defined($res{Date}  = &unpackD) or return;
    defined($res{Hash}  = &unpackHash) or return;
    $res{Parts} = &unpackHashList or return;
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
    return \%res;
}

sub packFileInfo_v04 {
    my ($d) = @_;
    my ($res, $metas);
    $res = packD($d->{Date}) . packHash($d->{Hash}) . packHashList($d->{Parts});
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
    return $res;
}

sub unpackFileInfoList_v04 {
    my ($nres, @res, $info);
    defined($nres   = &unpackD) or return;
    @res = ();
    while ($nres--) {
        $info = &unpackFileInfo_v04 or return;
        push @res, $info;
    }
    return \@res;
}

sub packFileInfoList_v04 {
    my ($l) = @_;
    my ($res, $info);
    $res = packD(scalar @$l);;
    foreach $info (@$l) {
        $res .= packFileInfo_v04($info);
    }
    return $res;
}

sub makeFileInfo_v04 {
    my ($path) = @_;
    my ($base, $ext);
    my ($context, %meta, $hash, $type);

    $path = bsd_glob($path, GLOB_TILDE);
    print $path, "\n";

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

    my @parts = ();
    if ($size > SZ_FILEPART) {
        seek(HANDLE, 0, 0);
        my ($nparts, $part);
        $nparts = ceil($size / SZ_FILEPART);
        for (my $i = 0; $i < $nparts; $i++) {
            read(HANDLE, $part, SZ_FILEPART);
            push @parts, md4_hex($part);
            $context->add($part);
        }
    } else {
        $context->addfile(\*HANDLE);
    }
    $hash = $context->hexdigest;
    
    close HANDLE;

    return {Date => $date, Hash => $hash, Parts => \@parts, Meta => \%meta, Path => $path};
}

1;

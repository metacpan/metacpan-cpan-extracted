package PlayStation::MemoryCard;
# Copyright (c) 2021 Gavin Hayes and others, see LICENSE in the root of the project
use version; our $VERSION = version->declare("v0.2.0");
use strict;
use warnings;
use Encode qw(decode encode);
use File::Basename;

sub parse_directory {
    my ($directory) = @_;
    my $inuse = unpack('C', $directory);
    my $datasize = unpack('V', substr($directory, 0x4, 0x4));
    my $linkindex = unpack('v', substr($directory, 0x8));
    my $codestr =  unpack('Z*', substr($directory, 0xA));
    my @toxor    = unpack('C127', $directory);
    my $storedxor = unpack('C', substr($directory, 0x7F));

    #my @blocktypes = ('INUSE', 'SRTLINK', 'MIDLINK', 'ENDLINK', 'EMPTY', 'UNUSABLE', 'UNKNOWN');
    my $blockcount = int($datasize / 0x2000);

    my $calcxor = 0;
    foreach my $char (@toxor) {
        $calcxor ^= $char; 
    }

    return {
        'inuse'     => $inuse,
        'datasize'  => $datasize,
        'linkindex' => $linkindex,
        'codename'  => $codestr,
        'xor'       => $storedxor,

        'calcxor'    => $calcxor,
        'calcblocks' => $blockcount
    };
}

sub parse_file_header {
    my ($file) = @_;
    my $id = unpack('a2', $file);
    my $displayflag = unpack('C', substr($file, 0x2));
    my $blocknum = unpack('C', substr($file, 0x3));
    my $shiftjisbuf = unpack('a64', substr($file, 0x4, 0x40));
    my @clut = unpack('v16', substr($file, 0x60, 0x20));


    my $iconfnt = 0;
    if(($displayflag >= 0x11)|| ($displayflag <= 0x13)) {
        $iconfnt = $displayflag - 0x10;
    }

    my $firstnul = index($shiftjisbuf, "\0");
    if($firstnul != -1) {    
        $shiftjisbuf = substr($shiftjisbuf, 0, $firstnul);    
    }
    my $shiftjis = decode('shiftjis', $shiftjisbuf);

    return {
        'id' => $id,
        'displayflag' => $displayflag,
        'blocknum' => $blocknum,
        'titlebuf' =>  $shiftjisbuf,
        'clut' => \@clut,
        'title' => $shiftjis,
        'framecnt' => $iconfnt
    };
}

sub is_mcd {
    my ($res) = @_;

    (substr($res, 0, 2) eq 'MC') or return 0;


    # A PSX memory card is 1 Mebibyte/ 128 kibibyte/ 131072 bytes
    # 1 header block of 8192 and 15 data blocks of 8192.
    return (length($res) == 131072);
}

sub is_mcs {
    my ($res) = @_;
    # A PSX mcs save is 1 directory frame and X data frames
    my $datasize = length($res) - 0x80;
    return (($datasize % 0x2000) == 0);
}

sub xordirectory {
    my ($directory) = @_;
    my @toxor = unpack('C127', $directory);
    my $xor = 0;
    foreach my $char (@toxor) {
        $xor ^= $char; 
    }
    return $xor;
}


sub load {
    my ($class, $filename, $overridefilename) = @_;
    
    my $fh;
    if($filename ne '-') {
        open($fh, '<', $filename) or die("failed to open: $filename");
    }
    else {
        $fh = *STDIN;
        $filename = 'STDIN';
    }
    my %self = ('filename' => $filename, 'contents' => '');    
    my $res = read($fh, $self{'contents'}, 131073);

    # a mcd file (full memory card dump) should be the largest file
    (($res) && ($res <= 131072)) or return undef;

    if(is_mcd($self{'contents'})) {
        $self{'type'} = 'mcd';
    }
    elsif(is_mcs($self{'contents'})) {
        $self{'type'} = 'mcs';
    }
    elsif(($res <= (15*0x2000)) && ($res >= 0x2000) && (($res % 0x2000) == 0)) {
        $self{'type'} = 'rawsave';
        my $filecodename = ($filename ne 'STDIN') ? basename($filename) : undef;
        $self{'codename'} = $overridefilename ? $overridefilename : $filecodename;
    }
    elsif(substr($res, 0, 2) eq 'MC') {
        warn("File starts with MC, but filesize is $res. Assuming type is mcd");
        $self{'type'} = 'mcd';        
    }
    else {        
        return undef;
    }

    if(($self{'type'} eq 'mcd') || ($self{'type'} eq 'mcs')) {
        $self{'hasdir'} = 1;
    }

    bless \%self, $class;
    return \%self;
}

# loop through the directory entries of a MCD file, calling callback for each one
# if it's a startblock read in the save as pass it to the callback
sub foreachDirEntry {
    my ($self, $callback) = @_;
    ($self->{'type'} eq 'mcd') or die("Unhandled filetype");

    my $startindex = 1;
    my $dataoffset = 0x2000;
    my $maxcount = 15;
    
    for(my $i = $startindex; $i < ($startindex+$maxcount); $i++) {
        my $entrydata = substr($self->{'contents'}, ($i * 0x80), 0x80);
        my $entry = parse_directory($entrydata);
        my $save;
        if($entry->{'inuse'} == 0x51) {            
            $save = {
                'filename' => $entry->{'codename'},
                'data' => substr($self->{'contents'}, $dataoffset, $entry->{'datasize'}),
            };
        }
        $callback->($entry, $save, $entrydata);
        $dataoffset += 0x2000;         
    }
}

sub _readMCSSave {
    my ($self) = @_;
    my $entrydata = substr($self->{'contents'}, 0, 0x80);
    my $entry = parse_directory($entrydata);

    return {
        'filename' => $entry->{'codename'},
        'data' => substr($self->{'contents'}, 0x80, $entry->{'datasize'})
    };
}

sub _readRawSave {
    my ($self) = @_;
    $self->{'codename'} or die("cannot read raw save without a filename");
    return {
        'filename' => $self->{'codename'},
        'data' => $self->{'contents'}
    };
}


sub readSave {
    my ($self) = @_;
    if($self->{'type'} eq 'mcs') {
        return _readMCSSave($self);
    }
    elsif($self->{'type'} eq 'rawsave') {
        return _readRawSave($self);
    }
    else {
        die("unimplemented type");
    }
}

sub FormatSaveFirstDirEntry {
    my ($save, $dirindex) = @_;
    my $savelen = length($save->{'data'});
    my $blockcount = length($save->{'data'}) / 0x2000;
    (($blockcount % 1) == 0) or die("not integer blocksize");
    ($blockcount >= 1) or die("must have at least one block");
    my $blockptr = ($blockcount == 1) ? 0xFFFF : $dirindex;    
    my $directory = pack('VVvZ21x96', 0x51, $savelen, $blockptr, $save->{'filename'});
    $directory .= pack('C', xordirectory($directory));    

    return ($directory, $blockcount);
}

sub FormatSaveAsMCD {
    my ($dirstart, $save) = @_;

    my $dirindex = ($dirstart / 0x80);
    my ($directory, $blockcount) = FormatSaveFirstDirEntry($save, $dirindex);
    
    # format the possible mid and end link directories
    if($blockcount > 1) {
        while ($blockcount > 2) {
            $dirindex++;
            my $newdir = pack('VVvx117', 0x52, 0x0, $dirindex);
            $newdir .= pack('C', xordirectory($newdir));
            $directory .= $newdir;
            $blockcount--;
        }
        my $newdir = pack('VVvx117', 0x53, 0x0, 0xFFFF);
        $newdir .= pack('C', xordirectory($newdir));
        $directory .= $newdir;
    }
    
    return {
        'dirdata'     => $directory,
        'savedata' => $save->{'data'}
    };    
}

sub FormatSaveAsMCS {
    my ($save) = @_;
    my ($directory, $blockcount) = FormatSaveFirstDirEntry($save, 1);
    return $directory .= $save->{'data'};
}

sub SaveNameAndTitleMatch {
    my ($save, $string) = @_;
    $save->{'header'} //= PlayStation::MemoryCard::parse_file_header($save->{'data'});
    my $title = $save->{'header'}{'title'};    
    my $asciititle = $title;
    $asciititle =~ tr/\x{3000}\x{FF01}-\x{FF5E}/ -~/; # fullwidth to half-width if possible
    #warn("title: $title");
    #warn("searchfname: $string");
    #warn("asciititle: $asciititle");
    return (!$string || 
    ($save->{'filename'} eq $string) || ($title eq $string) || ($asciititle eq $string) ||
    ($save->{'filename'} =~ /\Q$string\E/i) || ($title =~ /\Q$string\E/i) || ($asciititle =~ /\Q$string\E/i));
}

sub BlankMCD {
    my $cardbuf = pack('x131072');

    # header frame
    substr($cardbuf, 0, 2, 'MC');
    substr($cardbuf, 0x7F, 1, pack('C', 0x0E));
    # directory frames
    for(my $i = 1; $i < 16; $i++) {
        my $frameoffset = $i*0x80;
        substr($cardbuf, $frameoffset, 1, pack('C', 0xA0));
        substr($cardbuf, $frameoffset+0x8, 2, pack('v', 0xFFFF));
        substr($cardbuf, $frameoffset+0x7F, 1, pack('C', 0xA0));
    }
    # broken sector list
    for(my $i = 16; $i < 36; $i++) {
        my $frameoffset = $i*0x80;
        substr($cardbuf, $frameoffset, 4, pack('V', 0xFFFFFFFF));
        substr($cardbuf, $frameoffset+0x8, 2, pack('v', 0xFFFF));
    }
    # broken sector replacement data 36-55
    # unused frames 56-62
    # write test frame 63
    # file blocks

    return $cardbuf;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PlayStation::MemoryCard - Utilities for working with PlayStation memory
card and save files

=head1 SYNOPSIS

    mkmcd BESLEM-99999TONYHAX tonyhax.mcs card1.mcd > out.mcd # Make a new memory card file from a raw save, mcs save, and memory card file
    lsmc card.mcd thps2-us.mcs BESLEM-99999TONYHAX            # Print info of saves and card file
    raw2mcs RAWSAVE > out.mcs                                 # Convert a raw save into a mcs save
    mcs2raw in.mcs                                            # Convert a mcs save into a raw save
    mcsaveextract card.mcd [savesubstring] > thps2-us.mcs     # Extract a save file from a card file
    mciconextract thps2-us.mcs > thps2-us.tim                 # Extract a save icon as TIM
    mciconextract thps2-us.mcs --gif > thps2-us.tim           # Extract a save icon as GIF

=head1 AUTHOR

Gavin Hayes, C<< <gahayes at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc PlayStation::MemoryCard

Additional documentation, support, and bug reports can be found at the
repository L<https://github.com/G4Vi/psx_mc_cli>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
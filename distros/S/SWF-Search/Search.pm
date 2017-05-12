package SWF::Search;

use 5.006;
use strict;
use Carp;
use IO::File;
use warnings;

our $VERSION = '0.01';

=head1 NAME

SWF::Search - Extract strings and information from Macromedia SWF files

=head1 SYNOPSIS

  use SWF::Search;

  my $search = SWF::Search->new(File=>"mymovie.swf");

  my @found  = $search("Spock");
  my @text   = $search->strings;

=head1 DESCRIPTION

This module allows the searching of Macromedia SWF files for text
strings.  The supported methods of searching for text are currently
limited to strings within editable text fields, and frame labels.  
Future versions will support strings created by font-shape based text,
and text used within actionscript expressions.

This initial release also does not support the compressed SWF files
created by Flash MX.  

=head1 METHODS

=over

=item my $search = SWF::Search->new(File=>"mymovie.swf");

Instantiates and returns a new search object.  Valid options are:

=over

=item File => $filename

Selects a SWF file to search on.

=item CaseSensitive => 1/0

Turns search case sensitivity on or off.  (Off by default.)

=item Debug => 1/0

Turns debugging messages on or off.  (Off by default.)

=back

=cut

sub new {

    #  usage:  my $s = SWF::Search->new(File=>"mymovie.swf");
    #
    #    The Instantiator.  Takes options, returns an object.  Surprise!
    #    Also does an initial parse of the given SWF file for kicks.

    my ($class, %args) = @_;
    
    my $self = bless {
	_debug          => $args{Debug},
	_case_sensitive => $args{CaseSensitive},
	_file           => undef,
	_fh             => undef,
	_bitbuf         => '',
	_strings        => [],
	_labels         => [],
    }, ref($class) || $class;

    $self->file($args{File}) if (defined $args{File});
    return $self;
}


=item $s->search("string" [,Type=>I<type>, %options]);

Examines the SWF file for the given search term, and returns a list of 
text strings containing the term.  If no search term is given, the 
method will return all found text strings in the file.  A B<Type> option
may also be passed to the method, requesting that the search only be
performed on a certain kind of text.  The currently supported text 
types are B<All>, B<EditText>, and B<Label>.  If no B<Type> option is 
given, the method defaults to searching B<All> text.  Additional options
for the search may also be given.  Currently, the only available option 
flag is B<CaseSensitive>; searches are case-insensitive by default.

=cut

sub search {
    my ($self, $term, %opt) = @_;
    my @str;

    for ($opt{Type} || 'All') {
	/^(All|EditText)$/ && do {@str = (@str,$self->strings)};
	/^(All|Label)$/    && do {@str = (@str,$self->labels)};
    }

    return @str unless (defined $term);
    if ($opt{CaseSensitive} || $self->{_case_sensitive}) {
	return grep /$term/,  @str;
    }
    else {
	return grep /$term/i, @str;
    }
}


=item $s->strings();

Returns a list of text strings found in the SWF movie file.

=cut

sub strings {
    my $self = shift;
    return @{$self->{_strings}};
}

=item $s->labels();

Returns a list of frame label text found in the SWF movie file.

=cut

sub labels {
    my $self = shift;
    return @{$self->{_labels}};
}


=item $s->file($filename);

Sets and parses the filename on which to search if an argument
is given, or returns the filename if called without an argument..

=cut

sub file {
    my ($self, $val) = @_;
    if (@_ > 1) {
	$self->{_file} = $val;
	my $fh = new IO::File($val, "r") || die "can't open $val: $!";
	$self->fh($fh);
	$self->{_strings} = [];
	$self->_flush_bitbuf;
	$self->_parse_file;
    }
    return $self->{_file};
}


sub _parse_file {
    my $self = shift;

    $self->_read_header;

    while (my ($tagid,$taglen) = $self->_read_tag) {
	$self->{_debug} && print "TAGID: $tagid = ".debug_tag($tagid)."\n";

	$tagid == 37 and do {$self->_parse_DefineEditText;next;};
	$tagid == 43 and do {$self->_parse_FrameLabel;    next;};

	$self->fh->read(undef,$taglen);  # skip non-string tag
    }
}


###  SWF reader methods
#
#    In an actual SWF parser, these would be more complex.  However,
#    since we only care about text and such here, I've simplified
#    things considerably for speed and laziness.

sub _read_header {
    my $self = shift;
    my ($sig,$version,$length,$fsize,$frate,$fcount);
    
    #  read header, check format, version and size

    $self->fh->read($sig,3);

    if ($sig eq "CWS") { 
	carp "Compressed SWF files not supported yet.  Sorry.";
	return;
    }
    if ($sig ne "FWS") {
	carp "Unsupported file format. [$sig]  Try again...";
	return;
    }
    
    $self->fh->read($version,1);
    if (_bits2num(unpack("B*",$version))>5) {
	$self->{_debug} && 
	    carp "There may be problems with Flash MX files.  Be warned...";
    }

    my ($file_length) = (stat($self->file))[7];
    $self->fh->read($length,4);
    $length = unpack("L",$length);
    
    if ($file_length != $length) {
	carp "File length incorrect.  Hrm.";
	return;
    }
    
    # read framesize rect, dump
    $self->_read_rect;

    # dump framerate and framecount
    $self->fh->read(undef,4);
}

sub _read_tag {
    #  reads a tag structure, returns the tag id and length
    my $self = shift;

    my $tag_head;
    $self->fh->read($tag_head,2);
    $tag_head = unpack("B*", $tag_head);

    my $tagid  = _bits2num(substr($tag_head, 8, 8) . 
                           substr($tag_head, 0, 2));
    my $taglen = _bits2num(substr($tag_head, 2, 6));

    if ($tagid == 0) {
	return;
    }

    if ($taglen == 63) { # long tag
	my $tmpbytes;
	$self->fh->read($tmpbytes,4);
	$taglen = unpack("L",$tmpbytes);
    }
    
    return($tagid,$taglen);
}

sub _read_rect {
    #  we don't really care what the contents of the rect are, 
    #  so this is just for reading and dumping the right bits.

    my $self = shift;

    my $Nbits = $self->_read_bits(5);
    $Nbits    = _bits2num($Nbits);
    my $Xmin  = $self->_read_bits($Nbits);
    my $Xmax  = $self->_read_bits($Nbits);
    my $Ymin  = $self->_read_bits($Nbits);
    my $Ymax  = $self->_read_bits($Nbits);
    $self->_flush_bitbuf;
}

sub _read_string {
    #  reads and returns a null-terminated string from the filehandle

    my $self = shift;
    my ($chr,$str);

    while ($self->fh->read($chr,1)) {
	last if (ord($chr) == 0);
	$str .= $chr;
    }

    $str =~ s/[\n\cM\cJ]//g if (defined $str);
    return $str;
}

sub _read_bits {

    #  reads the requested number of bits  and returns them as a string

    my $self = shift;
    my $numbits = shift || return;
    my ($bits,$tmpbits);

    if (($self->_bitbuf eq "") && (($numbits % 8) == 0)) {  # read whole bytes
	$self->fh->read($bits,$numbits/8);
	$bits = unpack("B*",$bits);
    } 
    else {
	if ($numbits > length($self->_bitbuf)) {  # need to fill up bitBuffer
	    my $bytes2read = int(($numbits-length($self->_bitbuf))/8)+1;
	    $self->fh->read($tmpbits,$bytes2read);
	    $self->_bitbuf($self->_bitbuf.unpack("B*",$tmpbits));
	}
	
	#  read bits from the cache
	
	$bits = substr($self->_bitbuf,0,$numbits);
	$self->_bitbuf(substr($self->_bitbuf,$numbits));
    }
    
    return $bits;
}

sub _bits2num {
    my $bits = shift || return;
    return unpack('N',pack("B32","0"x(32-length$bits).$bits));
}


sub _parse_FrameLabel {
    my $self = shift;
    my $Name =  $self->_read_string;
    push @{$self->{_labels}},$Name;
}

sub _parse_DefineEditText {
    my $self = shift;

    $self->fh->read(undef,2);  # TextId
    $self->_read_rect;         # Bounds
    my $HasText      = $self->_read_bits(1);
    my $WordWrap     = $self->_read_bits(1);
    my $Multiline    = $self->_read_bits(1);
    my $Password     = $self->_read_bits(1);
    my $ReadOnly     = $self->_read_bits(1);
    my $HasTextColor = $self->_read_bits(1);
    my $HasMaxLength = $self->_read_bits(1);
    my $HasFont      = $self->_read_bits(1);
    my $Reserved     = $self->_read_bits(2);
    my $HasLayout    = $self->_read_bits(1);
    my $NoSelect     = $self->_read_bits(1);
    my $Border       = $self->_read_bits(1);
    my $Reserved2    = $self->_read_bits(2);
    my $UseOutlines  = $self->_read_bits(1);

    if ($HasFont) {
	$self->fh->read(undef,4);  # FontId, Fontheight
    }
    if ($HasTextColor) {
	$self->fh->read(undef,4);  # TextColor 
    }
    if ($HasMaxLength) {
	$self->fh->read(undef,2);  # MaxLength
    }
    if ($HasLayout) {
	$self->fh->read(undef,9);  # Align, LeftMargin, RightMargin,
                                   # Indent, Leading      
    }
    my $VariableName = $self->_read_string;
    if ($HasText) {
	my $InitialText =  $self->_read_string;
	push @{$self->{_strings}},$InitialText;
    }
}


### "private" methods

sub fh {
    my ($self, $val) = @_;
    $self->{_fh} = $val if (@_ > 1);
    return $self->{_fh};
}

sub _bitbuf {
    my ($self, $val) = @_;
    $self->{_bitbuf} = $val if (@_ > 1);
    return $self->{_bitbuf};
}

sub _flush_bitbuf {
    my $self = shift;
    $self->{_bitbuf} = '';
}


=back

=head1 AUTHOR

Copyright 2002, Marc Majcher.  All rights reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: swf-search@majcher.com

This module is based on the OpenSWF specification and SDK released by
Macromedia at http://www.macromedia.com/software/flash/open/licensing/fileformat/

=head1 SEE ALSO

SWF::File

=cut


sub debug_tag {
    my $num = shift;
    my %tag2num = (
		   Header                 => -1,  # to make my life easier
		   End                    =>  0,
		   ShowFrame              =>  1,
		   DefineShape            =>  2,
		   FreeCharacter          =>  3,
		   PlaceObject            =>  4,
		   RemoveObject           =>  5,
		   DefineBits             =>  6,
		   DefineButton           =>  7,
		   JPEGTables             =>  8,
		   SetBackgroundColor     =>  9,
		   DefineFont             => 10,
		   DefineText             => 11,
		   DoAction               => 12,
		   DefineFontInfo         => 13,
		   DefineSound            => 14,
		   StartSound             => 15,
		   DefineButtonSound      => 17,
		   SoundStreamHead        => 18,
		   SoundStreamBlock       => 19,
		   DefineBitsLossless     => 20,
		   DefineBitsJPEG2        => 21,
		   DefineShape2           => 22,
		   DefineButtonCxform     => 23,
		   Protect                => 24,
		   PathsArePostScript     => 25,
		   PlaceObject2           => 26,
		   RemoveObject2          => 28,
		   SyncFrame              => 29,
		   FreeAll                => 31,
		   DefineShape3           => 32,
		   DefineText2            => 33,
		   DefineButton2          => 34,
		   DefineBitsJPEG3        => 35,
		   DefineBitsLossless2    => 36,
		   DefineEditText         => 37,
		   DefineMovie            => 38,
		   DefineSprite           => 39,
		   NameCharacter          => 40,
		   SerialNumber           => 41,
		   DefineTextFormat       => 42,
		   FrameLabel             => 43,
		   SoundStreamHead2       => 45,
		   DefineMorphShape       => 46,
		   FrameTag               => 47,
		   DefineFont2            => 48,
		   GenCommand             => 49,
		   DefineCommandObj       => 50,
		   CharacterSet           => 51,
		   FontRef                => 52,

	       #undocumented MX tags

	       UnknownActionScript => 59,
	       NewFontInfo         => 62,

              # tag 59: 
              # two bytes of unknown content, 
              # followed by actionscript bytecode
              # (usually 0x88 constant pool) 

              # tag 62 - new font info: 
              # font_id - UI16 
              # name_length - UI8 
              # name - name_length bytes 
              # unknown - UI16 
              # character codes for referenced fonts - 
              # UI16[nglyphs] - could be unicode 
		
		   );
    
    my %num2tag = reverse %tag2num;
    return $num2tag{$num};
}


1;

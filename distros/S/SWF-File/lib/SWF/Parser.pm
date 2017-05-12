package SWF::Parser;

use strict;
use vars qw($VERSION);

$VERSION = '0.11';

use SWF::BinStream;
use Carp;

sub new {
    my $class = shift;
    my %param = @_;
    my $self = { _tag             => {},
		 _version         => 5,
		 _aborted         => 0,
	     };
    $self->{_header_callback} = 
       $param{'header-callback'}
    || $param{'header_callback'}
    || (sub {0});
    $self->{_tag_callback} = 
       $param{'tag-callback'}
    || $param{'tag_callback'}
    || (sub {0});
    $self->{_header} = {} unless $param{header} and $param{header} =~ /^no(?:ne)?$/;
    $self->{_stream}=$param{'stream'}||(SWF::BinStream::Read->new('', sub{ die "The stream ran short by $_[0] bytes."}));


    bless $self, $class;
}

sub parse {
    my ($self, $data) = @_;
    my $stream = $self->{_stream};

    if ($self->{_aborted}) {
	carp 'The SWF parser has been aborted';
	return $self;
    }

#    unless (defined $data) {
#	if (my $bytes=$stream->Length) {
#	    carp "Data remains $bytes bytes in the stream.";
#	}
#	return $self;
#    }
    $stream->add_stream($data);
    eval {{
	unless (exists $self->{_header}) {
	    $self->parsetag while !$self->{_aborted} and $stream->Length;
	} else {
	    $self->parseheader;
	    redo if !$self->{_aborted} and $stream->Length;
	}
    }};
    if ($@) {
	return $self if ($@=~/^The stream ran short by/);
	die $@;
    }
    $self;
}

sub parse_file {
    my($self, $file) = @_;
    no strict 'refs';  # so that a symbol ref as $file works
    local(*F);
    unless (ref($file) || $file =~ /^\*[\w:]+$/) {
	# Assume $file is a filename
	open(F, $file) || die "Can't open $file: $!";
	$file = *F;
    }
    binmode($file);
    my $chunk = '';
    while(!$self->{_aborted} and read($file, $chunk, 4096)) {
	$self->parse($chunk);
    }
    close($file);
    $self->eof unless $self->{_aborted};
}

sub eof
{
    shift->parse(undef);
}

sub parseheader {
    my $self = shift;
    my $stream = $self->{_stream};
    my $header = $self->{_header};

    unless (exists $header->{signature}) {
	my $h = $header->{signature} = $stream->get_string(3);
	Carp::confess "This is not SWF stream " if ($h ne 'CWS' and $h ne 'FWS');
    }
    $stream->Version($header->{version} = $self->{_version} = $stream->get_UI8) unless exists $header->{version};
    $header->{filelen} = $stream->get_UI32 unless exists $header->{filelen};
    $stream->add_codec('Zlib') if ($header->{signature} eq 'CWS');
    $header->{nbits} = $stream->get_bits(5) unless exists $header->{nbits};
    my $nbits = $header->{nbits};
    $header->{xmin} = $stream->get_sbits($nbits) unless exists $header->{xmin};
    $header->{xmax} = $stream->get_sbits($nbits) unless exists $header->{xmax};
    $header->{ymin} = $stream->get_sbits($nbits) unless exists $header->{ymin};
    $header->{ymax} = $stream->get_sbits($nbits) unless exists $header->{ymax};
    $header->{rate} = $stream->get_UI16 / 256 unless exists $header->{rate};
    $header->{count} = $stream->get_UI16 unless exists $header->{count};

    $self->{_header_callback}->($self, @{$header}{qw(signature version filelen xmin ymin xmax ymax rate count)});
    delete $self->{_header};
}

sub parsetag {
    my $self = shift;
    my $tag = $self->{_tag};
    my $stream = $self->{_stream};
    $tag->{header}=$stream->get_UI16 unless exists $tag->{header};
    unless (exists $tag->{length}) {
	my $length = ($tag->{header} & 0x3f);
	$length=$stream->get_UI32 if ($length == 0x3f);
	$tag->{length}=$length;
    }
    unless (exists $tag->{data}) {
	$stream->_require($tag->{length});
	$tag->{data} = $stream;
	$tag->{_next_pos} = $stream->tell + $tag->{length};
    }
    eval {
	$self->{_tag_callback}->($self, $tag->{header} >> 6, $tag->{length}, $tag->{data});
    };
    if ($@) {
	Carp::confess 'Short!' if ($@=~/^The stream ran short by/);
	die $@;
    }
    my $offset = $tag->{_next_pos} - $stream->tell;
    Carp::confess 'Short!' if $offset < 0;
    $stream->get_string($offset) if $offset > 0;
    $self->{_tag}={};
}

sub abort {
    shift->{_aborted} = 1;
}

1;

__END__

=head1 NAME

SWF::Parser - Parse SWF file.

=head1 SYNOPSIS

  use SWF::Parser;

  $parser = SWF::Parser->new( 'header-callback' => \&header, 'tag-callback' => \&tag);
  # parse binary data
  $parser->parse( $data );
  # or parse SWF file
  $parser->parse_file( 'flash.swf' );

=head1 DESCRIPTION

I<SWF::Parser> module provides a parser for SWF (Macromedia Flash(R))
file. It splits SWF into a header and tags and calls user subroutines.

=head2 METHODS

=over 4

=item SWF::Parser->new( 'header-callback' => \&headersub, 'tag-callback' => \&tagsub [, stream => $stream, header => 'no'])

Creates a parser.
The parser calls user subroutines when find SWF header and tags.
You can set I<SWF::BinStream::Read> object as the read stream.
If not, internal stream is used.
If you want to parse a tag block without SWF header, set header => 'no'.

=item &headersub( $self, $signature, $version, $length, $xmin, $ymin, $xmax, $ymax, $framerate, $framecount )

You should define a I<header-callback> subroutine in your script.
It is called with the following arguments:

  $self:       Parser object itself.
  $signature:  'FWS' for normal SWF and 'CWS' for compressed SWF.
  $version:    SWF version No.
  $length:     File length.
  $xmin, $ymin, $xmax, $ymax:
     Boundary rectangle size of frames, ($xmin,$ymin)-($xmax, $ymax), in TWIPS(1/20 pixels).
  $framerate:  The number of frames per seconds.
  $framecount: Total number of frames in the SWF.

=item &tagsub( $self, $tagno, $length, $datastream )

You should define a I<tag-callback> subroutine in your script.
It is called with the following arguments:

  $self:       Parser object itself.
  $tagno:      The ID number of the tag.
  $length:     Length of tag.
  $datastream: The SWF::BinStream::Read object that can be read the rest of tag data.


=item $parser->parse( $data )

parses the data block as a SWF.
Can be called multiple times.

=item $parser->parse_file( $file );

parses a SWF file.
The argument can be a filename or an already opened file handle.

=item $parser->parseheader;

parses a SWF header and calls I<&headersub>.
You don't need to call this method specifically because 
this method is usually called from I<parse> method.

=item $parser->parsetag;

parses SWF tags and calls I<&tagsub>.
You don't need to call this method specifically because 
this method is usually called from I<parse> method.

=item $parser->abort;

tells the parser to abort parsing.

=back

=head1 COPYRIGHT

Copyright 2000 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<SWF::BinStream>, L<SWF::Element>

SWF file format specification from Macromedia.


=cut

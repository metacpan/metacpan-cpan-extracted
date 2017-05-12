package SWF::ForcibleConverter;

use strict;
use warnings;
use vars qw($VERSION $DEBUG);
$VERSION    = '0.02';
$DEBUG      = $ENV{SWF_FORCIBLECONVERTER_DEBUG};

use Carp qw/croak/;

use constant HEADER_SIZE        =>    8;
use constant MIN_BUFFER_SIZE    => 4096;

use vars qw($COMPRESSION_LEVEL);
$COMPRESSION_LEVEL = 6;

sub create_io_file {
    require IO::File; IO::File->new(@_);
}

sub create_io_handle {
    require IO::Handle; IO::Handle->new(@_);
}

sub create_io_uncompress {
    require IO::Uncompress::Inflate;
    IO::Uncompress::Inflate->new(@_)
        or die "Cannot create IO::Uncompress::Inflate: $IO::Uncompress::Inflate::InflateError";
}

sub create_io_compress {
    require IO::Compress::Deflate;
    IO::Compress::Deflate->new(@_)
        or die "Cannot create IO::Compress::Deflate: $IO::Compress::Deflate::DeflateError";
}

sub new {
    my $class = shift;
    $class = ref $class || $class;
    
    my $args = shift || {};
    my $self = {};
    bless $self, $class;

    # set with validation
    $self->set_buffer_size( $args->{buffer_size} )
        if( exists $args->{buffer_size} );

    # stash
    $self->{_r_io}          = undef; # handle for reading
    $self->{_w_io}          = undef; # handle for writing
    $self->{_header}        = undef; # original header HEADER_SIZE bytes

    # you have to customize and set these chunks before drain()
    $self->{_header_v9}     = undef; # header for output editing on
    $self->{_first_chunk}   = undef; # the first chunk just behind header

    return $self;
}

sub buffer_size {
    my $self = shift;
    return @_ ? $self->{buffer_size} = shift : $self->{buffer_size};
}

sub set_buffer_size {
    my $self = shift;
    my $size = shift;
    croak "size of buffer is @{[ MIN_BUFFER_SIZE ]} necessity at least"
        if( ! $size or $size < MIN_BUFFER_SIZE );
    $self->buffer_size( $size );
}

sub get_buffer_size {
    shift->buffer_size || MIN_BUFFER_SIZE;
}

#-----------------------------------------------------------
#
#

sub _open_r {
    my $self = shift;
    my $file = shift; # or STDIN
    unless( $self->{_r_io} ){
        my $io;
        if( defined $file ){
            if( ref($file) ){
                $io = $file; # it sets opend file handle that is a "IO"
            }else{
                $io = create_io_file;
                $io->open($file,"r") or die "Cannot open $file for reading: $!";
            }
        }else{
            $io = create_io_handle;
            $io->fdopen(fileno(STDIN),"r") or die "Cannot open STDIN: $!";
        }
        $self->{_r_io} = $io;

        # clear keeping header because input is reopend,
        # it may be the other resource
        $self->{_header} = undef; 
        $self->{_header_v9} = undef;
        $self->{_first_chunk} = undef;
    }
    return $self->{_r_io};
}

sub _open_w {
    my $self = shift;
    my $file = shift; # or STDOUT
    unless( $self->{_w_io} ){
        my $io;
        if( defined $file ){
            $io = create_io_file;
            $io->open($file,"w") or die "Cannot open $file for writing: $!";
        }else{
            $io = create_io_handle;
            $io->fdopen(fileno(STDOUT),"w") or die "Cannot open STDOUT: $!";
        }
        $self->{_w_io} = $io;
    }
    return $self->{_w_io};
}

sub _close_r {
    my $self = shift;
    if( $self->{_r_io} ){
        $self->{_r_io}->close;
        $self->{_r_io} = undef;
    }
}

sub _close_w {
    my $self = shift;
    if( $self->{_w_io} ){
        $self->{_w_io}->close;
        $self->{_w_io} = undef;
    }
}

sub _switch_input_handle_to_uncompress {
    my $self    = shift;
    my $input   = shift;
    $self->{_r_io} = create_io_uncompress($input);
}

sub _switch_output_handle_to_compress {
    my $self    = shift;
    my $output  = shift;
    $self->{_w_io} = create_io_compress($output, Append => 1, -Level => $COMPRESSION_LEVEL );
}

sub _version {
    my $self    = shift;
    my $header  = shift;
    ord(substr($header, 3, 1));
}

sub _is_compressed {
    my $self    = shift;
    my $header  = shift;
    substr($header, 0, 1) eq "\x43";
}

sub _modify_custom_header_to_version_9 {
    my $self    = shift;
    my $h = $self->{_header_v9};
    substr($h, 3, 1, "\x09");
    $self->{_header_v9} = $h;
}

sub _modify_custom_header_to_uncompressed {
    my $self = shift;
    my $h = $self->{_header_v9};
    substr($h, 0, 1, "\x46"); # "F"WS
    $self->{_header_v9} = $h;
}

sub _modify_custom_header_to_compressed {
    my $self = shift;
    my $h = $self->{_header_v9};
    substr($h, 0, 1, "\x43"); # "C"WS
    $self->{_header_v9} = $h;
}

#-----------------------------------------------------------
# io methods
# 

sub _read_header {
    my $self    = shift;
    my $input   = shift;
    my $r = $self->_open_r($input);

    # skip if it already read header
    unless( $self->{_header} ){
        
        # read header, 8 bytes from othe rigin
        my $header;
        my $size = $r->read($header, HEADER_SIZE);
        die "Failed to read the header" if( ! defined $size or $size != HEADER_SIZE );

        $self->{_header}    = $header; # keep for reuse
        $self->{_header_v9} = $header;
    }
    
    return $self->{_header};
}

sub _read_first_chunk {
    my $self    = shift;
    my $input   = shift;
    my $r       = $self->_open_r($input);
    my $readsize= $self->get_buffer_size;

    if( ! $self->{_header} and $self->{_first_chunk} ){
        croak "It tried to read the first chunk although the header was not read";
    }

    if( $self->_is_compressed($self->_read_header($input)) ){
        $r = $self->_switch_input_handle_to_uncompress($r);
        $self->_modify_custom_header_to_uncompressed;
    }

    unless( $self->{_first_chunk} ){

        my $chunk = undef;
        my $size = $r->read($chunk, $readsize);
        if( ! defined $size or ( $size != $readsize and ! $r->eof ) ){
            die "Failed to read the first chunk (@{[ defined $size ? $size : 'undef' ]})";
        }
        $self->{_first_chunk} = $chunk;
    }
    
    return $self->{_first_chunk};
}

sub _drain {
    my $self    = shift;
    my $input   = shift;
    my $output  = shift;
    my $options = shift || {};
    
    my $force_cws = ($options->{cws} || $options->{cws} ? 1 : 0);
    my $force_fws = ($options->{fws} || $options->{fws} ? 1 : 0);

    # ready to output
    my $w;
    my $writer;
    if( ref($output) eq 'CODE' ){
        $writer = $output;
    }else{
        $w = $self->_open_w($output);
        $writer = sub {
            $w->print($_[0]);
        };
    }
    my $total = 0;

    # choose format of output as cws or fws
    my $to_compress = $self->_is_compressed($self->{_header}) ? 1 : 0;
    if( $force_cws != $force_fws ){
        $to_compress = 1 if( $force_cws );
        $to_compress = 0 if( $force_fws );
    }

    # print the header that is always uncompressed 8 bytes
    if( $to_compress ){
        $self->_modify_custom_header_to_compressed;
        $writer->($self->{_header_v9});
        $total += length $self->{_header_v9};
        $w = $self->_switch_output_handle_to_compress( $w );
    }else{
        $writer->($self->{_header_v9});
        $total += length $self->{_header_v9};
    }

    # print out buffered data
    for my $chunk ( @{$self->{_first_chunk}} ){
        if( ref $chunk eq 'SCALAR' ){
            $writer->($$chunk); $total += length $$chunk;
        }else{
            $writer->( $chunk); $total += length  $chunk;
        }
    }        
    
    # print out unread data
    my $r = $self->_open_r($input);
    my $readsize = $self->get_buffer_size;
    while( ! $r->eof ){
        my $buf;
        my $size = $r->read($buf, $readsize);
        if( ! defined $size or $size != $readsize ){
            if( ! $r->eof ){
                die "Failed to read a chunk";
            }
        }
        $writer->($buf);
        $total += length $buf;
    }

    # drain() can be called once
    $self->_close_w;
    $self->_close_r;

    return $total;
}

#-----------------------------------------------------------
# main public utilities
# 

sub version {
    my $self    = shift;
    my $input   = shift;
    $self->_version($self->_read_header($input));
}

sub is_compressed {
    my $self    = shift;
    my $input   = shift;
    $self->_is_compressed($self->_read_header($input));
}

#-----------------------------------------------------------
# main jobs with drain will close handles
# 

sub uncompress {
    my $self    = shift;
    my $input   = shift;
    my $output  = shift;

    my $first = $self->_read_first_chunk($input);
    $self->{_first_chunk} = [\$first];
    $self->_drain($input, $output, { fws => 1 });
}

sub _get_body_position { # function for ->covert9()
    my $the_9th = shift; # 9th char

    my $result  = 0;
    $result += 3; # "FWS" or "CWS"
    $result += 1; # version
    $result += 4; # length

    my $rectNBits = int( ord($the_9th) >> 3 );  # unsigned right shift
    $result += int( (5 + $rectNBits * 4) / 8 ); # stage(rect)
    $result += 2; # ?
    $result += 1; # frame rate
    $result += 2; # total frames
    
    return $result;
}

sub convert9 {
    my $self    = shift;
    my $input   = shift;
    my $output  = shift;
    my $options;
    if( scalar @_ == 1 ){
        $options = shift @_;
    }else{
        my %opts = @_;
        $options = \%opts;
    }

    # prepare
    my $header      = $self->_read_header($input);
    my $buf_size    = $self->get_buffer_size;

    # read first chunk that includes info for body position
    my $first = $self->_read_first_chunk($input);
    my $pos = _get_body_position(substr($first, 0, 1));

    # read and write header with updating the version to 9
    my $version = $self->_version($header);

    if( $version < 9 ){
        $self->_modify_custom_header_to_version_9;
    }

    my $total = 0;
    if( 9 <= $version ){
        # simply, copy (but uncompressed)
        $self->{_first_chunk} = [\$first];
        $total += $self->_drain($input, $output, $options);

    }else{
    
        my $result = undef;
        my $offset = $pos - HEADER_SIZE;
        if( 8 == $version ){
            # find file attributes position

                                 # require Config;
            my $shortsize   = 2; # $Config::Config{shortsize};
            my $intsize     = 4; # $Config::Config{intsize};

            my $currentp = $offset;
            while( 1 ){
                last if( length $first < $currentp - HEADER_SIZE );
                my $short = unpack "x${currentp}s", $first;
                my  $tag = $short >> 6;
                if( $tag == 69 ){
                    $result = $currentp;
                    last;
                }
                $currentp += 2;
                
                my  $len = $short & 0x3f;
                if( $len == 0x3f ){
                    $len = unpack "x${currentp}i", $first;
                    $currentp += $intsize;
                }
                $currentp += $len;
            }
        }

        if( defined $result ){
        
            my $attr_pos = $result + 2 - HEADER_SIZE;
            
            my $target = unpack('C', substr($first, $attr_pos, 1));
            $target |= 0x08;
            substr($first, $attr_pos, 1, pack('C',$target));

            $self->{_first_chunk} = [\$first];
            $total += $self->_drain($input, $output, $options);

        }else{

            $self->{_first_chunk} = [
                substr($first, 0, $offset),
                "\x44\x11\x08\x00\x00\x00",
                substr($first, $offset),
                ];
            $total += $self->_drain($input, $output, $options);
        }
    }
    
    return $total;
}

sub convert9_compress {
    my $self    = shift;
    my $input   = shift;
    my $output  = shift;
    $self->convert9($input, $output, { cws => 1 });
}

sub convert9_uncompress {
    my $self    = shift;
    my $input   = shift;
    my $output  = shift;
    $self->convert9($input, $output, { fws => 1 });
}

1;
__END__


=pod

=head1 NAME

SWF::ForcibleConverter - Convert SWF file into version 9 format forcibly if version is under 9

=head1 SYNOPSIS

    use SWF::ForcibleConverter;
    
    my $fc = SWF::ForcibleConverter->new;
    my $size = $fc->convert9($input, $output);

=head1 DESCRIPTION

SWF::ForcibleConverter is an utility
that converts SWF file into version 9 format forcibly.

This program processes SWF that has version number of format less than 9.
And version 9 or upper versions will be treated as it is,
without converting, except compressibility change.

A reason of the changing is convenient for my algorithm, it inflates a file once.
But this point does not become a problem.

=head1 CONSTRUCTOR

The constructor new() receives hash reference as an option. 

    my $fc = SWF::ForcibleConverter->new({
                buffer_size => 4096,
                });

The option has following key that is available.

=head2 buffer_size

Buffer size (bytes) when reading input data.

At least 4096 is required, or croak.

Default is 4096.

=head1 METHOD

On the following explanation,
$input or $output are file path or opened IO object.

Both are omissible.
In that case, it uses STDIN or STDOUT.

As follows, this is convenient because of pipe processing. 

    $ cat in.swf | perl -MSWF::ForcibleConverter -e \
        'SWF::ForcibleConverter->new->convert9' > out.swf

Note that when using STDIO, uncompress() or convert9*() can be called only once.

=head2 buffer_size([$num])

This is accessor. When $num is given, it sets the member directly, without validation.
Regularly, please use [get|set]_buffer_size methods.

=head2 get_buffer_size

Get buffer size.

=head2 set_buffer_size($num)

Set buffer size.

At least 4096 is required, or croak.

=head2 version($input)

Get version number of SWF file.

=head2 is_compressed($input)

Return true if $input is compressed.

=head2 uncompress($input, $output)

Convert $input SWF into uncompressed $output SWF.

This method does not change version format,
simply outputs with uncompressing.

=head2 convert9($input, $output)

    my $input   = "/path/to/original.swf";
    my $output  = "converted.swf";
    my $bytes   = $fc->convert9($input, $output);

Convert $input SWF into $output SWF with changing version 9 format forcibly.
And it returns size of $output.

Note that if the $input is compressed format, that is known as CWS,
$output will be CWS as well.
The another case is uncompressed, as FWS.
You can call convert9_compress() or convert9_uncompress() instead.

=head2 convert9_compress($input, $output)

convert9_compress() is the same as convert9() 
except $output is always compressed (that is CWS).

=head2 convert9_uncompress($input, $output)

convert9_uncompress() is the same as convert9() 
except $output is always uncompressed (that is FWS).

=head1 REPOSITORY

SWF::ForcibleConverter is hosted on github https://github.com/hiroaki/SWF-ForcibleConverter

=head1 AUTHOR

WATANABE Hiroaki E<lt>hwat@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

SWF::ForcibleConverter was prepared with reference to "ForcibleLoader"
that is produced by Spark project with the kind of respect:

L<http://www.libspark.org/wiki/yossy/ForcibleLoader>

=cut

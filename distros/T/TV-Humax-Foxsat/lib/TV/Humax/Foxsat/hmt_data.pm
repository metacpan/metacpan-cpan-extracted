#!/usr/bin/perl
package TV::Humax::Foxsat::hmt_data;

=head1 NAME

TV::Humax::Foxsat::hmt_data - Package representing Humax file metadata

=head1 VERSION

version 0.06

=cut

use namespace::autoclean;
use DateTime;
use Moose;
use Moose::Util::TypeConstraints;
use TV::Humax::Foxsat::epg_data;
use TV::Humax::Foxsat;

our $VERSION = '0.06'; # VERSION

use Trait::Attribute::Derived Unpack => {
    source    => 'rawDataBlock',
    fields    => { 'unpacker' => 'Str' },
    processor => sub {
        my ($self, $value, $fields) = @_;
        defined $value or die "Error rawDataBlock not defined";
        return unpack( $fields->{'unpacker' }, $value)
    },
};

# The raw data that all the fields are extracted from.
has 'rawDataBlock' => (
    is  => 'rw',
    isa => 'Str',
);

# For field documentation see: http://foxsatdisk.wikispaces.com/.hmt+file+format
has 'lastPlay' => (
    is       => 'rw', 
    isa      => 'Int',
    traits   => [ Unpack ],
    unpacker => '@5 n',
);

has 'ChanNum' => (
    is       => 'rw', 
    isa      => 'Int',
    traits   => [ Unpack ],
    unpacker => '@17 n',
);

has 'startTime' => (
    is       => 'rw', 
    isa      => 'DateTime',
    traits   => [ Unpack ],
    unpacker => '@25 N',
    postprocessor   =>  sub { return DateTime->from_epoch( epoch => $_, time_zone => 'GMT' ) },
);

has 'endTime' => (
    is       => 'rw', 
    isa      => 'DateTime',
    traits   => [ Unpack ],
    unpacker => '@29 N',
    postprocessor   =>  sub { return DateTime->from_epoch( epoch => $_, time_zone => 'GMT' ) },
);

has 'fileName' => (
    is       => 'rw', 
    isa      => 'Str',
    traits   => [ Unpack ],
    unpacker => '@33 A512',
);

has 'progName' => (
    is       => 'rw', 
    isa      => 'Str',
    traits   => [ Unpack ],
    unpacker => '@546 A255',
);

has 'ChanNameEPG' => (
    is       => 'rw', 
    isa      => 'Str',
    traits   => [ Unpack ],
    unpacker => '@838 A9',
);

has 'Freesat' => (
    is       => 'rw', 
    isa      => 'Bool',
    traits   => [ Unpack ],
    unpacker => '@870 c',
    postprocessor   =>  sub { return !!( $_ & 0x50 ) },
);

has 'Viewed' => (
    is       =>'rw', 
    isa      =>'Bool',
    traits   => [ Unpack ],
    unpacker => '@871 c',
    postprocessor   =>  sub { return !!( $_ & 0x20 ) },
);

has 'Locked' => (
    is       => 'rw', 
    isa      => 'Bool',
    traits   => [ Unpack ],
    unpacker => '@871 c',
    postprocessor   =>  sub { return !!( $_ & 0x80 ) },
);

has 'HiDef' => (
    is       => 'rw', 
    isa      => 'Bool',
    traits   => [ Unpack ],
    unpacker => '@872 c',
    postprocessor   =>  sub { return !!( $_ & 0x80 ) },
);

has 'Encrypted' => (
    is       => 'rw', 
    isa      => 'Bool',
    traits   => [ Unpack ],
    unpacker => '@872 c',
    postprocessor   =>  sub { return !!( $_ & 0x10 ) },
);

has 'CopyProtect' => (
    is       => 'rw', 
    isa      => 'Bool',
    traits   => [ Unpack ],
    unpacker => '@873 c',
    postprocessor   =>  sub { return !!( $_ & 0x21 ) },
);

has 'Subtitles' => (
    is       => 'rw', 
    isa      => 'Bool',
    traits   => [ Unpack ],
    unpacker => '@1037 c',
    postprocessor   =>  sub { return ( $_ == 0x1F ) },
);

has 'AudioType' => (
    is       => 'rw', 
    isa      => enum([qw[ MPEG1 AC3 ]]),
    traits   => [ Unpack ],
    unpacker => '@1037 c',
    postprocessor   =>  sub { return ( ( $_ & 0x10 ) ? 'AC3' :'MPEG1' ) },
);

has 'VideoPID' => (
    is       => 'rw', 
    isa      => 'Int',
    traits   => [ Unpack ],
    unpacker => '@1051 n',
);

has 'AudioPID' => (
    is       => 'rw', 
    isa      => 'Int',
    traits   => [ Unpack ],
    unpacker => '@1053 n',
);

has 'TeletextPID' => (
    is       => 'rw', 
    isa      => 'Int',
    traits   => [ Unpack ],
    unpacker => '@1059 n',
);

has 'VideoType' => (
    is       => 'rw', 
    isa      => enum([qw[ SD HD ]]),
    traits   => [ Unpack ],
    unpacker => '@1069 c',
    postprocessor   =>  sub { return ( ( $_ & 0x01 ) ? 'HD' :'SD' ) },
);

has 'EPG_Block_count' => (
    is       => 'rw', 
    isa      => 'Int',
    traits   => [ Unpack ],
    unpacker => '@4099 c',
);

has 'EPG_blocks' => (
    is          =>  'ro',
    isa         =>  'ArrayRef[TV::Humax::Foxsat::epg_data]',
    lazy_build  =>  1,
);


# Convenience function to read data from a file
# TODO: Don't read more than we need by checking how many EPG blocks there are.
sub raw_from_file
{
    my $self = shift @_;
    my $src_file = shift;
    my $file_size = -s $src_file;

    # Read the data into a memory buffer
    open my $src_FH, '<', $src_file or die("Error reading from $src_file $!");
    my $raw_buff = undef;
    my $bytes_read = sysread $src_FH, $raw_buff, $file_size, 0;
    close $src_FH;

    $self->rawDataBlock($raw_buff);

    return;
}

sub _build_EPG_blocks
{
    my $self = shift @_;

    my @retList = ();
    my $epg_blocks  = substr $self->rawDataBlock(), 4100;

    for( my $block_num=0; $block_num < $self->EPG_Block_count(); $block_num++ )
    {
        my $nextBlock = TV::Humax::Foxsat::epg_data->new();
        $nextBlock->rawEPGBlock( substr $epg_blocks, 0, 544 );
        my $remainder = substr $epg_blocks, 544;
        my $guide_block_len = unpack('@2  n',   $remainder );
        $nextBlock->guideBlockLen( $guide_block_len );
        $nextBlock->rawGuideBlock( substr($remainder, 4+$guide_block_len) );
        $epg_blocks = substr $epg_blocks, 544+4+$guide_block_len;
        push @retList, $nextBlock;
    }

    return \@retList;
}

# All done 
1;

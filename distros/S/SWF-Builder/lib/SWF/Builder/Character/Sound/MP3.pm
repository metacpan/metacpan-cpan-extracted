package SWF::Builder::Character::Sound::MP3;

use strict;
use Carp;

our $VERSION="0.01";

our @ISA = ('SWF::Builder::Character::Sound::Def');

my @bitrates = 
    (
     [32000, 40000, 48000, 56000,  64000,  80000,  96000,  112000, 128000, 160000, 192000, 224000, 256000, 320000 ], 
     [ 8000,  16000, 24000, 32000,  40000,  48000,  56000,  64000,  80000,  96000,  112000, 128000, 144000, 160000 ], 
     );

my @samplerates = ( 11025, 22050, 44100 );

my @size = ( 72, 72, 144 );
my @samplecount = ( 576, 576, 1152 );

my %channel =
    (
     '00' => 1,
     '01' => 1,
     '10' => 0, # ?
     '11' => 0,
     );

sub new {
    my ($class, $filename, %param) = @_;

    my $self = bless {
	_filename => $filename,
    }, $class;

    open my $f, '<', $filename or croak "Can't find '$filename'";
    binmode $f;
    eval { $self->_file_check($f) };
    if ($@) {
	croak substr($@, 1) if $@ =~/^\*/;
	die;
    }
    close $f;

    $self->Latency($param{Latency}) if defined $param{Latency};
    $self;
}

sub Latency {
    my ($self, $msec) = @_;
    $self->{_initial_seek} = $msec;
}

sub _get_frame {
    my ($self, $f) = @_;

    local $/ = "\xff";

    while(<$f>) {
	read $f, my $header, 1;
	next unless (($header & "\xe0") eq "\xe0");
	read $f, $header, 2, 1;
	my (undef, $version, $layer, undef, $bitrate, $samplerate, $padding, undef, $channel) = unpack('A3A2A2A1 A4A2A1A1 A2A6', unpack('B*', $header));

	die "*Invalid MP3 frame header" if ( $version eq '01' or
					      $layer   ne '01' or
					      $bitrate eq '1111' or
					      $samplerate eq '11');
	die "*Free bitrate is not supported" if $bitrate eq '0000';
	die "*This sampling rate is not supported" unless $samplerate eq '00';
	$version = oct("0b$version");
	$version-- if $version >= 2;
	$bitrate = $bitrates[$version != 2][oct("0b$bitrate")-1];
	my $length = int($size[$version] * $bitrate / $samplerates[$version]) + $padding;
	read $f, my $content, $length - 4;
	return ("\xff$header$content", $version, $channel);
    }
    return; # end of file
}

*_file_check = \&_get_frame;

sub _set_initial_seek {
    my ($self, $f) = @_;
    my $msec = $self->{_initial_seek};
    my $data = '';
    my $seek = 0;
    my $count = 0;
    my ($content, $version, $channel);

    while( ($content, $version, $channel) = $self->_get_frame($f)) {
	my $fsize = $samplecount[$version];
	my $fmsec = $fsize * 1000 / $samplerates[$version];
	$data .= $content;
	$count += $fsize;
	if ($msec <= 0) {
	    $seek += int(-$msec * $samplerates[$version] / 1000);
	    last;
	}
	$msec -= $fmsec;
	$seek += $fsize;
    }
    return ($data, $version, $channel, $count, $seek);
}

sub _pack {
    my ($self, $stream) = @_;
    my $filename = $self->{_filename};
    my $tag = SWF::Element::Tag::DefineSound->new;

    open my $f, '<', $filename or croak "Can't find '$filename'";
    binmode $f;
    eval {
	my ($data, $version, $channel, $count, $seek) = $self->_set_initial_seek($f);
	$tag->SoundFormat(2);
	$tag->SoundRate($version+1);
	$tag->SoundSize(1);
	$tag->SoundType($channel{$channel});
	my $sd = $tag->SoundData;
	$sd->add(pack('v', $seek).$data);
	while(my ($content, $version) = $self->_get_frame($f)) {
	    $sd->add($content);
	    $count += $samplecount[$version];
	}
	$tag->SoundSampleCount($count);
	$tag->SoundID($self->{ID});
	$tag->pack($stream);
    };
    if ($@) {
	croak substr($@, 1) if $@ =~ /^\*/;
	die;
    }
}

sub _init_streaming {
    my ($self, $framerate) = @_;
    my $filename = $self->{_filename};
    my $htag = SWF::Element::Tag::SoundStreamHead2->new;

    open my $f, '<', $filename or croak "Can't find '$filename'";
    binmode $f;
    my ($data, $version, $channel, $count, $seek) = $self->_set_initial_seek($f);
    $htag->StreamSoundCompression(2);
    $htag->StreamSoundRate($version+1);
    $htag->StreamSoundSize(1);
    $htag->StreamSoundType($channel{$channel});
    $htag->PlaybackSoundRate($version+1);
    $htag->PlaybackSoundSize(1);
    $htag->PlaybackSoundType($channel{$channel});
    $htag->LatencySeek($seek);
    my $sc = $samplerates[$version] / $framerate;
    $htag->StreamSoundSampleCount($sc);

    bless {
	_sound => $self,
	_file => $f,
	_last_sc => $count - $seek,
	_swfframe_sc => $sc,
	_mp3frame_sc => $count,
	_last_data => $data,
	_framerate => $framerate,
	_header_tag => $htag,
    }, 'SWF::Builder::Character::Sound::MP3::Streaming';
}

####

package SWF::Builder::Character::Sound::MP3::Streaming;

sub header_tag {
    shift->{_header_tag};
}

sub next_block_tag {
    my $self = shift;

    my $data = $self->{_last_data};
    return unless defined $data;   # return undef if EOF

    my $f = $self->{_file};
    my $version = $self->{_last_version};
    my $last_sc = $self->{_last_sc};
    my $swfframe_sc = $self->{_swfframe_sc};
    my $mp3frame_sc = $self->{_mp3frame_sc};
    my $blockdata;
    my $sc = 0;

    while ($last_sc <= $swfframe_sc) {
	$blockdata .= $data;
	($data, $version) = $self->{_sound}->_get_frame($f);
	last unless defined $data;
	$sc = $samplecount[$version];
	$last_sc += $sc;
	$mp3frame_sc += $sc;
    }
    return '' unless $blockdata; # return false (but defined) if SWF frames are short.

    $blockdata = pack('vv', $mp3frame_sc - $sc, $swfframe_sc - $last_sc + $sc) . $blockdata;

    $self->{_last_sc} = $last_sc;
    $self->{_swfframe_sc} = $swfframe_sc + $samplerates[$version] / $self->{_framerate};
    $self->{_mp3frame_sc} = $sc;
    $self->{_last_data} = $data;

    return SWF::Element::Tag::SoundStreamBlock->new(StreamSoundData => $blockdata);
}

sub __dump {
    my $self = shift;
    for my $k (qw/ _file _last_samplecount _frame_samplecount _framerate _header_tag/ ) {
	print "$k => ", $self->{$k},"\n";
    }
}

1;



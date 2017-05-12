package SWF::Builder::Character::Sound;

use strict;
use bytes;

use Carp;
use SWF::Element;
use SWF::Builder::ExElement;
use SWF::Builder::Character;

our $VERSION="0.01";

@SWF::Builder::Character::Sound::ISA = qw/ SWF::Builder::Character /;

sub play {
    my ($self, %param) = @_;

    my $parent = $param{MovieClip} || $param{MC} || $self->{_parent} or croak "Can't get the movieclip to play on";
    if ($parent eq '_root') {
	$parent = $self->{_root};
    } elsif (ref($parent) eq 'SWF::Builder') {
	$parent = $parent->{_root};
    }
    croak "The item can play only on the movie which defines it" if $parent->{_root} != $self->{_root};

    my $frame = $param{Frame} || 1;
    my $tag = SWF::Element::Tag::StartSound->new( SoundID => $self->{ID} );

    my $info = $tag->SoundInfo;
    if ($param{Multiple}) {
	$info->SyncNoMultiple(0);
    } else {
	$info->SyncNoMultiple(1);
    }
    if ($param{Stop}) {
	$info->SyncStop(1);
    }

    $info->LoopCount($param{Loop}||$param{LoopCount}) if exists $param{Loop} or exists $param{LoopCount};
    $info->InPoint($param{In} * 44.1) if exists $param{In};
    $info->OutPoint($param{Out} * 44.1) if exists $param{Out};

    if (exists $param{Envelope}) {
	my $env = $info->EnvelopeRecords;
	while( my ($pos, $vol) = splice(@{$param{Envelope}}, 0, 2) ) {
	    my $e = $env->new_element;
	    $e->Pos44($pos * 44.1);
	    if (ref($vol) eq 'ARRAY') {
		$e->LeftLevel($vol->[0]);
		$e->RightLevel($vol->[1]);
	    } else {
		$e->LeftLevel($vol);
		$e->RightLevel($vol);
	    }
	    push @$env, $e;
	}
    }
    $parent->_depends($self, $frame);
    push @{$parent->{_frame_list}[$frame-1]}, $tag;
}

sub stop {
    shift->play(Stop=>1, @_);
}

####

@SWF::Builder::Character::Sound::Imported::ISA = qw/ SWF::Builder::Character::Imported SWF::Builder::Character::Sound /;

####

package SWF::Builder::Character::Sound::Def;

use Carp;

@SWF::Builder::Character::Sound::Def::ISA = qw/ SWF::Builder::Character::Sound /;

sub new {
    my $class = shift;
    my $filename = shift;
    my $type = shift;

    ($type) = $filename =~ /\.([^.]+)$/ unless (defined $type);
    croak "Can't guess sound type" if $type eq '';

    $type = uc($type);

    my $package = "SWF::Builder::Character::Sound::$type";
    eval "require $package";
    if ($@) {
	croak "Sound type '$type' is not supported" if $@=~/^Can\'t locate/;
	die;
    }
    my $self = $package->new($filename, @_);
    $self->_init_character;
    $self;
}

sub _pack {

#stub

}

sub start_streaming {
    my ($self, %param) = @_;

    my $parent = $param{MovieClip} || $param{MC} || $self->{_parent} or croak "Can't get the movieclip to play on";
    if ($parent eq '_root') {
	$parent = $self->{_root};
    } elsif (ref($parent) eq 'SWF::Builder') {
	$parent = $parent->{_root};
    }

    croak "A streaming sound has already set in the movie clip" if $parent->{_streamsoundf};
    $parent->{_streamsoundf} = 1;
    my $frame = $param{Frame} || 1;

    my $ss = $self->_init_streaming($self->{_root}{_file}->FrameRate);
    push @{$parent->{_frame_list}[0]}, $ss->header_tag;

#    $ss->__dump;

    while (defined(my $btag = $ss->next_block_tag)) {
	push @{$parent->{_frame_list}[$frame-1]}, $btag if $btag;
	$frame++;
    }
}


1;
__END__

=head1 NAME

SWF::Builder::Character::Sound - SWF Sound character

=head1 SYNOPSIS

    my $sound = $mc->new_sound( 'ring.mp3' );
    $sound->play;

=head1 DESCRIPTION

This module creates SWF sound characters from MP3 or raw Microsoft WAV files.

=over 4

=item $sound = $mc->new_sound( $filename )

loads a sound file and returns a new sound character.
It supports only MP3 now.

=item $sound->play( [ %options ] )

plays the sound.

Options:

=over 4

=item MovieClip => $mc, Frame => $frame

'MovieClip'(MC) is a parent movie clip on which the sound is played.
If MC is not set, the sound is played on the movie clip in which it is defined.
'Frame' is the frame number on which the sound is played.

=item Multiple => 0/1

avoids/allows multiple playing. If 0, don't start the sound if already playing.

=item Loop => $count

sets the loop count.

=item In => $in_msec, Out => $out_msec

'In' sets the beginning point of the sound and 'Out' sets the last
in milliseconds.

=item Envelope => [ $msec1, $volumelevel1, $msec2, $volumelevel2, ... ]

sets the sound envelope.
Volume level is set to $volumelevel1 at $msec1, and $volumelevel2 at $msec2, ...
Volume level can take a number from 0 to 32768, or a reference to the array of
volume levels of left and right channels.

=back

=item $sound->stop( [ MovieClip => $mc, Frame => $frame ] )

stops playing the sound. 
It can take 'MovieClip' and 'Frame' options as same as the 'play' method.

=item $sound->start_streaming( [ MovieClip => $mc, Frame => $frame ] )

starts the streaming sound, which synchronizes with the movie timeline.
It can take 'MovieClip' and 'Frame' options as same as the 'play' method.

=item $sound->Latency( $msec )

sets the sound latency in milliseconds.

=back

=head1 COPYRIGHT

Copyright 2003- Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

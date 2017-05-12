package SWF::Builder::Character::MovieClip;

use strict;
use utf8;

use Carp;
use SWF::Element;
use SWF::Builder;

use Carp;

our $VERSION='0.05';

@SWF::Builder::Character::MovieClip::ISA = ('SWF::Builder::Character::Displayable');

sub place {
    my $self = shift;

    bless $self->SUPER::place(@_), 'SWF::Builder::DisplayInstance::MovieClip';
}

####

@SWF::Builder::Character::MovieClip::Imported::ISA = qw/ SWF::Builder::Character::Imported SWF::Builder::Character::MovieClip /;

####

package SWF::Builder::Character::MovieClip::Def;

@SWF::Builder::Character::MovieClip::Def::ISA = qw/ SWF::Builder::Movie SWF::Builder::Character::MovieClip /;

sub new {
    my $self = shift->SUPER::new;
    $self->{_init_action} = undef;
    $self->_init_character;
    $self;
}

sub _pack {
    my ($self, $stream) = @_;

    $self->set_depth;
  SWF::Builder::DefineSprite->new
      ( SpriteID    => $self->{ID},
	FrameCount  => scalar(@{$self->{_frame_list}}),
	ControlTags => $self->{_frame_list}
	)->pack($stream);
    if ($self->{_init_action}) {
	my $tag = SWF::Element::Tag::DoInitAction->new;
	$tag->SpriteID($self->{ID});
	$tag->Actions($self->{_init_action}{_actions});
	$tag->pack($stream);
    }
}

sub init_action {
    require SWF::Builder::ActionScript;
    my $self = shift;

    $self->{_root}->_depends($self, 1);
    $self->{_init_action} ||= SWF::Builder::ActionScript->new(Version => $self->{_root}{_version});
}

sub _destroy {
    my $self = shift;
    $self->SWF::Builder::Movie::_destroy;
    $self->SWF::Builder::Character::Displayable::_destroy;
}

@SWF::Builder::DefineSprite::ISA = qw/ SWF::Element::Tag::DefineSprite /;

sub SWF::Builder::DefineSprite::_pack {
    my ($self, $stream) = @_;
    $self->SpriteID->pack($stream);
    $stream->set_UI16(scalar @{$self->ControlTags});
    $self->ControlTags->pack($stream);
}

#####

package SWF::Builder::DisplayInstance::MovieClip;

use Carp;

@SWF::Builder::DisplayInstance::MovieClip::ISA = qw/ SWF::Builder::DisplayInstance /;

my %special_keys = (
		    '<Left>'      => 1,
		    '<Right>'     => 2,
		    '<Home>'      => 3,
		    '<End>'       => 4,
		    '<Insert>'    => 5,
		    '<Backspace>' => 8,
		    '<Delete>'    => 6,
		    '<Enter>'     => 13,
		    '<Up>'        => 14,
		    '<Down>'      => 15,
		    '<PgUp>'      => 16,
		    '<PgDn>'      => 17,
		    '<Tab>'       => 18,
		    '<Escape>'    => 19, # ? don't work.
		    '<Space>'     => 32,
		    );

sub on {
    require SWF::Builder::ActionScript;
    
    my ($self, $event, $key) = @_;
    my $clipactions = $self->{_tags}[0]{_tag}->ClipActions;
    my $newaction = $clipactions->new_element;
    my $eventsub = "ClipEvent$event";
    
    eval{$newaction->$eventsub(1)};
    croak "$event is not a valid clip action event" if $@;
    push @$clipactions, $newaction;
    $newaction->KeyCode($special_keys{$key} || ord($key)) if $event eq 'KeyPress';
    my $action = SWF::Builder::ActionScript->new(Version => $self->{_root}{_version});
    $newaction->Actions($action->{_actions});
    return $action;
}

*onClipEvent = \&on;

#####

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SWF::Builder::Character::MovieClip - SWF movie clip object.

=head1 SYNOPSIS

  my $new_mc = $movie->new_movie_clip;
  my $mc_shape = $new_mc->new_shape
    ->moveto( ... )->lineto( ... )...
  $mc_shape->place;

  my $mc_i = $new_mc->place;
  $mc_i->on('EnterFrame')->r_rotate(10);

=head1 DESCRIPTION

Movie clips are sub movies which can be included in other movie clips.
They have their own timeline, child instances, and actions.
An SWF::Builder::MovieClip object has character constructors and other methods
for movies. See L<SWF::Builder>.
Each instance of movie clip objects can have clip actions.

=over 4

=item $new_mc = $mc->new_movie_clip

=item $new_mc = $mc->new_mc

returns a new movie clip. 

=item $mc->new_XXX

Character constructors. See L<SWF::Builder>.

=item $as = $mc->init_action

returns SWF::Builder::ActionScript object to initialize the movie clip.

=item $mc_i = $mc->place( ... )

returns the display instance of the movie clip. See L<SWF::Builder>.

=item $mc_i->on( $event [, $key] )

=item $mc_i->onClipEvent( $event [, $key] )

sets a clip action to the movie clip instance and returns
SWF::Builder::ActionScript object for it.
See L<SWF::Builder::ActionScript> for the details of the actionscript.
The method 'on' and 'onClipEvent' is same for movie clip instances.

Supported events are described as follows:

=over 4

=item Load

The movie clip is loaded.

=item EnterFrame

Entering each frame.

=item Unload

The movie clip is unloaded.

=item MouseMove

The mouse is moved.

=item MouseDown

A mouse button is pressed.

=item MouseUp

A mouse button is released.

=item KeyDown

A key is pressed.

=item KeyUp

A key is released.

=item Data

Data received.

=item Initialize

The movie clip is initialized.

=item Press

A mouse button is pressed while the mouse is inside the movie clip.

=item Release

A mouse button is released while the mouse is inside the movie clip.

=item ReleaseOutside

A mouse button is released while the mouse is outside the movie clip
after the mouse button is pressed inside.

=item RollOver

The mouse enters the movie clip while the mouse button is up.

=item RollOut

The mouse leaves the movie clip while the mouse button is up.

=item DragOver

The mouse enters the movie clip while the mouse button is down.

=item DragOut

The mouse leaves the movie clip while the mouse button is down.

=item KeyPress

The key specified by $key is pressed.
$key is an ascii character or one of the special keys as follows:

  <Backspace>
  <Delete>
  <Down>
  <End>
  <Enter>
  <Home>
  <Insert>
  <Left>
  <PgDn>
  <PgUp>
  <Right>
  <Space>
  <Tab>
  <Up>

=back

=back

=head1 COPYRIGHT

Copyright 2003 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

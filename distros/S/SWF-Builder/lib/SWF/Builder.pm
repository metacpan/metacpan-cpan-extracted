package SWF::Builder;

use strict;

use SWF::File;
use SWF::Element;
use SWF::Builder::ExElement;
use SWF::Builder::Character;

use Carp;

our $VERSION = '0.16';
my $SFTAG = SWF::Element::Tag::ShowFrame->new;

sub new {
    my $class = shift;
    my $self = bless {
	_root =>
	  SWF::Builder::Movie::Root->new(@_)
    }, $class;
    $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $sub = $SWF::Builder::AUTOLOAD;

    return if $sub =~/::DESTROY$/;
    $sub =~ s/.+:://;
    croak "Can't locate object method \"$sub\" via package \"".ref($self).'" (perhaps you forgot to load "'.ref($self).'"?)' unless $self->{_root}->can($sub);
    $self->{_root}->$sub(@_);
}

sub DESTROY {
    my $r = shift->{_root};
    $r->_destroy if defined $r;
}

####

package SWF::Builder::Depth;
use Carp;

sub new {
    my ($class, $parent, $lower) = @_;
    my $self = bless {
	_parent => $parent,
	_depth => SWF::Element::Depth->new,
    }, $class;
    $lower ||= $self;
    $self->{_lower} = $lower;
    $self->{_upper} = $lower->{_upper}||$lower;
    $lower->{_upper} = $lower->{_upper}{_lower} = $self;
    return $self;
}

sub set_depth {
    my ($self, $n) = @_;

    $self->{_depth}->configure($n);
    $n+1;
}

sub _destroy {
    my $self = shift;
    while(my $lower = $self->{_lower}) {
	%$self = ();
	$self = $lower;
    }
}


####

package SWF::Builder::_FrameList;

@SWF::Builder::_FrameList::ISA = qw/ SWF::Element::Array::TAGARRAY /;

sub pack {
    my ($self, $stream) = @_;
    
    for my $frame (@$self) {
	for my $tag (@$frame) {
	    $tag->pack($stream);
	}
	$SFTAG->pack($stream);
    }
  SWF::Element::Tag::End->new->pack($stream);
}

####

package SWF::Builder::Movie;

use Carp;
use SWF::Builder::ExElement;

sub new {
    my $class = shift;

    my $self = bless {
	_frame_list => SWF::Builder::_FrameList->new,
	_streamsoundf => 0,
    }, $class;
    $self->{_depth_list} = SWF::Builder::Depth->new($self);

    $self;
}

sub new_shape {
    require SWF::Builder::Character::Shape;

    shift->_new_character(SWF::Builder::Character::Shape::Def->new);
}

sub new_static_text {
    require SWF::Builder::Character::Text;

    shift->_new_character(SWF::Builder::Character::Text::Def->new(@_));
}

*new_text = \&new_static_text;

sub new_dynamic_text {
    require SWF::Builder::Character::EditText;
    my $s =shift;
my $q = SWF::Builder::Character::DynamicText->new(@_);
    $s->_new_character($q);
}


sub new_edit_text {
    require SWF::Builder::Character::EditText;

    shift->_new_character(SWF::Builder::Character::EditText::Def->new(@_));
}


sub new_html_text {
    require SWF::Builder::Character::EditText;

    shift->_new_character(SWF::Builder::Character::HTMLText->new(@_));
}

sub new_text_area {
    require SWF::Builder::Character::EditText;

    shift->_new_character(SWF::Builder::Character::TextArea->new(@_));
}

sub new_input_field {
    require SWF::Builder::Character::EditText;

    shift->_new_character(SWF::Builder::Character::InputField->new(@_));
}

sub new_password_field {
    require SWF::Builder::Character::EditText;

    shift->_new_character(SWF::Builder::Character::PasswordField->new(@_));
}

sub new_font {
    require SWF::Builder::Character::Font;

    shift->_new_character(SWF::Builder::Character::Font::Def->new(@_));
}

sub new_movie_clip {
    require SWF::Builder::Character::MovieClip;

    shift->_new_character(SWF::Builder::Character::MovieClip::Def->new);
}

*new_mc = \&new_movie_clip;

sub new_gradient {
    require SWF::Builder::Gradient;

    SWF::Builder::Gradient->new;
}

sub new_jpeg {
    require SWF::Builder::Character::Bitmap;

    my $self = shift;

    unshift @_, 'JPEGFile' if @_==1;
    $self->_new_character(SWF::Builder::Character::Bitmap::JPEG->new(@_));
}

sub new_bitmap {
    require SWF::Builder::Character::Bitmap;

    my $self = shift;

    $self->_new_character(SWF::Builder::Character::Bitmap::Lossless->new(@_));
}

sub new_sound {
    require SWF::Builder::Character::Sound;

    my $self = shift;

    $self->_new_character(SWF::Builder::Character::Sound::Def->new(@_));
}

sub import_asset {
    my $self = shift;

    my $i = $self->_new_character(SWF::Builder::Character::Imported->new(@_));
    $self->_depends($i, 1);  # set 'depend' flag by force because imported assets may be used only by ActionScript.
    $i;
}

#sub shape_tween {
#    require SWF::Builder::Character::MorphShape;
#
#    my $self = shift;
#
#    $self->_new_character(SWF::Builder::Character::MorphShape->shape_tween(@_));
#}

sub _new_character {
    my ($parent, $self) = @_;

    push @{$parent->{_root}{_character_IDs}}, $self->{ID};
    push @{$parent->{_root}{_to_destroy}}, $self;
    $self->{_parent} = $parent;
    $self->{_root}   = $parent->{_root};

    return $self;
}


sub frame_action {
    require SWF::Builder::ActionScript;

    my ($self, $frame) = @_;

    my $tag = SWF::Element::Tag::DoAction->new;
    push @{$self->{_frame_list}[$frame-1]}, $tag;
    my $action = SWF::Builder::ActionScript->new(Version => $self->{_root}{_version});
    $tag->Actions($action->{_actions});
    return $action;
}

sub frame_label {
    my ($self, $frame, $label, $anchor) = @_;

    utf2bin($label);
    push @{$self->{_frame_list}[$frame-1]}, SWF::Element::Tag::FrameLabel->new(Name => $label, NamedAnchorFlag => $anchor);
}


sub set_depth {
    my $self = shift;
    my $n = 1;
    my $depth = $self->{_depth_list}{_upper};
    while ($depth != $self->{_depth_list}) {
	$n = $depth->set_depth($n);
	$depth = $depth->{_upper};
    }
}

sub _destroy {
    my $self = shift;

    $self->{_depth_list}->_destroy;
    %$self = ();
}

####

package SWF::Builder::Movie::Root;
use Carp;

use base qw/ SWF::Builder::Movie SWF::Builder::ExElement::Color::AddColor /;

sub new {
    my $class = shift;
    my %param = @_;
    my $version = $param{Version} || 6;

    my $self = $class->SUPER::new;

    $self->{_file} = SWF::File->new
	( undef,
	  Version => $version,
	  FrameRate => $param{FrameRate},
	  FrameSize => [ map {$_*20} @{$param{FrameSize}}],
	  );
    $self->{_backgroundcolor} = $param{BackgroundColor};
    $self->{_root} = $self;
    $self->{_character_IDs} = [];
    $self->{_ID_seed} = 1;
    $self->{_target_path} = '_root';
    $self->{_to_destroy} = [];
    $self->{_version} = $version;
    $self->{_as_namespace} = {};
    $self->{_init_action} = undef;
    $self->{_auto_namer} = 1;
    $self->_init_is_alpha;
    $self;
}

sub pack {
    my ($self, $stream) = @_;

    for my $id (@{$self->{_character_IDs}}) {
	$id->configure(undef);
    }

    $self->set_depth;

    $self->{_frame_list}->pack($stream);

}

our $EMPTY_SPRITE = SWF::Element::Tag::DefineSprite->new(ControlTags=>[SWF::Element::Tag::ShowFrame->new]);

sub save {
    my ($self, $file) = @_;
    my $stream = $self->{_file};

    $self->{_is_alpha}->configure(0);
    SWF::Element::Tag::SetBackgroundColor->new(BackgroundColor => $self->_add_color($self->{_backgroundcolor}))->pack($stream);
    $self->{_ID_seed} = 1;
    if (keys %{$self->{_as_namespace}}) {
	my $action = SWF::Builder::ActionScript->new(Version => $self->{_version});
	$action->compile(_create_namespace_initializer('', '_global', $self->{_as_namespace}));
#	SWF::Element::Tag::DefineSprite->new(SpriteID => $self->{_ID_seed}, ControlTags=>[SWF::Element::Tag::ShowFrame->new])->pack($stream);
	SWF::Element::Tag::DefineSprite->new(SpriteID => $self->{_ID_seed}, ControlTags=>[SWF::Element::Tag::End->new])->pack($stream);
	SWF::Element::Tag::DoInitAction->new(SpriteID => $self->{_ID_seed}++, Actions => $action->{_actions})->pack($stream);
    }
    if ($self->{_init_action}) {
#	SWF::Element::Tag::DefineSprite->new(SpriteID => $self->{_ID_seed}, ControlTags=>[SWF::Element::Tag::ShowFrame->new])->pack($stream);
	SWF::Element::Tag::DefineSprite->new(SpriteID => $self->{_ID_seed}, ControlTags=>[SWF::Element::Tag::End->new])->pack($stream);
	SWF::Element::Tag::DoInitAction->new(SpriteID => $self->{_ID_seed}++, Actions => $self->{_init_action}{_actions})->pack($stream);
    }

    $self->pack($stream);
    $stream->close($file);
}

sub _create_namespace_initializer {
    my ($as, $pname, $namehash) = @_;

    for my $name (keys %$namehash) {
	my $n = "$pname.$name";
	$as .= <<ASEND;
//#
if (eval('$n') == undefined) {
    set('$n', new Object());
}
ASEND
#//
        $as = _create_namespace_initializer($as, $n, $namehash->{$name});
    }
    return $as;
}

sub use_namespace {
    require SWF::Builder::ActionScript;

    my $self = shift;

    while (my $name = shift) {
	my $ns = $self->{_as_namespace};
	my @n = split /\./, $name;
	for my $n (@n) {
	    $ns->{$n} ||= {};
	    $ns = $ns->{$n};
	}
    }
}

sub init_action {
    require SWF::Builder::ActionScript;

    my $self = shift;

    $self->{_init_action} ||= SWF::Builder::ActionScript->new(Version => $self->{_version});
}

sub auto_namer {
    shift->{_auto_namer} = 1;
}

sub no_namer {
    shift->{_auto_namer} = 0;
}


sub _depends {
    my ($self, $char, $frame) = @_;

    push @{$self->{_frame_list}[$frame-1]}, $char;
}

sub FrameRate {
    my $self = shift;
    $self->{_file}->FrameRate(@_);
}

sub FrameSize {
    my $self = shift;
    $self->{_file}->FrameSize(map {$_*20} @_);
}

sub BackgroundColor {
    my ($self, $color) = @_;
    $self->{_backgroundcolor} = $color if defined $color;
    $self->{_backgroundcolor};
}

sub compress {
    my $self = shift;
    $self->{_file}->compress(@_);
}

sub _destroy {
    my $self = shift;
    undef $self->{_root};
    for (@{$self->{_to_destroy}}) {
	$_->_destroy;
    }
    $self->SUPER::_destroy;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SWF::Builder - Create SWF movie.

=head1 SYNOPSIS

  use SWF::Builder;

  my $movie = SWF::Builder->new
    ( FrameRate => 15,
      FrameSize => [0, 0, 400, 400],
      BackgroundColor => 'ffffff'
      );

  my $shape = $movie->new_shape   # red triangle.
    ->fillstyle('ff0000')
    ->linestyle(1, '000000')
    ->moveto(0,-11)
    ->lineto(10,6)
    ->lineto(-10,6)
    ->lineto(0,-11);

  my $instance = $shape->place;

  for (my $x = 0; $x < 400; $x++) {
      $instance->rotate(15)->moveto($x,200);
  }
  $movie->save('triangle.swf');

=head1 DESCRIPTION

I<SWF::Builder> is a wrapper of I<SWF::File>. 
It provides an easy way to create SWF6 movie.

The SWF movie consists a dictionary of character definitions and 
a hierarchical group of movie clips.  You create a movie by following steps:

=over 4

=item 1.

create a '_root' movie by SWF::Builder->new.

=item 2.

define characters such as shapes, fonts, texts, movieclips, and so on, 
by $movie->new_XXX methods.

=item 3.

get a display instance of the character by $char->place.

=item 4.

move, scale, and rotate the instance every frame.

=item 5.

repeat 2-4 if you need.

=item 6.

save the whole movie by $movie->save.

=back

=head2 '_root' movie

The '_root' movie is a top of the movie clip hierarchy.
It has properties of the whole SWF movie. It also has character constructors
and other methods for movie. See the next section for details.

=over 4

=item $movie = SWF::Builder->new( [FrameRate => $rate, FrameSize => [$xmin, $ymin, $xmax, $ymax], BackgroundColor => $color, Version => $version] )

creates a new '_root' movie. It can take three optional named parameters.
FrameRate is a frame count per second. FrameSize is a box size of frames,
which is an array reference of the coordinates of top-left and bottom-right
of the box in pixels.
BackgroundColor is a background color of the movie. It can take a six-figure
hexadecimal string, an array reference of R, G, and B value, an array reference
of named parameters such as [Red => 255], and SWF::Element::RGB object.
Version is a version number of the SWF. It must be 6 and above.

=item $movie->FrameRate( $rate )

=item $movie->FrameSize( $xmin, $ymin, $xmax, $ymax )

=item $movie->BackgroundColor( $color )

sets the property. See SWF::Builder->new.

=item $movie->use_namespace( $namespace )

prepares ActionScript namespace. For example, $movie->use_namespace('SWF.Builder')
creates movieclip which is initialized by

    if (_global.SWF == undefined) {
	_global.SWF = new Object();
    }
    if (_global.SWF.Builder == undefined) {
	_global.SWF.Builder = new Object();
    }

and place the movieclip on the first frame of the root movie.
 
=item $movie->init_action

returns SWF::Builder::ActionScript object to initialize the root movie.

=item $movie->no_namer

=item $movie->auto_namer

deactivate/reactivate auto_namer. Default is active.
Auto_namer gives a suitable name to characters and display instances automatically
when their name is referred before being named explicitly.

=item $movie->save( $filename )

saves the movie.

=back

=head2 Character constructors

=over 4

=item $mc->new_shape

returns a new shape (type: Shape).
See L<SWF::Builder::Character::Shape> for the detail.

=item $mc->new_font( $fontfile [, $fontname] )

returns a new font (type: Font).
$fontfile is a font file name. It should be a TrueType font file (ttf/ttc).
Optional $fontname is a font name referred by HTMLs in dynamic texts.
It is taken from the TrueType file if not defined.
See L<SWF::Builder::Character::Font> for the detail.

=item $mc->new_static_text( [$font, $text] )

returns a new static text (type: Text), which is fixed by authoring and cannot
be changed at playing time.
See L<SWF::Builder::Character::Text> for the detail of a text.

=item $mc->new_edit_text( [$font, $text] )

=item $mc->new_dynamic_text( [$font, $text] )

=item $mc->new_html_text( [$html] )

=item $mc->new_text_area( $width, $height )

=item $mc->new_input_field( [$length] )

=item $mc->new_password_field( [$length] )

return new dynamic editable text variations (type: EditText).
See L<SWF::Builder::Character::EditText> for the detail.

=item $mc->new_movie_clip

=item $mc->new_mc

returns a new movie clip (type: MovieClip). 
See L<SWF::Builder::Character::MovieClip> for the detail.

=item $mc->new_gradient

returns a new gradient object.
See L<SWF::Builder::Gradient> and L<SWF::Builder::Character::Shape> for the detail.

=item $mc->new_jpeg( ... )

returns a new JPEG bitmap (type: Bitmap).
See L<SWF::Builder::Character::Bitmap> for the detail.

=item $mc->new_bitmap( $obj [, $type] )

returns a new lossless bitmap (type: Bitmap).
See L<SWF::Builder::Character::Bitmap> for the detail.

=item $mc->import_asset( $url, $name [, $type] )

returns a character which will be imported from the SWF movie in $url by $name.
This method does not actually import a character but put
an 'ImportAssets' tag on the movie.
$type is a type of the character, such as 'Shape', 'Font', 'Text',
'EditText', 'MovieClip', and 'Bitmap'.  Default is 'MovieClip'.
This method does not check whether a character which has $name and $type is actually exported.

=back

=head2 Other methods for movies

Here describe other common methods for root movie and movie clips.

=over 4

=item $mc->frame_action( $frame )

returns SWF::Builder::ActionScript object for a frame action.

=item $mc->frame_label( $frame, $label [, $anchorflag] )

gives $label to $frame to which ActionScripts can refer.
If the $anchorflag is set to 1, it is accessible as an
HTML anchor.

=back

=head2 Characters

Display and export methods of characters are described here.
See SWF::Builder::Character::* for details of type-specific methods.

=over 4

=item $disp_i = $char->place( [ MovieClip => $mc, Frame => $frame, above => $another_i, below => $another_i, clip_with => $mask_i ] )

places the character on $mc and returns the display instance.
It can take four optional named parameters.
'MovieClip'(MC) is a parent movie clip on which the character is placed.
The movie clip must be under the same root movie with the movie clip 
in which the character is defined. 
If MC is not set, the character is placed on the movie clip in which
it is defined. 
'Frame' is a first frame number on which the character is placed. Default is 1.
You can set the relative depth of the new instance by 'above' and 'below'.
'clip_with' is a mask instance with which the character is clipped.

Font character can't place itself.

=item $mask_i = $char->place_as_mask( [ MovieClip => $mc, Frame => $frame, above => $another_i, below => $another_i ] )

places the character on $mc as the mask object (clipping layer)
and returns the mask instance.
It can take optional parameters as same as 'place' method except 'clip_with'.
You can handle the mask instance as same as the display instance.

Only Shape and Text characters can place_as_mask.

=item $char->name( [$name] )

gives a name to the character, exports the character, and returns the name.
ActionScripts can refer the character as $name.
Other movies can import the character by $name.
When you call 'name' method without a parameter, the method simply returns the name
of the character. If the character is not named yet and auto_namer is active,
auto_namer gives a suitable name.

=item $char->export_asset( [$name] )

Same as $char->name.

=back

=head2 Display instances

It is necessary to get the display instance to show the defined character.
Each instance has its own timeline tied to the parent movie clip
and the current frame to move, to rotate, etc.

=over 4

=item $disp_i->name( [$name] )

gives a name to the display instance to which ActionScripts can refer and returns the name.
When you call 'name' method without a parameter, the method simply returns the name
of the character. If the character is not named yet and auto_namer is active,
auto_namer gives a suitable name.

=item $fobj = $disp_i->frame( $frame )

gets the specified frame object of the display instance and sets the current
frame of the display instance to $frame.

Moving, rotating, scaling, and any other matrix transforming of 
the display instance are handled in a frame by frame via a frame object.
When a frame object is not specified, the 'current frame object' kept by the
display item is used.  The current frame is counted up after it is used.

=item $fobj/$disp_i->moveto( $x, $y )

moves the display item to ($x, $y) at the (current) frame.

=item $fobj/$disp_i->r_moveto( $dx, $dy )

moves the display item relatively ( to (former X + $x, former Y + $y)).

=item $fobj/$disp_i->scale( $xscale [, $yscale] )

magnifies/reduces the display item at the (current) frame.
The scaling effect is accumulative.

=item $fobj/$disp_i->rotate( $angle )

rotates the display item at the (current) frame.
The rotation angle is accumulative.

=item $fobj/$disp_i->reset

resets the rotation and scaling at the (current) frame.

=item $fobj/$disp_i->remove

removes the display instance from the parent movie clip at the (current) frame.

=item $fobj/$disp_i->matrix

gets the transformation matrix of the display instance at the (current) frame.
The result is an SWF::Element::MATRIX object.

=item $fobj/$disp_i->frame_action

=item $fobj/$disp_i->frame_label( $label [, $anchorflag] )

same as those for movie clips, setting the frame number to that of the frame object.

=back

=head1 COPYRIGHT

Copyright 2003 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

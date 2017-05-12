package SWF::Builder::Character;

use strict;

use Carp;
use SWF::Element;
use SWF::Builder::ExElement;
use SWF::Builder;

our $VERSION = '0.03';

sub _init_character {
    my $self = shift;

    $self->{ID} = SWF::Element::ID->new;
    $self->{_depends} = {};
    $self->{_parent} = undef;
    $self->{_root} = undef;
    $self->{_export_name} = undef;
}

sub name {
    my ($self, $name) = @_;

    if (defined $name) {
	my $rname = $name;
	croak "Can't rename the character which has been already exported as '".$self->{_export_name}."'" if defined $self->{_export_name};
	utf2bin($name);
	$self->{_root}->_depends($self, 1);
	$self->{_export_name} = $name;
	return $rname;
    } else {
	unless (defined $self->{_export_name}) {
	    if ($self->{_root}{_auto_namer}) {
		$name = join('', $self =~ /Character::([^:]+)::.+\(0x(.+)\)$/);
		$self->{_root}{_names}{$name} = $self;
		$self->{_root}->_depends($self, 1);
		$self->{_export_name} = $name;
	    } else {
		croak "Can't get the name of the character";
	    }
	} else {
	    my $rname = $self->{_export_name};
	    bin2utf($rname);
	    return $rname;
	}
    }
}

*export_asset = \&name;

sub pack {
    my ($self, $stream) = @_;

    return if $self->{ID}->defined;
    for my $dep (values %{$self->{_depends}}) {
	$dep->pack($stream) unless $dep->{ID}->defined;
    }

    if ($self->{_root}) {
	$self->{ID}->configure($self->get_ID);
    } else {
	croak "Character ID need to be initialized to pack" unless $self->{ID}->defined;
    }

    $self->_pack($stream);

    if (defined $self->{_export_name}) {
      SWF::Element::Tag::ExportAssets->new
	  ( Assets => [[ ID => $self->{ID}, Name => $self->{_export_name}]]
	    )->pack($stream);
    }
}

sub get_ID {
    shift->{_root}{_ID_seed}++;
}

sub _depends {
    my ($self, $char) = @_;

    $self->{_depends}{$char} = $char;
}

sub _destroy {
    %{+shift} = ();
}

####

package SWF::Builder::Character::Displayable;

@SWF::Builder::Character::Displayable::ISA = qw/SWF::Builder::Character/;

use Carp;

sub _search_sibling {
    my ($parent, $ref) = @_;
    my $p;

    while(exists $ref->{_parent}) {
	$p = $ref->{_parent};
	return $ref if $p eq $parent;
	$ref = $p;
    }
    return undef;
}

sub place {
    my ($self, %param) = @_;

    my $parent = $param{MovieClip} || $param{MC} || $param{clip_with} || $self->{_parent} or croak "Can't get the movieclip to place";
    if ($parent eq '_root') {
	$parent = $self->{_root};
    } elsif (ref($parent) eq 'SWF::Builder') {
	$parent = $parent->{_root};
    }
    croak "The item can be placed only on the movie which defines it" if $parent->{_root} != $self->{_root};

    my $frame = $param{Frame} || 1;

    $parent->_depends($self, $frame);

    my $disp_i = 
	bless {
	    _parent        => $parent,
	    _root          => $self->{_root},
	    _first_frame   => $frame,
	    _last_frame_offset
		           => 2**64,
	    _current_frame => $frame,
	    _obj           => $self,
	    _tags          => [],
	}, 'SWF::Builder::DisplayInstance';

    push @{$self->{_root}{_to_destroy}}, $disp_i;

    my $depth;

    if (exists $param{below}) {
	my $refitem = _search_sibling($parent, $param{below}) or croak "Can't place the item below what on the different movieclip";
	$depth = SWF::Builder::Depth->new($disp_i, $refitem->{_depth}{_lower});
    } elsif (exists $param{above}) {
	my $refitem = _search_sibling($parent, $param{above}) or croak "Can't place the item above what on the different movieclip";
	$depth = SWF::Builder::Depth->new($disp_i, $refitem->{_depth});
    } else {
	$depth = SWF::Builder::Depth->new($disp_i, $parent->{_depth_list}{_lower});
    }

    $disp_i->{_depth} = $depth;
    $disp_i->frame($frame);
    $disp_i->{_current_frame} = $frame;
    $disp_i;
}

####

package SWF::Builder::Character::UsableAsMask;

@SWF::Builder::Character::UsableAsMask::ISA = qw/SWF::Builder::Character::Displayable/;

sub place_as_mask {
    my $self = shift;

    my $disp_i = $self->place(@_);
    bless $disp_i, 'SWF::Builder::MaskInstance';
    bless $disp_i->{_depth}, 'SWF::Builder::MaskDepth';
    $disp_i->{_clipdepth} = SWF::Element::Depth->new(0);
    $disp_i->{_frame_list} = $disp_i->{_parent}{_frame_list};
    $disp_i->{_depth_list} = SWF::Builder::Depth->new($disp_i);
    $disp_i->{_depends} = {};
    $disp_i->frame($disp_i->{_first_frame});
    $disp_i->{_current_frame} = $disp_i->{_first_frame};
    $disp_i;
}


####

package SWF::Builder::Character::Imported;

@SWF::Builder::Character::Imported::ISA = qw/SWF::Builder::Character/;

use Carp;

sub new {
    my ($class, $url, $name, $type) = @_;

    $type ||= 'MovieClip';
    $class = "SWF::Builder::Character::${type}::Imported";

    my $self = bless {
	_url => $url,
	_name => $name,
	}, $class;

    eval "require SWF::Builder::Character::$type";
    croak "Can't import character type '$type'" unless UNIVERSAL::can($class, '_init_character');
    $self->_init_character;
    $self;
}

sub _pack {
    my ($self, $stream) = @_;

  SWF::Element::Tag::ImportAssets->new
      ( URL    => $self->{_url},
	Assets => [[ID => $self->{ID}, Name => $self->{_name}]]
	)->pack($stream);

}

####

package SWF::Builder::DisplayInstance;

use Carp;
use SWF::Builder::ExElement;

sub frame {
    my ($self, $frame) = @_;
    my $frametag;

    my $frame_offset = $frame - $self->{_first_frame};

    unless (defined($self->{_tags}[$frame_offset])) {
	croak "The frame $frame is out of range" if $frame_offset < 0 or $frame_offset >= $self->{_last_frame_offset};
	$frametag = bless {
	    _parent => $self,
	    _frame_offset => $frame_offset,
	    _tag => 
	      SWF::Element::Tag::PlaceObject2->new
		  ( Depth => $self->{_depth}{_depth} ),
	      }, 'SWF::Builder::DisplayInstance::Frame';
	$self->{_tags}[$frame_offset] = $frametag;
	push @{$self->{_parent}{_frame_list}[$frame-1]}, $frametag;	
	if ($frame_offset == 0) {
	    $frametag->{_tag}->CharacterID($self->{_obj}{ID});
	} else {
	    $frametag->{_tag}->PlaceFlagMove(1);
	}
    } else {
	$frametag = $self->{_tags}[$frame_offset];
    }
    $self->{_current_frame} = $frame+1;
    $frametag;
}

sub name {
    my ($self, $name) = @_;
    my $tag = $self->{_tags}[0]{_tag};
    if (defined $name) {
	my $rname = $name;
	croak "Can't rename the display instance, which is already named as '".$self->Name."'" if $tag->Name->defined;
	utf2bin($name);
	$tag->Name($name);
	return $rname;
    } else {
	unless ($tag->Name->defined) {
	    if ($self->{_root}{_auto_namer}) { 
		($name) = ($self =~ /\(0x(.+)\)$/);
		$name = "DI$name";
		$self->{_root}{_names}{$name} = $self;
		$tag->Name($name);
	    } else {
		croak "Can't get the name of the display instance";
	    }
	} else {
	    my $rname = $tag->Name;
	    bin2utf($rname);
	    return $rname;
	}
    }
}

sub AUTOLOAD {
    my $self = shift;
    my ($name, $class);
    my $sub = $SWF::Builder::DisplayInstance::AUTOLOAD;

    return if $sub =~/::DESTROY$/;
    $sub =~ s/.+:://;
    croak "Can't locate object method \"$sub\" via package \"".ref($self).'" (perhaps you forgot to load "'.ref($self).'"?)' unless SWF::Builder::DisplayInstance::Frame->can($sub);
    $self->frame($self->{_current_frame})->$sub(@_);
}

sub _destroy {
    %{+shift} = ();
}
####

package SWF::Builder::DisplayInstance::Frame;

use Carp;

sub scale {
    my $self = shift;

    $self->matrix->scale(@_);
    $self;
}

sub moveto {
    my $self = shift;
    $self->matrix->moveto($_[0]*20, $_[1]*20);
    $self;
}

sub r_moveto {
    my ($self, $to_rx, $to_ry) = @_;

    my $m = $self->matrix;
    $m->moveto($m->TranslateX + $to_rx*20, $m->TranslateY + $to_ry*20);
    $self;
}

sub rotate {
    my ($self, $r) = @_;

    $self->matrix->rotate($r);
    $self;
}

sub reset {
    my $self = shift;
    my $m = $self->matrix;
    $m->ScaleX(1);
    $m->ScaleY(1);
    $m->RotateSkew0(0);
    $m->RotateSkew1(0);
    $self;
}

sub remove {
    my $self = shift;
    my $parent = $self->{_parent};

    croak "This DisplayInstance has already set to remove " if ($parent->{_last_frame_offset} < 2**64);

    $self->{_tag} = SWF::Element::Tag::RemoveObject2->new( Depth => $parent->{_depth}{_depth} );
    $parent->{_last_frame_offset} = $self->{_frame_offset};
    $self;
}

sub frame_action {
    my $self = shift;

    $self->{_parent}{_parent}->frame_action($self->{_parent}{_first_frame}+$self->{_frame_offset});
}

sub frame_label {
    my $self = shift;

    $self->{_parent}{_parent}->frame_label($self->{_parent}{_first_frame}+$self->{_frame_offset}, @_);
}

sub ratio {
    my ($self, $ratio) = @_;
    $self->{_tag}->Ratio($ratio);
    $self;
}

sub matrix {
    my $self = shift;
    my $tag = $self->{_tag};

    unless ($tag->Matrix->defined) {
	my $ptags = $self->{_parent}{_tags};
	my $frame_offset = $self->{_frame_offset};
	$frame_offset-- until ($frame_offset == 0 or defined $ptags->[$frame_offset] and $ptags->[$frame_offset]{_tag}->Matrix->defined);
	$tag->Matrix($ptags->[$frame_offset]{_tag}->Matrix->clone);
    }
    $tag->Matrix;
}

sub pack {
    my ($self, $stream) = @_;

    $self->{_tag}->pack($stream);
}

####

package SWF::Builder::MaskInstance;

@SWF::Builder::MaskInstance::ISA = qw/ SWF::Builder::DisplayInstance /;

sub _depends {
    my $self = shift;

    $self->{_parent}->_depends(@_);
}

sub frame {
    my $self = shift;

    my $frametag = $self->SUPER::frame(@_);
    $frametag->{_tag}->ClipDepth($self->{_clipdepth});
    $frametag;
}

#####

package SWF::Builder::MaskDepth;

@SWF::Builder::MaskDepth::ISA = qw/ SWF::Builder::Depth /;

sub set_depth {
    my ($self, $n) = @_;

    $self->{_depth}->configure($n++);
    my $depth_list = $self->{_parent}{_depth_list};
    my $depth = $depth_list->{_upper};
    while ($depth != $depth_list) {
	$n = $depth->set_depth($n);
	$depth = $depth->{_upper};
    }
    $self->{_parent}{_clipdepth}->configure($n-1);
    $n;
}


1;

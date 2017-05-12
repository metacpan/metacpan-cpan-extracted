package SWF::Builder::ActionScript;

use strict;

use Carp;
use SWF::Element;
use SWF::Builder;
use SWF::Builder::ExElement;

our $VERSION = "0.041";

sub new {
    my ($class, %param) = @_;
    bless {
	_version => $param{Version}||6,
	_actions => SWF::Element::Array::ACTIONRECORDARRAY->new,
    }, $class;
}

sub _add_tags {
    my $self = shift;
    my $actions = $self->{_actions};

    if ($actions->[-1] and $actions->[-1]->Tag == 0) {
	if (my $label = pop(@$actions)->LocalLabel) {
	    push @$actions, SWF::Element::ACTIONRECORD->new( 'Tag', @{+shift}, LocalLabel => $label );
	}
    }
    push @$actions, map { SWF::Element::ACTIONRECORD->new( 'Tag', @$_)} @_;
    $self;
}

sub _adata {
  SWF::Element::ACTIONDATA->new(@_);
}

sub _get_type {
    my $value = shift;

    if ($value =~ /^\d+$/) {
	return 'Integer';
    } elsif ($value =~ /^[+-]?(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	return 'Double';
    } else {
	return 'String';
    }
}

sub tellTarget {
    my ($self, $target, $code) = @_;

    if (UNIVERSAL::isa($target, 'SWF::Builder::DisplayInstance')) {
	$target = $target->name;
    }
    utf2bin($target);
    $self->_add_tags( [ 'SetTarget', TargetName => $target ] );
    &$code($self);
    $self->_add_tags( [ 'SetTarget', TargetName => '' ] );
}

sub gotoAndPlay {
    &gotoAndStop;
    shift->_add_tags( ['Play'] );
}

sub gotoAndStop {
    my ($self, $frame) = @_;

    if ($frame =~ /^\d+$/) {
	$self->_add_tags( [ 'GotoFrame', Frame => $frame-1 ] );
    } else {
	utf2bin($frame);
	$self->_add_tags( [ 'GotoLabel', Label => $frame ] );
    }
}

sub play {
    shift->_add_tags( ['Play'] );
}

sub stop {
    shift->_add_tags( ['Stop'] );
}

sub setProperty {
    my ($self, $property, $value) = @_;

    utf2bin($value);
    $self->_add_tags
	( [ 'Push', 
	    DataList => [ _adata( String => '' ),
			  _adata( Property => $property ),
			  _adata( _get_type($value) => $value ),
			  ],
	    ],
	  [ 'SetProperty' ],
	  );
}

sub calcProperty {
    my ($self, $property, $op, $value) = @_;

    utf2bin($value);
    $self->_add_tags
	( [ 'Push', 
	    DataList => [ _adata( String => '' ),
			  _adata( Property => $property ),
			  _adata( String => '' ),
			  _adata( Property => $property ),
			  ],
	    ],
	  [ 'GetProperty' ],
	  [ 'Push', 
	    DataList => [ _adata( _get_type($value) => $value ),
			  ],
	    ],
	  [ $op ],
	  [ 'SetProperty' ],
	  );
}


sub moveto {
    my ($self, $x, $y) = @_;

    $self->setProperty('_x', $x);
    $self->setProperty('_y', $y);
}

sub r_moveto {
    my ($self, $x, $y) = @_;

    $self->calcProperty('_x', 'Add2', $x);
    $self->calcProperty('_y', 'Add2', $y);
}

sub rotate {
    my ($self, $r) = @_;

    $self->setProperty('_rotation', $r);
}

sub r_rotate {
    my ($self, $r) = @_;

    $self->calcProperty('_rotation', 'Add2', $r);
}

sub scale {
    my ($self, $xscale, $yscale) = @_;

    $yscale ||= $xscale;
    $self->setProperty('_xscale', $xscale);
    $self->setProperty('_yscale', $yscale);
}

sub show {
    shift->setProperty('_visible', 1);
}

sub hide {
    shift->setProperty('_visible', 0);
}



# compiler

sub compile {
    require SWF::Builder::ActionScript::Compiler;

    my $self = shift;
    my $c = SWF::Builder::ActionScript::Compiler->new(@_, Version => $self->{_version});

    $c->compile($self->{_actions});
}

sub load {
    my $self = shift;
    my $file = shift;

    open my $f, '<', $file;
    select((select($f), undef $/)[0]);
    $self->compile(<$f>, @_);
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SWF::Builder::ActionScript - SWF ActionScript object.

=head1 SYNOPSIS

  $mc->frame_action(1)->compile( <<AS_END );
    function move_mc(dx) {
        this._x += dx;
    }
  AS_END

  my $mc_i = $mc->place;
  $mc_i->on('KeyPress', '<Left>')->compile('move_mc(-5)');
  $mc_i->on('KeyPress', '<Right>')->compile('move_mc(5)');
  $mc_i->on('EnterFrame')->r_rotate(15);

=head1 DESCRIPTION

L<SWF::Builder::ActionScript> supports some simple actions and compiling 
ActionScript compatible with FlashMX. 

=head2 Constructors

Methods for movie clip to create a frame action and a clip action.
These return an SWF::Builder::ActionSctipt object.

=over 4

=item $as = $mc->frame_action( $frame )

creates a frame action.

=item $as = $mc_i->on/onClipEvent( $event [, $key] )

creates a clip action. See L<SWF::Builder::MovieClip> for details of the events.

=back

=head2 Simple actions

These method add some simple actions to $as and return $as itself.

=over 4

=item $as->gotoAndPlay( $frame )

tells the flash player to go to $frame.

=item $as->gotoAndStop( $frame )

tells the flash player to go to $frame and stop playing.

=item $as->play

tells the flash player to play the movie clip.

=item $as->stop

tells the flash player to stop playing the movie clip.

=item $as->setProperty( $property, $value )

sets a movie clip property.

=item $as->moveto( $x, $y )

moves the movie clip to ($x, $y).

=item $as->r_moveto( $dx, $dy )

moves the movie clip to (current X + $dx, current Y + $dy).

=item $as->rotate( $r )

rotates the movie clip toward $r degree absolutely.

=item $as->r_rotate( $dr )

rotates the movie clip to +$dr degree right.

=item $as->scale( $xscale [, $yscale] )

magnifies/reduces the movie clip.

=item $as->show

shows the movie clip.

=item $as->hide

hides the movie clip.

=item $as->tellTarget( $target, \&actionsub )

changes the target movie clip for actions in &actionsub.
$target is a target path string in slash syntax.
&actionsub is called with an ActionScript object whose target is changed.
For example,

  $mc_i->on('Press')->tellTarget( 'mc_i2', sub {
      shift->r_rotate(15);
  });

rotates 'mc_i2' to 15-degree right when $mc_i is clicked.

=back

=head2 Compiler

L<SWF::Builder::ActionScript> has a FlashMX-compatible compiler 
for complex actions.

=over 4

=item $as->compile( $script_text [, %options] )

compiles $script_text.
Options are as follows:

=over 4

=item Optimize => $opt_string

controls optimization. 
Optimize option strings are as follows:

 O_PEEPHOLE  peephole optimization.
 O_CONSTEXP  calculate constant expressions.
 O_CONSTMATH calculate math funcions with constant args and constant properties.
 O_LEFTONCE  evaluate a lefthand side of an assignment expression only once. See ATTENTION.
 O_REGISTER  assign local variables to registers.
 O_LOCALREG  assign local variables to local registers using ActionDefineFunction2 (aka 'Optimize for Flash Player 6r65').
 O_6R65      same as 'O_LOCALREG'.
 O_ALL       enable all optimize options.

If you want to reset an optimize option, put a minus sign on the head of the option. 
All optimize options are joined with space or '|'.
Default is 'O_ALL|-O_REGISTER|-O_LOCALREG' (enable all optimize options except O_REGISTER and O_LOCALREG).

ATTENTION: FlashMX ActionScript compiler seems to evaluate a lefthand
side of a compound assignment operator twice, while ECMA-262 provides
to evaluate it once.
For example, FlashMX compiles 'a[i++] += 2' as same as 'a[i++] = a[i++] + 2',
which counts up i twice.
O_LEFTONCE controls this. If you want the same as FlashMX, give '-O_LEFTONCE'.

=item Trace => $mode

tells the compiler how to compile 'trace' action.

=over 4

=item 'none'

ignore all trace action.

=item 'eval'

evaluate the parameters of a trace action, but don't output anything.
This is default.

=item 'lcwin'

output the value to another movie via a LocalConnection.
You can use 'tracewindow.swf' at scripts directory as output window.

=item 'trace'

use ActionTrace tag.

=back

=item Warning => $level

sets the warning level.

 0: deplicated actions.
 1: useless operator in void context.
 2: future reserved and other unsupported features.

=back

=item $as->load( $script_filename [, %options] )

loads a script and compiles it.
See compile method for %options.

=back

=head3 Compiler bugs/features

Pragmas are not supported.

The compiler evaluates a lefthand side of an assignment expression once
by default. See Optimize option.

Slow...

=head1 COPYRIGHT

Copyright 2003 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

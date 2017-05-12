
# Button - mouse clickable surfaces

package SDL::App::FPS::Button;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use SDL::App::FPS::Thingy;
use vars qw/@ISA @EXPORT_OK $VERSION/;
@ISA = qw/SDL::App::FPS::Thingy Exporter/;

use SDL::Event;
use SDL::Constants;

$VERSION = '0.02';

@EXPORT_OK = qw/ 
  BUTTON_IN
  BUTTON_OUT
  BUTTON_HOVER
  BUTTON_PRESSED
  BUTTON_DOWN
  BUTTON_RELEASED
  BUTTON_UP
  BUTTON_CLICK

  BUTTON_RECTANGULAR
  BUTTON_ELLIPTIC

  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_RIGHT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_WHEEL_UP
  BUTTON_MOUSE_WHEEL_DOWN
  /;

sub BUTTON_IN () 	{ 1; }
sub BUTTON_OUT () 	{ 2; }
sub BUTTON_HOVER () 	{ 4; }
sub BUTTON_PRESSED () 	{ 8; }
sub BUTTON_DOWN () 	{ 8; }
sub BUTTON_RELEASED () 	{ 16; }
sub BUTTON_UP () 	{ 16; }
sub BUTTON_CLICK ()	{ 32; }

sub BUTTON_RECTANGULAR ()	{ 0; }
sub BUTTON_ELLIPTIC ()		{ 1; }

sub BUTTON_MOUSE_LEFT ()	{  1; }
sub BUTTON_MOUSE_RIGHT ()	{  4; }
sub BUTTON_MOUSE_MIDDLE ()	{  2; }
sub BUTTON_MOUSE_WHEEL_UP ()    {  8; }
sub BUTTON_MOUSE_WHEEL_DOWN ()  { 16; }

sub _init
  {
  my $self = shift;

  my ($x,$y,$w,$h,$type,$shape,$button,$callback,@args) = @_;

  $self->{x} = abs($x); 
  $self->{y} = abs($y); 
  $self->{w} = abs($w) || 1; 
  $self->{h} = abs($h) || 1; 
  $self->{type} = abs($type || 1);
  $self->{shape} = abs($shape || 0) & 1;		# 0 or 1
  $self->{button} = abs($button || 0);

  $self->{callback} = $callback;
  if ($self->{shape} == BUTTON_ELLIPTIC)
    {
    $self->{hit} = \&_hit_elliptic;
    $self->{r2} = $self->{w} * $self->{h};
    }
  else
    {
    $self->{hit} = \&_hit_rect;
    $self->{x1} = $self->{x} - int($self->{w} / 2); 
    $self->{y1} = $self->{y} - int($self->{h} / 2); 
    $self->{x2} = $self->{x} + int($self->{w} / 2); 
    $self->{y2} = $self->{y} + int($self->{h} / 2); 
    }

  if (($self->{type} & BUTTON_CLICK) != 0)
    {
    $self->{click_event_state} = 0;			# reset state
    }
  if (($self->{type} & BUTTON_OUT) != 0)
    {
    $self->{out_event_state} = 0;			# reset state (is out)
    }
  if (($self->{type} & BUTTON_IN) != 0)
    {
    $self->{in_event_state} = 1;			# reset state (is out)
    }

  $self->{args} = [ @args ];
  $self;
  }

sub resize ($$$)
  {
  # set a new w and h of the area
  my ($self,$w,$h) = @_;

  $self->{w} = abs($w); 
  $self->{h} = abs($h); 
  $self->{x1} = $self->{x} - int($self->{w} / 2); 
  $self->{y1} = $self->{y} - int($self->{h} / 2); 
  $self->{x2} = $self->{x} + int($self->{w} / 2); 
  $self->{y2} = $self->{y} + int($self->{h} / 2); 
  $self;
  }

sub move_to ($$$)
  {
  # set a new x and y of the area
  my ($self,$x,$y) = @_;

  $self->{x} = int(abs($x)); 
  $self->{y} = int(abs($y)); 
  $self->{x1} = $self->{x} - int($self->{w} / 2); 
  $self->{y1} = $self->{y} - int($self->{h} / 2); 
  $self->{x2} = $self->{x} + int($self->{w} / 2); 
  $self->{y2} = $self->{y} + int($self->{h} / 2); 
  $self;
  }

sub x ($$)
  {
  my $self = shift;
  if (@_ > 0)
    {
    $self->{x} = abs(shift); 
    $self->{x1} = $self->{x} - int($self->{w} / 2); 
    $self->{x2} = $self->{x} + int($self->{w} / 2); 
    }
  $self->{x}; 
  }

sub y ($$)
  {
  my $self = shift;
  if (@_ > 0)
    {
    $self->{y} = abs(shift); 
    $self->{y1} = $self->{y} - int($self->{h} / 2); 
    $self->{y2} = $self->{y} + int($self->{h} / 2); 
    }
  $self->{y}; 
  }

sub width ($$)
  {
  my $self = shift;
  if (@_ > 0)
    {
    $self->{w} = abs(shift) || 1; 
    $self->{x1} = $self->{x} - int($self->{w} / 2); 
    $self->{x2} = $self->{x} + int($self->{w} / 2); 
    }
  $self->{w}; 
  }

sub height ($$)
  {
  my $self = shift;
  if (@_ > 0)
    {
    $self->{h} = abs(shift) || 1; 
    $self->{y1} = $self->{y} - int($self->{h} / 2); 
    $self->{y2} = $self->{y} + int($self->{h} / 2); 
    }
  $self->{h}; 
  }

sub _hit_rect ($$$)
  {
  # given an x and y coordinates, returns true whether the point x,y is inside
  # the area
  my ($self,$x,$y) = @_;

  1 - ((($x < $self->{x1}) || ($x > $self->{x2}) ||
   ($y < $self->{y1}) || ($y > $self->{y2})) <=> 0);
  }

sub _hit_elliptic ($$$)
  {
  # given an x and y coordinates, returns true whether the point x,y is inside
  # the area
  my ($self,$x,$y) = @_;

  my $xdiff = $self->{x} - $x; $xdiff *= $xdiff;
  my $ydiff = $self->{y} - $y; $ydiff *= $ydiff;

  ($xdiff + $ydiff <= $self->{r2}) <=> 0;
  }

sub check ($$$)
  {
  # check whether the event occured in our area or not
  my ($self,$event,$type) = @_;

  return unless $self->{active};

  my $callback = $self->{callback}; 

  return unless defined $callback;	# no callback given

  # one of the "click" watcher?
  if (($self->{type} & (BUTTON_CLICK+BUTTON_UP+BUTTON_DOWN)) != 0)
    {
    # yes, and we ignore mouse motion events
    return unless $type == SDL_MOUSEBUTTONUP || $type == SDL_MOUSEBUTTONDOWN;
    # check that the required button was pressed
    my $button = $event->button();
    return unless ($button & $self->{button}) != 0;
    }
  else
    {
    # no, one of the motion watchers and these ignore clicks
    return if $type == SDL_MOUSEBUTTONUP || $type == SDL_MOUSEBUTTONDOWN;
    }

  # so we now know this event is important for us

  # check whether mouse is inside or outside
  my $x = $event->motion_x();  
  my $y = $event->motion_y();  
  my $hit = &{$self->{hit}}($self,$x,$y);

  my $call = 0;						# don't callback

  if ($hit)
    {
    # ptr inside area

    # BUTTON_CLICK events (these care only about hits):
  
    if (($self->{type} & BUTTON_CLICK) != 0)
      {
      if (($self->{click_event_state} == 0) && ($type == SDL_MOUSEBUTTONDOWN))
        {
        $self->{click_event_state} ++;
        }
      if (($self->{click_event_state} == 1) && ($type == SDL_MOUSEBUTTONUP))
        {
        # first down, now up => callback
        $call = 1;					# do callback
        $self->{click_event_state} = 0;			# reset state
        }
      }

    # BUTTON_UP events
    if ((($self->{type} & BUTTON_UP) != 0) && ($type == SDL_MOUSEBUTTONUP))
      {
      $call = 1;					# do callback
      }
    
    # BUTTON_DOWN events
    if ((($self->{type} & BUTTON_DOWN) != 0) && ($type == SDL_MOUSEBUTTONDOWN))
      {
      $call = 1;					# do callback
      }

    # BUTTON_HOVER events
    if ((($self->{type} & BUTTON_HOVER) != 0))
      {
      $call = 1;					# do callback
      }
    
    # BUTTON_OUT events
    if ((($self->{type} & BUTTON_OUT) != 0))
      {
      $self->{out_event_state} = 1;			# ptr now inside
      }
    
    # BUTTON_IN events
    if ((($self->{type} & BUTTON_IN) != 0))
      {
      if ($self->{in_event_state} != 0)			# last outside?
        {
        $self->{in_event_state} = 0;			# reset state
        $call = 1;					# do callback
        }
      }

    }
  else
    {
    # ptr outside area

    # BUTTON_OUT events
    if ((($self->{type} & BUTTON_OUT) != 0))
      {
      if ($self->{out_event_state} != 0)		# last inside?
        {
        $self->{out_event_state} = 0;			# reset state
        $call = 1;					# do callback
        }
      }

    # BUTTON_IN events
    if ((($self->{type} & BUTTON_IN) != 0))
      {
      $self->{in_event_state} = 1;			# ptr now outside
      }
    }

  &{$callback}($self->{app},$self,@{$self->{args}}) if $call != 0;
  }

1;

__END__

=pod

=head1 NAME

SDL::App::FPS::Button - a clickable area (aka button) for SDL::App::FPS

=head1 SYNOPSIS

	use SDL::FPS::App;
	use SDL::FPS::App::Button;

	$app = SDL::FPS::App->new( ... );
	
	my $button = $app->add_button( $x,$y,$w,$h,
	  BUTTON_CLICK, BUTTON_RECTANGULAR, BUTTON_MOUSE_LEFT, sub { ... } );

=head1 EXPORTS

Exports on request the following symbols:

Event types:

  BUTTON_IN
  BUTTON_OUT
  BUTTON_HOVER
  BUTTON_DOWN
  BUTTON_UP
  BUTTON_CLICK

Button shapes:

  BUTTON_RECTANGULAR
  BUTTON_ELLIPTIC

Mouse button types:

  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_RIGHT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_WHEEL_DOWN
  BUTTON_MOUSE_WHEEL_UP
  BUTTON_MOUSE_MIDDLE

=head1 DESCRIPTION

This package provides a class for rectangular, elliptic or round 'clickable'
areas, which you can use as buttons.

Each of these buttons will watch for C<SDL_MOUSEMOVED>, C<SDL_MOUSEBUTTONUP>
and C<SDL_MOUSEBUTTONDOWND> events and when they occured, call the
corrosponding callback function.

=head1 CALLBACK

Once the specific event occurs, the given callback code (CODE ref) is called
with the following parameters:

	&{$callback}($self,$button,@arguments);

C<$self> is the app the object resides in (e.g. the object of type
SDL::App::FPS), C<$button> is the button itself, and the additional arguments
are whatever was passed when new() was called.

=head1 METHODS

=over 2

=item new()

	my $button = SDL::App::FPS::Button->new(
		$app,$x,$y,$w,$h,$type,$button,$shape,$callback,@args);

Creates a new button, and registers it with the application C<$app>.
C<$type> is one of the following event types:

	BUTTON_IN	 The mouse was moved from the outside to the
			 inside the area, happens only when the mouse
			 crossed the border from outside to inside
	BUTTON_OUT	 Like BUTTON_IN, but in the other direction
	BUTTON_HOVER	 Happens whenever the mouse is moved and the
			 pointers final position is inside the area
			 In most cases you want to use BUTTON_IN instead
	BUTTON_DOWN	 A mouse button was pressed inside the area
	BUTTON_UP	 A mouse button was released inside the area
	BUTTON_CLICK	 A mouse button was pressed inside the area and
			 then released again inside the area

The last type gives a user a chance to move the mouse pointer out of the area
while holding it pressed and so prevent the callback from happening.

You can use C<||> or C<+> add them together, the callback will then happen
when any one of these events occured:

	my $button = SDL::App::FPS::Button->new(
		$app,$x,$y,$w,$h,BUTTON_DOWN+BUTTON_UP,
		$button,$shape,$callback,@args);

Please note that for a single click inside the area, both pressed and
released events will occur, resulting in the callback being called twice.

For types BUTTON_IN, BUTTON_OUT and BUTTON_HOVER, the C<$button> argument
will be ignored.

The C<$button> argument is one of the three mouse buttons BUTTON_MOUSE_LEFT,
BUTTON_MOUSE_RIGHT or BUTTON_MOUSE_MIDDLE. You can add them together to
trigger the callback for more than one button, like:
	
	my $button = SDL::App::FPS::Button->new(
		$app,$x,$y,$w,$h,BUTTON_CLICK,
		BUTTON_MOUSE_LEFT+BUTTON_MOUSE_RIGHT,
		$shape,$callback,@args);

C<$shape> is one of the two BUTTON_RECTANGULAR or BUTTON_ELLIPTIC shapes.

=item move_to()

	$button->move_to($x,$y);

Move the button center to the new coordinates $x and $y.

=item resize()

	$button->resize($w,$h);

Resize the button's width and height to C<$w> and C<$h>.

=item is_active()

	if ($button->is_active())
	  {
	  ...
	  }

Returns true if the button is active.

=item deactivate()

	$button->deactivate();

Deactivate the button. It will no longer respond to mouse clicks.

=item activate()

	$button->activate();

Re-activate the button. It will now again respond to mouse clicks.

=item hit()

	$button->hit($x,$y);

Returns true if the point $x,$y is inside the button area.

=item id()

	$group->id();

Returns the ID of the group itself.

=item x()

	$button->x(8);
	if ($button->x() < 78)
	  {
	  ...
	  }

Get/set the button's x coordinate.

=item y()

	$button->y(1);
	if ($button->y() < 28)
	  {
	  ...
	  }

Get/set the button's y coordinate.

=item width()

	$button->width(1);
	if ($button->width() < 28)
	  {
	  ...
	  }

Get/set the button's width (aka size in X direction).

=item height()

	$button->height(1);
	if ($button->height() < 28)
	  {
	  ...
	  }

Get/set the button's height (aka size in Y direction).

=back

=head1 BUGS

None known yet.

=head1 AUTHORS

(c) 2002, 2003 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut


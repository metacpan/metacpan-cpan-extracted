
# represents the playfield for the Boulder game

package SDL::App::FPS::MyCave;

# (C) 2002 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS;
use SDL::App::FPS::Color qw/
 BLACK RED GREEN WHITE BLUE GRAY DARKGRAY LIGHTGRAY YELLOW BROWN
 darken
  /;

##############################################################################

sub new
  {
  my ($class) = shift;
  my $self = {};

  $self->{w} = 76;
  $self->{h} = 25;
  $self->{screen_x} = 55;
  $self->{screen_y} = 10;
  $self->{screen_w} = 570;
  $self->{screen_h} = 460;
  $self->{fields_x} = 38;
  $self->{fields_y} = 20;
  $self->{ofs_x} = 0;
  $self->{ofs_y} = 0;
  $self->{rect} = SDL::Rect->new();
  $self->{self} = shift;
  $self->{app} = $self->{self}->app();
  $self->{guy_x} = 1;
  $self->{guy_y} = 3;
  $self->{fall_time} = 450;
  $self->{free_fall_time} = 200;
  $self->{last_fall} = $self->{self}->current_time();	
  
  $self->{color} = { 
   '#' => BROWN, ' ' => BLACK, '+' => WHITE, 'R' => DARKGRAY, 'O' => LIGHTGRAY,
   'W' => BLUE,
   'G' => YELLOW,
   'E' => RED,
   };
  
  $self->{fw} = $self->{screen_w} / $self->{fields_x};
  $self->{fh} = $self->{screen_h} / $self->{fields_y};
 
  # init playfield with rocks and set a fog
  $self->{playfield} = [ ];
  $self->{fog} = [ ];
  for (my $y = 0; $y < $self->{h}; $y++)
    {
    $self->{playfield}->[$y] = [];
    $self->{fog}->[$y] = [];
    for (my $x = 0; $x < $self->{w}; $x++)
      {
      $self->{playfield}->[$y]->[$x] = 'R';
      $self->{fog}->[$y]->[$x] = 0;		# never seen
      }
    }

  my $text = [ 
'## ####+#########RRRRRRRRRRRRR#############################################',
'#    O############WW##WW####RRRR##########################################',
'G        ###########WWWWWWW######RRRR#####################################',
'### ######O#########WWW#########RRRROO####################################',
'###  ####O O#######WWWWO#########RRRRRO###################################',
'#### ###O#+######WWWWWRRRRRRRRRRRR#OORR###################################',
'#### #######O##WWWWWWRRRRR####RRRRRRO#R###################################',
'#### ###   #####WWWWWWWRRRRR##############################################',
'#### ###O##   ##RRORRRWRRRRRRR######RRRR#RRRR##R##########################',
'#### # OO############RRRRRRR#######R#####R###R#R##########################',
'####          RRRR####RRRRRRR#######RRR##R###R#R######RRRRR###############',
'#######  ######R## ####################R#R###R#R##########################',
'######   ######RRR R#####RRRR######RRRR##RRRR##RRRRR######################',
'####   #######R### #####RRRR##############################################',
'######    ###RRR## ####RRRRRRRR##########RRRR##RRRRR#RRRR##R##############',
'######    ####RRR# ###RRRRRRRR###########R###R#R#####R###R#R##############',
'####    ####RRR### ##RRR#####O###########RRRR##RRRR##RRRR##R##############',
'####  #  #####RR## ####RRROO#############R#####R#####R#R###R##############',
'#####    ###RRRRR# ####R#OO#O############R#####RRRRR#R##R##RRRRR##########',
'#############RRR## ######+RRRR############################################',
'##############RRR# ########R##############################################',
'############RRRR## ###R###RR############################################OO',
'##############RR## ##RRR#RRRRR###########################################E',
  ];
  bless $self, $class;
  my $y = 1;
  foreach my $line (@$text)
    {
    $self->_init_line($y++,$line);
    }

  $self->{need_draw} = 1;
  $self;
  }

sub _init_line
  {
  my ($self,$y,$line) = @_;

  my @fields = split//,$line;
  my $x = 1;
  foreach my $f (@fields)
    {
    $self->{playfield}->[$y]->[$x++] = $f;
    }
  }

sub _shade
  {
  # depending on how far the field from the guy is, return a darkening factor
  # also checks the fog buffer to see if we ever saw the field at all
  my ($self,$x,$y) = @_;

  my $xdist = ($x - $self->{guy_x});
  my $ydist = ($y - $self->{guy_y});
  my $dist = $xdist*$xdist + $ydist*$ydist;
  if ($dist > 100)
    {
    return 1 if $self->{fog}->[$y]->[$x] == 0;	# never seen and too far
    return 0.6;					# too far but already seen
    }
  $self->{fog}->[$y]->[$x] = 1;			# lift fog
  return sin(1.57*$dist/90) * 0.6;
  }

sub move
  {
  my ($self,$dir) = @_;

  my $x = $self->{guy_x};
  my $y = $self->{guy_y};
  my $xnew = $x+1;
  my $ynew = $y;
  # 0 => right, 1 down, 2 left, 3 up	
  if ($dir == 1)
    {
    $xnew = $x; $ynew = $y+1;
    }
  elsif ($dir == 2)
    {
    $xnew = $x-1;
    }
  elsif ($dir == 3)
    {
    $xnew = $x; $ynew = $y-1;
    }
  # outside the playfield?
  if (($xnew < 0) || ($ynew < 0) ||
   ($xnew > $self->{w}) || ($ynew > $self->{h}))
    {
    return;
    }
  my $can_move = 0; my $won = 0;
  # if targetfield == Earth
  my $target = $self->{playfield}->[$ynew]->[$xnew];
  if ($target eq '#')
    {
    # remove earth
    $target = ' '; $can_move = 1;
    # check for boulder above our head
    }
  elsif ($target eq ' ')
    {
    $can_move = 1;
    }
  elsif ($target eq 'E')
    {
    $can_move = 1; $won = 1;
    }
  elsif ($target eq '+')
    {
    $can_move = 1; $self->_pickup_diamond();
    }
  if ($can_move)
    {
    $self->{guy_x} = $xnew;
    $self->{guy_y} = $ynew;
    $self->{playfield}->[$y]->[$x] = ' ';
    $self->{playfield}->[$ynew]->[$xnew] = 'G';
    # if guy moved, check whether we must scroll the playfiled
    if ($xnew - $self->{ofs_x} < 5)
      {
      $self->{ofs_x}-- if ($self->{ofs_x} > 0)
      } 
    if ($ynew - $self->{ofs_y} < 5)
      {
      $self->{ofs_y}-- if ($self->{ofs_y} > 0)
      } 
    if ($self->{ofs_x} + $self->{fields_x} - $xnew < 5)
      {
      $self->{ofs_x}++ if ($self->{ofs_x} + $self->{fields_x} < $self->{w})
      } 
    if ($self->{ofs_y} + $self->{fields_y} - $ynew < 5)
      {
      $self->{ofs_y}++ if ($self->{ofs_y} + $self->{fields_y} < $self->{h})
      } 
    $self->{need_draw} = 1;
    }
  return $won;
  }

sub _pickup_diamond
  {
  my ($self) = shift;
  $self->{score} += 100;
  print "picked up diamond\n";
  }
  
sub _check_fall
  {
  my $self = shift;

  return if ($self->{self}->current_time() - $self->{last_fall}  < 550);
  $self->{last_fall} = $self->{self}->current_time();

  # check for flying objects and let them fall down
  for (my $y = $self->{h}-1; $y > 0; $y--)
    {
    for (my $x = 0; $x < $self->{w}; $x++)
      {
      $self->_check_under($x,$y)
       if $self->{playfield}->[$y]->[$x] =~ /^[O+W]$/;
      }
    }
  }

sub _check_under
  {
  # check whether a thing at the current field can fall down
  my ($self,$x,$y,$obj) = @_;

  # free fall? If yes (empty, water or guy), then setup a timer
  my $under = $self->{playfield}->[$y+1]->[$x];
  if ($under =~ /^[G W]/)
    {
    $self->_move_object($x,$y,$x,$y+1);
    }

  # figure out which side we could fall down

  my $left = $self->{playfield}->[$y]->[$x-1];		# #O <-- will not fall
							#  #
  $under = $self->{playfield}->[$y+1]->[$x-1];
  my $l = 0; $l = 1 if ($left =~ /^[G W]/ && $under =~ /^[G W]/);

  my $right = $self->{playfield}->[$y]->[$x+1];		# O# <-- will not fall
							# #
  $under = $self->{playfield}->[$y+1]->[$x+1];
  my $r = 0; $r = 1 if ($right =~ /^[G W]/ && $under =~ /^[G W]/);

  return 0 if $r+$l == 0;				# none
  
  my $select = 0;			# left
  if ($r+$l == 2)
    {
    # select one at random
    $select = 1 if rand() < 0.5;	# maybe right
    }
  else
    {
    # select whatever is free
    $select = 1 if $r == 1;		# leave select at left if $l == 1
    }
  
  if ($select == 0)
    {
    $self->_move_object($x,$y,$x-1,$y+1);
    } 
  else
    {
    $self->_move_object($x,$y,$x+1,$y+1);
    }
  }

sub _move_object
  {
  my ($self,$x,$y,$xnew,$ynew) = @_;

  my $object = $self->{playfield}->[$y]->[$x];
  my $under = $self->{playfield}->[$ynew]->[$xnew];
  $self->{playfield}->[$ynew]->[$xnew] = $object;
  $self->{playfield}->[$y]->[$x] = ' ';
  $self->{need_draw} = 1;
  if ($under eq 'G') 
    {
    if ($object eq 'O') { print "You were rocked!\n"; }#$self->{self}->quit(); }
    if ($object eq 'W') { print "You drowned!\n"; }#$self->{self}->quit(); }
    $self->_pickup_diamond() if $object eq '+';
    $self->{playfield}->[$ynew]->[$xnew] = 'G';
    }
  }

sub update
  {
  my ($self) = @_;

  $self->_check_fall();
  $self->draw() if $self->{need_draw} == 1;
  }

sub resize
  {
  my ($self,$w,$h) = @_;
  }

sub draw 
  {
  # draw the entire playfield to the screen
  my ($self) = @_;
  
  my $r = $self->{rect};
  $r->x ( $self->{screen_x});
  $r->y ( $self->{screen_y});
  $r->width ( $self->{screen_w} );
  $r->height ( $self->{screen_h} );
  $self->{app}->fill($r,BLACK);

  for (my $y = 0; $y < $self->{fields_y}; $y++)
    {
    for (my $x = 0; $x < $self->{fields_x}; $x++)
      {
      $self->_draw_field($x+$self->{ofs_x},$y+$self->{ofs_y});
      }
    }
  $self->{need_draw} = 0;
  
  }

sub _draw_field
  {
  # draw one field to the screen
  my ($self,$x,$y) = @_;

  my $r = $self->{rect};
  $r->x ( $self->{screen_x} + ($x-$self->{ofs_x}) * $self->{fw} +1 );
  $r->y ( $self->{screen_y} + ($y-$self->{ofs_y}) * $self->{fh} +1 );
  $r->width ( $self->{fw} - 2);
  $r->height ( $self->{fh} - 2);

  my $type = $self->{playfield}->[$y]->[$x];
  my $c = $self->{color}->{$type};
  my $shade = $self->_shade($x,$y);
  $self->{app}->fill($r,darken($c,$shade));
  }

1;

__END__


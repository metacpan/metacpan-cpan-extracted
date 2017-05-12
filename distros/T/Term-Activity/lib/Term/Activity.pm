=head1 NAME

Term::Activity - Process Activity Display Module

=head1 SYNOPSIS

This module is designed to produce informational STDERR output while a 
process is funinctioning over many iterations or outputs. It is instanced 
with an optional name and other configurable values and is then called on 
each iterative loop.

=head1 DESCRIPTION

The information displayed is the current time processed (measured since 
the instancing of the module), the number of actions second, a text-graphic 
indicator of activity (skinnable), and the total count of actions thus far.

An example output (on a small terminal) might appear like this:

  03:13:54 1 : [~~~~~~~~~~~~~~~~~\_______________] 9,461

Showing that nearly three hours and 14 minues have occured with a 
current rate of 1 action per second, for a total of 9,461 total actions.
(For the curious, the skin shown is the default skin, AKA 'wave')

The display occurs on a single line that is updated regularly. The 
display automatically calibrates itself so that it appears to update 
approximately once a second.

When the Term::Activity module passes out of scope it updates the display 
with the final time, count, and a newline before exiting.

Term::Activity can resize itself to the width of the current window if
Term::Size is installed. If not, it defaults to an 80-character display.
Term::Size is thouroughly reccomended.

=head1 USAGE

=head2 Basic Usage:

  my $ta = new Term::Activity;

  while ( doing stuff ) {
    $ta->tick;
  }

=head2 Process labels:

You can label the output with a string to be displayed along with the 
other output. This is handy for scripts that go through multiple 
processess.

You can either instance them as a scalar value:

  my $ta = new Term::Activity 'Batch7';

Or via a configuration hash reference:

  my $ta = new Term::Activity ({ label => 'Batch7' });

Also, through the course of processing, you can change the label.

  $ta->relabel("New Label");

=head2 Skins:

Skins can be selected via a configuration hash reference. Currently there 
are two skins 'wave' and 'flat.' "Wave" is the default skin.

  my $ta = new Term::Activity ({ skin => 'flat' });

The "flat" skin cycles through a series of characters. You may also 
provide an arrayreference of your favorite characters if you'd like 
different ones:

  my $ta = new Term::Activity ({ 
     skin  => 'flat',
     chars => [ '-', '=', '%', '=', '-' ]
  });

=head2 Start Time:

The start time for the process timer is initialized when the 
Term::Activity is created. Sometimes, with longer programs you want the 
count to remain constant through several different forms of processing. 
You can set the start time to a previous start time to do this.

The parameter is called 'time' in the initilization hash:

  my $start_time = time;

  # Stuff happens

  my $ta = new Term::Activity ({ 
     time => $start_time
  });
  
=head2 Count:

As with the time, you might want to start at a later count, so you can keep track of 
total count across several runs.

The parameter to change the starting count is called 'count' in the initialization hash:


  my $ta = new Term::Activity ({ 
     count => $start_count
  });


=head2 Interval:

The interval is how often the screen is updated to reflect changes. By default, 
Term::Activity auto-tunes this towards an update approximately each second.

Initially, however, there is no way of knowing how often you will call tick(), so an 
assumed interval of 100 iterations before update is the starting value.

For slower processes, you probably want to start this at 1 - that is, a visual update at
each call of tick()

  my $ta = new Term::Activity ({ 
     interval => 1
  });

=head2 Debug:

By setting the debug parameter to 1 a very verbose debug output is 
produced along with the regular output to let you see settings have been 
selected and what computations are being performed.

  my $ta = new Term::Activity ({ 
     debug => 1
  });

=head2 Multiple Instances:

As stated above, when the Term::Activity module passes out of scope it 
updates the display with the final time, count, and a newline before exiting.
Consuquently if you would like to use Term::Activity multiple times in a 
single program you will need to undefine the object and reinstance it:

  my $ta = new Term::Activity;

  while ( doing stuff ) {
    $ta->tick;
  }

  $ta = undef;
  $ta = new Term::Activity;

  while ( doing more stuff ) {
    $ta->tick;
  }

  (lather. rinse. repeat.)

=head1 KNOWN ISSUES

Resizing the window during execution may cause the status bar to stop
refreshing properly.

Is the window is too small to accomodate the time, label, count, and 
basic spacing (that is, there is less that 0 spaces for the activity to 
be displayed) the effect, while being preety in a watching-the-car-wreck 
way, it is not informative. Remember to keep your label strings short.

=head1 BUGS AND SOURCE

	Bug tracking for this module: https://rt.cpan.org/Dist/Display.html?Name=Term-Activity
	
	Source hosting: http://www.github.com/bennie/perl-Term-Activity

=head1 VERSION

	Term::Activity v1.20 2014/04/30

=head1 COPYRIGHT

    (c) 2003-2014, Phillip Pollard <bennie@cpan.org>

=head1 LICENSE

This source code is released under the "Perl Artistic License 2.0," the text of 
which is included in the LICENSE file of this distribution. It may also be 
reviewed here: http://opensource.org/licenses/artistic-license-2.0

=head1 AUTHORSHIP

    Additional contributions by Kristina Davis <krd@menagerie.tf>

    Derived from Util::Status 1.12 2003/09/08
    With permission granted from Health Market Science, Inc.

=head1 SEE ALSO:

  Term::ProgressBar

=cut

#*************************************************************************

package Term::Activity;

use 5.6.0;
use strict;
use warnings;

$Term::Activity::VERSION='1.20';

sub new {
  my $class = $_[0];
  my $self  = {};
  bless($self,$class);

  ## configurables

  our $chars    = undef; # custom charset to use
  our $count    = 0;     # full count
  our $debug    = 0;     # debug output
  our $interval = 100;   # how often to update the terminal
  our $name     = '';    # optional label name
  our $start    = time;  # starting time


  my $raw_skin = 'wave';

  if ( UNIVERSAL::isa($_[1],'HASH') ) {

    $chars    = $_[1]->{chars}    if defined $_[1]->{chars};
    $count    = $_[1]->{count}    if defined $_[1]->{count};
    $debug    = $_[1]->{debug}    if defined $_[1]->{debug};
    $interval = $_[1]->{interval} if defined $_[1]->{interval};
    $name     = $_[1]->{label}    if defined $_[1]->{label};
    $start    = $_[1]->{time}     if defined $_[1]->{time};
    $raw_skin = 'flat' if defined $_[1]->{skin} and lc($_[1]->{skin}) eq 'flat';

  } elsif ( defined $_[1] and length $_[1] ) {

    $name = $_[1];

  }

  $name =~ s/[\r\n]//g;

  ## basic settings

  our $width = $self->_width_init; # Terminal width
  our $last  = $start;             # last update time

  our $marker = 0; # starting position
  our $skip   = $width - 19;                     # The area for the chars
  our $ants   = [ map { ' '; } ( 1 .. $skip ) ]; # characters to display

  ## bootstrap

  our $name_length = length $name; # Length of optional name label

  our $ants_method_init = '_ants_' . $raw_skin . '_init';
  our $ants_method      = '_ants_' . $raw_skin;

  $self->_debug("Intializing skin: $raw_skin ($ants_method)");
  $self->$ants_method_init($chars);

  $self->_debug("Starting count     : $count");
  $self->_debug("Starting size      : $width");
  $self->_debug("Starting interval  : $interval");
  $self->_debug("Starting time      : $start");
  $self->_debug("Starting last time : $last");

  return $self;
}

sub DESTROY {
  my $self = shift @_;
  if ( our $count > 0 ) {
    $self->_update;
    print STDERR "\n";
  }
}

sub relabel {
  our $name = $_[1];
  our $name_length = length $name;
  return $name_length;
}

sub tick {
  my $self = shift @_;
  our ($count,$interval);

  $count++;
  $self->_debug("tick()  count: $count  interval: $interval");

  print STDERR "\n" if $count == 1;
  return 0 if $count % $interval;
  return $self->_update;
}

sub _ants_flat_init {
  my $self = shift @_;
  my $char = shift @_;
  our $chars;
  if ( ref $char && scalar(@$char) > 1 ) {
    $chars = $char;
  } else {
    $chars = [ '.', '=', '~', '#', '^', '-' ];
  }
}

sub _ants_flat {
  our ( $ants, $chars, $marker, $skip );

  if ($skip > $#$ants) {
    for my $i ( 0 .. $#$ants - $skip ) {
      unshift @$ants, $chars->[0];
    }
  } else {
    for my $i ( 0 .. $#$ants - $skip ) {
      pop @$ants;
    }
  }
  if ( $marker >= $skip ) {
    push @$chars, shift @$chars;
    $marker = 0;
  } else {
    $ants->[$marker++] = $chars->[0];
  }
  return join('',@$ants);
}

sub _ants_wave {
  our ( $ants, $chars, $marker, $skip );

  if ($skip > $#$ants) {
    for my $i ( 1 .. $#$ants - $skip) {
      unshift @$ants, $chars->[0]->[0];
    }
  } else {
    for my $i ( 1 .. $#$ants - $skip) {
      pop @$ants;
    }
  }
  if ( $marker >= $skip ) {
    $ants->[$skip] = $chars->[0]->[1];
    push @$chars, shift @$chars;
    $marker = 0;
  } else {
    $ants->[$marker++] = $chars->[0]->[1];
    $ants->[$marker]   = $chars->[0]->[0];
  }
  return join('',@$ants);
}

sub _ants_wave_init {
  my $self = shift @_;
  my $c = shift @_;
  our $chars;
  if ($c) {
    $chars = $c;
  } else {
    $chars = [ [ '\\', '~' ], [ '/', '_' ] ];
  }
}

sub _clock {
  my $self = shift @_;
  my $sec  = time - our $start;
  my $hr   = int($sec/3600);
     $sec -= $hr * 3600;
  my $min  = int($sec/60);
     $sec -= $min * 60;
  return join ':', map { $self->_zedten($_); } ($hr,$min,$sec);
}

sub _commaify {
  my $self = shift @_;
  my $num  = shift @_;
  1 while $num =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/;
  return $num;
}

sub _debug {
  my $self = shift @_;
  return unless our $debug > 0;
  print STDERR join( ' ', 'DEBUG:', @_ ) . "\n";
}

sub _update {
  my $self = shift @_;
  our ($ants_method,$count,$interval,$name,$skip,$width,$name_length);

  $self->_debug('_update()');

  my $o_interval        = $self->_commaify($interval);
  my $o_interval_length = length $o_interval;
  my $o_count           = $self->_commaify($count);
  my $o_count_length    = length $o_count;

  $self->_update_width;

  $skip = $width - 19 - $o_interval_length - $o_count_length - $name_length;

  my $format;
  my $out;

  if ( $name_length ) {
    $format = "\r\%s \%${o_interval_length}s : [\%${skip}s] \%${o_count_length}s \%${name_length}s ";
    $out = sprintf $format, $self->_clock, $o_interval, $self->$ants_method, $o_count, $name;
  } else {
    $skip++; # Without the name, gobble up the extra space
    $format = "\r\%s \%${o_interval_length}s : [\%${skip}s] \%${o_count_length}s ";
    $out = sprintf $format, $self->_clock, $o_interval, $self->$ants_method, $o_count;
  }

  $self->_update_interval;

  $format = "\%-.${width}s";

  $self->_debug("_update sprintf: $format\n$out");

  return print STDERR sprintf $format, $out;
}

sub _update_interval {
  my $self = shift @_;
  my $now  = time;

  our ($interval, $last);
  my $delta = $now - $last;

  if ( $delta > 5 && $interval > $delta ) { # The query is way slow, adjust down
    $interval = int($interval/$delta);
    $interval = 1 unless $interval;
  } elsif ( $delta > 2 && $interval > 1 ) { # The query is a little slow
    $interval--;
  } elsif ( $delta < 1 ) { # The query is fast
    $interval++;
  }

  $last = time;
}

sub _update_width {
  my $self = shift @_;  
  our $width = chars(*STDOUT{IO}) if our $use_term_size;
}

sub _width_init {
  my $default = 80;
  our $use_term_size = 0;

  eval { require Term::Size };

  return $default if $@;

  import Term::Size 'chars';
  my ( $cols, $rows ) = chars(*STDOUT{IO});

  if ( $cols > 0 ) {
    $use_term_size = 1;
    return $cols;
  }

  return $default;
}

sub _zedten {
  my $self = shift @_;
  my $in   = shift @_;
  $in = '0'.$in if $in < 10 && $in > -1;
  return $in;
}

1;

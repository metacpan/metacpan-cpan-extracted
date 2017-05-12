package Term::StatusBar;
no warnings 'portable';

$|++;
require 5.6.0; 
our ($AUTOLOAD, $FH);
our $VERSION = '1.18';


sub new {
   my ($class, %params) = @_;

   my $self = bless{
      startRow      => $params{startRow} || 1,
      startCol      => $params{startCol} || 1,
      startPos      => $params{startPos} || 'top',
      label         => $params{label} || 'Status: ',
      scale         => $params{scale} || 40,
      totalItems    => $params{totalItems} || 1,
      avgItems      => 1,
      updateCount   => 0,
      char          => $params{char} || ' ',
      count         => 0,
      itemsPP       => 1,
      updateInc     => int($params{updateInc}) || 1,
      curItems      => $params{totalItems} || 1,
      baseScale     => 100,
      start         => 0,
      maxCol        => 80,
      maxRow        => 24,
      prevSubText   => undef,
      subText       => undef,
      subTextAlign  => $params{subTextAlign} || 'left',
      reverse       => $params{reverse} || 0,
      barColor      => $params{barColor} || "\033[7;37m",
      fillColor     => $params{fillColor} || "\033[7;34m",
      colorTerm     => $params{colorTerm}ne'0',
      barStart      => undef,
      subTextChange => undef,
      subTextLength => undef,
      fh            => $params{fh} || *STDOUT,
      precision     => $params{precision} || 0,
      showTime      => $params{showTime} || 0,
      lastTime      => undef, 
      itemAccum     => $params{totalItems} || 1,
   }, ref $class || $class;

   $FH = $self->{fh};

   if (!$self->{colorTerm}){
      $self->{barColor} = '';
   }

   $self->subText($params{subText});
   $self->setItems($params{totalItems}) if $params{totalItems};
   $self->{barStart} = length($self->{label})+1;

   ## Check if scale exceeds current width of screen 
   ## and adjust accordingly. Not much we can do if 
   ## label exceeds screen width
   $self->_get_max_term();

   if ($self->{startPos} eq 'bottom'){
      $self->{startRow} = $self->{maxRow}-($self->{subText}?2:1);
   }

   if (($self->{scale} + $self->{barStart} + 5) >= $self->{maxCol}){
      $self->{scale} = $self->{maxCol} - 5 - $self->{barStart};
   }

   if ($self->{precision} > 4){ $self->{precision} = 4; }

   if ($self->{showTime}){
      eval { require Time::HiRes };

      if (!$@){
         if ($self->{startPos} ne 'bottom'){
            $self->{startRow}++;
         }
      }
      else{
         $self->{showTime} = 0;
      }
   }

   $SIG{INT} = \&{__PACKAGE__."::sigint"};
   return $self;
}

##
## Just in case this isn't done in caller. We 
## need to be able to reset the display.
##
sub sigint {
	my $self = shift;
	my $offset = $self->{startRow} + ($self->{reverse}?-5:5);
	print $FH "\033[$offset;1H\033[0m\n\n";
	exit;
}


##
## Used to get/set object variables. 
##
sub AUTOLOAD {
  my ($self, $val) = @_;
  (my $method = $AUTOLOAD) =~ s/.*:://;

  if (exists $self->{$method}){
    if (defined $val){
      $self->{$method} = $val;
    }
    else{
      return $self->{$method};
    }
  }
}


##
## Sets the subText and redisplays
##
sub subText {
  my ($self, $newSubText) = @_;
  return $self->{subText} if !defined $newSubText;

  if ($newSubText ne $self->{subText}){
    $self->{subText} = $newSubText;
    $self->{subTextLength} = length($newSubText);
    $self->{subTextChange} = 1;
    print $FH $self->_printSubText();
  }
  else{
    $self->{subTextChange} = 0;
  }
}


##
## Set totalItems, curItems, and itemsPP 
##
sub setItems {
  my ($self, $num) = @_;

  ## Items must be > 0
  $num = 1 if !$num;
  $self->{totalItems} = $self->{curItems} = abs($num) if !$self->{count};

  if ($self->{totalItems} > $self->{baseScale}){
    $self->{itemsPP} = int($self->{totalItems}/$self->{baseScale});
  }
}


##
## Adds more text to current subText
##
sub addSubText {
  my ($self, $text) = @_;
  return if !defined $text || $text eq '';

  $self->{prevSubText} = $self->{subText} if !$self->{prevSubText};
  $self->{subText} = $self->{prevSubText} . $text;
  $self->{subTextChange} = 1;
}


##
## Init object on screen
## 
sub start {
  my ($self) = @_;

  print $FH "\033[$self->{startRow};$self->{startCol}H", (' 'x($self->{maxCol}-$self->{startCol}));
  print $FH "\033[$self->{startRow};$self->{startCol}H$self->{label}";
  print $FH $self->{barColor}, ($self->{char}x$self->{scale}), "\033[0m";

  print $FH $self->_printPercent($self->{reverse}?100:0);
  print $FH $self->_printSubText();

  $self->{start}++;
}


##
## Updates approximate time
##

sub _calcTime {
   my ($self) = @_;
   return if !$self->{showTime};
   my ($time);

   if (!$self->{reverse} && $self->{lastTime}){
      my $tp = &Time::HiRes::tv_interval($self->{lastTime});
      my $tmp = $self->{itemAccum};
      $self->{itemAccum} = $self->{totalItems} - $self->{count};

      ## Prevent divide by zero errors
      if ($tmp-$self->{itemAccum} > 0){
         $tp = ($tp/($tmp-$self->{itemAccum}))*$self->{itemAccum};
      }
      else{
         goto NO_TIME;
      }

      my ($hours, $mins, $secs) = ("00")x3;
      if ($tp >= 3600){
         $hours = sprintf("%02d", int($tp/3600));
         $tp -= $hours*3600;
      }
      if ($tp >= 60){
         $mins = sprintf("%02d", int($tp/60));
         $tp -= $mins*60;
      }
      if ($tp >= 1){
         $secs = sprintf("%02d", int($tp));
      }

      $time = "$hours:$mins:$secs";
   }
   else{
NO_TIME:
      $time = "00:00:00";
   }

   my $pos = int($self->{scale}/2) + $self->{barStart}-5;
   my $t = "\033[".($self->{startRow}-1).";$self->{startCol}H";
   $t .= ' 'x($self->{barStart}+$self->{scale});
   $t .= "\033[".($self->{startRow}-1).";${pos}H".$time;

   print $FH $t;
   $self->{lastTime} = [&Time::HiRes::gettimeofday()];
}


##
## Updates the status bar on screen 
##
sub update {
  my ($self, $items) = @_;
  $self->start if !$self->{start};
  $self->{updateCount}++;

  ## Determines if an update is needed
  if (!$items){
    $self->{count}++;

    if (--$self->{curItems} % ($self->{itemsPP}*int($self->{updateInc}))){
      return;
    }
  }
  else{
    ## This stuff is for uneven updates, like processing files by line
    $self->{curItems} -= $items;
    $self->{count} += $items;
    $self->{avgItems} = int($self->{count}/$self->{updateCount});

    if ($self->{curItems} % ($self->{avgItems}*int($self->{updateInc}))){
      return;
    }
  }

  my $percent = $self->{count}/$self->{totalItems};
  $percent = 1-$percent if $self->{reverse};
  my $count = int($percent*$self->{scale});
  $percent = sprintf("%.$self->{precision}f", $percent*100);

  $self->_calcTime();

  ## Due to calls to int(), the numbers sometimes do not work out 
  ## exactly. If the bar is suppose to be full and at 100% this 
  ## makes sure it happens
  if ($self->{totalItems} - $self->{count} < $self->{itemsPP}){
    $count = $self->{scale};
    $percent = $self->{reverse}?0:100;
  }

  my $startCol = $self->{barStart}+$count;
  my $bar;

  ## Make sure bar has correct color at its final state 
  if ($percent != 0){
    $bar = "\033[$self->{startRow};$self->{barStart}H\033[K".$self->{fillColor}.($self->{char}x($count))."\033[0m";
    $bar .= "\033[$self->{startRow};${startCol}H".$self->{barColor}.($self->{char}x($self->{scale}-$count))."\033[0m";
  }
  else{
    $bar = "\033[$self->{startRow};${startCol}H".$self->{barColor}.($self->{char}x($self->{scale}-$count))."\033[0m"; 
  }

  $bar .=  $self->_printPercent($percent);
  $bar .=  $self->_printSubText();

  print $FH $bar; 
}


##
## Clear the count of status bar. This is so you can
## use the same object several times and set the
## scale and totalItems differently each run
##
sub reset {
  my ($self, $newDefaults) = @_;

  @$self{qw(count start prevSubText subText 
            subTextChange subTextLength curItems 
            totalItems)} = (0,0,'','',0,0,0,0);

  if ($newDefaults){
    for my $k (keys %$newDefaults){
      ## Just in case
      next if $k eq 'reset';
      $self->$k($newDefaults->{$k});
    }
  }
}


##
## Prints percent to screen
##
sub _printPercent {
  my ($self, $percent) = @_;

  my $t = "\033[$self->{startRow};".($self->{barStart}+$self->{scale}+1)."H";
  $t   .= "\033[37m$percent%       \033[0m";

  return $t;
}


##
## Calculates position to place sub-text
##
sub _printSubText {
  my ($self) = @_;
  my ($pos, $t, $subTemp);

  return if !$self->{subText} || !$self->{subTextChange};

  ## Truncate subText if necessary
  if ($pos+$self->{subTextLength} > $self->{scale}+$self->{barStart}){
    $subTemp = $self->{subText};
    $self->{subText} = substr($self->{subText}, 0, $self->{subTextLength}-($self->{scale}+$self->{barStart})).'...';
    $self->{subTextLength} = length($self->{subText});
  }

  if ($self->{subTextAlign} eq 'center'){
    my $tmp = int($self->{scale}/2) + $self->{barStart};
    $pos = $tmp - int($self->{subTextLength}/2);
  }
  elsif ($self->{subTextAlign} eq 'right'){
    $pos = $self->{barStart} + $self->{scale} + $self->{startCol} - $self->{subTextLength};
  }
  else{
    $pos = $self->{startCol}+$self->{barStart};
  }

  $pos = 0 if $pos < 0;

  $t  = "\033[".($self->{startRow}+1).";$self->{startCol}H\033[K";
  $t .= "\033[".($self->{startRow}+1).";${pos}H".$self->{subText};

  ## Restore original subText and length
  if ($subTemp){
    $self->{subText} = $subTemp;
    $self->{subTextLength} = length($self->{subText});
  }

  return $t;
}


sub _get_max_term{
   my ($self) = @_;

   ## suck in Term::Size, if possible
   eval { require Term::Size };

   ## no Term::Size; try using tput to find terminal width
   if($@){
   ## find tput via poor man's "which"
      for my $path (split /:/, $ENV{'PATH'}){
         next if !(-x "$path/tput");
         chomp($self->{maxCol} = `$path/tput cols`);
         last;
      }
   }
   else {
      ($self->{maxCol}, $self->{maxRow}) = &Term::Size::chars($self->{fh});
   }
}


1;
__END__
=pod

=head1 NAME

Term::StatusBar - Dynamic progress bar

=head1 SYNOPSIS

    use Term::StatusBar;

    my $status = new Term::StatusBar (
                    label => 'My Status: ',
                    totalItems => 10,  ## Equiv to $status->setItems(10)
    );

    $status->start;  ## Optional, but recommended

    doSomething(10);

    $status->reset;  ## Resets internal state
    $status->label('New Status: ');  ## Reuse current object with new data
    $status->char('|');

    doSomething(20);


    sub doSomething {
        $status->setItems($_[0]);
        for (1..$_[0]){
            sleep 1;
            $status->update;  ## Will call $status->start() if needed
        }
    }

=head1 DESCRIPTION

Term::StatusBar provides an easy way to create a terminal status bar, 
much like those found in a graphical environment. Term::Size is used to
ensure the bar does not extend beyond the terminal's width. All outout 
is sent to STDOUT by default.

=head1 METHODS

=head2 B<new(parameters)>

This creates a new StatusBar object. It can take several parameters:

   startRow     - This indicates which row to place the bar at. Default is 1.
   startCol     - This indicates which column to place the bar at. Default is 1.
   startPos     - This will replace startRow if specified. Currently takes ['bottom','top'].
   label        - This places text to the left of the status bar. Default is "Status: ".
   scale        - This indicates how long the bar is. Default is 40.
   totalItems   - This tells the bar how many items are being iterated. Default is 1.
   char         - This indicates which character to use for the base bar. Default is ' ' (space).
   updateInc    - Updates bar every X%. Default is every 1%.
   subText      - Text to display below the status bar.
   subTextAlign - How to align subText ('left', 'center', 'right').
   reverse      - Status bar empties to 0% rather than fills to 100%.
   barColor     - Base color of the status bar (default white -- \033[7;37m).
   fillColor    - Fill color of the status bar (default blue -- \033[7;34m).
   colorTerm    - Specify if your terminal can handle colors. Default is 1.
   fh           - User-defined file handle.
   precision    - Formats percentage with decimals. Up to 4 places supported.
   showTime     - Shows approximate time to completion in "00:00:00" format.

=head2 B<setItems(#)>

This method does several things with the number that is passed in. First it sets 
$obj->{totalItems}, second it sets an internal counter 'curItems', last it 
determines the update increment.

This method must be used, unless you pass totalItems to the constructor.

=head2 B<subText('text')>

Sets subText and redisplays it if necessary.

=head2 B<addSubText('text')>

This takes the original value of $obj->{subText} and concats 'text' to it 
each time it is called. Text is then re-displayed to screen. 

=head2 B<start()>

This method 'draws' the initial status bar on the screen.

=head2 B<update($items)>

This is really the core of the module. This updates the status bar and 
gives the appearance of movement. It really just redraws the entire thing, 
adding any new incremental updates needed.

You should only pass $items in when processing a file with an uneven number of 
bytes per line. This is so you don't have to initially read the file in to get 
a line count.

=head2 B<reset([\%options])>

This resets the bar's internal state and makes it available for re-use. If 
the optional hash ref is passed in, the status bar can be filled with 
specified values. The keys are interpreted as function calls on the status 
bar object with the values as parameters.

=head2 B<_printPercent()>

Internal method to print the current percentage to the screen.

=head2 B<_printSubText()>

Internal method to print the subText to the screen.

=head2 B<_calcTime()>

Internal method to calculate and print estimated time to completion.

=head2 B<_get_max_term()>

Internal method to get the terminal's current width and height.

=head1 CHANGES

=begin text 
   2003-08-11
      + Removed DESTROY()

   2003-06-12
      + Added new options: startPos and colorTerm.
      + Changed escape sequence to \033.

   2003-06-11
      + Fixed divide-by-zero error in _calcTime().
      + Fixed bug in updateInc. Wasn't updating correctly.
      + Fixed bug with subText() and _printSubText() being "out-of-sync".
         - Caused text to not be displayed at the appropriate time.
      + Fixed bug with long subTexts not being cleared.
         - Caused extra characters to remain on the screen.
      + Prevent long subText values from wrapping by truncating to StatusBar width.
         - This should work with all subTextAlign types.
      + update() can now take an argument of items processed. This should only be used when an 
        uneven number of items are processed per iteration. An example would be the number of bytes 
        a line in a file contains.

   2003-05-06
      + Fixed bug where subTextLength was not being re-evaluated.
      + Bar's final state color is now appropriate. When emptied to 0% is was getting re-filled.
      + Added "no warnings 'portable" so Perl 5.8 would be happy.
      + Added ability to send output to user-defined file handle.
      + Added precision for percentage output to a max of 4 decimal places. Default is 0.
      + Can now specify a different 'updateInc', which adjusts how often the bar is updated. Default is every 1%.
      + Can now indicate if you want to see approximate time to completion.

   2003-01-27
      + Added 'reverse' option to constructor.
      + Cleaned up code a bit.
      + Only update items when needed (subText was being updated even if it had not changed).
      + Pre-compute lengths and use static value rather than calling length() every iteration.

=end text

=head1 AUTHOR

Shay Harding E<lt>sharding@ccbill.comE<gt>

=head1 NOTES 

Has only been tested on Linux platform. I would like to hear of successes/problems on other platforms.
Patches, ideas and comments are always welcome.

=head1 ACKNOWLEDGEMENTS

Scott Wiersdorf's B<Term::Twiddle> for the _get_max_width() function.


=head1 COPYRIGHT

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<Term::Report>

=cut


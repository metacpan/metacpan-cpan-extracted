# $Id: Visual.pm,v 0.06 2003/01/14 23:00:18 lunartear Exp $
# Copyrights and documentation are after __END__.
package Term::Visual;
use strict;
use warnings;
use vars qw($VERSION $REVISION $console);
$VERSION = '0.08';
$REVISION = do {my@r=(q$Revision: 0.08 $=~/\d+/g);sprintf"%d."."%02d"x$#r,@r};
#use Visual::StatusBar;
use Term::Visual::StatusBar;
use POE qw(Wheel::Curses Wheel::ReadWrite ); 
use Curses;
use Carp;

BEGIN {
  my $debug_default = 0;

  $debug_default++ if defined $ENV{TV_DEBUG};
  defined &DEBUG or eval "sub DEBUG () { $debug_default }";

  if (&DEBUG) {
      my $debug_file = $ENV{TV_LOG_FILE} || 'term_visual.log';
      defined &DEBUG_FILE or eval "sub DEBUG_FILE () { '$debug_file' }";
      open ERRS, ">" . &DEBUG_FILE or croak "Can't open Debug file: $!"; 
  }
}

### Term::Visual Constants.

sub WINDOW       () { 0 } # hash of windows and there properties
sub WINDOW_REV   () { 1 } # window name => id key value pair for reverse lookups
sub PALETTE      () { 2 } # Palette Element
sub PAL_COL_SEQ  () { 3 } # Palette Color Sequence
sub CUR_WIN      () { 4 } # holds the current window id
sub ERRLEVEL     () { 5 } # Error Level boolean 
sub ALIAS        () { 6 } # Visterm's Alias  
sub BINDINGS     () { 7 } # key bindings
sub COMMON_INPUT () { 8 } # Common input boolean

### Palette Constants.

sub PAL_PAIR    () { 0 }  # Index of the COLOR_PAIR in the palette.
sub PAL_NUMBER  () { 1 }  # Index of the color number in the palette.
sub PAL_DESC    () { 2 }  # Text description of the color.

### Title line constants.

sub TITLE_LINE  () { 0 }  # Where the title goes.
sub TITLE_COL   () { 0 }


sub current_window { 
  if (DEBUG) { print ERRS " Enter current_window\n"; }
  my $self = shift;
  return $self->[CUR_WIN];
}


sub CREATE_WINDOW_ID {
  if (DEBUG) { print ERRS "Enter CREATE_WINDOW_ID\n"; }
  my $self = shift;
  my $id = 0;
  my @list = sort {$a <=> $b} keys %{$self->[WINDOW]};
  if (@list) {
    my $high_number = $list[$#list] + 1;
    for my $i (0..$high_number) {
      next if (defined $list[$i] && $i == $list[$i]);
      $id = $i; last;
    }
  }
  return $id;
}


### Mold the Object.

sub new {
  if (DEBUG) { print ERRS "Enter Visterm->new\n"; }
  my $package = shift;
  my %params = @_;
  my $alias = delete $params{Alias};
  my $errlevel = delete $params{Errlevel} || 0;
  my $current_window = -1;

  my $common_input = delete $params{Common_Input};
  # These options only make sense if Common_Input is specified
  my $tabcomplete = delete $params{Tab_Complete};
  my $history_size = delete $params{History_Size};

  my $self =
    bless [ { }, # WINDOW stores window properties under each window id.
            { }, # WINDOW_REV reverse window lookups.
            { }, # Palette
              0, # Palette Color Sequence
             $current_window,
             $errlevel, # Visterms error level.
             $alias,
            { }, # BINDINGS
             $common_input ? {
               History_Position => -1,
               History_Size     => $history_size,
               Command_History  => [ ],
               Data             => "",
               Data_Save        => "",
               Cursor           => 0,
               Cursor_Save      => 0,
               Tab_Complete     => $tabcomplete,
               Insert           => 1,
               Edit_Position    => 0,
             } : undef,
          ], $package;

  POE::Session->create
    ( object_states => 
      [ $self =>   # $_[OBJECT]
      {                 _start => "start_terminal",
                         _stop => "terminal_stopped",
                 send_me_input => "register_input",
                 private_input => "got_curses_input",
                    got_stderr => "got_stderr",
                      shutdown => "shutdown",
      } ],
      args => [ $alias ], 
       
    );

  return $self;
}

sub got_stderr {
  my ($self, $kernel, $stderr_line) = @_[OBJECT, KERNEL, ARG0];
  my $window_id = $self->[CUR_WIN];

if (DEBUG) {  print ERRS $stderr_line, "\n"; } 

     &print($self, $window_id,
          "\0(stderr_bullet)" .
          "2>" .
          "\0(ncolor)" .
          " " .
          "\0(stderr_text)" .
          $stderr_line );
}

sub start_terminal {
  if (DEBUG) { print ERRS "Enter start_terminal\n"; }
  my ($kernel, $heap, $object, $alias) = @_[KERNEL, HEAP, OBJECT, ARG0];
  
  $kernel->alias_set( $alias );
  $console = POE::Wheel::Curses->new( InputEvent => 'private_input');
   use_default_colors();
  my $old_mouse_events = 0;
  mousemask(0, $old_mouse_events);

  #TODO See about adding support for a wheel mouse after defining old mouse
  #     events above, so that copy/paste will work as expected.

  ### Set Colors used by Visterm
  _set_color( $object,  stderr_bullet => "bright white on red",
                        stderr_text   => "bright yellow on black",
                        ncolor        => "white on black",
                        statcolor     => "green on black", 
                        st_frames     => "bright cyan on blue",
                        st_values     => "bright white on blue", );


  ### Redirect STDERR into the terminal buffer.
  use Symbol qw(gensym);

  # Pipe STDERR to a readable handle.
  my $read_stderr = gensym();

  pipe($read_stderr, STDERR) or do
  { open STDERR, ">&=2";
    die "can't pipe STDERR: $!";
  };

  $heap->{stderr_reader} = POE::Wheel::ReadWrite->new
    ( Handle      => $read_stderr,
      Filter      => POE::Filter::Line->new(),
      Driver      => POE::Driver::SysRW->new(),
      InputEvent  => "got_stderr",
    );

}

### create a curses window
### TODO add error handling

sub create_window {
  if (DEBUG) { print ERRS "Enter create_window\n"; }
  my $self = shift;
  my %params = @_;
  my $use_title = 1 unless defined $params{Use_Title};
  my $use_status = 1 unless defined $params{Use_Status};
  my $new_window_id = CREATE_WINDOW_ID($self);
  my $window_name = $params{Window_Name} || $new_window_id;
  my $input_prompt = $params{Input_Prompt} || ""; 
  my $prompt_size = 0;
  if (length $input_prompt) {
       $prompt_size = length( $input_prompt ) ;
  }
  my $input;
  if ($self->[COMMON_INPUT]) {
    $input = $self->[COMMON_INPUT];
  }
  else {
    $input = {
       History_Position => -1,
       History_Size     => 50,
       Command_History  => [ ],
       Data             => "",
       Data_Save        => "",
       Cursor           => $prompt_size || 0,
       Cursor_Save      => 0,
       Tab_Complete     => undef,
       Insert           => 1,
       Edit_Position    => 0,
       Prompt           => $input_prompt,
       Prompt_Size      => $prompt_size,
    };
  }
  # Allow override of possible global options
  if ($params{History_Size}) {
    $input->{History_Size} = $params{History_Size};
  }
  if ($params{Tab_Complete}) {
    $input->{Tab_Complete} = $params{Tab_Complete};
  }

  if (defined $new_window_id) {
    if (DEBUG) { print ERRS "new_window_id is defined: $new_window_id\n"; }
    if (!$self->[WINDOW]->{$new_window_id}) {
      $self->[WINDOW]->{$new_window_id} =
         { Buffer           => [ ],
           Buffer_Size      => $params{Buffer_Size} || 500,
           Input            => $input,
           Use_Title        => $use_title,
           Use_Status       => $use_status,
           Scrolled_Lines   => 0,
           Window_Id        => $new_window_id,
           Window_Name      => $window_name };

        my $winref = $self->[WINDOW]->{$new_window_id};

        # Set the newly created window as the current window
        $self->[CUR_WIN] = $new_window_id;

      $self->[WINDOW_REV]->{$window_name} = $new_window_id;

      # create the screen, statusbar, title, and entryline 
      # for this window instance

      if ($winref->{Use_Title}) {
        $winref->{Title_Start} = 0;
        $winref->{Title_Height} = 1;
        $winref->{Title} = $params{Title} || "";

        $winref->{Screen_Start} = $winref->{Title_Start} + 1;

        $winref->{Window_Title} =  newwin( $winref->{Title_Height}, 
                                    $COLS, 
                                    $winref->{Title_Start},
                                    0 );
        # Should we die here??
        die "No title!!" unless defined $winref->{Window_Title};

        my $title = $winref->{Window_Title};

        $title->bkgd($self->[PALETTE]->{st_frames}->[PAL_PAIR]); 
        $title->erase();
        _refresh_title( $self, $new_window_id);
      }

      if ($winref->{Use_Status}) {
        $winref->{Status_Height} = $params{Status_Height} || 2;
        $winref->{Status_Start} = $LINES - $winref->{Status_Height} - 1;

        #FIXME I think this got lost when the new design was implemented.
        $winref->{Def_Status_Field} = [ ];

        $winref->{Screen_End} = $winref->{Status_Start} - 1;

        $winref->{Window_Status} = newwin( $winref->{Status_Height},
                                    $COLS,
                                    $winref->{Status_Start},
                                    0 );
        my $status = $winref->{Window_Status};
        if (DEBUG) { print ERRS $status, " <-status in create_window\n"; }
        $status->bkgd($self->[PALETTE]->{st_frames}->[PAL_PAIR]); 
        $status->erase();
        $status->noutrefresh();

        $winref->{Status_Object} = Term::Visual::StatusBar->new();
        set_status_format( $self, $new_window_id, %{$params{Status}});
        $winref->{Status_Lines} = $winref->{Status_Object}->get();
        if (DEBUG) { print ERRS "passed set_status_format in create_window\n"; }
      }

      if ($winref->{Use_Title} && $winref->{Use_Status}) {
        $winref->{Screen_Height} = 
         $winref->{Screen_End} - $winref->{Screen_Start} + 1;
      }

      else {
        $winref->{Screen_Start} = 0 unless defined $winref->{Screen_Start};
        $winref->{Screen_End} = $LINES - 2 unless defined $winref->{Screen_End};
        $winref->{Screen_Height} = 
         $winref->{Screen_End} - $winref->{Screen_Start} + 1 
         unless defined $winref->{Screen_Height};
      }

      $winref->{Edit_Height} = 1;
      $winref->{Edit_Start} = $LINES - 1;

      $winref->{Buffer_Last} = $winref->{Buffer_Size} - 1;
      $winref->{Buffer_First} = $winref->{Screen_Height} - 1;
      $winref->{Buffer_Visible} = $winref->{Screen_Height} - 1;


      $winref->{Window_Edit} = newwin( $winref->{Edit_Height},
                                $COLS,
                                $winref->{Edit_Start},
                                0 );
      my $edit = $winref->{Window_Edit};
      $edit->scrollok(1);

      $winref->{Window_Screen} = newwin( $winref->{Screen_Height},
                                  $COLS,
                                  $winref->{Screen_Start},
                                  0 );
      my $screen = $winref->{Window_Screen};

      $screen->bkgd($self->[PALETTE]->{ncolor}->[PAL_PAIR]);
      $screen->erase();
      $screen->noutrefresh();

      $winref->{Buffer_Row} = $winref->{Buffer_Last};

      $winref->{Buffer} = [("") x $winref->{Buffer_Size}];

      _refresh_edit($self, $new_window_id);


      # Flush updates.
      doupdate();

      return $new_window_id;
      
    }
    else { 
      if (DEBUG) { print ERRS "Window $params{Window_Name} already exists\n"; } 
      carp "Window $params{Window_Name} already exists"; 
    }
  }
  else { 
    if (DEBUG) { print ERRS "Window $params{Window_Name} couldn't be created\n"; }
    croak "Window $params{Window_Name} couldn't be created"; 
  }
}


### delete one or more windows  ##TODO add error handling
### $vt->delete_window($window_id);

sub delete_window {
  if (DEBUG) { print ERRS "Enter delete_window\n"; }
  my $self = shift;
  my $win;
  for (@_) {
    $win = $_;
    my $name = get_window_name($self, $_);
    delete $self->[WINDOW]->{$_};
    delete $self->[WINDOW_REV]->{$name};
  }
  return unless defined $win;
  my $new_win;
  my $cur_win = $win;
  # Select previous window
  while (--$cur_win > 0) {
    if (exists $self->[WINDOW]{$cur_win}) {
      $new_win = $cur_win;
      last;
    }
  }
  # No previous window, select next window
  unless (defined $new_win) {
    $cur_win = $win;
    while (++$cur_win <= keys %{$self->[WINDOW]}) {
      if (exists $self->[WINDOW]{$cur_win}) {
        $new_win = $cur_win;
        last;
      }
    }
  }
  if (defined $new_win) {
    change_window($self, $new_win);
  }
  elsif (DEBUG) {
    print ERRS "We have no more windows!\n"
  }
}

### check if a window exists

sub validate_window {
  if (DEBUG) { print ERRS "Enter validate_window\n"; }
  my $self = shift;
  my $query = shift;
  if (DEBUG) { print ERRS "Validating: $query\n"; }
  if ($query =~ /^\d+$/ && defined $self->[WINDOW]->{$query}) { return 1; }
  elsif (defined $self->[WINDOW_REV]->{$query}) { return 1; }
  else { return 0; }
}

### return a windows palette or a specific colorname's description
### my %palette = $vt->get_palette(); # entire palette.
### my ($color_desc, $another_desc) = $vt->get_palette($colorname, $somecolor); # color desc.

sub get_palette {  
  my $self = shift;
  my @result;
  if ($#_ >= 0) { 
    for (@_) { push( @result, $self->[PALETTE]->{$_}->[PAL_DESC] ); }
    return @result;
  }
  else {
    for my $key (keys %{$self->[PALETTE]}) {
      push( @result, $key, $self->[PALETTE]->{$key}->[PAL_DESC]);
    }
    return @result;
  }

}

### set the palette for a window

sub set_palette {
  if (DEBUG) { print ERRS "Enter set_palette\n"; }
  my $self = shift;
  if (DEBUG) { print ERRS "palette needs an even number of parameters\n" if @_ & 1; } 
  croak "palette needs an even number of parameters" if @_ & 1;
  my %params = @_;
  _set_color($self, %params);
}

sub get_window_name {
  my $self = shift;
  my $id = shift;
  if ($id =~ /^\d+$/) {
    return $self->[WINDOW]->{$id}->{Window_Name};
  } 
  else { 
    if (DEBUG) { print ERRS "$id is not a Window ID\n"; }
    croak "$id is not a Window ID"; 
  }
}

sub get_window_id {
  my $self = shift;
  my $query = shift;
  my $validity = validate_window($self, $query);
  if ($validity) {
    return $self->[WINDOW_REV]->{$query};
  }
  else {
    if (DEBUG) { print ERRS "$query is not a Window Name\n"; }
    croak "$query is not a Window Name";
  }
}

### set the Title for a Window.

sub set_title {
  if (DEBUG) { print ERRS "Enter set_title\n"; }
  my $self = shift;
  my ($window_id, $title) = @_;
  my $validity = validate_window($self, $window_id);
  if ($validity) {
    $self->[WINDOW]->{$window_id}->{Title} = $title;
    if ($window_id == $self->[CUR_WIN]) {
      _refresh_title( $self, $window_id ); 
      doupdate();
    }
  }
  else {
    if (DEBUG) { print ERRS "Window $window_id is nonexistant\n"; }
    croak "Window $window_id is nonexistant";
  }
}

### get the Title for a Window.

sub get_title {
  my $self = shift;
  my $window_id = shift;
  my $validity = validate_window($self, $window_id);
  if ($validity) {
    return $self->[WINDOW]->{$window_id}->{Title};
  }
  else {
    if (DEBUG) { print ERRS "Window $window_id is nonexistant\n"; }
    croak "Window $window_id is nonexistant";
  }
}

### print lines to window
### a window_id must be given as the first argument.

sub print {
  if (DEBUG) { print ERRS "Enter print\n"; }
  my $self = shift;
  my $window_id = shift;
  if (!validate_window($self, $window_id)) {
    if (DEBUG) { print ERRS "Can't print to nonexistant Window $window_id\n"; }
    croak "Can't print to nonexistant Window $window_id";
  }

    my @lines;
       foreach my $l (@_) {
               foreach my $ll (split(/\n/,$l)) {
                       $ll =~ s/\r//g;
                       push(@lines,$ll);
               }
       }

  my $winref = $self->[WINDOW]->{$window_id};

  foreach (@lines) {

    # Start a new line in the scrollback buffer.

    push @{$winref->{Buffer}}, "";
    $winref->{Scrolled_Lines}++;
    my $column = 1;

    # Build a scrollback line.  Stuff surrounded by \0() does not take
    # up screen space, so account for that while wrapping lines.

    my $last_color = "\0(ncolor)";
    while (length) {

      # Unprintable color codes.
      if (s/^(\0\([^\)]+\))//) {
        $winref->{Buffer}->[-1] .= $last_color = $1;
        next;
      }

      # Wordwrap visible stuff.
      if (s/^([^\0]+)//) {
        my @words = split /(\s+)/, $1;
        foreach my $word (@words) {
          unless (defined $word) {
            warn "undefined word";
            next;
          }

           while ($column + length($word) >= $COLS) {
       # maybe this word length should be configurable
                 if (length($word) > 20) {
                     # save the word
                      my $preword = $word;
                     # shorten the word to the end of the line
                      $word = substr($word,0,($COLS - $column)); 
                     # add the word
                      $winref->{Buffer}->[-1] .= "$word\0(ncolor)";
                      $word = '';

                     # put the last color on the next line and wrap
                      push @{$winref->{Buffer}}, $last_color;
                      $winref->{Scrolled_Lines}++;
                      # slice the unmodified word
                      $word = substr($preword,($COLS - $column)); 
                      $column = 1;
                      next;
                } else {
                     $winref->{Buffer}->[-1] .= "\0(ncolor)";
                     push @{$winref->{Buffer}}, $last_color;
                }
                $winref->{Scrolled_Lines}++;
                $column = 1;
                next if $word =~ /^\s+$/;
           }
           $winref->{Buffer}->[-1] .= $word;
           $column += length($word);
           $word = '';
        }
      }
    }  
  }

  # Keep the scrollback buffer a tidy length.
  splice(@{$winref->{Buffer}}, 0, @{$winref->{Buffer}} - $winref->{Buffer_Size})
    if @{$winref->{Buffer}} > $winref->{Buffer_Size};

  # Refresh the buffer when it's all done.
  if ($self->[CUR_WIN] == $window_id) {
    _refresh_buffer($self, $window_id);  
    _refresh_edit($self, $window_id);    
    doupdate();         
  }
}

## Register key bindings

sub bind {
  my $self = shift;
  carp "invalid arugments to ->bindings()" if @_ & 1;
  my %bindings = @_;
  for (keys %bindings) {
    my $key = _parse_key($_)
      or carp "Invalid escape sequence $_";
    $self->[BINDINGS]{$key} = $bindings{$_};
  }
}

## UnRegister key bindings

sub unbind {
  my $self = shift;
  for (@_) {
    my $key = _parse_key($_)
      or carp "Invalid escape sequence $_";
    delete $self->[BINDINGS]{$key};
  }
}

sub _parse_key {
  my ($key) = @_;
  my $esc = '';
  while ($key =~ s/^(A(?:lt)|C(?:trl)?)-//i) {
    my $in = uc $1;
    if (substr($in, 0, 1) eq 'C') {
      $esc .= '^'
    }
    elsif (substr($in, 0, 1) eq 'A') {
      $esc .= '^[';
    }
    else {
      die "We should not get here: $_";
    }
  }

  if (length($key) == 1) {
    return $esc . $key;
  }
  else {
    return $esc . "KEY_" . uc($key);
  }
}

### Register an input handler thing.

sub register_input {
  if (DEBUG) { print ERRS "Enter register_input\n"; }
  my ($kernel, $heap, $sender, $event) = @_[KERNEL, HEAP, SENDER, ARG0];

  # Remember the remote session and the event it wants to receive with
  # input.  This saves the sender's ID (instead of a reference)
  # because references mess with Perl's garbage collection.

  $heap->{input_session} = $sender->ID();
  $heap->{input_event}   = $event;
 
   # Increase the sender's reference count so the session stays alive
   # while the terminal is active.  We'll decrease the reference count
   # in _stop so it can go away when the terminal does.
 
   $kernel->refcount_increment( $sender->ID(), "terminal link" );

}

### Get input from the Curses thing.

sub got_curses_input {
  if (DEBUG) { print ERRS "Enter got_curses_input\n"; }
  my ($self, $kernel, $heap, $key) = @_[OBJECT, KERNEL, HEAP, ARG0];

  my $window_id = $self->[CUR_WIN];
  my $winref = $self->[WINDOW]->{$window_id};
  $key = uc(keyname($key)) if $key =~ /^\d{2,}$/;
  $key = uc(unctrl($key))  if $key lt " " or $key gt "~";

  # If it's a meta key, save it.
  if ($key eq '^[') {
    $winref->{Input}{Prefix} .= $key;
    return;
  }

  # If there was a saved prefix, recall it.
  if ($winref->{Input}{Prefix}) {
    $key = $winref->{Input}{Prefix} . $key;
    $winref->{Input}{Prefix} = '';
  }

  ### Handle internal keystrokes here.  Page up, down, arrow keys, etc.

  # key bindings
  if (exists $self->[BINDINGS]{$key} and $heap->{input_session}) {
    $kernel->post( $heap->{input_session}, $self->[BINDINGS]{$key},
                   $key, $winref, $window_id
                 );
    return;
  }

  # Beginning of line.
  if ($key eq '^A' or $key eq 'KEY_HOME') {
    if ($winref->{Input}{Cursor}) {
      if ($winref->{Input}{Prompt_Size}) {
        $winref->{Input}{Cursor} = $winref->{Input}{Prompt_Size};
      } else {
         $winref->{Input}{Cursor} = 0;
      }
      _refresh_edit($self, $window_id); 
      doupdate();        
    }
    return;
  }

  # Back one character.
  if ($key eq 'KEY_LEFT') {
    if ($winref->{Input}{Cursor}) {
      if($winref->{Input}{Prompt}) {
        if($winref->{Input}{Cursor} > $winref->{Input}{Prompt_Size}) {
            $winref->{Input}{Cursor}--;
        }
      } else {
            $winref->{Input}{Cursor}--;
        }
            _refresh_edit($self, $window_id);
            doupdate();
    }
    return;
  }
  if (DEBUG) { print ERRS $key, "\n"; }
  # Switch Windows to the left  Shifted left arrow
  #FIXME come up with a better fix. KEY_LEFT didnt work for me.
  if ($key eq 'ð' or $key eq '^[KEY_LEFT') {
    $window_id--;
    change_window($self, $window_id );
    return;
  }

  # Switch Windows to the right  Shifted right arrow
  #FIXME come up with a better fix. KEY_RIGHT didnt work for me.
  if ($key eq 'î' or $key eq '^[KEY_RIGHT') {
    $window_id++; 
    change_window($self, $window_id );
    return;
  }

  # Interrupt.
  if ($key eq '^\\') {

    $kernel->alias_remove($self->[ALIAS]);
    delete $heap->{stderr_reader};
    undef $console;
    if (defined $heap->{input_session}) {
        delete $heap->{input_session};          
    }
    $kernel->signal($kernel, "UIDESTROY");
    return;
  }

  # Delete a character.
  if ($key eq '^D' or $key eq 'KEY_DC') {
       my $csize = $winref->{Input}{Cursor} - $winref->{Input}{Prompt_Size};
    if ($csize < length($winref->{Input}{Data})) {
      substr($winref->{Input}{Data}, $winref->{Input}{Cursor} - $winref->{Input}{Prompt_Size}, 1) = '';
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # End of line.
  if ($key eq '^E' or $key eq 'KEY_LL') {
    if ($winref->{Input}{Cursor} < length($winref->{Input}{Data})) {
      $winref->{Input}{Cursor} = length($winref->{Input}{Data});
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Forward character.
  if ($key eq '^F' or $key eq 'KEY_RIGHT') {
    if (($winref->{Input}{Cursor} - $winref->{Input}{Prompt_Size}) < length($winref->{Input}{Data})) {
      $winref->{Input}{Cursor}++;
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Backward delete character.
  if ($key eq '^H' or $key eq "^?" or $key eq 'KEY_BACKSPACE') {
    if ($winref->{Input}{Cursor}) {
     if ($winref->{Input}{Cursor} > ($winref->{Input}{Prompt_Size} )) {
      $winref->{Input}{Cursor}--;
      substr($winref->{Input}{Data}, $winref->{Input}{Cursor} - $winref->{Input}{Prompt_Size}, 1) = '';
      _refresh_edit($self, $window_id);
      doupdate();
     }
    }
    return;
  }

  # Accept line.
  if ($key eq '^J' or $key eq '^M') {
    $kernel->post( $heap->{input_session}, $heap->{input_event},
                   $winref->{Input}{Data}, undef
                 );

    # And enter the line into the command history.
    command_history( $self, $window_id, 0 );  
    return;
  }

  # Kill to EOL.
  if ($key eq '^K') {
    if ($winref->{Input}{Cursor} < length($winref->{Input}{Data})) {
      substr($winref->{Input}{Data}, $winref->{Input}{Cursor}) = '';
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Refresh screen.
  if ($key eq '^L' or $key eq 'KEY_RESIZE') {

    # Refresh the title line.
    _refresh_title($self, $window_id);   

    # Refresh the status lines.
      _refresh_status( $self, $window_id);  

    # Refresh the buffer.
    _refresh_buffer($self, $window_id);  

    # Refresh the edit line.
    _refresh_edit($self, $window_id);

    # Flush updates.
    doupdate();

    return;
  }

  # Next in history.
  if ($key eq '^N'  ) {
    command_history( $self, $window_id, 2 ); 
    return;
  }

  # Previous in history.
  if ($key eq '^P' ) {
    command_history( $self, $window_id, 1 );
    return;
  }

  # Display input status.
  if ($key eq '^Q') {  
    &print( $self, $window_id,  # <- can I do this better?
               "\0(statcolor)******",
               "\0(statcolor)*** cursor is at $winref->{Input}{Cursor}",
               "\0(statcolor)*** input is: ``$winref->{Input}{Data}''",
               "\0(statcolor)*** scrolled lines: $winref->{Scrolled_Lines}",
               "\0(statcolor)*** screen height: " . $winref->{Screen_Height},
               "\0(statcolor)*** buffer row: $winref->{Buffer_Row}", 
               "\0(statcolor)*** scrollback height: " . scalar(@{$winref->{Buffer}}),
               "\0(statcolor)******"
             );
    return;
  }

  # Transpose characters.
  if ($key eq '^T') {
    if ($winref->{Input}{Cursor} > 0 and $winref->{Input}{Cursor} < length($winref->{Input}{Data})) {
      substr($winref->{Input}{Data}, $winref->{Input}{Cursor}-1, 2) =
        reverse substr($winref->{Input}{Data}, $winref->{Input}{Cursor}-1, 2);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Discard line.
  if ($key eq '^U') {
    if (length($winref->{Input}{Data})) {
      $winref->{Input}{Data} = '';
      $winref->{Input}{Cursor} = 0;
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Word rubout.
  if ($key eq '^W' or $key eq '^[^H') {
    if ($winref->{Input}{Cursor}) {
      substr($winref->{Input}{Data}, 0, $winref->{Input}{Cursor}) =~ s/(\S*\s*)$//;
      $winref->{Input}{Cursor} -= length($1);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # First in history.
  if ($key eq '^[<') {
    # TODO
    return;
  }

  # Last in history.
  if ($key eq '^[>') {
    # TODO
    return;
  }

  # Capitalize from cursor on.  Requires uc($key)
  if (uc($key) eq '^[C') {

    # If there's text to capitalize.
    if (substr($winref->{Input}{Data}, $winref->{Input}{Cursor}) =~ /^(\s*)(\S+)/) {

      # Track leading space, and uppercase word.
      my $space = $1; $space = '' unless defined $space;
      my $word  = ucfirst(lc($2));

      # Replace text with the uppercase version.
      substr( $winref->{Input}{Data},
              $winref->{Input}{Cursor} + length($space), length($word)
            ) = $word;

      $winref->{Input}{Cursor} += length($space . $word);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Uppercase from cursor on.  Requires uc($key)
  if (uc($key) eq '^[U') {

    # If there's text to uppercase.
    if (substr($winref->{Input}{Data}, $winref->{Input}{Cursor}) =~ /^(\s*)(\S+)/) {

      # Track leading space, and uppercase word.
      my $space = $1; $space = '' unless defined $space;
      my $word  = uc($2);

      # Replace text with the uppercase version.
      substr( $winref->{Input}{Data},
              $winref->{Input}{Cursor} + length($space), length($word)
            ) = $word;

      $winref->{Input}{Cursor} += length($space . $word);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Lowercase from cursor on.  Requires uc($key)
  if (uc($key) eq '^[L') {

    # If there's text to uppercase.
    if (substr($winref->{Input}{Data}, $winref->{Input}{Cursor}) =~ /^(\s*)(\S+)/) {

      # Track leading space, and uppercase word.
      my $space = $1; $space = '' unless defined $space;
      my $word  = lc($2);

      # Replace text with the uppercase version.
      substr( $winref->{Input}{Data},
              $winref->{Input}{Cursor} + length($space), length($word)
            ) = $word;

      $winref->{Input}{Cursor} += length($space . $word);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Forward one word.  Requires uc($key)
  if (uc($key) eq '^[F') {
    if (substr($winref->{Input}{Data}, $winref->{Input}{Cursor}) =~ /^(\s*\S+)/) {
      $winref->{Input}{Cursor} += length($1);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Backward one word.  This needs uc($key).
  if (uc($key) eq '^[B') {
    if (substr($winref->{Input}{Data}, 0, $winref->{Input}{Cursor}) =~ /(\S+\s*)$/) {
      $winref->{Input}{Cursor} -= length($1);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Delete a word forward.  This needs uc($key).
  if (uc($key) eq '^[D') {
    if ($winref->{Input}{Cursor} < length($winref->{Input}{Data})) {
      substr($winref->{Input}{Data}, $winref->{Input}{Cursor}) =~ s/^(\s*\S*\s*)//;
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Transpose words.  This needs uc($key).
  if (uc($key) eq '^[T') {
    my ($previous, $left, $space, $right, $rest);

    if (substr($winref->{Input}{Data}, $winref->{Input}{Cursor}, 1) =~ /\s/) {
      my ($left_space, $right_space);
      ($previous, $left, $left_space) =
        ( substr($winref->{Input}{Data}, 0, $winref->{Input}{Cursor}) =~ /^(.*?)(\S+)(\s*)$/
        );
      ($right_space, $right, $rest) =
        ( substr($winref->{Input}{Data}, $winref->{Input}{Cursor}) =~ /^(\s+)(\S+)(.*)$/
        );
      $space = $left_space . $right_space;
    }
    elsif ( substr($winref->{Input}{Data}, 0, $winref->{Input}{Cursor}) =~
            /^(.*?)(\S+)(\s+)(\S*)$/
          ) {
      ($previous, $left, $space, $right) = ($1, $2, $3, $4);
      if (substr($winref->{Input}{Data}, $winref->{Input}{Cursor}) =~ /^(\S*)(.*)$/) {
        $right .= $1 if defined $1;
        $rest = $2;
      }
    }
    elsif (substr($winref->{Input}{Data}, $winref->{Input}{Cursor}) =~ /^(\S+)(\s+)(\S+)(.*)$/
          ) {
      ($left, $space, $right, $rest) = ($1, $2, $3, $4);
      if ( substr($winref->{Input}{Data}, 0, $winref->{Input}{Cursor}) =~ /^(.*?)(\S+)$/ ) {
        $previous = $1;
        $left = $2 . $left;
      }
    }
    else {
      return;
    }

    $previous = '' unless defined $previous;
    $rest     = '' unless defined $rest;

    $winref->{Input}{Data}  = $previous . $right . $space . $left . $rest;
    $winref->{Input}{Cursor} = length($previous. $left . $space . $right);

    _refresh_edit($self, $window_id);
    doupdate();
    return;
  }

  # Toggle insert mode.
  if ($key eq 'KEY_IC') {
    $winref->{Input}{Insert} = !$winref->{Input}{Insert};
    return;
  }
  # If the window is scrolled up go back to the beginning.
  if ($key eq 'KEY_SELECT') {
    $winref->{Buffer_Row} = $winref->{Buffer_Last};
    _refresh_buffer($self, $window_id);
    _refresh_edit($self, $window_id);
    doupdate();
    return;
  }

  # Scroll back a page.  
  if ($key eq 'KEY_PPAGE') {
    if ($winref->{Buffer_Row} > $winref->{Buffer_First}) {
      $winref->{Buffer_Row} -= $winref->{Screen_Height};
      if ($winref->{Buffer_Row} < $winref->{Buffer_First}) {
        $winref->{Buffer_Row} = $winref->{Buffer_First}
      } 
      _refresh_buffer($self, $window_id);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Scroll forward a page. 
  if ($key eq 'KEY_NPAGE') {
    if ($winref->{Buffer_Row} < $winref->{Buffer_Last}) {
      $winref->{Buffer_Row} += $winref->{Screen_Height};
      if ($winref->{Buffer_Row} > $winref->{Buffer_Last}) {
        $winref->{Buffer_Row} = $winref->{Buffer_Last};
      }
      _refresh_buffer($self, $window_id);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Scroll back a line. 
  if ($key eq 'KEY_UP') {
    if ($winref->{Buffer_Row} > $winref->{Buffer_First}) {
      $winref->{Buffer_Row}--;
      _refresh_buffer($self, $window_id);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  # Scroll forward a line. 
  if ($key eq 'KEY_DOWN') {
    if ($winref->{Buffer_Row} < $winref->{Buffer_Last}) {
      $winref->{Buffer_Row}++;
      _refresh_buffer($self, $window_id);
      _refresh_edit($self, $window_id);
      doupdate();
    }
    return;
  }

  if ($key eq "^I") {
    if ($winref->{Input}{Tab_Complete}) {
      my $left = substr($winref->{Input}{Data}, 0, $winref->{Input}{Cursor});
      my $right = substr($winref->{Input}{Data}, $winref->{Input}{Cursor});
      my @str = $winref->{Input}{Tab_Complete}->($left, $right);
      my $complete_word = $1 if $left =~ /(\S+)\s*\z/;
      $left =~ s/\Q$complete_word\E\s*\z// if $complete_word;
      if (@str == 1) {
        my $data = $left . $str[0];
        $winref->{Input}{Data} = $data . $right;
        $winref->{Input}{Cursor} = length $data;
        _refresh_edit($self, $window_id);
        doupdate();
      }
      elsif (@str) {
        # complete to something they all have in common
        my $shortest = '';
        for (@str) {
          if (!length($shortest) or length($_) < length $shortest) {
            $shortest = $_;
          }
        }
        my $i = length $shortest;
        for (@str) {
          while (substr($shortest, 0, $i) ne substr($_, 0, $i) and $i) {
            $i--;
          }
          last unless $i;
        }
        if ($i) {
          $winref->{Input}{Data} = $left . substr($shortest, 0, $i) . $right;
          $winref->{Input}{Cursor} = length($left) + $i;
        }
        my $table = columnize(
            Items    => \@str,
            MaxWidth => $COLS
        );
        for (split /\n/, $table) {
          &print($self, $window_id, $_);
        }
      }
    }
    return;
  }

  ### Not an internal keystroke.  Add it to the input buffer.
  #FIXME double check if this is needed...
  $key = chr(ord($1)-64) if $key =~ /^\^([@-_BC])$/;

  # Inserting or overwriting in the middle of the input.
  if ($winref->{Input}{Cursor} < length($winref->{Input}{Data})) {
    if ($winref->{Input}{Insert}) {
      substr($winref->{Input}{Data}, $winref->{Input}{Cursor}, 0) = $key;
    }
    else {
      substr($winref->{Input}{Data}, $winref->{Input}{Cursor}, length($key)) = $key;
    }
  }

  # Appending.
  else {
    $winref->{Input}{Data} .= $key;
  }

  $winref->{Input}{Cursor} += length($key);
  _refresh_edit($self, $window_id);
  doupdate();
  return;
}

sub columnize {
  croak "Arguments to columnize must be a hash" if @_ & 1;
  my %opts = @_;

  my $width = delete $opts{MaxWidth};
  $width = 80 unless defined $width;
  croak "Invalid width $width" if $width <= 0;

  my $padding = delete $opts{Padding};
  $padding = 2 unless defined $padding;
  croak "Invalid padding $padding" if $padding < 0;

  my $max_columns = delete $opts{MaxColumns};
  $max_columns = 10 unless defined $max_columns;
  croak "Invalid max columns $max_columns" if $max_columns <= 0;

  my $items = delete $opts{Items};
  croak "Items must be an array reference"
    unless ref($items) eq 'ARRAY';

  croak "Unknown arguments: '", join("', '", sort keys %opts), "'"
    if keys %opts;

  for my $i (reverse 2 .. $max_columns) {
    my $n = 0;
    my @cols;
    my $num_rows = 0;
    for (0 .. $#{$items}) {
      push @{$cols[$n++]}, $items->[$_];
      unless (($_ + 1) % $i) {
        $n = 0;
        $num_rows++;
      }
    }
    my @long;
    for $n (0 .. $#cols) {
      for my $item (@{$cols[$n]}) {
        if (!$long[$n] or length($item) > $long[$n]) {
          $long[$n] = length $item;
        }
      }
    }
    my $total = 0;
    for (@long) {
      $total += $_ + $padding;
    }
    next if $total > $width;
    my $table = '';
    for (0 .. $num_rows) {
      my $row;
      for $n (0 .. $#cols) {
        my $item = $cols[$n][$_];
        last unless defined $item;
        $row .= $item . (' ' x ($long[$n] - length($item) + $padding));
      }
      $table .= $row . "\n";
    }
    return $table;
    last;
  }
  return join("\n", @$items) . "\n";
}
##FIXME Has this been replaced with _parse_key() ??
my %ctrl_to_visible;
BEGIN {
  for (0..31) {
    $ctrl_to_visible{chr($_)} = chr($_+64);
  }
}

### Common thing.  Refresh the buffer on the screen.
##  Pass in $self and a window_id 

sub _refresh_buffer {
  if (DEBUG) { print ERRS "Enter _refresh_buffer\n"; }
  my $self = shift;
  my $window_id = shift;
  my $winref = $self->[WINDOW]->{$window_id};
  my $screen = $winref->{Window_Screen};

  if ($window_id != $self->[CUR_WIN]) { return; }
  # Adjust the buffer row to compensate for any scrolling we encounter
  # while in scrollback.

  if ($winref->{Buffer_Row} < $winref->{Buffer_Last}) {
    $winref->{Buffer_Row} -= $winref->{Scrolled_Lines};
  }

  # Don't scroll up past the start of the buffer.

  if ($winref->{Buffer_Row} < $winref->{Buffer_First}) {
    $winref->{Buffer_Row} = $winref->{Buffer_First};
  }

  # Don't scroll down past the bottom of the buffer.

  if ($winref->{Buffer_Row} > $winref->{Buffer_Last}) {
    $winref->{Buffer_Row} = $winref->{Buffer_Last};
  }

  # Now splat the last N lines onto the screen.

  $screen->erase();
  $screen->noutrefresh();

  $winref->{Scrolled_Lines} = 0;

  my $screen_y = 0;
  my $buffer_y = $winref->{Buffer_Row} - $winref->{Buffer_Visible};
  while ($screen_y < $winref->{Screen_Height}) {
    $screen->move($screen_y, 0);
    $screen->clrtoeol();
    $screen->noutrefresh();

    next if $buffer_y < 0;
    next if $buffer_y > $winref->{Buffer_Last};

    my $line = $winref->{Buffer}->[$buffer_y]; # does this work?
    my $column = 1;
    while (length $line) {
      while ($line =~ s/^\0\(([^)]+)\)//) {
        my $cmd = $1;
        if ($cmd =~ /blink_(on|off)/) {
          if ($1 eq 'on') { $screen->attron(A_BLINK); }
          if ($1 eq 'off') { $screen->attroff(A_BLINK); }
          $screen->noutrefresh();
        }
        elsif ($cmd =~ /bold_(on|off)/) {
          if ($1 eq 'on') { $screen->attron(A_BOLD); }
          if ($1 eq 'off') { $screen->attroff(A_BOLD); }
          $screen->noutrefresh();
        }
        elsif ($cmd =~ /underline_(on|off)/) {
          if ($1 eq 'on') { $screen->attron(A_UNDERLINE); }
          if ($1 eq 'off') { $screen->attroff(A_UNDERLINE); }
          $screen->noutrefresh();
        }
        else {
          $screen->attrset($self->[PALETTE]->{$cmd}->[PAL_PAIR]); 
          $screen->noutrefresh();
        }
      }

      if ($line =~ s/^([^\0]+)//x) {

        # TODO: This needs to be revised so it cuts off the last word,
        # not omits it entirely.
        # Has this been fixed already??
        next if $column >= $COLS;
        if ($column + length($1) > $COLS) {
          my $word = $1;
          substr($word, ($column + length($1)) - $COLS - 1) = '';
          $screen->addstr($word);
        }
        else {
          $screen->addstr($1);
        }
        $column += length($1);
        $screen->noutrefresh();
      }
    }

    $screen->attrset($self->[PALETTE]->{ncolor}->[PAL_PAIR]); 
    $screen->noutrefresh();
    $screen->clrtoeol();
    $screen->noutrefresh();
  }
  continue {
    $screen_y++;
    $buffer_y++;
  }
}

# Internal function to set the color palette for a window.

sub _set_color {
  if (DEBUG) { print ERRS "Enter _set_color\n"; }
  my $self= shift;
#  my $window_id = shift;
#  my $winref = $self->[WINDOW]->{$window_id};
  my %params = @_;

  my %color_table =
   ( bk      => COLOR_BLACK,    black   => COLOR_BLACK,
     bl      => COLOR_BLUE,     blue    => COLOR_BLUE,
     br      => COLOR_YELLOW,   brown   => COLOR_YELLOW,
     fu      => COLOR_MAGENTA,  fuschia => COLOR_MAGENTA,
     cy      => COLOR_CYAN,     cyan    => COLOR_CYAN,
     gr      => COLOR_GREEN,    green   => COLOR_GREEN,
     ma      => COLOR_MAGENTA,  magenta => COLOR_MAGENTA,
     re      => COLOR_RED,      red     => COLOR_RED,
     wh      => COLOR_WHITE,    white   => COLOR_WHITE,
     ye      => COLOR_YELLOW,   yellow  => COLOR_YELLOW,
     de      => -1,             default => -1,
   );

  my %attribute_table =
   ( al         => A_ALTCHARSET,
     alt        => A_ALTCHARSET,
     alternate  => A_ALTCHARSET,
     blink      => A_BLINK,
     blinking   => A_BLINK,
     bo         => A_BOLD,
     bold       => A_BOLD,
     bright     => A_BOLD,
     dim        => A_DIM,
     fl         => A_BLINK,
     flash      => A_BLINK,
     flashing   => A_BLINK,
     hi         => A_BOLD,
     in         => A_INVIS,
     inverse    => A_REVERSE,
     inverted   => A_REVERSE,
     invisible  => A_INVIS,
     inviso     => A_INVIS,
     lo         => A_DIM,
     low        => A_DIM,
     no         => A_NORMAL,
     norm       => A_NORMAL,
     normal     => A_NORMAL,
     pr         => A_PROTECT,
     prot       => A_PROTECT,
     protected  => A_PROTECT,
     reverse    => A_REVERSE,
     rv         => A_REVERSE,
     st         => A_STANDOUT,
     stand      => A_STANDOUT,
     standout   => A_STANDOUT,
     un         => A_UNDERLINE,
     under      => A_UNDERLINE,
     underline  => A_UNDERLINE,
     underlined => A_UNDERLINE,
     underscore => A_UNDERLINE,
   );


  for my $color_name (keys %params) {

    my $description = $params{$color_name};
    my $foreground = 0;
    my $background = 0;
    my $attributes = 0;

    # Which is an alias to foreground or background depending on what
    # state we're in.
    my $which = \$foreground;

    # Clean up the color description.
    $description =~ s/^\s+//;
    $description =~ s/\s+$//;
    $description = lc($description);

    # Parse the description.
    foreach my $word (split /\s+/, $description) {

      # The word "on" means we're switching to background.
      if ($word eq 'on') {
        $which = \$background;
        next;
      }

      # If it's a color name, combine its value with the foreground or
      # background, whichever is currently selected.
      if (exists $color_table{$word}) {
        $$which |= $color_table{$word};
        next;
      }

      # If it's an attribute, it goes with attributes.
      if (exists $attribute_table{$word}) {
        $attributes |= $attribute_table{$word};
        next;
      }

      # Otherwise it's an error.
      if (DEBUG) { print ERRS "unknown color keyword \"$word\"\n"; }
      croak "unknown color keyword \"$word\"";
    }

    # If the palette already has that color, redefine it.
    if (exists $self->[PALETTE]->{$color_name}) {
      my $old_color_number = $self->[PALETTE]->{$color_name}->[PAL_NUMBER];
      init_pair($old_color_number, $foreground, $background);
      $self->[PALETTE]->{$color_name}->[PAL_PAIR] =
        COLOR_PAIR($old_color_number) | $attributes;
    }
    else {
      my $new_color_number = ++$self->[PAL_COL_SEQ];
      init_pair($new_color_number, $foreground, $background);
      $self->[PALETTE]->{$color_name} =
        [ COLOR_PAIR($new_color_number) | $attributes,  # PAL_PAIR
          $new_color_number,                            # PAL_NUMBER
          $description,                                 # PAL_DESC
        ];
    }
  }
}

### The terminal stopped.  Remove the reference count for the remote
### session.

sub terminal_stopped {
  if (DEBUG) { print ERRS "Enter terminal_stopped\n"; }
  my ($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->alias_remove($_[OBJECT][ALIAS]);
    delete $heap->{stderr_reader};
    undef $console;

  if (defined $heap->{input_session}) {
     $kernel->refcount_decrement( $heap->{input_session}, "terminal link" );
    delete $heap->{input_session};
  }
}

sub change_window {
  if (DEBUG) { print ERRS "change_window called\n"; }
  my $self = shift;
  my $window_id = shift;
  my @list = sort {$a <=> $b} keys %{$self->[WINDOW]};

  if (@list) {
    if ($window_id == -1) {
       $window_id = $list[$#list];
    }
    elsif ($window_id > $list[$#list]) {
      $window_id = 0;
    }
  }

  my $validity = validate_window($self, $window_id);
  if ($validity) {
    $self->[CUR_WIN] = $window_id;
    update_window( $self, $window_id );
  }
}

sub update_window {
  my $self = shift;
  my $window_id = shift;

  _refresh_title( $self, $window_id );
  _refresh_buffer( $self, $window_id );
  _refresh_status( $self, $window_id ); 
  _refresh_edit( $self, $window_id );
  doupdate();
}

sub _refresh_title {
  if (DEBUG) { print ERRS "Enter _refresh_title\n"; }
  my ($self, $window_id) = @_;
  my $winref = $self->[WINDOW]->{$window_id};
  my $title = $winref->{Window_Title};

  if ($window_id != $self->[CUR_WIN]) { return; }

  $title->move(TITLE_LINE, TITLE_COL);
  $title->attrset($self->[PALETTE]->{st_values}->[PAL_PAIR]); 
  $title->noutrefresh();
  $title->addstr($winref->{Title}) unless !$winref->{Title};
  $title->noutrefresh();
  $title->clrtoeol();
  $title->noutrefresh();
  doupdate();
}

sub _refresh_edit {
  if (DEBUG) { print ERRS "Enter _refresh_edit\n"; }
  my $self = shift;
  my $window_id = shift;
  my $winref = $self->[WINDOW]->{$window_id};
  my $edit = $winref->{Window_Edit};
  my $visible_input = $winref->{Input}{Data};

  # If the cursor is after the last visible edit position, scroll the
  # edit window left so the cursor is back on-screen.

  if ($winref->{Input}{Cursor} - $winref->{Input}{Edit_Position} >= $COLS) {
    $winref->{Input}{Edit_Position} = $winref->{Input}{Cursor} - $COLS + 1;
  }

  # If the cursor is moving left of the middle of the screen, scroll
  # things to the right so that both sides of the cursor may be seen.

  elsif ($winref->{Input}{Cursor} - $winref->{Input}{Edit_Position} < ($COLS >> 1)) {
    $winref->{Input}{Edit_Position} = $winref->{Input}{Cursor} - ($COLS >> 1);
    $winref->{Input}{Edit_Position} = 0 if $winref->{Input}{Edit_Position} < 0;
  }

  # If the cursor is moving right of the middle of the screen, scroll
  # things to the left so that both sides of the cursor may be seen.

  elsif ( $winref->{Input}{Cursor} <= length($winref->{Input}{Data}) - ($COLS >> 1) + 1 ){
    $winref->{Input}{Edit_Position} = $winref->{Input}{Cursor} - ($COLS >> 1);
  }

  # Condition $visible_input so it really is.
  $visible_input = substr($visible_input, $winref->{Input}{Edit_Position}, $COLS-1);

  $edit->attron(A_NORMAL);
  $edit->erase();
  $edit->noutrefresh();
  if ($winref->{Input}{Prompt}) {
    $visible_input = $winref->{Input}{Prompt} . $visible_input;
  }
  while (length($visible_input)) {
    if ($visible_input =~ /^[\x00-\x1f]/) {
      $edit->attron(A_UNDERLINE);
      while ($visible_input =~ s/^([\x00-\x1f])//) {
        $edit->addstr($ctrl_to_visible{$1});
      }
    }
    if ($visible_input =~ s/^([^\x00-\x1f]+)//) {
      $edit->attroff(A_UNDERLINE);
      $edit->addstr($1);
    }
  }

  $edit->noutrefresh();
  $edit->move( 0, $winref->{Input}{Cursor} - $winref->{Input}{Edit_Position} );
  $edit->noutrefresh();
}

### Set or call command history lines.

sub command_history {
  if (DEBUG) { print ERRS "Enter command_history\n"; }
  my $self = shift;
  my $window_id = shift;
  my $flag = shift;
  my $winref = $self->[WINDOW]->{$window_id};

  if ($flag == 0) { #add to command history

    # Add to the command history.  Discard the oldest item if the
    # history size is bigger than our maximum length.

    unshift(@{$winref->{Input}{Command_History}}, $winref->{Input}{Data});
    pop(@{$winref->{Input}{Command_History}}) if @{$winref->{Input}{Command_History}} > $winref->{Input}{History_Size};

    # Reset the input, saved input, and history position.  Repaint the
    # edit box.

    $winref->{Input}{Data_Save} = $winref->{Input}{Data} = "";
    $winref->{Input}{Cursor_Save} = $winref->{Input}{Cursor} = $winref->{Input}{Prompt_Size} || 0;
    $winref->{Input}{History_Position} = -1;

    _refresh_edit($self, $window_id);
    doupdate();

    return;
  }

  if ($flag == 1) { # get last history 'KEY_UP'

    # At <0 command history, we save the input and move into the
    # command history.  The saved input will be used in case we come
    # back.

    if ($winref->{Input}{History_Position} < 0) {
      if (@{$winref->{Input}{Command_History}}) {
        $winref->{Input}{Data_Save} = $winref->{Input}{Data};
        $winref->{Input}{Cursor_Save} = $winref->{Input}{Cursor};
        $winref->{Input}{Data} = 
          $winref->{Input}{Command_History}->[++$winref->{Input}{History_Position}];
        $winref->{Input}{Cursor} = length($winref->{Input}{Data});
        if ($winref->{Input}{Prompt_Size}) {
          $winref->{Input}{Cursor} += $winref->{Input}{Prompt_Size};
        }
        _refresh_edit($self, $window_id);
        doupdate();
      }
    }

    # If we're not at the end of the command history, then we go
    # farther back.

    elsif ($winref->{Input}{History_Position} < @{$winref->{Input}{Command_History}} - 1) {
      $winref->{Input}{Data} = $winref->{Input}{Command_History}->[++$winref->{Input}{History_Position}];
      $winref->{Input}{Cursor} = length($winref->{Input}{Data});
        if ($winref->{Input}{Prompt_Size}) {
          $winref->{Input}{Cursor} += $winref->{Input}{Prompt_Size};
        }
      _refresh_edit($self, $window_id);
      doupdate();
    }

    return;
  }

  if ($flag == 2) { # get next history 'KEY_DOWN'

    # At 0th command history.  Switch to saved input.
    unless ($winref->{Input}{History_Position}) {
      $winref->{Input}{Data} = $winref->{Input}{Data_Save};
      $winref->{Input}{Cursor} = $winref->{Input}{Cursor_Save};
      $winref->{Input}{History_Position}--;
      _refresh_edit($self, $window_id);
      doupdate();
    }

    # At >0 command history.  Move towards 0.
    elsif ($winref->{Input}{History_Position} > 0) {
      $winref->{Input}{Data} = $winref->{Input}{Command_History}->[--$winref->{Input}{History_Position}];
      $winref->{Input}{Cursor} = length($winref->{Input}{Data});
        if ($winref->{Input}{Prompt_Size}) {
          $winref->{Input}{Cursor} += $winref->{Input}{Prompt_Size};
        }
      _refresh_edit($self, $window_id);
      doupdate();
    }

    return;
  }

  warn "unknown flag $flag";
}

sub set_status_field {
  if (DEBUG) { print ERRS "Enter set_status_field\n"; }
  my $self = shift;
  my $window_id = shift;
  my $validity = validate_window($self, $window_id);
  if ($validity) {
    my $winref = $self->[WINDOW]->{$window_id};
    my $status_obj = $winref->{Status_Object};
    $winref->{Status_Lines} = $status_obj->set(@_);
      _refresh_status($self, $window_id);
      _refresh_edit($self, $window_id);
      doupdate();

  }
}

sub set_status_format {
  if (DEBUG) { print ERRS "Enter set_status_format\n"; }
  my $self = shift;
  my $window_id = shift;
  my %status_formats = @_;
  if (DEBUG) { print ERRS %status_formats, " <-status_formats\n"; }
  my $validity = validate_window($self, $window_id);
  if ($validity) {
    my $winref = $self->[WINDOW]->{$window_id};
    my $status_obj = $winref->{Status_Object};
  if (DEBUG) { print ERRS "calling status_obj->set_format\n"; }
    $status_obj->set_format(%status_formats);
  if (DEBUG) { print ERRS "calling status_obj->get\n"; }
  $winref->{Status_Lines} = $status_obj->get();
if (DEBUG) { print ERRS "calling refresh_status\n"; }
    # Update the status line.
    _refresh_status( $self, $window_id );
if (DEBUG) { print ERRS "returned from refresh_status\n"; }
    doupdate();
  }
}

sub _refresh_status {
  if (DEBUG) { print ERRS "Enter _refresh_status\n"; }
  my ($self, $window_id) = (shift, shift);

  if ($window_id != $self->[CUR_WIN]) { return; }

  my ($row, $value);
  my $winref = $self->[WINDOW]->{$window_id};
  my $status = $winref->{Window_Status};
  my @status_lines = @{$winref->{Status_Lines}};
  while (@status_lines) {
    if (DEBUG) { print ERRS "in main while loop of refresh_status\n"; }
    $row = shift @status_lines;
    $value = shift @status_lines;
if (DEBUG) { print ERRS "$row <-row value-> $value\n"; }
if (DEBUG) { print ERRS $status, "<-status ref\n"; }
    $status->move( $row, 0 );

    # Parse the value.  Stuff surrounded by ^C is considered color
    # names.  This interferes with epic/mirc colors.

    while (defined $value and length $value) {
      if (DEBUG) { print ERRS "while defined value and length value in refresh_status\n"; }
      if ($value =~ s/^\0\(([^\)]+)\)//) {
        if (DEBUG) { print ERRS "value matched", '^\0\(([^\)]+)\)', "\n"; }
        $status->attrset($self->[PALETTE]->{$1}->[PAL_PAIR]);
        $status->noutrefresh();
      }
      if ($value =~ s/^([^\0]+)//) {
        if (DEBUG) { print ERRS "value matched", '^([^\0]+)', "\n"; }
        $status->addstr($1);
        $status->noutrefresh();
      }
    }
  }

  # Clear to the end of the line, and refresh the status bar.
  $status->attrset($self->[PALETTE]->{st_frames}->[PAL_PAIR]); 
  $status->noutrefresh();
  $status->clrtoeol();
  $status->noutrefresh();

}

sub set_input_prompt {
  if (DEBUG) { print ERRS "Enter set_input_prompt\n"; }
  my $self = shift;
  my $window_id = shift;
  my $prompt = shift;
  my $validity = validate_window($self, $window_id);
  if ($validity) {
    my $winref = $self->[WINDOW]->{$window_id};
    $winref->{Input}{Cursor} -= $winref->{Input}{Prompt_Size};
    $winref->{Input}{Prompt} = $prompt;
    $winref->{Input}{Cursor} = $winref->{Input}{Prompt_Size} = length $prompt;
      _refresh_edit($self, $window_id);
      doupdate();
 }
}

sub set_errlevel {}
sub get_errlevel {}

sub debug {
  my $self = shift;
  if (DEBUG) { for (@_) { print ERRS "$_\n";} }
  else { carp "turn on debugging in Term::Visual or define sub Term::Visual::DEBUG () { 1 }; before use Term::Visual; in your program"; }

}

sub shutdown {
my $self = shift;

$poe_kernel->post($self->[ALIAS], "_stop");

#    $_[KERNEL]->alias_remove($_[OBJECT][ALIAS]);
#    delete $_[HEAP]->{stderr_reader};
#    undef $console;
#    if (defined $_[HEAP]->{input_session}) {
#      $_[KERNEL]->post( $_[HEAP]->{input_session}, $_[HEAP]->{input_event},
#                        undef, 'interrupt' );

#clean up, and close Term::Visual's session so that the only thing that is left is client side, and when ^\ is punched in, clean up things that would leak otherwise, and interrupt?

#    }
}

1;

__END__

=head1 NAME

Term::Visual - split-terminal user interface

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;

  use Term::Visual;

  my $vt = Term::Visual->new(    Alias => "interface",
                              Errlevel => 0 );

  $vt->set_palette( mycolor   => "magenta on black",
                    thiscolor => "green on black" );

  my $window_id = $vt->create_window(
        Window_Name  => "foo",

        Status       => { 0 =>
                           { format => "template for status line 1",
                             fields => [qw( foo bar )] },
                          1 =>
                           { format => "template for status line 2",
                             fields => [ qw( biz baz ) ] },
                        },

        Buffer_Size  => 1000,
        History_Size => 50,

        Input_Prompt => "[foo] ", # Set the input prompt for the input line.
 
        Use_Title    => 0, # Don't use a titlebar 
        Use_Status   => 0, # Don't use a statusbar

        Title        => "Title of foo"  );

  POE::Session->create
    (inline_states => {
       _start         => \&start_handler,
       got_term_input => \&term_input_handler,
     }
    );

  sub start_handler {
    my $kernel = $_[KERNEL];

    # Tell the terminal to send me input as "got_term_input".
    $kernel->post( interface => send_me_input => "got_term_input" );
                    
    $vt->set_status_field( $window_id, bar => $value );

    $vt->set_input_prompt($window_id, "\$");

    $vt->print( $window_id, "my Window ID is $window_id" );
  }

  sub term_input_handler {
      my ($kernel, $heap, $input, $exception) = @_[KERNEL, HEAP, ARG0, ARG1];

      # Got an exception.  These are interrupt (^C) or quit (^\).
      if (defined $exception) {
        warn "got exception: $exception";
        exit;
      }
      $vt->print($window_id, $input);
  }

  # Only use delete_window if using multiple windows.
  $vt->delete_window( $window_id ); 

  $vt->shutdown; 


=head1 DESCRIPTION

Term::Visual is a "visual" terminal interface for curses applications.
It provides the split-screen interface you may have seen in console
based IRC and MUD clients.

Term::Visual uses the POE networking and multitasking framework to support
concurrent input from network sockets and the console, multiple
timers, and more.

=head1 PUBLIC METHODS

Term::Visual->method();

=over 2

=item new

Create and initialize a new instance of Term::Visual.

  my $vt = Term::Visual->new( 
                     Alias => "interface",
              Common_Input => 1,
              Tab_Complete => sub { ... },                 
                  Errlevel => 0 );

Alias is a session alias for POE.

Common_Input is an optional flag used
  to globalize History_Position,
               History_Size,
               Command_History,
               Data,
               Data_Save,
               Cursor,
               Cursor_Save,
               Tab_Complete,
               Insert,
               Edit_Position
  in create_window();
Thus all windows created will have common input.

Tab_Complete is a handler for tab completion.

  Tab_Complete => sub {
    my $left = shift;
    my @return;
    my %complete = (
        foo => "foobar ",
        biz => "bizbaz ",
       );
    return $complete{$left};
   }

Tab_Complete is covered more indepth in the examples directory.
 
Errlevel not implemented yet.

Errlevel sets Term::Visual's error level.

=item create_window

  my $window_id = $vt->create_window( ... );

Set the window's name

  Window_Name => "foo"

Set the Statusbar's format

  Status => { 0 => # first statusline
               { format => "\0(st_frames)" .
                           " [" .
                           "\0(st_values)" .
                           "%8.8s" .
                           "\0(st_frames)" .
                           "] " .
                           "\0(st_values)" .
                           "%s",
                 fields => [qw( time name )] },
              1 => # second statusline
               { format => "foo %s bar %s",
                 fields => [qw( foo bar )] },
            } 

Set the size of the scrollback buffer

  Buffer_Size => 1000

Set the command history size

  History_Size => 50

Set the input prompt of the window

  Input_Prompt => "foo"

Set the title of the window

  Title => "This is the Titlebar"

Don't use Term::Visual's Titlebar.

  Use_Title => 0

Don't use Term::Visual's StatusBar.

  Use_Status => 0

No need to declare Use_Status or Use_Title if you want to use
the Statusbar or Titlebar.


=item send_me_input

send_me_input is a handler Term::Visual uses to send the client input
from a keyboard and mouse.

create a handler for parsing the input in your POE Session.

  POE::Session->create
    (inline_states => {
       _start         => \&start_handler,
       got_term_input => \&term_input_handler,
     }
    );
 
POE's _start handler is a good place to tell Term::Visual how to send you input.

  sub start_handler {
    my $kernel = $_[KERNEL];
 
    # Tell the terminal to send me input as "got_term_input".
    $kernel->post( interface => send_me_input => "got_term_input" );
    ...
  }    

Now create your "term_input_handler" to parse input.
In this case we simply check for exceptions and print 
the input to the screen.

  sub term_input_handler {
    my ($kernel, $heap, $input, $exception) = @_[KERNEL, HEAP, ARG0, ARG1];

    # Got an exception.  These are interrupt (^C) or quit (^\).
    if (defined $exception) {
      warn "got exception: $exception";
      exit;
    }
    $vt->print($window_id, $input);
  }

=item print

Prints lines of text to the main screen of a window

  $vt->print( $window_id, "this is a string" );

  my @array = qw(foo bar biz baz);
  $vt->print( $window_id, @array );

=item current_window

  my $current_window = $vt->current_window;

  $vt->print( $current_window, "current window is $current_window" );

=item get_window_name

  my $window_name = $vt->get_window_name( $window_id );

=item get_window_id

  my $window_id = $vt->get_window_id( $window_name );

=item delete_window

  $vt->delete_window($window_id);

or

  $vt->delete_window(@window_ids);

=item validate_window

  my $validity = $vt->validate_window( $window_id );

or 

  my $validity = $vt->validate_window( $window_name );

  if ($validity) { do stuff };

=item get_palette

Return color palette or a specific colorname's description.

  my %palette = $vt->get_palette();

  my $color_desc = $vt->get_palette($colorname);

  my ($foo, $bar) = $vt->get_palette($biz, $baz);

=item set_palette

Set the color palette or specific colorname's value.

  $vt->set_palette( color_name => "color on color" );

  $vt->set_palette( color_name => "color on color",
                    another    => "color on color" );

  NOTE: (ncolor, st_values, st_frames, stderr_text, stderr_bullet, statcolor)
         are set and used by Term::Visual internally.
         It is safe to redifine there values.

=item color codes

Once your color definitions are set in the palette you must insert
color codes to your output.
These are formatted as follows: "\0(ncolor)"

So if you wanted to print something with a color you could simply use:

  $vt->print( $window_id, "\0(color_name)My this is a wonderful color." );

=item set_title

  $vt->set_title( $window_id, "This is the new Title" );

=item get_title

  my $title = $vt->get_title( $window_id );

=item change_window

Switch between windows

  $vt->change_window( $window_id );

  $vt->change_window( 0 );

  ...

  $vt->change_window( 1 );

=item set_status_format

  $vt->set_status_format( $window_id,
            0 => { format => "template for status line 1",
                   fields  => [ qw( foo bar ) ] },
            1 => { format => "template for status line 2",
                   fields  => [ qw( biz baz ) ] }, );

=item set_status_field

  $vt->set_status_field( $window_id, field => "value" );

  $vt->set_status_field( $window_id, foo => "bar", biz => "baz" );

=item set_input_prompt

  $vt->set_input_prompt($window_id, "\$");

  $vt->set_input_prompt($window_id, "[foo]");

=item columnize
  columnize takes a list of text and formats it into
  a columnized table.

  columnize is used internally, but might be of use 
  externally as well.

  Arguments given to columnize must be a hash.
  key 'Items' must be an array reference.
  The default value for Maxwidth may change to $COLS.

  my $table = $vt->columnize( 
     Items => \@list, 
     Padding => 2, # default value and optional
     MaxColumns => 10, # default value and optional
     MaxWidth => 80 # default value and optional
  );

=item bind

  bind is used for key bindings.
  our %Bindings = (
      Up   => 'history',
      Down => 'history',
       ...
  );

  $vt->bind(%Bindings);

  sub handler_history {
    my ($kernel, $heap, $key, $win) = @_[KERNEL, HEAP, ARG0, ARG2];
    if ($key eq 'KEY_UP') {
      $vt->command_history($win, 1);
    }
    else {
      $vt->command_history($win, 2);
    }
  }

  POE::Session->create(
      inline_states => {
          _start => \&handler_start,
          _stop  => \&handler_stop,
          history => \&handler_history,
          ...
      }
  );    


=item unbind
  unbind a key

  $vt->unbind('Up', 'Down');
  $vt->unbind(keys %Bindings);

=item debug
  write to the debug file

  $vt->debug("message");

  Debugging must be turned on before using this.

  change sub DEBUG () { 0 } to 1 or
  add this to your program: 
  sub Term::Visual::DEBUG () { 1 }
  use Term::Visual;

=item shutdown
  shutdown Term::Visual

  $vt->shutdown();

=back

=head1 Internal Keystrokes

=over 2

=item Ctrl A or KEY_HOME

Move to BOL.

=item KEY_LEFT

Back one character.

=item Alt P or Esc KEY_LEFT

Switch Windows decrementaly.

=item Alt N or Esc KEY_RIGHT

Switch Windows incrementaly.

=item Alt K or KEY_END

Not implemented yet.

Kill a Window.

=item Ctrl \

Kill Term::Visual.

=item Ctrl D or KEY_DC

Delete a character.

=item Ctrl E or KEY_LL

Move to EOL.

=item Ctrl F or KEY_RIGHT

Forward a character.

=item Ctrl H or KEY_BACKSPACE

Backward delete character.

=item Ctrl J or Ctrl M 'Return'

Accept a line.

=item Ctrl K

Kill to EOL.

=item Ctrl L or KEY_RESIZE

Refresh screen.

=item Ctrl N

Next in history.

=item Ctrl P

Previous in history.

=item Ctrl Q

Display input status.

=item Ctrl T

Transpose characters.

=item Ctrl U

Discard line.

=item Ctrl W

Word rubout.

=item Esc C

Capitalize word to right of cursor.

=item Esc U

Uppercase WORD.

=item Esc L

Lowercase word.

=item Esc F

Forward one word.

=item Esc B

Backward one word.

=item Esc D

Delete a word forward.

=item Esc T

Transpose words.

=item KEY_IC 'Insert'

Toggle Insert mode.

=item KEY_SELECT 'Home'

If window is scrolled up, page all the way down.

=item KEY_PPAGE 'Page Down'

Scroll down a page.

=item KEY_NPAGE 'Page Up'

Scroll up a page.

=item KEY_UP

Scroll up a line.

=item KEY_DOWN

Scroll down a line.

=back    

=head1 Author

=over 2

=item Charles Ayres


Except where otherwise noted, 
Term::Visual is Copyright 2002-2007 Charles Ayres. All rights reserved.
Term::Visual is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

Questions and Comments can be sent to lunartear@cpan.org

Please send bug reports and wishlist items to:
 http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-Visual

=back

=head1 Acknowledgments

=over 2

=item Rocco Caputo

A Big thanks to Rocco Caputo. 

Rocco has contributed to the development
of Term::Visual In many ways.

Rocco Caputo <troc+visterm@pobox.com>

=back

Thank you!

=cut

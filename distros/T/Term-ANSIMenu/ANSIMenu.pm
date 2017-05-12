package Term::ANSIMenu;

use 5.006;
use strict;
use warnings;
use Carp;
use Term::ReadKey;

our $VERSION = '0.02';

#===============================================================================
#Constants
#===============================================================================

#Screen control
use constant VT100      => "\x1B[61\"p";
use constant LINES      => "\x1B(0";
use constant ASCII      => "\x1B(B";
use constant WRAP_ON    => "\x1B[?7h";
use constant WRAP_OFF   => "\x1B[?7l";
use constant REGION_ON  => "\x1B[?6h";
use constant REGION_OFF => "\x1B[?6l";

#Deleting
use constant DEL_TO_END     => "\x1B[0K";
use constant DEL_FROM_BEGIN => "\x1B[1K";
use constant DEL_LINE       => "\x1B[2K";
use constant DEL_TO_EOS     => "\x1B[0J";
use constant DEL_FROM_BOS   => "\x1B[1J";
use constant DEL_SCREEN     => "\x1B[2J";
use constant CLS            => "\x1B[2J";

#Cursor control
use constant CURSOR_OFF  => "\x1B[?25l";
use constant CURSOR_ON   => "\x1B[?25h";
use constant CURSOR_SAV  => "\x1B7";
use constant CURSOR_RST  => "\x1B8";
use constant REGION_UP   => "\x1BM";
use constant REGION_DOWN => "\x1BD";
use constant NEXT_LINE   => "\x1BE";
use constant HOME        => "\x1B[H";

#Line drawing
use constant HOR => LINES . "q" . ASCII;
use constant VER => LINES . "x" . ASCII;
use constant ULC => LINES . "l" . ASCII;
use constant URC => LINES . "k" . ASCII;
use constant LRC => LINES . "j" . ASCII;
use constant LLC => LINES . "m" . ASCII;
use constant LTE => LINES . "t" . ASCII;
use constant RTE => LINES . "u" . ASCII;
use constant TTE => LINES . "w" . ASCII;
use constant BTE => LINES . "v" . ASCII;
use constant CTE => LINES . "n" . ASCII;

#Attributes
use constant CLEAR     => "\x1B[0m";
use constant RESET     => "\x1B[0m";
use constant BOLD      => "\x1B[1m";
use constant DIM       => "\x1B[2m";
use constant UNDERLINE => "\x1B[4m";
use constant BLINK     => "\x1B[5m";
use constant REVERSE   => "\x1B[7m";
use constant HIDDEN    => "\x1B[8m";

#Colors
use constant  BLACK   => "\x1B[30m";
use constant  RED     => "\x1B[31m";
use constant  GREEN   => "\x1B[32m";
use constant  YELLOW  => "\x1B[33m";
use constant  BLUE    => "\x1B[34m";
use constant  MAGENTA => "\x1B[35m";
use constant  CYAN    => "\x1B[36m";
use constant  WHITE   => "\x1B[37m";

use constant  ON_BLACK   => "\x1B[40m";
use constant  ON_RED     => "\x1B[41m";
use constant  ON_GREEN   => "\x1B[42m";
use constant  ON_YELLOW  => "\x1B[43m";
use constant  ON_BLUE    => "\x1B[44m";
use constant  ON_MAGENTA => "\x1B[45m";
use constant  ON_CYAN    => "\x1B[46m";
use constant  ON_WHITE   => "\x1B[47m";

#===============================================================================
#Encapsulated data
#===============================================================================

{
  my %_attribs = (           #Default value              Mode   #Comment
    _term_width           => [0,                         'r' ], #INT
    _term_height          => [0,                         'r' ], #INT
    _width                => [0,                         'rw'], #INT, clip if < length title or > $term_width
    _height               => [0,                         'rw'], #INT, clip if > $height
    _space_after_title    => [1,                         'rw'], #BOOL
    _space_after_items    => [1,                         'rw'], #BOOL
    _space_after_status   => [0,                         'rw'], #BOOL
    _spacious_items       => [0,                         'rw'], #BOOL
    _cursor               => [1,                         'rw'], #BOOL
    _cursor_char          => ['?',                       'rw'], #CHAR
    _up_keys              => [['UP', 'PGUP', 'LEFT'],    'rw'], #ARRAY of keys
    _down_keys            => [['DOWN', 'PGDN', 'RIGHT'], 'rw'], #ARRAY of keys
    _exit_keys            => [['q', 'Q', 'CTRL-c'],      'rw'], #ARRAY of keys
    _help_keys            => [['F1', '?']              , 'rw'], #ARRAY of keys
    _help                 => [[],                        'rw'], #ARRAY of [status_msg, CODE reference]
    _selection            => [0,                         'rw'], #INT, > 0 and <= number of items
    _selection_keys       => [['SPACE', 'ENTER'],        'rw'], #ARRAY of keys
    _selection_wrap       => [1,                         'rw'], #BOOL
    _selection_style      => [['REVERSE'],               'rw'], #ARRAY of attributes BLINK, REVERSE, BOLD, UNDERLINE or CLEAR
    _selection_fgcolor    => ['',                        'rw'], #FGCOLOR
    _selection_bgcolor    => ['',                        'rw'], #BGCOLOR
    _leader               => [0,                         'rw'], #BOOL
    _leader_delimiter     => ['',                        'rw'], #STR or LINE CHAR
    _trailer              => [0,                         'rw'], #BOOL
    _trailer_delimiter    => ['',                        'rw'], #STR or LINE CHAR
    _shortcut_prefix      => ['',                        'rw'], #STR or LINE CHAR
    _shortcut_postfix     => ['',                        'rw'], #STR or LINE CHAR
    _delimiter            => ['',                        'rw'], #STR or LINE CHAR
    _label_prefix         => ['',                        'rw'], #STR or LINE CHAR
    _label_postfix        => ['',                        'rw'], #STR or LINE CHAR
    _title                => ['',                        'rw'], #STR
    _title_style          => [['BOLD'],                  'rw'], #ARRAY of attributes BLINK, REVERSE, BOLD, UNDERLINE or CLEAR
    _title_fgcolor        => ['',                        'rw'], #FGCOLOR
    _title_bgcolor        => ['',                        'rw'], #BGCOLOR
    _title_align          => ['CENTER',                  'rw'], #LEFT|RIGHT|CENTER
    _title_fill           => [1,                         'rw'], #BOOL
    _title_frame          => [1,                         'rw'], #BOOL
    _title_frame_style    => [['BOLD'],                  'rw'], #ARRAY of attributes BLINK, REVERSE, BOLD or CLEAR
    _title_frame_fgcolor  => ['',                        'rw'], #FGCOLOR
    _title_frame_bgcolor  => ['',                        'rw'], #BGCOLOR
    _items                => [[],                        'rw'], #ARRAY of ['shortcut', 'description', \&code ]
    _item_style           => [['CLEAR'],                 'rw'], #ARRAY of attributes BLINK, REVERSE, BOLD, UNDERLINE or CLEAR
    _item_fgcolor         => ['',                        'rw'], #FGCOLOR
    _item_bgcolor         => ['',                        'rw'], #BGCOLOR
    _item_align           => ['LEFT',                    'rw'], #LEFT|RIGHT|CENTER
    _item_fill            => [1,                         'rw'], #BOOL
    _item_frame           => [1,                         'rw'], #BOOL
    _item_frame_style     => [['CLEAR'],                 'rw'], #ARRAY of attributes BLINK, REVERSE, BOLD or CLEAR
    _item_frame_fgcolor   => ['',                        'rw'], #FGCOLOR
    _item_frame_bgcolor   => ['',                        'rw'], #BGCOLOR
    _status               => ['',                        'rw'], #STR
    _status_style         => [['CLEAR'],                 'rw'], #ARRAY of attributes BLINK, REVERSE, BOLD, UNDERLINE or CLEAR
    _status_fgcolor       => ['',                        'rw'], #FGCOLOR
    _status_bgcolor       => ['',                        'rw'], #BGCOLOR
    _status_align         => ['LEFT',                    'rw'], #LEFT|RIGHT|CENTER
    _status_fill          => [1,                         'rw'], #BOOL
    _status_frame         => [0,                         'rw'], #BOOL
    _status_frame_style   => [['CLEAR'],                 'rw'], #ARRAY of attributes BLINK, REVERSE, BOLD or CLEAR
    _status_frame_fgcolor => ['',                        'rw'], #FGCOLOR
    _status_frame_bgcolor => ['',                        'rw'], #BGCOLOR
    _prompt               => ['',                        'rw'], #STR
    _prompt_style         => [['BOLD'],                  'rw'], #ARRAY of attributes BLINK, REVERSE, BOLD, UNDERLINE or CLEAR
    _prompt_fgcolor       => ['',                        'rw'], #FGCOLOR
    _prompt_bgcolor       => ['',                        'rw'], #BGCOLOR
    _prompt_align         => ['LEFT',                    'rw'], #LEFT|RIGHT|CENTER
    _prompt_fill          => [1,                         'rw'], #BOOL
    _prompt_frame         => [0,                         'rw'], #BOOL
    _prompt_frame_style   => [['BOLD'],                  'rw'], #ARRAY of attributes BLINK, REVERSE, BOLD or CLEAR
    _prompt_frame_fgcolor => ['',                        'rw'], #FGCOLOR
    _prompt_frame_bgcolor => ['',                        'rw']);#BGCOLOR

  my %_keynames = ( "\e[1~"  => "HOME",   #Linux console
                    "\e[2~"  => "INSERT", #VT100
                    "\e[3~"  => "DEL",    #VT100
                    "\e[4~"  => "END",    #Linux console
                    "\e[5~"  => "PGUP",   #VT100
                    "\e[6~"  => "PGDN",   #VT100
                    "\e[11~" => "F1",     #VT100
                    "\e[12~" => "F2",     #VT100
                    "\e[13~" => "F3",     #VT100
                    "\e[14~" => "F4",     #VT100
                    "\e[15~" => "F5",     #VT100
                    "\e[17~" => "F6",     #VT100
                    "\e[18~" => "F7",     #VT100
                    "\e[19~" => "F8",     #VT100
                    "\e[20~" => "F9",     #VT100
                    "\e[21~" => "F10",    #VT100
                    "\e[23~" => "F11",    #VT100
                    "\e[24~" => "F12",    #VT100
                    "\e[[A"  => "F1",     #Linux console
                    "\e[[B"  => "F2",     #Linux console
                    "\e[[C"  => "F3",     #Linux console
                    "\e[[D"  => "F4",     #Linux console
                    "\e[[E"  => "F5",     #Linux console
                    "\e[A"   => "UP",     #VT100
                    "\e[B"   => "DOWN",   #VT100
                    "\e[C"   => "RIGHT",  #VT100
                    "\e[D"   => "LEFT",   #VT100
                    "\e[F"   => "END",    #VT100
                    "\e[H"   => "HOME",   #VT100
                    "\eOA"   => "UP",     #XTerm
                    "\eOB"   => "DOWN",   #XTerm
                    "\eOC"   => "RIGHT",  #XTerm
                    "\eOD"   => "LEFT",   #XTerm
                    "\eOF"   => "END",    #XTerm
                    "\eOH"   => "HOME",   #XTerm
                    "\eOP"   => "F1",     #XTerm
                    "\eOQ"   => "F2",     #XTerm
                    "\eOR"   => "F3",     #XTerm
                    "\eOS"   => "F4",     #XTerm
                    "\ea"    => "META-a",
                    "\eb"    => "META-b",
                    "\ec"    => "META-c",
                    "\ed"    => "META-d",
                    "\ee"    => "META-e",
                    "\ef"    => "META-f",
                    "\eg"    => "META-g",
                    "\eh"    => "META-h",
                    "\ei"    => "META-i",
                    "\ej"    => "META-j",
                    "\ek"    => "META-k",
                    "\el"    => "META-l",
                    "\em"    => "META-m",
                    "\en"    => "META-n",
                    "\eo"    => "META-o",
                    "\ep"    => "META-p",
                    "\eq"    => "META-q",
                    "\er"    => "META-r",
                    "\es"    => "META-s",
                    "\et"    => "META-t",
                    "\eu"    => "META-u",
                    "\ev"    => "META-v",
                    "\ew"    => "META-w",
                    "\ex"    => "META-x",
                    "\ey"    => "META-y",
                    "\ez"    => "META-z",
                    "\x01"   => "CTRL-a",
                    "\x02"   => "CTRL-b",
                    "\x03"   => "CTRL-c",
                    "\x04"   => "CTRL-d",
                    "\x05"   => "CTRL-e",
                    "\x06"   => "CTRL-f",
                    "\x07"   => "CTRL-g",
                    "\x08"   => "CTRL-h",
                    "\x09"   => "TAB",    #Also CRTL-i
                    "\x0A"   => "ENTER",  #Also CTRL-j
                    "\x0B"   => "CTRL-k",
                    "\x0C"   => "CTRL-l",
                    "\x0D"   => "CTRL-m", #Apparently CTRL-m gives \x0A
                    "\x0E"   => "CTRL-n",
                    "\x0F"   => "CTRL-o",
                    "\x10"   => "CTRL-p",
                    "\x11"   => "CTRL-q",
                    "\x12"   => "CTRL-r",
                    "\x13"   => "CTRL-s",
                    "\x14"   => "CTRL-t",
                    "\x15"   => "CTRL-u",
                    "\x16"   => "CTRL-v",
                    "\x17"   => "CTRL-w",
                    "\x18"   => "CTRL-x",
                    "\x19"   => "CTRL-y",
                    "\x1A"   => "CTRL-z",
                    "\x20"   => "SPACE",
                    "\x7F"   => "BS");

  #Get the name of a key or return undef
  sub _get_keyname {
    my ($self, $sequence) = @_;
    my $keyname = undef;
    $keyname = $_keynames{$sequence} if exists $_keynames{$sequence};
    return $keyname;
  }

  #Is argument a valid key name?
  sub _is_keyname {
    my ($self, $name) = @_;
    return 1 if length($name) == 1 and $name =~ /^[[:graph:] ]$/;
    my %keynames = reverse %_keynames;
    return 1 if exists $keynames{$name};
    return 0;
  }

 #Get default value for an attribute
  sub _get_default {
    my ($self, $attrib) = @_;
    return $_attribs{$attrib}[0];
  }

  #Get a list of all attributes
  sub _list_attribs {
    return keys %_attribs;
  }

  #Verify the access mode for an attribute
  sub _check_mode {
    my ($self, $attrib, $mode) = @_;
    return $_attribs{$attrib}[1] =~ /$mode/i;
  }

  #Verify existence of an attribute
  sub _check_attrib {
    my ($self, $attrib) = @_;
    return exists $_attribs{$attrib};
  }

  #Verify validity of an attribute value
  sub _check_value {
    my ($self, $attrib, $value) = @_;
    my $ok = 0;
    #Make sure a value was given
    return $ok unless defined $value;
    #Now check if the given value(s) is/are appropriate
    SWITCH: {
      if ($attrib eq '_width') {
        $ok++ if $value > 0 and $value < $self->{_term_width};
        last SWITCH;
      }
      if ($attrib eq '_height') {
        $ok++ if $value > 0 and $value < $self->{_term_height};
        last SWITCH;
      }
      if ($attrib =~ /^_space_after_/) {
        $ok++ if $value =~ /^(?:\-|\+|0|1|NO|N|YES|Y|FALSE|F|TRUE|T)$/i;
        last SWITCH;
      }
      if ($attrib eq '_spacious_items') {
        $ok++ if $value =~ /^(?:\-|\+|0|1|NO|N|YES|Y|FALSE|F|TRUE|T)$/i;
        last SWITCH;
      }
      if ($attrib eq '_cursor') {
        $ok++ if $value =~ /^(?:\-|\+|0|1|NO|N|YES|Y|FALSE|F|TRUE|T)$/i;
        last SWITCH;
      }
      if ($attrib eq '_cursor_char') {
        $ok++ if $value =~ /^[[:graph:] ]$/;
        last SWITCH;
      }
      if ($attrib eq '_selection') {
        $ok++ if $value =~ /^\d+$/ and $value <= scalar(@{$self->{_items}});
        last SWITCH;
      }
      if ($attrib eq '_selection_wrap') {
        $ok++ if $value =~ /^(?:\-|\+|0|1|NO|N|YES|Y|FALSE|F|TRUE|T)$/i;
        last SWITCH;
      }
      if ($attrib eq '_help') {
        last SWITCH unless ref($value) eq 'ARRAY';
        foreach my $help (@{$value}) {
          if (defined $help) {
            last SWITCH unless ref($help) eq 'ARRAY';
            if (defined $help->[0]) {
              last SWITCH unless $help->[0] =~ /^[[:graph:] ]*$/;
            }
            if (defined $help->[1]) {
              last SWITCH unless ref($help->[1]) eq 'CODE';
            }
          }
        }
        $ok++;
        last SWITCH;
      }
      if ($attrib =~ /_keys$/) {
        last SWITCH unless ref($value) eq 'ARRAY';
        foreach my $arg (@{$value}) {
          last SWITCH unless $self->_is_keyname($arg);
        }
        $ok++;
        last SWITCH;
      }
      if ($attrib eq '_items') {
        last SWITCH unless ref($value) eq 'ARRAY';
        foreach my $item (@{$value}) {
          last SWITCH unless ref($item) eq 'ARRAY';
          last SWITCH unless defined($item->[0]) and $self->_is_keyname($item->[0]);
          last SWITCH unless defined($item->[1]) and $item->[1] =~ /^[[:graph:] ]*$/;
          if (defined $item->[2]) {
            last SWITCH unless ref($item->[2]) eq 'CODE';
          }
        }
        $ok++;
        last SWITCH;
      }
      if ($attrib =~ /_fill$/) {
        $ok++ if $value =~ /^(?:\-|\+|0|1|NO|N|YES|Y|FALSE|F|TRUE|T)$/i;
        last SWITCH;
      }
      if ($attrib =~ /_(?:leader|trailer)$/) {
        $ok++ if $value =~ /^(?:\-|\+|0|1|NO|N|YES|Y|FALSE|F|TRUE|T)$/i;
        last SWITCH;
      }
      if ($attrib =~ /_(?:pre|post)fix$/) {
        if ($value =~ /^ *(?:HOR|VER|ULC|URC|LRC|LLC|LTE|RTE|TTE|BTE|CTE) *$/) {
          $ok++;
        }
        elsif ($value =~ /^[[:graph:] ]*$/) {
          $ok++;
        }
        last SWITCH;
      }
      if ($attrib =~ /_delimiter$/) {
        if ($value =~ /^(?:HOR|VER|ULC|URC|LRC|LLC|LTE|RTE|TTE|BTE|CTE)$/) {
          $ok++;
        }
        elsif ($value =~ /^[[:graph:] ]?$/) {
          $ok++;
        }
        last SWITCH;
      }
      if ($attrib =~ /^_(?:prompt|status|title)$/) {
        $ok++ if $value =~ /^[[:graph:] ]*$/;
        last SWITCH;
      }
      if ($attrib =~ /_align$/) {
        $ok++ if $value =~ /^(?:LEFT|RIGHT|CENTER)$/i;
        last SWITCH;
      }
      if ($attrib =~ /_frame$/) {
        $ok++ if $value =~ /^(?:\-|\+|0|1|NO|N|YES|Y|FALSE|F|TRUE|T)$/i;
        last SWITCH;
      }
      if ($attrib =~ /_frame_style$/) {
        last SWITCH unless ref($value) eq 'ARRAY';
        foreach my $arg (@{$value}) {
          last SWITCH unless $arg =~ /^(?:BLINK|REVERSE|BOLD|CLEAR)$/i;
        }
        $ok++;
        last SWITCH;
      }
      if ($attrib =~ /_style$/) {
        last SWITCH unless ref($value) eq 'ARRAY';
        foreach my $arg (@{$value}) {
          last SWITCH unless $arg =~ /^(?:BLINK|REVERSE|BOLD|UNDERLINE|CLEAR)$/i;
        }
        $ok++;
        last SWITCH;
      }
      if ($attrib =~ /_[fb]gcolor$/) {
        $ok++ if $value =~ /^(?:BLACK|RED|GREEN|YELLOW|BLUE|MAGENTA|CYAN|WHITE)$/i;
        last SWITCH;
      }
      else {
        croak "No such attribute: $attrib";
      }
    }
    return $ok;
  }

  sub _linestr_length {
    my ($self, $str) = @_;

    my $length = 0;
    if ($str =~ /^( *)(?:HOR|VER|ULC|URC|LRC|LLC|LTE|RTE|TTE|BTE|CTE)( *)$/) {
      $length = length($1) + 1 + length($2);
    }
    else {
      $length = length $str;
    }
    return $length;
  }

  sub _print_linestr {
    my ($self, $str) = @_;

    if ($str =~ /^( *)(HOR|VER|ULC|URC|LRC|LLC|LTE|RTE|TTE|BTE|CTE)( *)$/) {
      print $1;
      print &{\&$2};
      print $3;
    }
    else {
      print $str;
    }
  }

  sub _print_color {
    my ($self, $fgcolor, $bgcolor) = @_;

    print &{\&$fgcolor} if $fgcolor;
    if ($bgcolor) {
      $bgcolor = "ON_" . $bgcolor;
      print &{\&$bgcolor};
    }
  }

  sub _print_style {
    my ($self, @styles) = @_;

    foreach my $style (@styles) {
      print &{\&$style} if $style;
    }
  }

  sub _items_start {
    my $self = shift;

    my $line = 1;
    if (length($self->title()) > 0) {
      $line++;
      $line += 2 if $self->title_frame();
      $line++ if $self->space_after_title();
    }
    return $line;
  }

  sub _status_start {
    my $self = shift;

    my $line = $self->_items_start();
    if ($self->item_count() > 0) {
      $line++ if $self->leader() and not $self->item_frame();
      $line += 2 if $self->item_frame();
      $line += $self->item_count();
      $line += $self->item_count() - 1 if $self->item_frame() and $self->spacious_items() and $self->item_count() > 1;
      $line++ if $self->trailer() and not $self->item_frame();
      $line++ if $self->space_after_items();
    }
    return $line;
  }

  sub _prompt_start {
    my $self = shift;

    my $line = $self->_status_start();
    if (length($self->status()) > 0) {
      $line++;
      $line += 2 if $self->status_frame();
      $line++ if $self->space_after_status();
    }
    return $line;
  }

  sub _cursor_pos {
    my $self = shift;

    my $line = $self->_prompt_start();
    $line++ if $self->prompt_frame();
    my $max_length = $self->width() - 1;
    $max_length -= 2 if $self->prompt_frame();
    my $prompt_length = length $self->prompt();
    $prompt_length = $max_length if $prompt_length > $max_length;
    my $padding = $max_length - $prompt_length;
    $padding = 0 if $padding < 0;
    my $col = 1;
    if ($self->prompt_fill()) {
      if ($self->prompt_align() eq 'CENTER') {
        $padding = int ($padding / 2);
        $col += $padding + $prompt_length;
        $col++ if $self->prompt_frame();
      }
      elsif ($self->prompt_align() eq 'RIGHT') {
        $col += $padding + $prompt_length;
        $col++ if $self->prompt_frame();
      }
      else {
        $col += $prompt_length;
        $col++ if $self->prompt_frame();
      }
    }
    else {
      $col += $prompt_length;
      $col++ if $self->prompt_frame();
    }
    return $line, $col;
  }

  sub _clear_after_items {
    my $self = shift;

    $self->pos($self->_status_start(), 1);
    print DEL_TO_EOS;
  }

  sub _update_hint {
    my ($self, $hint) = @_;

    if (defined $hint and $self->_check_value('_status', $hint)) {
      $self->_clear_after_items();
      $self->print_status($hint) if $self->status();
      $self->print_prompt() if $self->prompt();
      $self->print_cursor();
    }
  }

}

#===============================================================================
#Constructor and destructor
#===============================================================================

sub new {
  my ($caller, %args) = @_;

  my $caller_is_obj = ref($caller);
  my $class = $caller_is_obj || $caller;
  my $self = bless {}, $class;

  #Set attributes
  my ($w, $h) = GetTerminalSize;
  $self->{_term_width} = $w;
  $self->{_term_height} = $h;
  foreach my $attrib ($self->_list_attribs()) {
    next unless $self->_check_mode($attrib, 'w');
    my ($arg) = ($attrib =~ /^_(\w+)/);
    if (exists $args{$arg}) {
      if ($self->_check_value($attrib, $args{$arg})) {
        $self->{$attrib} = $self->$arg($args{$arg});
      }
      else {
        croak "Invalid value for $arg: $args{$arg}";
      }
    }
    elsif ($caller_is_obj) {
      $self->{$attrib} = $caller->{$attrib};
    }
    else {
      $self->{$attrib} = $self->_get_default($attrib);
    }
  }
  $self->{_width} = $w unless $self->_check_value('_width', $self->{_width});
  $self->{_height} = $h unless $self->_check_value('_height', $self->{_height});
  #Initialize terminal
  $| = 1;            #Set flush mode
  print "\e[61\"p";  #Set VT100 mode
  print "\e[2J";     #Clear screen
  print "\e[1;1H";   #Position cursor at top left
  return $self;
}

sub DESTROY {
  Term::ReadKey::ReadMode(0); #Restore propper readmode
  #print "\e[?6l";             #Remove region
  print "\e(B";               #Restore charset
  #print "\e8";                #Restore cursor
  print "\e[?25h";            #Turn cursor on
  print "\e[0m";              #Restore all attributes
  #print "\e[2J";              #Clear screen
  #print "\e[1;1H";            #Position cursor at top left
}

#===============================================================================
#Accessors and mutators
#===============================================================================

#Sorry, I just don't like AUTOLOAD and yes I do know about affordances but
#separate read/write methods feel awkward to me. Consequently this is more code
#than strictly needed, but that's only a one-time investment. A small one if
#you're using vim `;-)

sub width {
  my ($self, $width) = @_;

  if ($width) {
    if ($self->_check_value('_width', $width)) {
      $self->{_width} = $width;
    }
    else {
      carp "width must be larger than 0 and smaller than the terminal width";
    }
  }
  return $self->{_width};
}

sub height {
  my ($self, $height) = @_;

  if ($height) {
    if ($self->_check_value('_height', $height)) {
      $self->{_height} = $height;
    }
    else {
      carp "height must be larger than 0 and smaller than the terminal height";
    }
  }
  return $self->{_height};
}

sub space_after_title {
  my ($self, $space) = @_;

  if (defined $space) {
    if ($self->_check_value('_space_after_title', $space)) {
      if ($space =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_space_after_title} = 1;
      }
      else {
        $self->{_space_after_title} = 0;
      }
    }
    else {
      carp "space_after_title must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_space_after_title};
}

sub space_after_items {
  my ($self, $space) = @_;

  if (defined $space) {
    if ($self->_check_value('_space_after_items', $space)) {
      if ($space =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_space_after_items} = 1;
      }
      else {
        $self->{_space_after_items} = 0;
      }
    }
    else {
      carp "space_after_items must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_space_after_items};
}

sub space_after_status {
  my ($self, $space) = @_;

  if (defined $space) {
    if ($self->_check_value('_space_after_status', $space)) {
      if ($space =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_space_after_status} = 1;
      }
      else {
        $self->{_space_after_status} = 0;
      }
    }
    else {
      carp "space_after_status must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_space_after_status};
}

sub spacious_items {
  my ($self, $space) = @_;

  if (defined $space) {
    if ($self->_check_value('_spacious_items', $space)) {
      if ($space =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_spacious_items} = 1;
      }
      else {
        $self->{_spacious_items} = 0;
      }
    }
    else {
      carp "spacious_items must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_spacious_items};
}

sub cursor {
  my ($self, $cursor) = @_;

  if (defined $cursor) {
    if ($self->_check_value('_cursor', $cursor)) {
      if ($cursor =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_cursor} = 1;
      }
      else {
        $self->{_cursor} = 0;
      }
    }
    else {
      carp "cursor must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_cursor};
}

sub cursor_char {
  my ($self, $char) = @_;

  if ($char) {
    if ($self->_check_value('_cursor_char', $char)) {
      $self->{_cursor_char} = $char;
    }
    else {
      carp "cursor_char must be a printable character";
    }
  }
  return $self->{_cursor_char};
}

sub up_keys {
  my ($self, $keys) = @_;

  if ($keys) {
    if (ref $keys eq 'ARRAY') {
      if ($self->_check_value('_up_keys', $keys)) {
        $self->{_up_keys} = $keys;
      }
      else {
        carp "up_keys must be one or more keynames";
      }
    }
    else {
      carp "up_keys must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_up_keys}} : $self->{_up_keys};
}

sub down_keys {
  my ($self, $keys) = @_;

  if ($keys) {
    if (ref $keys eq 'ARRAY') {
      if ($self->_check_value('_down_keys', $keys)) {
        $self->{_down_keys} = $keys;
      }
      else {
        carp "down_keys must be one or more keynames";
      }
    }
    else {
      carp "down_keys must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_down_keys}} : $self->{_down_keys};
}

sub help {
  my ($self, $help) = @_;

  if ($help) {
    if (ref $help eq 'ARRAY') {
      if ($self->_check_value('_help', $help)) {
        $self->{_help} = $help;
      }
      else {
        carp "help must an array of arrays containing strings and code references";
      }
    }
    else {
      carp "help must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_help}} : $self->{_help};
}

sub help_keys {
  my ($self, $keys) = @_;

  if ($keys) {
    if (ref $keys eq 'ARRAY') {
      if ($self->_check_value('_help_keys', $keys)) {
        $self->{_help_keys} = $keys;
      }
      else {
        carp "help_keys must be one or more keynames";
      }
    }
    else {
      carp "help_keys must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_help_keys}} : $self->{_help_keys};
}

sub exit_keys {
  my ($self, $keys) = @_;

  if ($keys) {
    if (ref $keys eq 'ARRAY') {
      if ($self->_check_value('_exit_keys', $keys)) {
        $self->{_exit_keys} = $keys;
      }
      else {
        carp "exit_keys must be one or more keynames";
      }
    }
    else {
      carp "exit_keys must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_exit_keys}} : $self->{_exit_keys};
}

sub selection {
  my ($self, $sel) = @_;

  if (defined $sel) {
    if ($self->_check_value('_selection', $sel)) {
      $self->{_selection} = $sel;
    }
    else {
      carp "selection must be larger than or equal to 0 and smaller than or equal to the number of items";
    }
  }
  return $self->{_selection};
}

sub selection_wrap {
  my ($self, $wrap) = @_;

  if (defined $wrap) {
    if ($self->_check_value('_selection_wrap', $wrap)) {
      if ($wrap =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_selection_wrap} = 1;
      }
      else {
        $self->{_selection_wrap} = 0;
      }
    }
    else {
      carp "selection_wrap must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_selection_wrap};
}

sub selection_keys {
  my ($self, $keys) = @_;

  if ($keys) {
    if (ref $keys eq 'ARRAY') {
      if ($self->_check_value('_selection_keys', $keys)) {
        $self->{_selection_keys} = $keys;
      }
      else {
        carp "selection_keys must be one or more keynames";
      }
    }
    else {
      carp "selection_keys must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_selection_keys}} : $self->{_selection_keys};
}

sub selection_style {
  my ($self, $styles) = @_;

  if ($styles) {
    if (ref $styles eq 'ARRAY') {
      if ($self->_check_value('_selection_style', $styles)) {
        foreach my $style (@{$styles}) {
          $style = uc $style;
        }
        $self->{_selection_style} = $styles;
      }
      else {
        carp "selection_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR";
      }
    }
    else {
      carp "selection_style must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_selection_style}} : $self->{_selection_style};
}

sub selection_fgcolor {
  my ($self, $fgcolor) = @_;

  if ($fgcolor) {
    if ($self->_check_value('_selection_fgcolor', $fgcolor)) {
      $self->{_selection_fgcolor} = uc $fgcolor;
    }
    else {
      carp "selection_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_selection_fgcolor};
}

sub selection_bgcolor {
  my ($self, $bgcolor) = @_;

  if ($bgcolor) {
    if ($self->_check_value('_selection_bgcolor', $bgcolor)) {
      $self->{_selection_bgcolor} = uc $bgcolor;
    }
    else {
      carp "selection_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_selection_bgcolor};
}

sub leader {
  my ($self, $leader) = @_;

  if (defined $leader) {
    if ($self->_check_value('_leader', $leader)) {
      if ($leader =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_leader} = 1;
      }
      else {
        $self->{_leader} = 0;
      }
    }
    else {
      carp "leader must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_leader};
}

sub trailer {
  my ($self, $trailer) = @_;

  if (defined $trailer) {
    if ($self->_check_value('_trailer', $trailer)) {
      if ($trailer =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_trailer} = 1;
      }
      else {
        $self->{_trailer} = 0;
      }
    }
    else {
      carp "trailer must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_trailer};
}

sub shortcut_prefix {
  my ($self, $prefix) = @_;

  if (defined $prefix) {
    if ($self->_check_value('_shortcut_prefix', $prefix)) {
      $self->{_shortcut_prefix} = $prefix;
    }
    else {
      carp "shortcut_prefix must be a string of printable characters or a line-drawing character";
    }
  }
  return $self->{_shortcut_prefix};
}

sub shortcut_postfix {
  my ($self, $postfix) = @_;

  if (defined $postfix) {
    if ($self->_check_value('_shortcut_postfix', $postfix)) {
      $self->{_shortcut_postfix} = $postfix;
    }
    else {
      carp "shortcut_postfix must be a string of printable characters or a line-drawing character";
    }
  }
  return $self->{_shortcut_postfix};
}

sub delimiter {
  my ($self, $del) = @_;

  if (defined $del) {
    if ($self->_check_value('_delimiter', $del)) {
      $self->{_delimiter} = $del;
    }
    else {
      carp "delimiter must be a string of printable characters or a line-drawing character";
    }
  }
  return $self->{_delimiter};
}

sub leader_delimiter {
  my ($self, $del) = @_;

  if (defined $del) {
    if ($self->_check_value('_leader_delimiter', $del)) {
      $self->{_leader_delimiter} = $del;
    }
    else {
      carp "leader_delimiter must be a string of printable characters or a line-drawing character";
    }
  }
  return $self->{_leader_delimiter};
}

sub trailer_delimiter {
  my ($self, $del) = @_;

  if (defined $del) {
    if ($self->_check_value('_trailer_delimiter', $del)) {
      $self->{_trailer_delimiter} = $del;
    }
    else {
      carp "trailer_delimiter must be a string of printable characters or a line-drawing character";
    }
  }
  return $self->{_trailer_delimiter};
}

sub label_prefix {
  my ($self, $prefix) = @_;

  if (defined $prefix) {
    if ($self->_check_value('_label_prefix', $prefix)) {
      $self->{_label_prefix} = $prefix;
    }
    else {
      carp "label_prefix must be a string of printable characters or a line-drawing character";
    }
  }
  return $self->{_label_prefix};
}

sub label_postfix {
  my ($self, $postfix) = @_;

  if (defined $postfix) {
    if ($self->_check_value('_label_postfix', $postfix)) {
      $self->{_label_postfix} = $postfix;
    }
    else {
      carp "label_postfix must be a string of printable characters or a line-drawing character";
    }
  }
  return $self->{_label_postfix};
}

sub title {
  my ($self, $title) = @_;

  if (defined $title) {
    if ($self->_check_value('_title', $title)) {
      $self->{_title} = $title;
    }
    else {
      carp "title must be a string of printable characters";
    }
  }
  return $self->{_title};
}

sub title_style {
  my ($self, $styles) = @_;

  if ($styles) {
    if (ref $styles eq 'ARRAY') {
      if ($self->_check_value('_title_style', $styles)) {
        foreach my $style (@{$styles}) {
          $style = uc $style;
        }
        $self->{_title_style} = $styles;
      }
      else {
        carp "title_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR";
      }
    }
    else {
      carp "title_style must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_title_style}} : $self->{_title_style};
}

sub title_fgcolor {
  my ($self, $fgcolor) = @_;

  if ($fgcolor) {
    if ($self->_check_value('_title_fgcolor', $fgcolor)) {
      $self->{_title_fgcolor} = uc $fgcolor;
    }
    else {
      carp "title_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_title_fgcolor};
}

sub title_bgcolor {
  my ($self, $bgcolor) = @_;

  if ($bgcolor) {
    if ($self->_check_value('_title_bgcolor', $bgcolor)) {
      $self->{_title_bgcolor} = uc $bgcolor;
    }
    else {
      carp "title_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_title_bgcolor};
}

sub title_align {
  my ($self, $align) = @_;

  if ($align) {
    if ($self->_check_value('_title_align', $align)) {
      $self->{_title_align} = uc $align;
    }
    else {
      carp "title_align must be LEFT, RIGHT or CENTER";
    }
  }
  return $self->{_title_align};
}

sub title_fill {
  my ($self, $fill) = @_;

  if (defined $fill) {
    if ($self->_check_value('_title_fill', $fill)) {
      if ($fill =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_title_fill} = 1;
      }
      else {
        $self->{_title_fill} = 0;
      }
    }
    else {
      carp "title_fill must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_title_fill};
}

sub title_frame {
  my ($self, $frame) = @_;

  if (defined $frame) {
    if ($self->_check_value('_title_frame', $frame)) {
      if ($frame =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_title_frame} = 1;
      }
      else {
        $self->{_title_frame} = 0;
      }
    }
    else {
      carp "title_frame must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_title_frame};
}

sub title_frame_style {
  my ($self, $styles) = @_;

  if ($styles) {
    if (ref $styles eq 'ARRAY') {
      if ($self->_check_value('_title_frame_style', $styles)) {
        foreach my $style (@{$styles}) {
          $style = uc $style;
        }
        $self->{_title_frame_style} = $styles;
      }
      else {
        carp "title_frame_style must be BLINK, REVERSE, BOLD and/or CLEAR";
      }
    }
    else {
      carp "title_frame_style must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_title_frame_style}} : $self->{_title_frame_style};
}

sub title_frame_fgcolor {
  my ($self, $fgcolor) = @_;

  if ($fgcolor) {
    if ($self->_check_value('_title_frame_fgcolor', $fgcolor)) {
      $self->{_title_frame_fgcolor} = uc $fgcolor;
    }
    else {
      carp "title_frame_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_title_frame_fgcolor};
}

sub title_frame_bgcolor {
  my ($self, $bgcolor) = @_;

  if ($bgcolor) {
    if ($self->_check_value('_title_frame_bgcolor', $bgcolor)) {
      $self->{_title_frame_bgcolor} = uc $bgcolor;
    }
    else {
      carp "title_frame_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_title_frame_bgcolor};
}

sub items {
  my ($self, $items) = @_;

  if ($items) {
    if (ref $items eq 'ARRAY') {
      if ($self->_check_value('_items', $items)) {
        $self->{_items} = $items;
      }
      else {
        carp "items must be an array of arrays containing keynames, descriptions and code references";
      }
    }
    else {
      carp "items must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_items}} : $self->{_items};
}

sub item_style {
  my ($self, $styles) = @_;

  if ($styles) {
    if (ref $styles eq 'ARRAY') {
      if ($self->_check_value('_item_style', $styles)) {
        foreach my $style (@{$styles}) {
          $style = uc $style;
        }
        $self->{_item_style} = $styles;
      }
      else {
        carp "item_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR";
      }
    }
    else {
      carp "item_style must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_item_style}} : $self->{_item_style};
}

sub item_fgcolor {
  my ($self, $fgcolor) = @_;

  if ($fgcolor) {
    if ($self->_check_value('_item_fgcolor', $fgcolor)) {
      $self->{_item_fgcolor} = uc $fgcolor;
    }
    else {
      carp "item_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_item_fgcolor};
}

sub item_bgcolor {
  my ($self, $bgcolor) = @_;

  if ($bgcolor) {
    if ($self->_check_value('_item_bgcolor', $bgcolor)) {
      $self->{_item_bgcolor} = uc $bgcolor;
    }
    else {
      carp "item_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_item_bgcolor};
}

sub item_align {
  my ($self, $align) = @_;

  if ($align) {
    if ($self->_check_value('_item_align', $align)) {
      $self->{_item_align} = uc $align;
    }
    else {
      carp "item_align must be LEFT, RIGHT or CENTER";
    }
  }
  return $self->{_item_align};
}

sub item_fill {
  my ($self, $fill) = @_;

  if (defined $fill) {
    if ($self->_check_value('_item_fill', $fill)) {
      if ($fill =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_item_fill} = 1;
      }
      else {
        $self->{_item_fill} = 0;
      }
    }
    else {
      carp "item_fill must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_item_fill};
}

sub item_frame {
  my ($self, $frame) = @_;

  if (defined $frame) {
    if ($self->_check_value('_item_frame', $frame)) {
      if ($frame =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_item_frame} = 1;
      }
      else {
        $self->{_item_frame} = 0;
      }
    }
    else {
      carp "item_frame must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_item_frame};
}

sub item_frame_style {
  my ($self, $styles) = @_;

  if ($styles) {
    if (ref $styles eq 'ARRAY') {
      if ($self->_check_value('_item_frame_style', $styles)) {
        foreach my $style (@{$styles}) {
          $style = uc $style;
        }
        $self->{_item_frame_style} = $styles;
      }
      else {
        carp "item_frame_style must be BLINK, REVERSE, BOLD and/or CLEAR";
      }
    }
    else {
      carp "item_frame_style must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_item_frame_style}} : $self->{_item_frame_style};
}

sub item_frame_fgcolor {
  my ($self, $fgcolor) = @_;

  if ($fgcolor) {
    if ($self->_check_value('_item_frame_fgcolor', $fgcolor)) {
      $self->{_item_frame_fgcolor} = uc $fgcolor;
    }
    else {
      carp "item_frame_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_item_frame_fgcolor};
}

sub item_frame_bgcolor {
  my ($self, $bgcolor) = @_;

  if ($bgcolor) {
    if ($self->_check_value('_item_frame_bgcolor', $bgcolor)) {
      $self->{_item_frame_bgcolor} = uc $bgcolor;
    }
    else {
      carp "item_frame_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_item_frame_bgcolor};
}

sub status {
  my ($self, $status) = @_;

  if (defined $status) {
    if ($self->_check_value('_status', $status)) {
      $self->{_status} = $status;
    }
    else {
      carp "status must be a string of printable characters";
    }
  }
  return $self->{_status};
}

sub status_style {
  my ($self, $styles) = @_;

  if ($styles) {
    if (ref $styles eq 'ARRAY') {
      if ($self->_check_value('_status_style', $styles)) {
        foreach my $style (@{$styles}) {
          $style = uc $style;
        }
        $self->{_status_style} = $styles;
      }
      else {
        carp "status_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR";
      }
    }
    else {
      carp "status_style must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_status_style}} : $self->{_status_style};
}

sub status_fgcolor {
  my ($self, $fgcolor) = @_;

  if ($fgcolor) {
    if ($self->_check_value('_status_fgcolor', $fgcolor)) {
      $self->{_status_fgcolor} = uc $fgcolor;
    }
    else {
      carp "status_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_status_fgcolor};
}

sub status_bgcolor {
  my ($self, $bgcolor) = @_;

  if ($bgcolor) {
    if ($self->_check_value('_status_bgcolor', $bgcolor)) {
      $self->{_status_bgcolor} = uc $bgcolor;
    }
    else {
      carp "status_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_status_bgcolor};
}

sub status_align {
  my ($self, $align) = @_;

  if ($align) {
    if ($self->_check_value('_status_align', $align)) {
      $self->{_status_align} = uc $align;
    }
    else {
      carp "status_align must be LEFT, RIGHT or CENTER";
    }
  }
  return $self->{_status_align};
}

sub status_fill {
  my ($self, $fill) = @_;

  if (defined $fill) {
    if ($self->_check_value('_status_fill', $fill)) {
      if ($fill =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_status_fill} = 1;
      }
      else {
        $self->{_status_fill} = 0;
      }
    }
    else {
      carp "status_fill must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_status_fill};
}

sub status_frame {
  my ($self, $frame) = @_;

  if (defined $frame) {
    if ($self->_check_value('_status_frame', $frame)) {
      if ($frame =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_status_frame} = 1;
      }
      else {
        $self->{_status_frame} = 0;
      }
    }
    else {
      carp "status_frame must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_status_frame};
}

sub status_frame_style {
  my ($self, $styles) = @_;

  if ($styles) {
    if (ref $styles eq 'ARRAY') {
      if ($self->_check_value('_status_frame_style', $styles)) {
        foreach my $style (@{$styles}) {
          $style = uc $style;
        }
        $self->{_status_frame_style} = $styles;
      }
      else {
        carp "status_frame_style must be BLINK, REVERSE, BOLD and/or CLEAR";
      }
    }
    else {
      carp "status_frame_style must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_status_frame_style}} : $self->{_status_frame_style};
}

sub status_frame_fgcolor {
  my ($self, $fgcolor) = @_;

  if ($fgcolor) {
    if ($self->_check_value('_status_frame_fgcolor', $fgcolor)) {
      $self->{_status_frame_fgcolor} = uc $fgcolor;
    }
    else {
      carp "status_frame_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_status_frame_fgcolor};
}

sub status_frame_bgcolor {
  my ($self, $bgcolor) = @_;

  if ($bgcolor) {
    if ($self->_check_value('_status_frame_bgcolor', $bgcolor)) {
      $self->{_status_frame_bgcolor} = uc $bgcolor;
    }
    else {
      carp "status_frame_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_status_frame_bgcolor};
}

sub prompt {
  my ($self, $prompt) = @_;

  if (defined $prompt) {
    if ($self->_check_value('_prompt', $prompt)) {
      $self->{_prompt} = $prompt;
    }
    else {
      carp "prompt must be a string of printable characters";
    }
  }
  return $self->{_prompt};
}

sub prompt_style {
  my ($self, $styles) = @_;

  if ($styles) {
    if (ref $styles eq 'ARRAY') {
      if ($self->_check_value('_prompt_style', $styles)) {
        foreach my $style (@{$styles}) {
          $style = uc $style;
        }
        $self->{_prompt_style} = $styles;
      }
      else {
        carp "prompt_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR";
      }
    }
    else {
      carp "prompt_style must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_prompt_style}} : $self->{_prompt_style};
}

sub prompt_fgcolor {
  my ($self, $fgcolor) = @_;

  if ($fgcolor) {
    if ($self->_check_value('_prompt_fgcolor', $fgcolor)) {
      $self->{_prompt_fgcolor} = uc $fgcolor;
    }
    else {
      carp "prompt_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_prompt_fgcolor};
}

sub prompt_bgcolor {
  my ($self, $bgcolor) = @_;

  if ($bgcolor) {
    if ($self->_check_value('_prompt_bgcolor', $bgcolor)) {
      $self->{_prompt_bgcolor} = uc $bgcolor;
    }
    else {
      carp "prompt_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_prompt_bgcolor};
}

sub prompt_align {
  my ($self, $align) = @_;

  if ($align) {
    if ($self->_check_value('_prompt_align', $align)) {
      $self->{_prompt_align} = uc $align;
    }
    else {
      carp "prompt_align must be LEFT, RIGHT or CENTER";
    }
  }
  return $self->{_prompt_align};
}

sub prompt_fill {
  my ($self, $fill) = @_;

  if (defined $fill) {
    if ($self->_check_value('_prompt_fill', $fill)) {
      if ($fill =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_prompt_fill} = 1;
      }
      else {
        $self->{_prompt_fill} = 0;
      }
    }
    else {
      carp "prompt_fill must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_prompt_fill};
}

sub prompt_frame {
  my ($self, $frame) = @_;

  if (defined $frame) {
    if ($self->_check_value('_prompt_frame', $frame)) {
      if ($frame =~ /^(?:\+|1|YES|Y|TRUE|T)$/i) {
        $self->{_prompt_frame} = 1;
      }
      else {
        $self->{_prompt_frame} = 0;
      }
    }
    else {
      carp "prompt_frame must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T";
    }
  }
  return $self->{_prompt_frame};
}

sub prompt_frame_style {
  my ($self, $styles) = @_;

  if ($styles) {
    if (ref $styles eq 'ARRAY') {
      if ($self->_check_value('_prompt_frame_style', $styles)) {
        foreach my $style (@{$styles}) {
          $style = uc $style;
        }
        $self->{_prompt_frame_style} = $styles;
      }
      else {
        carp "prompt_frame_style must be BLINK, REVERSE, BOLD and/or CLEAR";
      }
    }
    else {
      carp "prompt_frame_style must be given as a reference to an array";
    }
  }
  return wantarray ? @{$self->{_prompt_frame_style}} : $self->{_prompt_frame_style};
}

sub prompt_frame_fgcolor {
  my ($self, $fgcolor) = @_;

  if ($fgcolor) {
    if ($self->_check_value('_prompt_frame_fgcolor', $fgcolor)) {
      $self->{_prompt_frame_fgcolor} = uc $fgcolor;
    }
    else {
      carp "prompt_frame_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_prompt_frame_fgcolor};
}

sub prompt_frame_bgcolor {
  my ($self, $bgcolor) = @_;

  if ($bgcolor) {
    if ($self->_check_value('_prompt_frame_bgcolor', $bgcolor)) {
      $self->{_prompt_frame_bgcolor} = uc $bgcolor;
    }
    else {
      carp "prompt_frame_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE";
    }
  }
  return $self->{_prompt_frame_bgcolor};
}

#===============================================================================
#Methods
#===============================================================================

sub read_key {
  my $self = shift;

  my $key = undef;
  ReadMode(4);
  my $char = ReadKey(0);
  if ($char eq "\e") {
    #Escape sequences
    $char = ReadKey(0);
    if ($char eq "[") {
      $char = ReadKey(0);
      if ($char =~ /[ABCDFH]/) {
        #VT100 specific sequences
        $key = $self->_get_keyname("\e[" . $char);
      }
      elsif ($char eq "[") {
        $char = ReadKey(0);
        if ($char =~ /[ABCDE]/) {
          #Linux console specific sequences
          $key = $self->_get_keyname("\e[[" . $char);
        }
      }
      elsif ($char =~ /^\d$/) {
        my $num = $char;
        $char = ReadKey(0);
        while ($char ne '~') {
          $num = $num * 10 + $char;
          $char = ReadKey(0);
        }
        #VT100 and Linux console sequences
        $key = $self->_get_keyname("\e[" . $num . "~");
      }
    }
    elsif ($char eq "O") {
      $char = ReadKey(0);
      if ($char =~ /[ABCDFHPQRS]/) {
        #Xterm specific sequences
        $key = $self->_get_keyname("\eO" . $char);
      }
    }
    elsif ($char =~ /[a-z]/) {
      #Meta a-z
      $key = $self->_get_keyname("\e" . $char);
    }
  }
  elsif ($self->_get_keyname($char)) {
    #Keys with special names, including CTRL a-z
    $key = $self->_get_keyname($char);
  }
  elsif ($char =~ /^[[:graph:]]$/) {
    #Plain keys
    $key = $char;
  }
  ReadMode(0);
  return $key;
}

sub up {
  my ($self, $n) = @_;

  $n = 0 unless defined $n;
  if ($n =~ /^\d+$/) {
    print "\x1B[" . $n . "A";
    return 1;
  }
  return 0;
}

sub down {
  my ($self, $n) = @_;

  $n = 0 unless defined $n;
  if ($n =~ /^\d+$/) {
    print "\x1B[" . $n . "B";
    return 1;
  }
  return 0;
}

sub right {
  my ($self, $n) = @_;

  $n = 0 unless defined $n;
  if ($n =~ /^\d+$/) {
    print "\x1B[" . $n . "C";
    return 1;
  }
  return 0;
}

sub left {
  my ($self, $n) = @_;

  $n = 0 unless defined $n;
  if ($n =~ /^\d+$/) {
    print "\x1B[" . $n . "D";
    return 1;
  }
  return 0;
}

sub region {
  my ($self, $t, $b) = @_;

  $t = 1 unless defined $t and $t <= $self->height();
  $b = $self->height() unless defined $b and $b <= $self->height();
  if ($b >= $t) {
    print "\x1B[" . $t . ";" . $b . "r";
    return 1;
  }
  return 0;
}

sub pos {
  my ($self, $l, $c) = @_;

  $l = 1 unless defined $l and $l > 0 and $l <= $self->height();
  $c = 1 unless defined $c and $c > 0 and $c <= $self->width();
  if ($l =~ /^\d+$/ and $c =~ /^\d+$/) {
    print "\x1B[" . $l . ";" . $c ."H";
    return 1;
  }
  return 0;
}

sub print_title {
  my $self = shift;

  my $width = $self->width();
  my $title = $self->title();
  my $max_length = $width;
  $max_length -= 2 if $self->title_frame();
  my $padding = $max_length - length $title;
  $title = substr($title, 0, $max_length) if length($title) > $max_length;
  if ($self->title_fill()) {
    if ($self->title_align() eq 'CENTER') {
      my $lpadding = int ($padding / 2);
      my $rpadding = $padding - $lpadding;
      $title = " " x $lpadding . $title . " " x $rpadding;
    }
    elsif ($self->title_align() eq 'RIGHT') {
      $title = " " x $padding . $title;
    }
    else {
      $title .= " " x $padding;
    }
  }
  $self->pos(1,1);
  if ($self->title_frame()) {
    print RESET;
    $self->_print_color($self->title_frame_fgcolor(), $self->title_frame_bgcolor());
    $self->_print_style($self->title_frame_style());
    print ULC;
    print HOR x length $title;
    print URC;
    print "\n";
    print VER;
  }
  print RESET;
  $self->_print_color($self->title_fgcolor(), $self->title_bgcolor());
  $self->_print_style($self->title_style());
  print $title;
  if ($self->title_frame()) {
    print RESET;
    $self->_print_color($self->title_frame_fgcolor(), $self->title_frame_bgcolor());
    $self->_print_style($self->title_frame_style());
    print VER;
    print "\n";
    print LLC;
    print HOR x length $title;
    print LRC;
  }
  print RESET;
  print "\n";
}

sub print_items {
  my ($self, $selected) = @_;

  if (defined $selected) {
    $self->selection($selected) if $self->_check_value('_selection', $selected);
  }
  my $width = $self->width();
  my $max_length = $width;
  if ($self->item_frame()) {
    $max_length -= 3;
  }
  elsif ($self->delimiter()) {
    $max_length--;
  }
  my $key_length = 0;
  my $desc_length = 0;
  foreach my $item (@{$self->items()}) {
    $key_length = length($item->[0]) if length($item->[0]) > $key_length;
    $desc_length = length($item->[1]) if length($item->[1]) > $desc_length;
  }
  $key_length += $self->_linestr_length($self->shortcut_prefix());
  $key_length += $self->_linestr_length($self->shortcut_postfix());
  my $label_length = $desc_length;
  $label_length += $self->_linestr_length($self->label_prefix());
  $label_length += $self->_linestr_length($self->label_postfix());
  if ($key_length + $label_length > $max_length or $self->item_fill()) {
    $label_length = $max_length - $key_length;
    $desc_length = $label_length - $self->_linestr_length($self->shortcut_prefix());
    $desc_length = $desc_length - $self->_linestr_length($self->shortcut_postfix());
  }
  my $last_item = $self->item_count() - 1;
  my $highlight = 0;
  $highlight++ if $self->selection() > 0 and $self->selection() <= $last_item + 1;
  my $i = 0;
  $self->pos($self->_items_start(),1);
  foreach my $item (@{$self->items()}) {
    if ($i == 0) {
      if ($self->item_frame()) {
        print RESET;
        $self->_print_color($self->item_frame_fgcolor(), $self->item_frame_bgcolor());
        $self->_print_style($self->item_frame_style());
        print ULC;
        print HOR x $key_length;
        print TTE;
        print HOR x $label_length;
        print URC;
        print "\n";
      }
      elsif ($self->leader()) {
        print RESET;
        $self->_print_color($self->item_fgcolor(), $self->item_bgcolor());
        $self->_print_style($self->item_style());
        print ULC;
        print HOR x ($key_length - 1);
        $self->_print_linestr($self->leader_delimiter()) if $self->delimiter();
        print HOR x ($label_length - 1);
        print URC;
        print "\n";
      }
    }
    if ($self->item_frame()) {
      print RESET;
      $self->_print_color($self->item_frame_fgcolor(), $self->item_frame_bgcolor());
      $self->_print_style($self->item_frame_style());
      print VER;
    }
    print RESET;
    if ($highlight and $i == $self->selection() - 1) {
      $self->_print_color($self->selection_fgcolor(), $self->selection_bgcolor());
      $self->_print_style($self->selection_style());
    }
    else {
      $self->_print_color($self->item_fgcolor(), $self->item_bgcolor());
      $self->_print_style($self->item_style());
    }
    $self->_print_linestr($self->shortcut_prefix()) if $self->shortcut_prefix();
    print $item->[0];
    if (length($item->[0]) < $key_length) {
      print ' ' x ($key_length - length($item->[0]));
    }
    $self->_print_linestr($self->shortcut_postfix()) if $self->shortcut_postfix();
    if ($self->item_frame()) {
      print RESET;
      $self->_print_color($self->item_frame_fgcolor(), $self->item_frame_bgcolor());
      $self->_print_style($self->item_frame_style());
      if ($self->spacious_items()) {
        print VER;
      }
      else {
        if ($self->delimiter()) {
          $self->_print_linestr($self->delimiter());
        }
        else {
          print VER;
        }
      }
    }
    elsif ($self->delimiter()) {
      $self->_print_linestr($self->delimiter());
    }
    print RESET;
    if ($highlight and $i == $self->selection() - 1) {
      $self->_print_color($self->selection_fgcolor(), $self->selection_bgcolor());
      $self->_print_style($self->selection_style());
    }
    else {
      $self->_print_color($self->item_fgcolor(), $self->item_bgcolor());
      $self->_print_style($self->item_style());
    }
    if ($self->label_prefix()) {
      $self->_print_linestr($self->label_prefix());
    }
    my $desc = '';
    if (length($item->[1]) > $desc_length) {
      $desc = substr($item->[1], 0, $desc_length);
    }
    elsif (length($item->[1]) < $desc_length) {
      if ($self->item_fill()) {
        if ($self->item_align() eq 'CENTER') {
          my $lpad = int (($desc_length - length($item->[1])) / 2);
          my $rpad = $desc_length - length($item->[1]) - $lpad;
          $desc = ' ' x $lpad . $item->[1] . ' ' x $rpad;
        }
        elsif ($self->item_align() eq 'RIGHT') {
          $desc = ' ' x ($desc_length - length($item->[1])) . $item->[1];
        }
        else {
          $desc = $item->[1] . ' ' x ($desc_length - length($item->[1]));
        }
      }
      else {
        $desc = $item->[1];
      }
    }
    else {
      $desc = $item->[1];
    }
    print $desc;
    if ($self->label_postfix()) {
      $self->_print_linestr($self->label_postfix());
    }
    if ($self->item_frame()) {
      print RESET;
      $self->_print_color($self->item_frame_fgcolor(), $self->item_frame_bgcolor());
      $self->_print_style($self->item_frame_style());
      print VER;
    }
    print "\n";
    if ($i < $last_item and $self->spacious_items()) {
      if ($self->item_frame()) {
        print LTE;
        print HOR x $key_length;
        print CTE;
        print HOR x $label_length;
        print RTE;
        print "\n";
      }
    }
    if ($i == $last_item) {
      if ($self->item_frame()) {
        print RESET;
        $self->_print_color($self->item_frame_fgcolor(), $self->item_frame_bgcolor());
        $self->_print_style($self->item_frame_style());
        print LLC;
        print HOR x $key_length;
        print BTE;
        print HOR x $label_length;
        print LRC;
        print "\n";
      }
      elsif ($self->trailer()) {
        print RESET;
        $self->_print_color($self->item_fgcolor(), $self->item_bgcolor());
        $self->_print_style($self->item_style());
        print LLC;
        print HOR x ($key_length - 1);
        $self->_print_linestr($self->trailer_delimiter()) if $self->delimiter();
        print HOR x ($label_length - 1);
        print LRC;
        print "\n";
      }
    }
    $i++;
  }
  print RESET;
}

sub print_status {
  my ($self, $text) = @_;

  my $width = $self->width();
  my $status;
  if (defined $text and length $text > 0) {
    $status = $text;
  }
  else {
    $status = $self->status();
  }
  my $max_length = $width;
  $max_length -= 2 if $self->status_frame();
  my $padding = $max_length - length $status;
  $status = substr($status, 0, $max_length) if length($status) > $max_length;
  if ($self->status_fill()) {
    if ($self->status_align() eq 'CENTER') {
      my $lpadding = int ($padding / 2);
      my $rpadding = $padding - $lpadding;
      $status = " " x $lpadding . $status . " " x $rpadding;
    }
    elsif ($self->status_align() eq 'RIGHT') {
      $status = " " x $padding . $status;
    }
    else {
      $status .= " " x $padding;
    }
  }
  $self->pos($self->_status_start(),1);
  if ($self->status_frame()) {
    print RESET;
    $self->_print_color($self->status_frame_fgcolor(), $self->status_frame_bgcolor());
    $self->_print_style($self->status_frame_style());
    print ULC;
    print HOR x length $status;
    print URC;
    print "\n";
    print VER;
  }
  print RESET;
  $self->_print_color($self->status_fgcolor(), $self->status_bgcolor());
  $self->_print_style($self->status_style());
  print $status;
  if ($self->status_frame()) {
    print RESET;
    $self->_print_color($self->status_frame_fgcolor(), $self->status_frame_bgcolor());
    $self->_print_style($self->status_frame_style());
    print VER;
    print "\n";
    print LLC;
    print HOR x length $status;
    print LRC;
  }
  print RESET;
  print "\n";
}

sub print_prompt {
  my $self = shift;

  my $width = $self->width();
  my $max_length = $width - 1; #Allocate space for cursor
  $max_length -= 2 if $self->prompt_frame();
  my $padding = $max_length - length $self->prompt();
  $padding = 0 if $padding < 0;
  my $lpadding = 0;
  my $rpadding = 0;
  my $prompt = $self->prompt();
  $prompt = substr($self->prompt(), 0, $max_length) if length($self->prompt()) > $max_length;
  if ($self->prompt_fill()) {
    if ($self->prompt_align() eq 'CENTER') {
      $lpadding = int ($padding / 2);
      $rpadding = $padding - $lpadding;
    }
  }
  $self->pos($self->_prompt_start(),1);
  if ($self->prompt_frame()) {
    print RESET;
    $self->_print_color($self->prompt_frame_fgcolor(), $self->prompt_frame_bgcolor());
    $self->_print_style($self->prompt_frame_style());
    print ULC;
    print HOR x (length($prompt) + 1);
    if ($self->prompt_fill()) {
      print HOR x $padding;
    }
    print URC;
    print "\n";
    print VER;
  }
  print RESET;
  $self->_print_color($self->prompt_fgcolor(), $self->prompt_bgcolor());
  $self->_print_style($self->prompt_style());
  if ($self->prompt_fill()) {
    if ($self->prompt_align() eq 'CENTER') {
      print ' ' x $lpadding;
      print $prompt, ' ';
      print ' ' x $rpadding;
    }
    elsif ($self->prompt_align() eq 'RIGHT') {
      print ' ' x $padding;
      print $prompt, ' ';
    }
    else {
      print $prompt, ' ';
      print ' ' x $padding;
    }
  }
  else {
    print $prompt, ' ';
  }
  if ($self->prompt_frame()) {
    print RESET;
    $self->_print_color($self->prompt_frame_fgcolor(), $self->prompt_frame_bgcolor());
    $self->_print_style($self->prompt_frame_style());
    print VER;
    print "\n";
    print LLC;
    print HOR x (length($prompt) + 1);
    if ($self->prompt_fill()) {
      print HOR x $padding;
    }
    print LRC;
  }
  print RESET;
  print "\n";
  $self->print_cursor();
}

#Position the cursor and print cursor_char
sub print_cursor {
  my $self = shift;

  my ($l, $c) = $self->_cursor_pos();
  $self->pos($l, $c);
  if ($self->cursor() and $self->prompt()) {
    print $self->cursor_char();
    $self->left(1);
    $self->cursor_on();
  }
  else {
    $self->cursor_off();
  }
}

#Turn off the cursor
sub cursor_off {
  my $self = shift;

  print CURSOR_OFF;
}

#Turn on the cursor
sub cursor_on {
  my $self = shift;

  print CURSOR_ON;
}

#Clear the screen
sub clearscreen {
  my $self = shift;

  $self->pos(1,1);
  print CLS;
}

#Is argument a UP key?
sub is_up_key {
  my ($self, $key) = @_;
  foreach my $up_key ($self->up_keys()) {
    return 1 if $key eq $up_key;
  }
  return 0;
}

#Is argument a DOWN key?
sub is_down_key {
  my ($self, $key) = @_;
  foreach my $down_key ($self->down_keys()) {
    return 1 if $key eq $down_key;
  }
  return 0;
}

#Is argument a HELP key?
sub is_help_key {
  my ($self, $key) = @_;
  foreach my $help_key ($self->help_keys()) {
    return 1 if $key eq $help_key;
  }
  return 0;
}

#Is argument a DOWN key?
sub is_exit_key {
  my ($self, $key) = @_;
  foreach my $exit_key ($self->exit_keys()) {
    return 1 if $key eq $exit_key;
  }
  return 0;
}

#Is argument a SELECTION key?
sub is_selection_key {
  my ($self, $key) = @_;
  foreach my $selection_key ($self->selection_keys()) {
    return 1 if $key eq $selection_key;
  }
  return 0;
}

#Is argument a shortcut key and if so which item does it refer to?
sub is_shortcut {
  my ($self, $key) = @_;

  my @items = @{$self->items()};
  for (my $i = 1; $i <= $self->item_count(); $i++) {
    return $i if $key eq $items[$i - 1]->[0];
  }
  return 0;
}

#Get a list of all shortcuts that directly select an item
sub shortcuts {
  my $self = shift;

  my @shortcuts = ();
  foreach my $item (@{$self->items()}) {
    push @shortcuts, $item->[0];
  }
  return wantarray ? @shortcuts : \@shortcuts;
}

#Get the number of items
sub item_count {
  my $self = shift;

  return scalar(@{$self->items()});
}

#Move selection
sub move_selection {
  my ($self, $offset) = @_;

  my $new_sel = 0;
  if (defined $offset and $offset =~ /^[+-]?\d+/) {
    if (abs($offset) > $self->item_count()) {
      $offset = $offset % $self->item_count();
    }
    $new_sel = $self->selection() + $offset;
    if ($new_sel > $self->item_count()) {
      $new_sel = $self->selection_wrap() ? $new_sel - $self->item_count() : $self->item_count();
    }
    elsif ($new_sel == 0) {
      $new_sel = $self->selection_wrap() ? $self->item_count() : 1;
    }
    elsif ($new_sel < 0) {
      $new_sel = $self->selection_wrap() ? $self->item_count() + $new_sel + 1 : 1;
    }
  }
  $self->selection($new_sel);
  $self->print_items();
  my @help = $self->help();
  if (defined $help[$new_sel]->[0] and length($help[$new_sel]->[0]) > 0) {
    $self->_update_hint($help[$new_sel]->[0]);
  }
  else {
    $self->update_status();
  }
  $self->print_cursor();
}

#Return code reference associated with a shortcut
sub get_code_ref {
  my ($self, $shortcut) = @_;

  foreach my $item (@{$self->items()}) {
    return $item->[2] if $item->[0] eq $shortcut;
  }
  return undef;
}

#Perform action associated with a key
#Return 0 for noop, 1 for success and undef for exit
sub do_key {
  my ($self, $key, @args) = @_;

  return 0 unless defined $key;
  if ($self->is_exit_key($key)) {
    return undef;
  }
  if ($self->is_up_key($key)) {
    $self->move_selection(-1);
    return 1;
  }
  if ($self->is_down_key($key)) {
    $self->move_selection(1);
    return 1;
  }
  if ($self->is_selection_key($key) and $self->selection() > 0) {
    if (defined $self->items()->[$self->selection() - 1]->[2]) {
      $self->do_item($self->items()->[$self->selection() - 1]->[2], $self->selection());
    }
    return 1;
  }
  if ($self->is_help_key($key)) {
    my @help = $self->help();
    if ($self->help()->[$self->selection()]) {
      $self->do_help($self->help()->[$self->selection()], $self->selection());
    }
    elsif ($help[0]) {
      $self->do_help($self->help()->[0], $self->selection());
    }
    return 1;
  }
  if (my $sel = $self->is_shortcut($key)) {
    $self->print_items($self->selection($sel));
    if (defined $self->items()->[$sel - 1]->[2]) {
      $self->do_item($self->items()->[$sel - 1]->[2], $sel);
    }
    if (defined $self->help()->[$sel]->[0] and length($self->help()->[$sel]->[0]) > 0) {
      $self->_update_hint($self->help()->[$sel]->[0]);
    }
    else {
      $self->update_status();
      $self->print_cursor();
    }
    return 1;
  }
  return 0;
}

sub do_item {
  my ($self, $code_ref, @args) = @_;

  $self->clearscreen();
  $code_ref->(@args);
  $self->print_menu();
}

sub do_help {
  my ($self, $ref, @args) = @_;

  if (defined $ref->[1]) {
    $self->clearscreen();
    $ref->[1]->(@args);
    $self->print_menu();
  }
  elsif (defined $ref->[0] and length($ref->[0]) > 0) {
    $self->_update_hint($ref->[0]);
  }
}

sub print_menu {
  my $self = shift;

  $self->clearscreen();
  if (length $self->title() > 0) {
    $self->print_title();
    print "\n" if $self->space_after_title();
  }
  if ($self->item_count() > 0) {
    $self->print_items();
    print "\n" if $self->space_after_items();
  }
  if (length $self->status() > 0) {
    $self->print_status();
    print "\n" if $self->space_after_status();
  }
  if (length $self->prompt() > 0) {
    $self->print_prompt();
  }
  else {
    $self->print_cursor()
  }
}

sub update_status {
  my ($self, $status) = @_;

  if (defined $status and $self->_check_value('_status', $status)) {
    $self->status($status);
  }
  $self->_clear_after_items();
  $self->print_status() if $self->status();
  $self->print_prompt() if $self->prompt();
  $self->print_cursor();
}

sub update_prompt {
  my ($self, $prompt) = @_;

  if (defined $prompt and $self->_check_value('_prompt', $prompt)) {
    $self->prompt($prompt);
  }
  $self->_clear_after_items();
  $self->print_status() if $self->status();
  $self->print_prompt() if $self->prompt();
  $self->print_cursor();
}

sub line_after_menu {
  my $self = shift;

  my $line = $self->_status_start();
  if (length($self->status()) > 0) {
    $line++;
    $line += 2 if $self->status_frame();
    $line++ if $self->space_after_status();
  }
  if (length($self->prompt()) > 0) {
    $line++;
    $line += 2 if $self->prompt_frame();
  }
  return $line;
}

#===============================================================================
#Make sure this modules ends with a true value
#===============================================================================

"That's all folks!";

__END__

#===============================================================================
#Documentation
#===============================================================================

=head1 NAME

Term::ANSIMenu - An infrastructure for creating menus in ANSI capable terminals

=head1 VERSION

This documenation describes version 0.01 of Term::ANSIMenu as released on
Thursday, April 17, 2003.

=head1 SYNOPSIS

  use Term::ANSIMenu;
  my $menu = Term::ANSIMenu->new(
                               width  => 40,
                               help   => [['', \&standard_help],
                                          ['hint 1', \&help_item],
                                          [ undef, \&standard_help],
                                          ['hint 3', undef]
                                         ],
                               title  => 'title',
                               items  => [['1', 'First menu item', \&exec_item],
                                          ['2', 'This string is just too long \
                                                 to fit in a normal terminal \
                                                 and thus it will be clipped.'],
                                          ['3', '', sub { system "man man" }]
                                         ],
                               status => 'status',
                               prompt => 'prompt: ');

  $menu->print_menu();
  while (my $key = $menu->read_key()) {
    last unless defined $menu->do_key($key);
    $menu->update_status('') if $key eq 'S';
    $menu->update_status('New status') if $key eq 's';
    $menu->update_prompt('') if $key eq 'P';
    $menu->update_prompt('New prompt: ') if $key eq 'p';
  }
  $menu->pos($menu->line_after_menu() + 1, 1);

=head1 DESCRIPTION

I wrote this mainly to make live easy on those staff members to whom I delegate
tasks. Most of them prefer to use a menu instead of having to type complicated 
commands. To them it's a faster and safer way of working (we all know about 
typos don't we...).

By using this module you can create menus with only a few lines of code and 
still have a shipload of features. Need context-sensitive help or a statusbar?
Like to use hotkeys? Want flashy colors and styles? It's all there. Just fill 
in the attributes and you're good to go.

=head2 Overview

A menu can be made up of a title, a number of selectable items, a status line
and a prompt. Each of those elements can be given a fore- and background color
and a style to give it the appearance wanted. The same goes for the optional 
frames around these elements. It is also possible to align each element 
independently (but the all items together are considered as one element).

Every item in the menu can be selected using definable hotkeys or navigation
keys. To assist users of the menu hints that will be diplayed in the status
line can be associated with itemsi. For situations where a simple hint isn't 
good enough context-sensitive help is available through definable keys (like 
the well-known E<lt>F1E<gt> and '?').

Finally to get out of the menu without having to explicitly create an entry for
that one or more keys can be assigned that will cause an immediate return from
the menu to the calling program. The exit status reflects the conditions under
which that happened.

On to the gory details...

=head2 Creating and destroying Term::ANSIMenu objects

A Term::ANSIMenu object is created with the usual call to new(), like this

  $menu = Term::ANSIMenu->new();

This will create an object with reasonable defaults. However some attributes
still have to be explicitly given before the resulting object makes a sensible
menu. Everything is optional, except for the selectable items that make up the
menu. You can do this either directly in the call to the constructor or by
using the corresponding mutator. Attributes can be set through new() by
specifying their name as a hash key and giving it an appropriate value. 

For example:

  $menu = Term::ANSIMenu->new(items => [['1', 'First menu item', \&exec_item],
                                        ['2', 'This string is just too long \
                                               to fit in a normal terminal \
                                               and thus it will be clipped.'],
                                        ['3', '', sub { system "man man" }]
                                       ]);

See the next section for a list of all mutators and the conditions they impose
on their values.

The call to new() will also initialize the terminal by setting it to VT100
mode. After that it will clear the screen and position the cursor in the
upper-left corner.

Upon destroying the object the destructor will restore the normal settings of
the terminal by setting the readmode back to 0 and by explicitly removing any
ANSI attributes and turning the cursor on. The screen is not cleared unless
the menu was explicitly instructed to do so.

=head2 Attributes

Attributes can be accessed by using a method that will function as both a 
accessor and a mutator. The name of that method is exactly the same as the name
of the corresponding attribute. In other words the value of an attribute can be
read using 

  $menu->attrib()

Its value can be changed like this:

  $menu->attrib($value)

Both calls return the current value (after setting it). If the return value is 
a list then it will be given as a list or as a reference to that list, depending
on the context. For example:

  $return_ref = $menu->attrib([<list>]);
  @return_list = $menu->attrib([<list>]);

The attributes listed below are publicly available through such methods.

B<width()>

The width of the menu.

  Type: integer
  Constraints: must be > 0 and <= than the current terminal width
  Default: <term_width>

B<height()>

The height of the menu. This is ignored at the moment, but might be used in a
future version.

  Type: integer
  Constraints: must be > 0 and <= than the current terminal height
  Default: <term_height>

B<space_after_title()>

Print an empty line as a spacer after the title.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<space_after_items()>

Print an empty line as a spacer after the selectable items.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<space_after_status()>

Print an empty line as a spacer after the status line.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 0

B<spacious_items()>

Print frame lines between the selectable items.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 0

B<cursor()>

Make the cursor visible when a prompt is printed.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<cursor_char()>

A single character to print at the cursor position in the prompt if the cursor
is visible.

  Type: char
  Constraints: must be a single printable character or a space
  Default: '?'

B<up_keys()>

A list of key names that will move the current selection to the previous item.

  Type: array
  Constraints: elements must be a single character or a special key name
  Default: ['UP', 'PGUP', 'LEFT']

B<down_keys()>

A list of key names that will move the current selection to the next item.

  Type: array
  Constraints: elements must be a single character or a special key name
  Default: ['DOWN', 'PGDN', 'RIGHT']

B<exit_keys()>

A list of key names that will exit the menu.

  Type: array
  Constraints: elements must be a single character or a special key name
  Default: ['q', 'Q', 'CTRL-c']

B<help_keys()>

A list of key names that will invoke context-sensitive help.

  Type: array
  Constraints: elements must be a single character or a special key name
  Default: ['F1', '?']

B<help()>

A list of hints and references to routines that provide additional help to the
user. The first array element is used when no item is selected, the order of 
the other elements corresponds with the order of the selectable items.

The hint must be a string of printable characters (including spaces). The 
code reference should point to a routine that will provide help. It is called 
with the number of the currently selected item as an argument.

If a hint is undefined or an empty string no information will be provided 
through the status line. If no code reference is defined help will not be 
available for that particular item.

  Type: array of arrays
  Constraints: [[<hint>, <code_ref>], ...]
  Default: []

B<selection()>

The number of the currently selected item. If no item is selected this will 
be 0.

  Type: integer
  Constraints: must be >= 0 and <= than the number of selectable items.
  Default: 0

B<selection_keys()>

A list of key names that will execute the current selection.

  Type: array
  Constraints: elements must be a single character or a special key name
  Default: ['SPACE', 'ENTER']

B<selection_wrap()>

Wrap around to the other end of the list when trying to move beyond the first 
or last entry.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<selection_style()>

Apply these character attributes to the selected item.

  Type: array
  Constraints: must be one or more of BLINK, REVERSE, BOLD, UNDERLINE and CLEAR
  Default: ['REVERSE']

B<selection_fgcolor()>

Apply this foreground color to the selected item.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<selection_bgcolor()>

Apply this background color to the selected item.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<leader()>

Print a line resembling the top of a frame before the list of items. The is
used only when no frame is drawn around the list of items.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 0

B<leader_delimiter()>

Print this character in the leader at the position where the delimiter between 
hotkey and description is printed in the list of items.

  Type: char
  Constraints: must be a single character which may be a line drawing character.
  Default: ''

B<trailer()>

Print a line resembling the bottom of a frame after the list of items. The is
used only when no frame is drawn around the list of items.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 0

B<trailer_delimiter()>

Print this character in the trailer at the position where the delimiter between 
hotkey and description is printed in the list of items.

  Type: char
  Constraints: must be a single character which may be a line drawing character.
  Default: ''

B<shortcut_prefix()>

A string to print immediately before the hotkey of an item.

  Type: string
  Constraints: must be a string of printable characters (including spaces) or a
               line drawing character optionally surrounded by one or more 
               spaces on one or both sides.
  Default: ''

B<shortcut_postfix()>

A string to print immediately after the hotkey of an item.

  Type: string
  Constraints: must be a string of printable characters (including spaces) or a
               line drawing character optionally surrounded by one or more 
               spaces on one or both sides.
  Default: ''

B<delimiter()>

Print this character between the hotkey and the description in the list of items.

  Type: char
  Constraints: must be a single character which may be a line drawing character.
  Default: ''

B<label_prefix()>

A string to print immediately before the description of an item.

  Type: string
  Constraints: must be a string of printable characters (including spaces) or a
               line drawing character optionally surrounded by one or more 
               spaces on one or both sides.
  Default: ''

B<label_postfix()>

A string to print immediately after the description of an item.

  Type: string
  Constraints: must be a string of printable characters (including spaces) or a
               line drawing character optionally surrounded by one or more 
               spaces on one or both sides.
  Default: ''

B<title()>

The text to use as the title of the menu.

  Type: string
  Constraints: astring of printable characters (including spaces)
  Default: ''

B<title_style()>

Apply these character attributes to the title.

  Type: array
  Constraints: must be one or more of BLINK, REVERSE, BOLD, UNDERLINE and CLEAR
  Default: ['BOLD']

B<title_fgcolor()>

Apply this foreground color to the title.

  Type: => string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<title_bgcolor()>

Apply this background color to the title.

  Type: => string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<title_align()>

Align the text of the title according to this setting. Unless title_fill is set
alignment will be ignored.

  Type: string
  Constraints: must be one of LEFT, RIGHT or CENTER
  Default: 'CENTER'

B<title_fill()>

Pad the title with whitespace to fill up the full width of the menu.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<title_frame()>

Put a frame around the title.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<title_frame_style()>

Apply these character attributes to the frame around the title.

  Type: array
  Constraints: must be one or more of BLINK, REVERSE, BOLD and CLEAR
  Default: ['REVERSE']

B<title_frame_fgcolor()>

Apply this foreground color to the frame around the title.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<title_frame_bgcolor()>

Apply this background color to the frame around the title.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<items()>

The list of selectable items. They will be presented in the order given here.
Each item consists of a hotkey (given as a single character or a key name), å
description (given as a string of printable characters, including spaces) and a
reference to a piece of code associated with this item. The description may be 
an empty string (why would someone want that?) and the code reference may be
undefined.

  Type: array of arrays
  Constraints: [[<keyname>, <string>, <code_ref>], ...]
  Default: []

B<item_style()>

Apply these character attributes to each item.

  Type: array
  Constraints: must be one or more of BLINK, REVERSE, BOLD, UNDERLINE and CLEAR
  Default: ['CLEAR']

B<item_fgcolor()>

Apply this foreground color to each item.

  Type: => string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<item_bgcolor()>

Apply this background color to each item.

  Type: => string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<item_align()>

Align the description of each item according to this setting. Unless item_fill
is set alignment will be ignored.

  Type: string
  Constraints: must be one of LEFT, RIGHT or CENTER
  Default: 'LEFT'

B<item_fill()>

Pad each item with whitespace to fill up the full width of the menu.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<item_frame()>

Put a frame around the list of selectable items.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<item_frame_style()>

Apply these character attributes to the frame around the items.

  Type: array
  Constraints: must be one or more of BLINK, REVERSE, BOLD and CLEAR
  Default: ['CLEAR']

B<item_frame_fgcolor()>

Apply this foreground color to the frame around the items.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<item_frame_bgcolor()>

Apply this background color to the frame around the items.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<status()>

The text to use in the status line.

  Type: string
  Constraints: astring of printable characters (including spaces)
  Default: ''

B<status_style()>

Apply these character attributes to the status line.

  Type: array
  Constraints: must be one or more of BLINK, REVERSE, BOLD, UNDERLINE and CLEAR
  Default: ['CLEAR']

B<status_fgcolor()>

Apply this foreground color to the status line.

  Type: => string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<status_bgcolor()>

Apply this background color to the status line.

  Type: => string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<status_align()>

Align the text of the status line according to this setting. Unless status_fill
is set alignment will be ignored.

  Type: string
  Constraints: must be one of LEFT, RIGHT or CENTER
  Default: 'LEFT'

B<status_fill()>

Pad the status line with whitespace to fill up the full width of the menu.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<status_frame()>

Put a frame around the status line.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 0

B<status_frame_style()>

Apply these character attributes to the frame around the status line.

  Type: array
  Constraints: must be one or more of BLINK, REVERSE, BOLD and CLEAR
  Default: ['CLEAR']

B<status_frame_fgcolor()>

Apply this foreground color to the frame around the status line.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<status_frame_bgcolor()>

Apply this background color to the frame around the status line.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<prompt()>

The text to use in the prompt.

  Type: string
  Constraints: astring of printable characters (including spaces)
  Default: ''

B<prompt_style()>

Apply these character attributes to the prompt.

  Type: array
  Constraints: must be one or more of BLINK, REVERSE, BOLD, UNDERLINE and CLEAR
  Default: ['BOLD']

B<prompt_fgcolor()>

Apply this foreground color to the prompt.

  Type: => string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<prompt_bgcolor()>

Apply this background color to the prompt.

  Type: => string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<prompt_align()>

Align the text of the prompt according to this setting. Unless prompt_fill is 
set alignment will be ignored.

  Type: string
  Constraints: must be one of LEFT, RIGHT or CENTER
  Default: 'LEFT'

B<prompt_fill()>

Pad the prompt with whitespace to fill up the full width of the menu.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 1

B<prompt_frame()>

Put a frame around the prompt.

  Type: boolean
  Constraints: must be one of -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T
  Default: 0

B<prompt_frame_style()>

Apply these character attributes to the frame around the prompt.

  Type: array
  Constraints: must be one or more of BLINK, REVERSE, BOLD and CLEAR
  Default: ['BOLD']

B<prompt_frame_fgcolor()>

Apply this foreground color to the frame around the prompt.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

B<prompt_frame_bgcolor()>

Apply this background color to the frame around the prompt.

  Type: string
  Constraints: must be one of BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN 
               or WHITE
  Default: ''

=head2 Methods

To manipulate the menu a small set of methods is provided.

B<read_key()>

Read a single key from STDIN and return its name. This is done in raw mode.

B<up($n)>

Move the cursor $n lines up. Any surplus that would move it beyond the
first line is ignored.

B<down($n)>

Move the cursor $n lines down. Any surplus that would move it beyond 
the last line is ignored.

B<right($n)>

Move the cursor $n columns to the right. Any surplus that would move it
beyond the last column is ignored.

B<left($n)>

Move the cursor $n columns to the left. Any surplus that would move it
beyond the first column is ignored.

B<pos($l, $c)>

Move the cursor to the given line ($l) and column ($c). If no valid arguments 
are given the cursor will be moved to the upper left corner (1,1).

B<print_title()>

Print the title of the menu.

B<print_items()>

Print the list of selectable items.

B<print_status()>

Print the status line.

B<print_prompt()>

Print the prompt.

B<print_cursor()>

Position the cursor after the prompt and print C<cursor_char> if the prompt
is visible.

B<cursor_off()>

Turn of the cursor (hide it).

B<cursor_on()>

Turn on the cursor (make it visible again).

B<clearscreen()>

Wipe the entire screen and put the cursor in the upper left corner.

B<is_up_key($keyname)>

Return 1 if the given key is mentioned in C<up_keys> and 0 if it is not.

B<is_down_key($keyname)>

Return 1 if the given key is mentioned in C<down_keys> and 0 if it is not.

B<is_help_key($keyname)>

Return 1 if the given key is mentioned in C<help_keys> and 0 if it is not.

B<is_exit_key($keyname)>

Return 1 if the given key is mentioned in C<exit_keys> and 0 if it is not.

B<is_selection_key($keyname)>

Return 1 if the given key is mentioned in C<selection_keys> and 0 if it is not.

B<is_shortcut($keyname)>

Return the number of the corresponding item if the given key is a shortcut. If
the key does not relate to an item 0 is returned.

B<shortcuts()>

List all shortcuts associated with a selectable item.

B<item_count()>

Return the number of selectable items.

B<move_selection($n)>

Move the selection $n entries up (negative value) or down (positive value). If 
C<selection_wrap> is not enabled this movement will stop at the first or last 
item.

B<do_key($keyname)>

Perform the action associated with this key. This could be a selection movement
or a help invocation or the execution of an item. After this 0 will be returned
if nothing was done, 1 for success and undef for exit.

B<do_item($n)>

Execute the code associated with item $n (if it is defined). The number of the
current selection is passed to the called routine.

B<do_help($n)>

Invoke help for the given item. The number of the current selection is passed 
to the called routine.

B<print_menu()>

Print the entire menu.

B<update_status($status)>

Change the value of C<status> and reprint the status line.

B<update_prompt($prompt)>

Change the value of C<prompt> and reprint the prompt.

B<line_after_menu()>

Return the number of the first line after the menu.

=head2 Exports

This is a fully object-oriented module. No exports are needed as all publicly 
available attributes and methods are accessible through the object itself.

=head1 NOTES

Hotkeys can be specified by using their name. This includes most of the
so-called special keys. Their names and corresponding keycodes as used in this 
module are listed below:

  "HOME"   => "\e[1~"   #Linux console
  "INSERT" => "\e[2~"   #VT100
  "DEL"    => "\e[3~"   #VT100
  "END"    => "\e[4~"   #Linux console
  "PGUP"   => "\e[5~"   #VT100
  "PGDN"   => "\e[6~"   #VT100
  "F1"     => "\e[11~"  #VT100
  "F2"     => "\e[12~"  #VT100
  "F3"     => "\e[13~"  #VT100
  "F4"     => "\e[14~"  #VT100
  "F5"     => "\e[15~"  #VT100
  "F6"     => "\e[17~"  #VT100
  "F7"     => "\e[18~"  #VT100
  "F8"     => "\e[19~"  #VT100
  "F9"     => "\e[20~"  #VT100
  "F10"    => "\e[21~"  #VT100
  "F11"    => "\e[23~"  #VT100
  "F12"    => "\e[24~"  #VT100
  "F1"     => "\e[[A"   #Linux console
  "F2"     => "\e[[B"   #Linux console
  "F3"     => "\e[[C"   #Linux console
  "F4"     => "\e[[D"   #Linux console
  "F5"     => "\e[[E"   #Linux console
  "UP"     => "\e[A"    #VT100
  "DOWN"   => "\e[B"    #VT100
  "RIGHT"  => "\e[C"    #VT100
  "LEFT"   => "\e[D"    #VT100
  "END"    => "\e[F"    #VT100
  "HOME"   => "\e[H"    #VT100
  "UP"     => "\eOA"    #XTerm
  "DOWN"   => "\eOB"    #XTerm
  "RIGHT"  => "\eOC"    #XTerm
  "LEFT"   => "\eOD"    #XTerm
  "END"    => "\eOF"    #XTerm
  "HOME"   => "\eOH"    #XTerm
  "F1"     => "\eOP"    #XTerm
  "F2"     => "\eOQ"    #XTerm
  "F3"     => "\eOR"    #XTerm
  "F4"     => "\eOS"    #XTerm
  "META-a" => "\ea"    
  "META-b" => "\eb"    
  "META-c" => "\ec"    
  "META-d" => "\ed"    
  "META-e" => "\ee"    
  "META-f" => "\ef"    
  "META-g" => "\eg"    
  "META-h" => "\eh"    
  "META-i" => "\ei"    
  "META-j" => "\ej"    
  "META-k" => "\ek"    
  "META-l" => "\el"    
  "META-m" => "\em"    
  "META-n" => "\en"    
  "META-o" => "\eo"    
  "META-p" => "\ep"    
  "META-q" => "\eq"    
  "META-r" => "\er"    
  "META-s" => "\es"    
  "META-t" => "\et"    
  "META-u" => "\eu"    
  "META-v" => "\ev"    
  "META-w" => "\ew"    
  "META-x" => "\ex"    
  "META-y" => "\ey"    
  "META-z" => "\ez"    
  "CTRL-a" => "\x01"   
  "CTRL-b" => "\x02"   
  "CTRL-c" => "\x03"   
  "CTRL-d" => "\x04"   
  "CTRL-e" => "\x05"   
  "CTRL-f" => "\x06"   
  "CTRL-g" => "\x07"   
  "CTRL-h" => "\x08"   
  "TAB"    => "\x09"   
  "ENTER"  => "\x0A"   
  "CTRL-k" => "\x0B"   
  "CTRL-l" => "\x0C"   
  "CTRL-m" => "\x0D"   
  "CTRL-n" => "\x0E"   
  "CTRL-o" => "\x0F"   
  "CTRL-p" => "\x10"   
  "CTRL-q" => "\x11"   
  "CTRL-r" => "\x12"   
  "CTRL-s" => "\x13"   
  "CTRL-t" => "\x14"   
  "CTRL-u" => "\x15"   
  "CTRL-v" => "\x16"   
  "CTRL-w" => "\x17"   
  "CTRL-x" => "\x18"   
  "CTRL-y" => "\x19"   
  "CTRL-z" => "\x1A"   
  "SPACE"  => "\x20"   
  "BS"     => "\x7F"   

Colors can be specified by using their common ANSI names:

  BLACK
  RED
  GREEN
  YELLOW
  BLUE
  MAGENTA
  CYAN
  WHITE

Character attributes can be specified by using these ANSI names:

  CLEAR
  BOLD
  UNDERLINE
  BLINK
  REVERSE

Some attributes can be assigned line drawing characters. The names of these 
characters are are:

  HOR (Horizontal line)
  VER (Vertical line)
  ULC (Upper Left Corner)
  URC (Upper Right Corner)
  LRC (Lower Right Corner)
  LLC (Lower Left Corner)
  LTE (Left T)
  RTE (Right T)
  TTE (Top T)
  BTE (Bottom T)
  CTE (Crossing Ts)

=head1 DIAGNOSTICS

All errors are reported through the Carp module. These are mainly encountered 
when using an illegal value for an attribute or method. When that happens a 
C<carp> warning is generated and the given value is just ignored. A C<croak>
message is generated when calling non-existent attributes or methods.

Following is a list of all diagnostic messages generated by Term::ANSIMenu. 
They should be self-explaining.

=over 4

=item *

No such attribute: E<lt>attribE<gt>

=item *

Invalid value for E<lt>attribE<gt>: E<lt>valueE<gt>

=item *

width must be larger than 0 and smaller than the terminal width

=item *

height must be larger than 0 and smaller than the terminal height

=item *

space_after_title must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

space_after_items must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

space_after_status must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

spacious_items must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

cursor must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

cursor_char must be a printable character

=item *

up_keys must be one or more keynames

=item *

up_keys must be given as a reference to an array

=item *

down_keys must be one or more keynames

=item *

down_keys must be given as a reference to an array

=item *

help must an array of arrays containing strings and code references

=item *

help must be given as a reference to an array

=item *

help_keys must be one or more keynames

=item *

help_keys must be given as a reference to an array

=item *

exit_keys must be one or more keynames

=item *

exit_keys must be given as a reference to an array

=item *

selection must be larger than or equal to 0 and smaller than or equal to the 
number of items

=item *

selection_wrap must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

selection_keys must be one or more keynames

=item *

selection_keys must be given as a reference to an array

=item *

selection_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR

=item *

selection_style must be given as a reference to an array

=item *

selection_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or 
WHITE

=item *

selection_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or 
WHITE

=item *

leader must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

trailer must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

shortcut_prefix must be a string of printable characters or a line-drawing 
character

=item *

shortcut_postfix must be a string of printable characters or a line-drawing 
character

=item *

delimiter must be a string of printable characters or a line-drawing character

=item *

leader_delimiter must be a string of printable characters or a line-drawing 
character

=item *

trailer_delimiter must be a string of printable characters or a line-drawing 
character

=item *

label_prefix must be a string of printable characters or a line-drawing 
character

=item *

label_postfix must be a string of printable characters or a line-drawing 
character

=item *

title must be a string of printable characters

=item *

title_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR

=item *

title_style must be given as a reference to an array

=item *

title_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE

=item *

title_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE

=item *

title_align must be LEFT, RIGHT or CENTER

=item *

title_fill must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

title_frame must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

title_frame_style must be BLINK, REVERSE, BOLD and/or CLEAR

=item *

title_frame_style must be given as a reference to an array

=item *

title_frame_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or 
WHITE

=item *

title_frame_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or 
WHITE

=item *

items must be an array of arrays containing keynames, descriptions and code 
references

=item *

items must be given as a reference to an array

=item *

item_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR

=item *

item_style must be given as a reference to an array

=item *

item_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE

=item *

item_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE

=item *

item_align must be LEFT, RIGHT or CENTER

=item *

item_fill must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

item_frame must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

item_frame_style must be BLINK, REVERSE, BOLD and/or CLEAR

=item *

item_frame_style must be given as a reference to an array

=item *

item_frame_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or 
WHITE

=item *

item_frame_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or 
WHITE

=item *

status must be a string of printable characters

=item *

status_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR

=item *

status_style must be given as a reference to an array

=item *

status_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE

=item *

status_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE

=item *

status_align must be LEFT, RIGHT or CENTER

=item *

status_fill must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

status_frame must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

status_frame_style must be BLINK, REVERSE, BOLD and/or CLEAR

=item *

status_frame_style must be given as a reference to an array

=item *

status_frame_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or 
WHITE

=item *

status_frame_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or 
WHITE

=item *

prompt must be a string of printable characters

=item *

prompt_style must be BLINK, REVERSE, BOLD, UNDERLINE and/or CLEAR

=item *

prompt_style must be given as a reference to an array

=item *

prompt_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE

=item *

prompt_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or WHITE

=item *

prompt_align must be LEFT, RIGHT or CENTER

=item *

prompt_fill must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

prompt_frame must be -, +, 0, 1, NO, N, YES, Y, FALSE, F, TRUE or T

=item *

prompt_frame_style must be BLINK, REVERSE, BOLD and/or CLEAR

=item *

prompt_frame_style must be given as a reference to an array

=item *

prompt_frame_fgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or
WHITE

=item *

prompt_frame_bgcolor must be BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN or
WHITE

=back

=head1 BUGS

Well, this is version 0.01, so there must be some. But I haven't seen them
yet. If you do find a bug or just like to see a feature added I'd appreciate
it if you'd let me know.

=head1 FILES

This module depends on the standard Carp module to blame your script if 
something goes wrong `;-)

It also depends on Term::ReadKey to read input from the keyboard. 

A terminal capable of interpreting ANSI sequences might help too...

=head1 SEE ALSO

Carp

Term::ReadKey

=head1 AUTHOR

J.A. de Vries E<lt>j.a.devries@dto.tudelft.nlE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, Jadev.

This module is free software. It may be used, redistributed and/or modified 
under the same terms as Perl itself.

=cut

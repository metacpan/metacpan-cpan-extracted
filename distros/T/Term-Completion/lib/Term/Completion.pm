package Term::Completion;

use strict;
use warnings;
use Carp qw(croak);
use IO::Handle;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(Complete);

our $VERSION = '1.02';

our %DEFAULTS = (
    # input/output channels
    in       => \*STDIN,
    out      => \*STDOUT,
    # key definitions
    tab      => qr/\t/,
    list     => qr/\cd/,
    'kill'   => qr/\cu/,
    erase    => qr/[\177\010]/, # BS and DEL
    wipe     => qr/\cw/,
    enter    => qr/[\r\n]/,
    up       => qr/\cp|\x1b\[[AD]/, # CTRL-p, up arrow, left arrow
    down     => qr/\cn|\x1b\[[BC]/, # CTRL-n, down arrow, right arrow
    # key definitions for paging
    quit     => qr/[\ccq]/, # CTRL-C or q
    # output parameters
    prompt   => '',
    columns  => 80, # default, if no Term::Size available
    rows     => 24,
    bell     => "\a",
    page_str => '--more--',
    eol      => "\r\n",
    del_one  => "\b \b",
    # help
    help     => undef,
    helptext => undef,
    # default: empty list of choices
    choices  => [],
    default  => ''
);

# selection which TTY handler to use
sub import
{
  my $class = shift;
  my @syms;
  # TODO Win32?
  my $termhandler = ($^O !~ /interix/i ? 'Term::Completion::_readkey' :
    'Term::Completion::_POSIX');
  foreach(@_) {
    if(/^:posix$/) {
      $termhandler = 'Term::Completion::_POSIX';
    }
    elsif(/^:stty$/) {
      $termhandler = 'Term::Completion::_stty';
    }
    elsif(/^:readkey$/) {
      $termhandler = 'Term::Completion::_readkey';
    }
    elsif(/^:DEFAULT$/ || !/^:/) {
      push(@syms, $_);
    }
    else {
      croak __PACKAGE__ . " does not export '$_'";
    }
  }
  eval "require $termhandler;";
  if($@) {
    croak "Cannot initialize ".__PACKAGE__.", error occurred while loading auxiliary class $termhandler:\n$@";
  }
  push(@ISA, $termhandler);
  $class->export_to_level(1, $class, @syms);
}

sub _get_defaults
{
  my %def = %DEFAULTS;
  delete @def{qw(columns rows)};
  return %def;
}

sub new
{
  my __PACKAGE__ $class = shift;

  if(ref $class) {
    $class = ref $class;
  }
  my %args = @_;
  my $this = bless({$class->_get_defaults, %args}, $class);
  return $this;
}

#sub DESTROY
#{
#  my __PACKAGE__ $this = shift;
#  1;
#}

# old style interface
sub Complete
{
  my $prompt = shift;
  $prompt = '' unless defined $prompt;

  my @choices;
  if (ref $_[0] || $_[0] =~ /^\*/) {
    @choices = sort @{$_[0]};
  } else {
    @choices = sort(@_);
  }

  __PACKAGE__->new(
    prompt => $prompt,
    choices => \@choices
  )->complete;
}

# sub get_key
# virtual - defined in tty driver classes

sub show_help
{
  my __PACKAGE__ $this = shift;
  my $text = $this->{helptext} || '';
  $text =~ s/\r?\n|\n?\r/$this->{eol}/g;
  $this->{out}->print($text);
}

sub complete
{
  my __PACKAGE__ $this = shift;

  my $return = $this->{default};
  my $r = length($return);

  if(defined $this->{helptext} && !defined $this->{help}) {
    $this->show_help();
  }

  # we grab full control of the terminal, switch off echo
  $this->set_raw_tty();

  my $tab_pressed = 0; # repeated tab counter
  my $choice_num; # selector
  my @choice_cycle;
  my $eof = 0;

  # handle terminal size changes
  # save any existing signal handler
  if(exists $SIG{'WINCH'}) {
    $this->{_sig_winch} = $SIG{WINCH};
    # set new signal handler
    local $SIG{'WINCH'} = sub {
      if($this->{_sig_winch}) {
        &{$this->{_sig_winch}};
      }
      # write new prompt and completion line
      $this->{out}->print($this->{eol}, $this->{prompt}, $return);
    };
  }

  # main loop for completion
  LOOP: {
    local $_ = '';
    $this->{out}->print($this->{prompt}, $return);
    my $key;
    GETC: while (defined($key = $this->get_key) && ($_ .= $key, $_ !~ $this->{enter})) {
      CASE: {
        # deal with arrow key escape sequences
        if(/^\x1b([^\[])/ || /^\x1b\[(?:[A-Z]|\d+~)(.)/) {
          # unknown ESC sequence: just keep the last key typed
          $_ = $1;
          redo CASE;
        }

        # (TAB) attempt completion
        $_ =~ $this->{tab} && do {
          if($tab_pressed++) {
            $this->show_choices($return);
            redo LOOP;
          }
          my @match = $this->get_choices($return);
          if (@match == 0) {
            # sound bell if there is no match
            $this->bell();
          } else {
            my $l = length(my $test = shift(@match));
            if(@match) {
              # sound bell if multiple choices
              $this->bell();
            }
            elsif($this->{delim}) {
              $test .= $this->{delim};
              $l++;
            }
            foreach my $cmp (@match) {
              until (substr($cmp, 0, $l) eq substr($test, 0, $l)) {
                $l--;
              }
            }
            my $add = $l - $r;
	    if($add > 0) {
              $this->{out}->print($test = substr($test, $r, $add));
              # reset counter if something was added
              $tab_pressed = 0;
              $choice_num = undef;
              $return .= $test;
              $r += $add;
            }
          }
          last CASE;
        };

        $tab_pressed = 0; # reset repeated tab counter

        # (^D) completion list
        $_ =~ $this->{list} && do {
          $this->show_choices($return);
          redo LOOP;
        };

        # on-demand help
        if(defined $this->{help}) {
          $_ =~ $this->{help} && do {
            if(defined $this->{helptext}) {
              $this->{out}->print($this->{eol});
              $this->show_help();
            }
            redo LOOP;
          };
        }

        # (^U) kill
        $_ =~ $this->{'kill'} && do {
          if ($r) {
            # start over on a new line
            $r = 0;
            $return = "";
            $this->{out}->print($this->{eol});
            $choice_num = undef;
            redo LOOP;
          }
          last CASE;
        };

        # (DEL) || (BS) erase
        $_ =~ $this->{erase} && do {
          if($r) {
            $this->{out}->print($this->{del_one});
            chop($return);
            $r--;
            $choice_num = undef;
          }
          last CASE;
        };

        # ^W wipe until separator
        $_ =~ $this->{wipe} && do {
          if($r) {
            my $sep = '';
            $sep = $this->{sep} if defined $this->{sep};
            $sep .= $this->{delim} if defined $this->{delim};
            if(length($sep) && $return =~ s/((?:^|[$sep$sep]+)[^$sep$sep]*[$sep$sep]*)$//s) {
              my $cut = $1;
              $this->{out}->print($this->{del_one} x length($cut));
              $r = length($return);
              $choice_num = undef;
            }
          }
          last CASE;
        };

        # up (CTRL-P)
        $_ =~ $this->{up} && do {
          unless(defined $choice_num) {
            @choice_cycle = $this->get_choices($return);
            if(defined $choice_cycle[$#choice_cycle]) {
              $choice_num = $#choice_cycle;
            }
          } else {
            if($choice_num <= 0) {
              $choice_num = @choice_cycle; # TODO get_choices returns number in scalar context?
            }
            $choice_num--;
          }
          #TODO only delete/print differences, not full string
          unless(defined $choice_num) {
            $this->bell();
          } else {
            $this->{out}->print($this->{del_one} x length($return));
            $return = $choice_cycle[$choice_num];
            $this->{out}->print($return);
            $r = length($return);
          }
          last CASE;
        };

        # down (CTRL-N)
        $_ =~ $this->{down} && do {
          unless(defined $choice_num) {
            @choice_cycle = $this->get_choices($return);
            if(defined $choice_cycle[0]) {
              $choice_num = 0;
            }
          } else {
            if(++$choice_num >= @choice_cycle) {
              $choice_num = 0;
            }
          }
          #TODO only delete/print differences, not full string
          unless(defined $choice_num) {
            $this->bell();
          } else {
            $this->{out}->print($this->{del_one} x length($return));
            $return = $choice_cycle[$choice_num];
            $this->{out}->print($return);
            $r = length($return);
          }
          last CASE;
        };

        # printable char
        ord >= 32 && do {
          $return .= $_;
          $r++;
          $this->{out}->print($_);
          $choice_num = undef;
          last CASE;
        };

        $_ !~ /^\x1b/ && do {
          # sound bell and reset any unknown key
          $this->bell();
          $_ = '';
        };
        next GETC; # nothing matched - get new character
      } # :ESAC
      $_ = '';
    } # while getc != enter
    $this->{out}->print($this->{eol});
    $return = $this->post_process($return);
    # only validate if we had input
    my $match = defined($key) ? $this->validate($return) : $return;
    unless(defined $match) {
      redo LOOP;
    }
    $return = $match;
  } # end LOOP

  $this->reset_tty;
  delete $this->{_sig_winch};

  return $return;
}

sub validate
{
  my __PACKAGE__ $this = shift;
  my $return = shift;
  unless($this->{validate}) {
    return $return;
  }
  elsif(ref $this->{validate}) {
    # arrayref with message to print and code ref
    my ($msg, $cb) = @{$this->{validate}};
    my $match = &$cb($return);
    unless(defined $match) {
      $this->{out}->print($msg,$this->{eol});
      return;
    }
    return $match;
  }

  # we may have several validation options
  my @vals = split(/[\s,]+/, $this->{validate});

  VALIDATE_OPTIONS: foreach my $val (@vals) {

    if($val eq 'lowercase') {
      $return = lc($return);
    }

    if($val eq 'uppercase') {
      $return = uc($return);
    }

    if($val eq 'match_one') {
      my @choices = $this->get_choices('');
      my @matches = grep(/^\Q$return\E/, @choices);
      MATCH: {
        if(@matches == 1) {
          # unique match at beginning
          $return = $matches[0];
          last MATCH;
        }
        elsif(@matches == 0) {
          @matches = grep(/\Q$return\E/, @choices);
          if(@matches == 1) {
            # unique match anywhere
            $return = $matches[0];
            last MATCH;
          }
        }
        $this->{out}->print("ERROR: Answer '$return' does not match a unique item!",$this->{eol});
        $return = undef;
        last VALIDATE_OPTIONS;
      } # MATCH
    }

    if($val eq 'nonempty') {
      unless(length $return) {
        $this->{out}->print("ERROR: Empty input not allowed!",$this->{eol});
        $return = undef;
        last VALIDATE_OPTIONS;
      }
    }

    if($val eq 'nonblank') {
      unless(length $return && $return =~ /\S/) {
        $this->{out}->print("ERROR: Blank input not allowed!",$this->{eol});
        $return = undef;
        last VALIDATE_OPTIONS;
      }
    }

    if($val eq 'fromchoices') {
      if(length($return) && !grep($return eq $_, $this->get_choices(''))) {
        $this->{out}->print("ERROR: You must choose one item from the list!",$this->{eol});
        $return = undef;
        last VALIDATE_OPTIONS;
      }
    }

    if($val eq 'numeric') {
      unless($return =~ /^-?(?:\.\d+|\d+\.?\d*)$/) {
        $this->{out}->print("ERROR: Value must be numeric!",$this->{eol});
        $return = undef;
        last VALIDATE_OPTIONS;
      }
    }

    if($val eq 'integer') {
      unless($return =~ /^-?\d+$/) {
        $this->{out}->print("ERROR: Value must be an integer number!",$this->{eol});
        $return = undef;
        last VALIDATE_OPTIONS;
      }
    }

    if($val eq 'nonzero') {
      if($return == 0) {
        $this->{out}->print("ERROR: Value must be a non-zero value!",$this->{eol});
        $return = undef;
        last VALIDATE_OPTIONS;
      }
    }

    if($val eq 'positive') {
      unless($return > 0.0) {
        $this->{out}->print("ERROR: Value must be a positive value!",$this->{eol});
        $return = undef;
        last VALIDATE_OPTIONS;
      }
    }

  } # end validation options

  # TODO die on unknown validate option?
  return $return;
}

sub bell
{
  my __PACKAGE__ $this = shift;
  my $bell = $this->{bell};
  $this->{out}->print($bell) if $bell;
}

sub get_choices
{
  my __PACKAGE__ $this = shift;
  grep(defined && /^\Q$_[0]/,@{$this->{choices}});
}

sub show_choices
{
  my __PACKAGE__ $this = shift;
  my $return = shift;
  # start new line - cursor was on input line
  $this->{out}->print($this->{eol});
  $this->_show_choices($this->get_choices($return));
}

sub _show_choices {
  my __PACKAGE__ $this = shift;
  my @choices = @_;

  my $eol = $this->{eol};
  unless(@choices) {
    return 1;
  }
  if(defined $this->{columns} && $this->{columns} == 0) {
    # poor man's solution:
    $this->{out}->print(join($eol, @choices), $eol);
    return 1;
  }

  # find width of widest entry
  my $MAXWIDTH = 0;
  grep(length > $MAXWIDTH && ($MAXWIDTH = length), @choices);
  $MAXWIDTH++; # add one for a blank between the columns

  if(exists $SIG{'WINCH'}) {
    $this->{_winch} = 0;
    local $SIG{'WINCH'} = sub {
      $this->{_winch}++;
      if($this->{_sig_winch}) {
        return &{$this->{_sig_winch}};
      }
    };
  }

  my ($COLUMNS,$ROWS) = ($this->{columns}, $this->{rows});
  START_PAGING: {
    ($COLUMNS,$ROWS) = $this->get_term_size()
      unless $COLUMNS && $ROWS;
    my $maxwidth = $MAXWIDTH;
    my $columns = $maxwidth >= $COLUMNS ? 1 : int($COLUMNS / $maxwidth);

    ## if there's enough margin to intersperse among the columns, do so.
    $maxwidth += int(($COLUMNS % $maxwidth) / $columns);
    my $lines = int((@choices + $columns - 1) / $columns);
    $columns-- while ((($lines * $columns) - @choices + 1) > $lines);

    my $i = 0;
    my $page_lines = 0;
    for (my $l = 0; $l < $lines; $l++) {
      my @line;
      for(my $c = 0; $c < $columns && $i<@choices; $c++) {
        push(@line, sprintf("%-${maxwidth}s", $_[$i++]));
      }
      # no paging if ROWS were set to 0
      if($ROWS && ++$page_lines == $ROWS) {
        $this->{out}->print($this->{page_str});
        my $c = $this->get_key;
        # delete pager line
        $this->{out}->print($this->{del_one} x length($this->{page_str}));
        if($c =~ $this->{quit}) {
          return 1;
        }
        elsif($this->{_winch}) {
          # winch signaled, restart paging
          $this->{_winch} = 0;
          $this->bell();
          $this->{out}->print($this->{eol});
	  $COLUMNS = $ROWS = undef;
          redo START_PAGING;
        }
        elsif($c =~ $this->{enter}) {
          $page_lines--;
        }
        else {
          $page_lines = 0;
        }
      }
      $this->{out}->print(@line, $eol);
    } # end loop over lines
  } # end START_PAGING
  1;
}

sub post_process
{
  my __PACKAGE__ $this = shift;
  my $return = shift;
  $return =~ s/^\s+|\s+$//sg;
  $return;
}

1;
__END__

=for stopwords CTRL

=head1 NAME

Term::Completion - read one line of user input, with convenience functions

=head1 USAGE

  use Term::Completion;
  my $tc = Term::Completion->new(
    prompt  => "Enter your first name: ",
    choices => [ qw(Alice Bob Chris Dave Ellen) ]
  );
  my $name = $tc->complete();
  print "You entered: $name\n";

=head1 DESCRIPTION

Term::Completion is an extensible, highly configurable replacement for the
venerable L<Term::Complete> package. It is object-oriented and thus allows
subclassing. Two derived classes are L<Term::Completion::Multi> and
L<Term::Completion::Path>.

A prompt is printed and the user may enter one line of input, submitting
the answer by pressing the ENTER key. This basic scenario can be implemented
like this:

    my $answer = <STDIN>;
    chomp $answer;

But often you don't want the user to type in the full word (from a list of
choices), but allow I<completion>, i.e. expansion of the word as far as
possible by pressing as few keys as necessary.

Some users like to cycle through the choices, preferably with the
up/down arrow keys.

And finally, you may not want the user to enter any random characters,
but I<validate> what was enter and come back if the entry did not pass
the validation.

If you are missing full line editing (left/right, delete to the left
and right, jump to the beginning and the end etc.), you are probably
wrong here, and want to consider L<Term::ReadLine> and friends.

=head2 Global Setup

The technical challenge for this package is to read single keystrokes from
the input handle - usually STDIN, the user's terminal. There are various ways
how to accomplish that, and Term::Completion supports them all:

=over 4

=item use Term::Completion qw(:stty);

Use the external C<stty> command to configure the terminal. This is what
L<Term::Complete> does, and works fine on systems that have a working
C<stty>. However, using an external command seems like an ugly overhead.
See also L<Term::Completion::_stty>.

=item use Term::Completion qw(:readkey);

This is the default for all systems, as we assume  you have 
L<Term::ReadKey> installed. This seems to be the right approach to also
support various platforms. See also L<Term::Completion::_readkey>.

=item use Term::Completion qw(:POSIX);

This uses the L<POSIX> interface (C<POSIX::Termios>) to set the
terminal in the right mode. It should be well portable on UNIX systems.
See also L<Term::Completion::_POSIX>.

=back

=head2 Exports

Term::Completion does not export anything by default, in order not to
pollute your namespace. Here are the exportable methods:

=over 4

=item Complete(...)

For compatibility with L<Term::Complete>, you can import the C<Complete>
function:

  use Term::Completion qw(Complete);
  my $result = Complete($prompt, @choices);

=back

=head2 Methods

Term::Completion objects are simple hashes. All fields are fully
accessible and can be tweaked directly, without accessor methods.

Term::Completion offers the following methods:

=over 4

=item new(...)

The constructor for Term::Completion objects. Arguments are key/value
pairs. See L<"Configuration"> for a description of all
options. Note that C<columns> and C<rows> overrides the real terminal
size from L<Term::Size>.

Usually you'd supply the list of choices and the prompt string:

  my $tc = Term::Completion->new(
    prompt => "Pick a color: ",
    choices => [ qw(red green blue) ]
  );

The object can be reused several times for the same purpose.
Term::Completion objects are simple hashes. All fields are fully
accessible and can be tweaked directly, without accessor methods.
In the example above, you can manipulate the choice list:

  push(@{$tc->{choices}}, qw(cyan magenta yellow));

Note that the constructor won't actually execute the query -
that is done by the C<complete()> method.

=item show_help()

Print the text stored in the object's C<helptext> member variable.

=item complete()

This method executes the query and returns the result string.
It is guaranteed that the result is a defined value, it may
however be empty or 0.

=item post_process($answer)

This method is called on the answer string entered by the user
after the ENTER key was pressed. The implementation in the base
class is just stripping any leading and trailing whitespace.
The method returns the post-processed answer string.

=item validate($answer)

This method is called on the post-processed answer and returns:

1. in case of success

The correct answer string. Please note that the validate method may
alter the answer, e.g. to adapt it to certain conventions (lowercase
only).

2. in case of failure

The I<undef> value. This indicates a failure of the validation. In that
situation an error message should be printed to tell the user why the
validation failed. This should be done using the following idiom for
maximum portability:

  $this->{out}->print("ERROR: no such choice available",
                      $this->{eol});

Validation is turned on by the C<validate> parameter.
See L<"Predefined Validations"> for a list of available
validation options.

You can override this method in derived classes to implement
your own validation strategy - but in some situations this
could be too much overhead. So the base class accepts an array
reference for a custom validation callback:

  my $tc = Term::Completion->new(
    prompt => 'Enter voltage: ',
    choices => [ qw(1.2 1.5 1.8 2.0 2.5 3.3) ],
    validate => [
      'Voltage must be a positive, non-zero value' =>
      sub { $_[0] > 0.0 ? $_[0] : undef }
    ]
  );

Note that the given code reference will be passed one single argument,
namely the current input string, and is supposed to return I<undef> if
the input is invalid, or the (potentially corrected) string, like in the
example above.

=item get_choices($answer)

This method returns the items from the choice list which match the
current answer string. This method is used by the completion algorithm
and the list of choices. This can be overridden to implement a
completely different way to get the choices (other than a static list) -
e.g. by querying a database.

=item show_choices($answer)

This method is called when the user types CTRL-D (or TAB-TAB) to show the
list of choices, available with the current answer string. Basically
C<get_choices($answer)> is called and then the list is pretty-printed
using C<_show_choices(...)>.

=item _show_choices(...)

Pretty-print the list of items given as arguments. The list is formatted
into columns, like in UNIX' C<ls> command, according to the current
terminal width (if L<Term::Size> is available). If the list is long,
then poor man's paging is enabled, comparable to the UNIX C<more>
command. The user can use ENTER to proceed by one line, SPACE to proceed
to the next page and Q or CTRL-C to quit paging. After listing the
choices and return from this method, the prompt and the current answer
are displayed again.

Override this method if you have a better pretty-printer/pager. :-)

=back

=head2 Configuration

There is a global hash C<%Term::Completion::DEFAULTS> that contains the
default values for all configurable options. Upon object construction
(see L<"new(...)"> any of these defaults can be overridden by placing
the corresponding key/value pair in the arguments. Find below the list
of configurable options, their default value and their purpose.

The key definitions are regular expressions (C<qr/.../>) - this allows
to match multiple keys for the same action, as well as disable the
action completely by specifying an expression that will never match a 
single character, e.g. C<qr/-disable-/>.

=over 4

=item C<in>

The input file handle, default is C<\*STDIN>. Can be any filehandle-like
object, has to understand the C<getc()> method.

=item C<out>

The output file handle, default is C<\*STDOUT>. Can be basically any
filehandle-like object, has to understand the C<print()> method.

=item C<tab>

Regular expression matching those keys that should work as the TAB key,
i.e. complete the current answer string as far as possible, and when
pressed twice, show the list of matching choices. Default is the tab
key, i.e. C<qr/\t/>.

=item C<list>

Regular expression matching those keys that should trigger the listing
of choices. Default is - like in L<Term::Complete> - CTRL-D, i.e.
C<qr/\cd/>.

=item C<kill>

Regular expression matching those keys that should delete all input.
Default is CTRL-U, i.e. C<qr/\cu/>.

=item C<erase>

Regular expression matching those keys that should delete one character
(backspace). Default is the BACKSPACE and the DELETE keys, i.e.
C<qr/[\177\010]/>.

=item C<wipe>

This is a special control: if either C<sep> or C<delim> are defined (see
below), then this key "wipes" all characters (from the right) until (and
including) the last separator or delimiter. Default is CTRL-W, i.e.
C<qr/\cw/>.

=item C<enter>

Regular expression matching those keys that finish the entry process.
Default is the ENTER key, and for paranoia reasons we use C<qr/[\r\n]/>.

=item C<up>

Regular expression matching those keys that select the previous item
from the choice list. Default is CTRL-P, left and up arrow keys, i.e.
C<qr/\cp|\x1b\[[AD]/>.

=item C<down>

Regular expression matching those keys that select the next item
from the choice list. Default is CTRL-N, right and down arrow keys, i.e.
C<qr/\cn|\x1b\[[BC]/>.

=item C<quit>

Regular expression matching those keys that exit from paging when the
list of choices is displayed. Default is 'q' and CTRL-C, i.e.
C<qr/[\ccq]/>.

=item C<prompt>

A default prompt string to apply for all Term::Completion objects.
Default is the empty string.

=item C<columns>

Default number of terminal columns for the list of choices. This default
is only applicable if L<Term::Size> is unavailable to get the real
number of columns. The default is 80.

=item C<rows>

Default number of terminal rows for the list of choices. This default is
only applicable if L<Term::Size> is unavailable to get the real number
of rows. The default is 24. If set to 0 (zero) there won't be any paging
when the list of choices is displayed.

=item C<bell>

The character which rings the terminal bell, default is C<"\a">. Used
when completing with the TAB key and there are multiple choices
available, and when paging is restarted because the terminal size was
changed.

=item C<page_str>

The string to display when max number of lines on the terminal has been
reached when displaying the choices. Default is C<'--more--'>.

=item C<eol>

The characters to print for a new line in raw terminal mode. Default is
C<"\r\n">.

=item C<del_one>

The characters to print for deleting one character (to the left).
Default is C<"\b \b">.

=item C<help>

Regular expression matching those keys that print C<helptext> on-demand.
Furthermore, with C<help> defined (I<undef>), automatic printing of
C<helptext> by the C<complete()> method is disabled (enabled).
Default is I<undef>, for backwards compatibility; C<qr/\?/> is suggested.

=item C<helptext>

This is an optional text which is printed by the C<complete()> method
before the actual completion process starts, unless C<help> is defined.
It may be a multi-line string and should end with a newline character.
Default is I<undef>. The text could for example look like this:

  helptext => <<'EOT',
    You may use the following control keys here:
      TAB      complete the word
      CTRL-D   show list of matching choices (same as TAB-TAB)
      CTRL-U   delete the entire input
      CTRL-H   delete a character (backspace)
      CTRL-P   cycle through choices (backward) (also up arrow)
      CTRL-N   cycle through choices (forward) (also down arrow)
  EOT

=item C<choices>

The default list of choices for all Term::Completion objects (unless
overridden by the C<new(...)> constructor. Has to be an array reference.
Default is the empty array reference C<[]>. Undefined items are
filtered out.

=item C<validate>

Enable validation of the entered string. The value can be either a string
of comma or blank-separated words, see below for available options; or an
array reference, containing two scalars: the validation error string and
a code reference that implements the check.

=back

=head2 Predefined Validations

Whenever you need validation of the user's input, you can always specify
your own code, see L</validate($answer)> above. To support everybody's
laziness, there are a couple of predefined validation methods available.
You can specify them as a blank or comma separated string in the
C<new(...)> constructor:

  my $tc = Term::Completion->new(
    prompt => 'Fruit: ',
    choices => [ qw(apple banana cherry) ],
    validate => 'nonblank fromchoices'
  );

In the example above, you are guaranteed the user will choose one of the
given choices. Here's a list of all pre-implemented validations:

=over 4

=item C<uppercase>

Map all the answer string to upper case before proceeding with any
further validation.

=item C<lowercase>

Map all the answer string to lower case before proceeding with any
further validation.

=item C<match_one>

This option has some magic: it tries to match the answer string first at
the beginning of all choices; if that yields a unique match, the match
is returned. If not, the answer string is matched at any position in the
choices, and if that yields a unique match, the match is returned.
Otherwise an error will be raised that the answer does not match a
unique item.

=item C<nonempty>

Raises an error if the answer has a length of zero characters.

=item C<nonblank>

Raises an error if the answer does not contain any non-whitespace
character.

=item C<fromchoices>

Only allow literal entries from the choice list, or the empty
string. If you don't like the latter, combine this with
C<nonempty>.

=item C<numeric>

Only allow numeric values, e.g. -1.234 or 987.

=item C<integer>

Only allow integer numbers, e.g. -1 or 234.

=item C<nonzero>

Prohibit the numeric value 0 (zero). To avoid warnings about non-numeric
values, this should be used together with one of C<numeric> or C<integer>.

=item C<positive>

Only allow numeric values greater than zero. To avoid warnings about
non-numeric values, this should be used together with one of C<numeric>
or C<integer>.

=back

This list obviously can be arbitrarily extended. Suggestions (submitted
as patches) are welcome.

=head1 CAVEATS

=head2 Terminal handling

This package temporarily has to set the terminal into 'raw' mode, which
means that all keys lose their special meaning (like CTRL-C, which
normally interrupts the script). This is a highly platform-specific
operation, and therefore this package depends on the portability of
L<Term::ReadKey> and L<POSIX>. Reports about failing platforms are
welcome, but there is probably little that can be fixed here.

=head2 Terminal size changes

This package does the best it can to handle changes of the terminal size
during the completion process. It displays the prompt again and the current
entry during completion, and restarts paging when showing the list of
choices. The latter however only after you press a key - the bell
sounds to indicate that something happened. This is because it does not
seem possible to jump out of a getc().

=head2 Arrow key handling

On UNIX variants, the arrow keys generate a sequence of bytes, starting
with the escape character, followed by a square brackets and others.
Term::Completion accumulates these characters until they either match
this sequence, or not. In the latter case, it will drop the previous
characters and proceed with the last one typed. That however means that
you won't be able to assign the bare escape key to an action. I found
this to be the lesser of the evils. Suggestions on how to solve this in
a clean way are welcome. Yes, I read 
L<perlfaq5/"How can I tell whether there's a character waiting on a filehandle?">
but that's probably little portable.

=head1 SEE ALSO

L<Term::Complete>, L<Term::ReadKey>, L<Term::Size>, L<POSIX>,
L<Term::ReadLine>

=head1 AUTHOR

Marek Rouchal, E<lt>marekr@cpan.org<gt>

=head1 BUGS

Please submit patches, bug reports and suggestions via the CPAN tracker
L<http://rt.cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2013 by Marek Rouchal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


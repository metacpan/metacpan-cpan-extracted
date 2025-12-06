# License: http://creativecommons.org/publicdomain/zero/1.0/
# (CC0 or Public Domain).  To the extent possible under law, the author,
# Jim Avera (email jim.avera at gmail dot com) has waived all copyright and
# related or neighboring rights to this document.  Attribution is requested
# but not required.
use strict; use warnings FATAL => 'all'; use utf8;
use feature qw(say state lexical_subs current_sub);
no warnings qw(experimental::lexical_subs);

package Spreadsheet::Edit::Log;

# Allow "use <thismodule. VERSION ..." in development sandbox to not bomb
{ no strict 'refs'; ${__PACKAGE__."::VER"."SION"} = 1999.999; }
our $VERSION = '1000.030'; # VERSION from Dist::Zilla::Plugin::OurPkgVersion
our $DATE = '2025-12-05'; # DATE from Dist::Zilla::Plugin::OurDate

use Carp;
use Scalar::Util qw/reftype refaddr blessed weaken openhandle/;
use List::Util qw/first any all/;
use File::Basename qw/dirname basename/;
use Data::Dumper::Interp qw/dvis vis visq avis hvis visnew addrvis u/;

use Exporter 5.57 ();
our @EXPORT = qw/fmt_call log_call fmt_methcall log_methcall
                 nearest_call abbrev_call_fn_ln_subname/;

our @EXPORT_OK = qw/btw btwN btwbt oops set_logdest
                    colorize ERROR_COLOR WARN_COLOR BOLD_COLOR/;

my %backup_defaults = (
  logdest         => \*STDERR,
  is_public_api   => sub{ $_[1][3] =~ /(?:::|^)[a-z][^:]*$/ },

  #fmt_object      => sub{ addrvis($_[1]) },
  # Just show the address, sans class::name.  Note addrvis wraps it in <...>
  fmt_object      => sub{ addrvis(refaddr($_[1])) },
);

sub set_logdest(*) {
  $backup_defaults{logdest} = $_[0];
}

my $default_pfx = '$lno';

our %opts = (
  color => 1,
);

use constant ERROR_COLOR => "error";
use constant WARN_COLOR  => "warn";
use constant BOLD_COLOR  => "norm";
use constant SUCCESS_COLOR  => "succ";

# Insert escapes to colorize text, provided the terminal supports ansi escapes
sub colorize($$) {
  my ($str, $type) = @_;
  state $codes;
  my sub _getcode($;$) {
    my ($name, $tput_args) = @_;
    unless (exists $codes->{$name}) {
      $tput_args //= $name;
      $codes->{$name} = `tput $tput_args 2>/dev/null`;
      $codes->{$name} = undef if $? != 0;
    }
    return $codes->{$name} // die("terminal does not support $name");
  }
  my ($color_start, $color_end);
  eval {
    # The basic colors 0-7 => black,red,green,yellow,blue,magenta,cyan,white
    # ("white" is often really light grey)
    $color_start =
      $type eq BOLD_COLOR    ? _getcode("bold") :
      $type eq WARN_COLOR    ? _getcode("boldyellow", "setaf 3 bold") :
      $type eq ERROR_COLOR   ? _getcode("boldred", "setaf 1 bold") :
      $type eq SUCCESS_COLOR ? _getcode("boldgreen", "setaf 2 bold") :
      croak "unknown message type '$type'"
      ;
    $color_end = _getcode("sgr0");
  };
  if ($@) {
    return $str if $@ =~ /terminal/; # not impl for current terminal
    die $@;
  }
  my @chunks = map{ $color_start.$_.$color_end } split /\R/, $str, -1;
  return join "\n", @chunks;
}

sub import {
  my $class = shift;
  my $pkg = caller;
  state $first_pkg;
  my @remaining_args;
  foreach (@_) {
    local $_ = $_; # mutable copy
    if (/btw/ && ($first_pkg//=$pkg) ne $pkg) {
      $default_pfx = '${pkg_space}$lno'; # show package if used in multiple
    }
    # Generate customized version of btwN() (called by btw) which uses an
    # arbitrary prefix expression.  The expression is eval'd each time,
    # referencing variables $path $fname $lno $package
    # (it is eval'd multiple times if a [list of level numbers] is given).
    if (/:btwN=(.*)\z/s) {
      warn ":btwN is deprecated, just use :btw=... and both btw() and btwN() will be generated\n";
      $_ = ":btw=$1";
    }
    if (/:btw=(.*)\z/s) {
      _genbtw_funcs($pkg,$1);
    }
    elsif (/^:(no)?(\w+)\z/ && exists($opts{$2})) {
      $opts{$2} = $1 ? 0 : 1;
    }
    elsif (/^:(\w+)=(.*)\z/ && exists($opts{$1})) {
      $opts{$1} = $2;
    }
    else {
      push @remaining_args, $_;
    }
  }
  @_ = ($class, @remaining_args);
  goto &Exporter::import
}#import


sub _btwTN($$@) {
  my ($pfxexpr, $N, @strings) = @_;
#die dvis '## TEX _btwTN: $pfxexpr $N\n';
  local $@;
  local $_ = join("", @strings);
  $pfxexpr = $default_pfx if $pfxexpr eq "__DEFAULT__";
  s/\n\z//s;
  my @levels;
  my $sep = ",";
  if (ref($N) eq "") {
    @levels = ($N);
  }
  elsif (ref($N) eq 'SCALAR' && defined($$N) && $$N >= 1) {
    @levels = 0..($$N-1); # mini-traceback
    #$sep = "<";
    #$sep = " ← ";
    #$sep = " ⇽ ";
    #$sep = " « "; # « exists in both Unicode and latin1
    $sep = " ⇐ ";
  }
  elsif (ref($N) eq 'ARRAY' && all{defined} @$N) {
    @levels = sort { $a <=> $b } @$N;
    $sep = " ⇐ " if $#levels == ($levels[-1] - $levels[0]);
  }
  else {
    confess "Invalid N arg to btwN: $N"
  }
  my $pfx = "";
  foreach my $n (@levels) {
    my ($package, $path, $lno) = caller($n);
    next unless defined $lno;
    (my $fname = $path) =~ s/.*[\\\/]//;
    $fname =~ s/\.pm$//;
    my $pkg = ($package =~ s/.*:://r);
    my $pkg_space = $package eq "main" ? "" : "$pkg ";
    my $s = eval qq< qq<${pfxexpr}> >;
    croak "ERROR IN btw prefix '$pfxexpr': $@" if $@;
    $pfx .= $sep if $pfx;
    $pfx .= $s;
  }
  if (ref($N) eq "") {
    foreach (2..$N) { $pfx .= "«" }
  }
  my $fh = _getoptions()->{logdest};
  $_ = colorize($_, WARN_COLOR) if $opts{color};
  print $fh "${pfx}: $_\n";
}#_btwTN

sub _genbtw_funcs($$) {
  my ($pkg, $pfxexpr) = @_;
#Carp::cluck dvis '## _gen $pkg $pfxexpr\n';
  no strict 'refs';
  my $btwN  = eval{ sub($@) { unshift @_,$pfxexpr; goto &_btwTN } } // die $@;
  my $btw   = eval{ sub(@)  { unshift @_,0 ; goto &{"${pkg}::btwN"} } } // die $@;
  my $btwbt = eval{ sub(@)  { unshift @_,\99 ; goto &{"${pkg}::btwN"} } } // die $@;
  *{"${pkg}::btwN"} = \&$btwN;
  *{"${pkg}::btw"}  = \&$btw;
  *{"${pkg}::btwbt"}  = \&$btwbt;
}
BEGIN {
  # Generate the functions used when imported the usual way.
  # The special prefix "__DEFAULT__" shows just $lno if btw() has only
  # been imported into a single package, otherwise it is more fully qualified.
  _genbtw_funcs(__PACKAGE__,'__DEFAULT__');
}

sub oops(@) {
  my @args = @_;
  foreach (@args) { $_ = colorize($_, ERROR_COLOR) if $opts{color}; }
  my $pkg = caller;
  my $pfx = "\nOOPS";
  #$pfx .= " in pkg '$pkg'" unless $pkg eq 'main';
  $pfx .= ": ";
  if (defined(&Spreadsheet::Edit::logmsg)) {
    # Show current apply sheet & row if any.
    @_=($pfx, &Spreadsheet::Edit::logmsg(@args));
  } else {
    @_=($pfx, @args);
  }
  push @_,"\n" unless $_[-1] =~ /\R\z/;
  STDOUT->flush if openhandle(*STDOUT);
  STDERR->flush if openhandle(*STDERR);
  goto &Carp::confess;
}

# Return ref to hash of effective options (READ-ONLY).
# If the first argument is a hashref it is shifted off and
# used as options which override defaults.
sub _getoptions {
  my $pkg;
  my $N=1; while (($pkg=caller($N)//oops) eq __PACKAGE__) { ++$N }
  no strict 'refs';
  my $r = *{$pkg."::SpreadsheetEdit_Log_Options"}{HASH};
  +{ %backup_defaults,
    (defined($r) ? %$r : ()),
    ((@_ && ref($_[0]) eq 'HASH') ? %{shift(@_)} : ())
   }
}

sub get_effective_logdest() { _getoptions->{logdest} }

# Format a usually-comma-separated list sans enclosing brackets.
#
# Items are formatted by vis() and thus strings will be "quoted", except that
# \"ref to string" inserts the string value without quotes and suppresses
# adjacent commas (for inserting fixed annotations).
# Object refs in the top two levels are not visualized.
#
# If the arguments are recognized as a sequence then they are formatted as
# Arg1..ArgN instead of Arg1,Arg2,...,ArgN.
#
sub _fmt_list($) {
  my @items = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : ($_[0]);
  oops if wantarray;
  if (my $is_sequential = (@items >= 4)) {
    my $seq;
    foreach(@items) {
      $is_sequential=0,last
        unless defined($_) && /^\w+$/ && ($seq//=$items[0])++ eq $_
    }
    if ($is_sequential) {
      return visq($items[0])."..".visq($items[-1])
    }
  }
  join "", map{
             my $item = $items[$_];
             ($_ > 0 && (ref($items[$_-1]) ne 'SCALAR' || ${$items[$_-1]} eq "")
                     && (ref($item)        ne 'SCALAR' || ${$item}        eq "")
               ? "," : ""
             )
            .(ref($item) eq 'SCALAR' ? ${$item} : visnew->Pad("  ")->vis($item)
             )
  } 0..$#items;
}
## test
#foreach ([], [1..5], ['f'..'i'], ['a'], ['a','x']) {
#  my @items = @$_;
#  warn avis(@items)," -> ", scalar(_fmt_list(@items)), "\n";
#  @items = (\"-FIRST-", @items);
#  warn avis(@items)," -> ", scalar(_fmt_list(@items)), "\n";
#  splice @items, int(scalar(@items)/2),0, \"-ANN-" if @items >= 1;
#  warn avis(@items)," -> ", scalar(_fmt_list(@items)), "\n";
#  push @items, \"-LAST-";
#  warn avis(@items)," -> ", scalar(_fmt_list(@items)), "\n";
#}
#die "TEX";

#####################################################################
# Locate the nearest call to a public sub in the call stack.
#
# A callback decides what might be a "public" entrypoint (default:
# any sub named starting with [a-z]).
#
# RETURNS
#   ([frame], [called args]) in array context
#   [frame] in scalar context
#
# "frame" means caller(n) results:
#   0       1        2       3
#   package filename linenum subname ...
#
##use constant _CALLER_OVERRIDE_CHECK_OK =>
##     (defined(&Carp::CALLER_OVERRIDE_CHECK_OK)
##      && &Carp::CALLER_OVERRIDE_CHECK_OK);

sub _nearest_call($$) {
  my ($state, $opts) = @_;
  my $callback = $opts->{is_public_api};
  for (my $lvl=1 ; ; ++$lvl) {
    my @frame = caller($lvl);
    confess "No public-API sub found" unless defined($frame[0]);
    my $calling_pkg = $frame[0];
    my ($called_pkg) = ($frame[3] =~ /^(.*)::/) or next; # eval?
    no strict 'refs';
    #if ((!any{ $_ eq $called_pkg } (__PACKAGE__,$calling_pkg,@{$calling_pkg."::CARP_NOT"}))
    if ($called_pkg ne __PACKAGE__ && $callback->($state, \@frame)) {
      return \@frame;
    }
  }
}
sub nearest_call(;$) {
  my $opts = &_getoptions;
  _nearest_call({}, $opts);
}

sub _abbrev_call_fn_ln_subname($$) {
  my ($state, $opts) = @_;
  my @results = @{ &_nearest_call($state, $opts) }[1,2,3]; # (fn, lno, subname)
  $results[0] = basename $results[0]; # filename
  $results[2] =~ s/.*:://;            # subname
  $results[2] = $opts->{subname_override} if defined $opts->{subname_override};
  @results
}
sub abbrev_call_fn_ln_subname(;$) {
  my $opts = &_getoptions;
  _abbrev_call_fn_ln_subname({},$opts);
}

sub _fmt_call($;$$) {
  my $opts = shift;
  confess "Expecting {optOPTIONS} INPUTS optRESULTS" unless @_==1 or @_==2;
  my ($inputs, $retvals) = @_;
#warn dvis '### $opts\n    $inputs\n    $retvals';

  my $state = {};
  my ($fn, $lno, $subname) = _abbrev_call_fn_ln_subname($state, $opts);
  # TODO: Allow supporessing $fn: for specified package(s)???
  my $msg = ">[$fn:$lno] ";

  my sub myequal($$) {
    if ((my $r1 = refaddr($_[0])) && (my $r2 = refaddr($_[1]))) {
      return $r1 == $r2;  # same object
    } else {
      return u($_[0]) eq u($_[1]);   # string reps eq, or both undef
    }
  }

  state $prev_obj;
  if (defined(my $obj = $opts->{self})) {
    # N.B. "self" might not be a ref, or might be unblessed
    if (! myequal($obj, $prev_obj)) {
      # Show the obj address in only the first of a sequence of calls
      # with the same object.
      my $rep = $opts->{fmt_object}->($state, $obj);
      if (defined($rep) && refaddr($rep)) {
        $msg .= _fmt_list($rep);  # Data::Dumper::Interp
      } else {
        $msg .= $rep;
      }
      $prev_obj = $obj;
      weaken($prev_obj);
    }
    $msg .= ".";
  } else {
    $prev_obj = undef;
  }

  $msg .= $subname;
  $msg .= " "._fmt_list($inputs) if @$inputs;
  oops "terminal newline in last input item" if substr($msg,-1) eq "\n";
  if (defined $retvals) {
    $msg .= "()" if @$inputs == 0;
    $msg .= " ==> ";
    $msg .= _fmt_list($retvals);
    oops "terminal newline in last retvals item" if substr($msg,-1) eq "\n";
  }
  $msg."\n"
}
sub fmt_call {
  my $opts = &_getoptions;
  &_fmt_call($opts, @_);
}

sub log_call {
  my $opts = &_getoptions;
  my $fh = $opts->{logdest};
  print $fh &_fmt_call($opts, @_);
}

sub fmt_methcall($;@) {
  my $opts = &_getoptions;
  my $obj = shift // croak "Missing 'self' argument\n";
  $opts->{self} = $obj;
  &_fmt_call($opts, @_);
}

sub log_methcall {
  my $opts = &_getoptions;
  my $fh = $opts->{logdest};
  print $fh &fmt_methcall($opts, @_);
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Edit::Log - log method/function calls, args, and return values

=head1 SYNOPSIS

  use Spreadsheet::Edit::Log qw/:DEFAULT btw btwN oops/;

  sub public_method {
    my $self = shift;
    $self->_internal_method(@_);
  }
  sub _internal_method {
    my $self = shift;

    # Debug printing; shows location of call
    btw "By the way, the zort is $self->{zort}" if $self->{debug};
    btwN 2, "message";  # With location of caller's caller's caller
    btwbt "message";    # With 1-line mini traceback
    print colorize("Red Alert!\n", ERROR_COLOR);

    # Wrapper for Carp::Confess
    oops "zort not set!" unless defined $self->{zort};

    my @result = (42, $_[0]*1000);

    log_call \@_, [\"Here you go:", @result] if $self->{verbose};

    @result;
  }
  ...
  $obj->public_method(100);
  #  file::lineno public_method 100 ==> Here you go:42,100000

=head1 DESCRIPTION

(This is generic, no longer specific to Spreadsheet::Edit.  Someday it might
be published as a stand-alone distribution rather than packaged with
Spreadsheet-Edit.)

Here are possibly-overkill convenience functions for "verbose logging" and/or debug
tracing of subroutine calls.

The resulting message string includes the location of the
user's call, the name of the public function or method called,
and a representation of the inputs and outputs.

The "public" function/method name shown is not necessarily the immediate caller of the logging function.

=head2 log_call {OPTIONS}, [INPUTS], [RESULTS]

Prints the result of calling C<fmt_call> with the same arguments.

The message is written to STDERR unless
a different destination is specified as described in OPTIONS or Default OPTIONS.

=head2 $msgstring = fmt_call {OPTIONS}, [INPUTS], [RESULTS]

{OPTIONS} and [RESULTS] are optional, i.e. may be entirely omitted.

A message string is composed and returned.   The general form is:

  File:linenum funcname input,items,... ==> output,items,...\n
 or
  File:linenum Obj<address>->methname input,items,... ==> output,items,...\n

C<[INPUTS]> and C<[RESULTS]> are each a ref to an array of items (or
a single non-aref item), used to form comma-separated lists.

Each item is formatted similar to I<Data::Dumper>, i.e. strings are "quoted"
and complex structures serialized; printable Unicode characters are shown as
themselves (rather than hex escapes)

... with two exceptions:

=over

=item 1.

If an item is a reference to a string then the string is inserted
as-is (unquoted),
and unless the string is empty, adjacent commas are suppressed.
This allows pasting arbitrary text between values.

=item 2.

If an item is an object (blessed reference) then only it's type and
abbreviated address are shown, unless overridden via
the C<fmt_object> option described below.

=back

B<{OPTIONS}>

(See "Default OPTIONS" below to specify some of these statically)

=over

=item self =E<gt> objref

If your sub is a method, your can pass C<self =E<gt> $self> and
the the invocant will be displayed separately before the method name.
To reduce clutter, the invocant is
displayed for only the first of a series of consecutive calls with the
same C<self> value.

=item subname_override =E<gt> STRING

STRING is shown instead of the name of the public entry-point function
identified via calls to I<is_public_api()>
(which is still invoked to locate where the entry-point was called from).

=item fmt_object =E<gt> CODE

Format a reference to a blessed thing,
or the value of the C<self> option (if passed) whether blessed or not.

The sub is called with args ($state, $thing).  It should return
either C<$thing> or an alternative representation string.  By default,
the type/classname is shown and an abbreviated address (see C<addrvis>
in L<Data::Dumper::Interp>).

C<$state> is a ref to a hash where you can store anything you want; it persists
only during the current C<fmt_call> invocation.

=item is_public_api =E<gt> CODE

Recognize a public entry-point in the call stack.

The sub is called repeatedly with
arguments S<< C<($state, [package,file,line,subname,...])>. >>

The second argument contains results from C<caller(N)>.
Your sub should return True if the frame represents the call to be described
in the message.

The default callback looks for any sub named with an initial lower-case letter;
in other words, it assumes that internal subs start with an underscore
or capital letter (such as for constants).
The actual code
is S<<< C<sub{ $_[1][3] =~ /(?:::|^)[a-z][^:]*$/ }> >>>.

=item logdest =E<gt> filehandle or *FILEHANDLE

=back

=head2 $string = fmt_methcall {OPTIONS}, $self, [INPUTS], [RESULTS]

A short-hand for

  $string = fmt_call {OPTIONS, self => $self}, [INPUTS], [RESULTS]

=head2 log_methcall $self, [INPUTS], [RESULTS]

=head2 log_methcall {OPTIONS}, $self, [INPUTS], [RESULTS]

A short-hand for

  log_call {OPTIONS, self => $self}, [INPUTS], [RESULTS]

Usually {OPTIONS} can be omitted for a more succinct form.

=head2 $frame = nearest_call {OPTIONS};

Locate the call frame for the "public" interface most recently called.
This accesses the internal logic used by C<fmt_call>, and uses the
same C<is_public_api> callback.

The result is a reference to the items returned by C<caller(N)> which
represent the call to be traced.

{OPTIONS} may be omitted.

=head2 ($filename, $linenum, $subname) = abbrev_call_fn_ln_subname {OPTIONS};

Returns abbreviated information from C<nearest_call>, possibly ambiguous
but usually more friendly to humans:  C<$filename> is the I<basename> only
and C<$subname> omits the Package:: prefix.

=head2 Default OPTIONS

B<our %SpreadsheetEdit_Log_Options = (...);> in your package
will be used to override the built-in defaults
(but are overridden by C<{OPTIONS}> passed in individual calls
to functions which accept an OPTIONS hash).

The "logdest" option may also be set globally (affects all pacakges)
by calling

=head3 set_logdest($filehandle or *FILEHANDLE)

Z<>

=head1 DEBUG UTILITIES

(Not related to the log functions above, other than using I<logdest>).

NOTE: None of these are exported by default.

=head2 btw STRING,STRING,...

=head2 btwN LEVELSBACK,STRING,STRING,...

=head2 btwbt STRING,STRING,...

Print debug trace messages.  I<btw> stands for "by the way...".

C<btw> prints a message to STDERR (or "logdest" - see OPTIONS and "Default OPTIONS").
preceeded by "linenum:"
giving the line number I<of the call to btw>.
A newline is appended to the message unless the last STRING already
ends with a newline.

This is similar C<warn> when the message omits a final newline
but with a different presentation.

C<btwN> displays the line number of the call LEVELSBACK
in the call stack (0 is the same as C<btw>, 1 for your caller's location etc.)

C<btwbt> displays an inline mini traceback before the message, like this:

  PkgA 565 ⇐ PkgB 330 ⇐ 456 ⇐ 413 : message...

By default, only the line numbers of calling locations are shown if the call
was from package 'main' or Spreadsheet::Edit::Log was imported by only a single module.

The import tag B<:btw=PFX> imports customized
C<btw()>, C<btwN()> and C<btwbt()> functions which prefix
messages with an arbitrary prefix B<PFX>
which may
contain I<$lno> I<$path> I<$fname> I<$package> I<$pkg> or I<$pkg_space>
to interpolate respectively
the calling line number, file path, file basename,
package name, S<abbreviated package name (*:: removed).>
or abbrev. package name followed by a space, or nothing if the package is "main".

Import tag B<:nocolor> prevents colorizing.
By default C<btw> and C<oops> messages are colorized if the terminal allows.

=head2 oops STRING,STRING,...

Prepends "\n<your package name> oops:\n" to the message and then
chains to Carp::confess for backtrace and death.

=head2 handlish = get_effective_logdest()

Returns the handle or glob specified in
C<$SpreadsheetEdit_Log_Options{logdest}> in your package, or if not set
then the value from calling C<set_logdest()>, or the built-in default.

=head1 COLORIZE TERMINAL TEXT

=head2 $newstring = colorize($string, SUCCESS_COLOR | ERROR_COLOR | WARN_COLOR | BOLD_COLOR);

Insert escape sequences to make the text display in an appropriate
color, provided the process has a tty and $TERM is a terminal type
which supports ansi color escapes.

=head1 SEE ALSO

L<Data::Dumper::Interp>

=head1 AUTHOR

Jim Avera (jim.avera gmail)

=head1 LICENSE

Public Domain or CC0

=for Pod::Coverage oops

=cut


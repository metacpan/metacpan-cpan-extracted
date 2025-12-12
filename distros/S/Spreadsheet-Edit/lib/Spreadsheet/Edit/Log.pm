# License: http://creativecommons.org/publicdomain/zero/1.0/
# (CC0 or Public Domain).  To the extent possible under law, the author,
# Jim Avera (email jim.avera at gmail dot com) has waived all copyright and
# related or neighboring rights to this document.  Attribution is requested
# but not required.
use strict; use warnings FATAL => 'all'; use utf8;
use feature qw(say state lexical_subs current_sub);
no warnings qw(experimental::lexical_subs);

package Spreadsheet::Edit::Log;

# Allow "use <thismodule> VERSION ..." in development sandbox to not bomb
{ no strict 'refs'; ${__PACKAGE__."::VER"."SION"} = 1999.999; }
our $VERSION = '1001.001'; # VERSION from Dist::Zilla::Plugin::OurPkgVersion
our $DATE = '2025-12-12'; # DATE from Dist::Zilla::Plugin::OurDate

use Carp;
use Scalar::Util qw/reftype refaddr blessed weaken openhandle/;
use List::Util qw/first any all/;
use File::Basename qw/dirname basename/;
use Data::Dumper::Interp ':DEFAULT', qw/avisl addrvis u/;

use Exporter 5.57 ();
our @EXPORT = qw/fmt_call log_call fmt_methcall log_methcall
                 nearest_call abbrev_call_fn_ln_subname/;

our @EXPORT_OK = qw/btw btwN btwbt oops set_logdest
                    colorize ERROR_COLOR WARN_COLOR BOLD_COLOR SUCCESS_COLOR/;

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

use constant ERROR_COLOR => "error";
use constant WARN_COLOR  => "warn";
use constant BOLD_COLOR  => "norm";
use constant SUCCESS_COLOR  => "succ";

# Insert escapes to colorize text, provided the terminal supports ansi escapes
our $colorcodes;
sub colorize($$) {
  my ($str, $colortype) = @_;
  return $str
    if $ENV{NO_COLOR};  # check every time
  my sub _getcode($$) {
    my ($name, $tput_args) = @_;
    unless (exists $colorcodes->{$name}) {
      $colorcodes->{$name} = `tput $tput_args 2>/dev/null`;
      $colorcodes->{$name} = undef if $? != 0;
    }
    return $colorcodes->{$name} // die("no color ($name)");
  }
  my ($color_start, $color_end);
  eval {
    # The basic colors 0-7 => black,red,green,yellow,blue,magenta,cyan,white
    # ("white" is often really light grey)
    $color_start =
      $colortype eq BOLD_COLOR    ? _getcode("bold", "bold") :
      $colortype eq WARN_COLOR    ? _getcode("boldyellow", "setaf 3 bold") :
      $colortype eq ERROR_COLOR   ? _getcode("boldred", "setaf 1 bold") :
      $colortype eq SUCCESS_COLOR ? _getcode("boldgreen", "setaf 2 bold") :
      croak "unknown message type '$colortype'"
      ;
    $color_end = _getcode("sgr0", "sgr0");
  };
  if ($@) {
    return $str if $@ =~ /no color/; # disabled or TERM does not support it.
    die $@;
  }
  my @chunks = map{ $_ eq "" ? "" : $color_start.$_.$color_end }
               split /\R/, $str, -1;
  return join "\n", @chunks;
}

sub oops(@) {
  my @args = @_;
  foreach (@args) { $_ = colorize($_, ERROR_COLOR); }
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

our (%btw_importing_pkgs, $multiple_btw_importers);
sub import {
  my $class = shift;
  my $pkg = caller;
  my @remaining_args;
  foreach (@_) {
    if (/^:btw\w*=/ or /^:(no)?color/) {
      croak "Import tag '${_}' is no longer supported.\n"; # as of v1001.001
    }
    if (/btw/) {
      $multiple_btw_importers = 1
        if keys(%btw_importing_pkgs) && !$btw_importing_pkgs{$pkg};
      $btw_importing_pkgs{$pkg}++;
      if (/^:btw$/) {
        push @remaining_args, qw/btw btwN btwbt/;
        next;
      }
    }
    push @remaining_args, $_;
  }

  @_ = ($class, @remaining_args);
  goto &Exporter::import
}#import

sub btwN($@) {
  my ($N, @strings) = @_;
#warn dvis '##btwN $N @strings\n';
  local $@;
  local $_ = join("", @strings);
  s/\n\z//s;
  my (@frames, $pkg_obvious);
  #my $sep = ">";
  #my $sep = " → ";
  #my $sep = " ⇢ ";
  #my $sep = " » "; # « exists in both Unicode and latin1
  my $sep = " ⇒ ";
  my @levels;
  if (ref($N) eq "") {
    @levels = ($N);
  }
  elsif (ref($N) eq 'SCALAR' && defined($$N) && $$N >= 1) {
    @levels = 0..($$N-1); # mini-traceback for N levels
  }
  elsif (ref($N) eq 'ARRAY' && @$N > 0 && all{defined} @$N) {
    @levels = sort { $a <=> $b } @$N;  # arbitrary list of levels
    $sep = "," unless $#levels == ($levels[-1] - $levels[0]);
  }
  else {
    carp "Invalid N arg to btwN: ${\vis($N)}\n";
    @levels = 0..99; # mini-traceback
  }
  if (!caller($levels[0])) {
    carp "INVALID stack frame level ",avisl(@levels)," (too far back) ";
    @levels = 0..99; # mini-traceback instead
  }

  { my (%pkgtail2full, %fname2full, $prev_package);
    my ($uniq_pkgtails, $uniq_fnames, $all_same_package) = (1, 1, 1);
    foreach my $n (@levels) {
      my @c = caller($n);
      my ($package, $path) = @c[0,1];
      last if !defined $package;
      $all_same_package = 0 if $package ne ($prev_package //= $package);
      my $pkg = ($package =~ s/.*:://r); # abbreviated package
      $uniq_pkgtails = 0 if ($pkgtail2full{$pkg} //= $package) ne $package;
      my $fname = ($path =~ s/.*[\\\/]//r);
      $uniq_fnames = 0 if ($fname2full{$fname} //= $path) ne $path;
      push @frames, {n=>$n, caller => \@c, pkg => $pkg, fname => $fname};
    }
    #if ($all_same_package && $prev_package eq "main") {
    #  foreach (@frames) { $_->{pkg} = "" };
    #}
    if (! $uniq_pkgtails) {
      foreach (@frames) { $_->{pkg} = $_->{caller}->[0] }; # pkg = package
    }
    if (! $uniq_fnames) {
      foreach (@frames) { $_->{fname} = $_->{caller}->[1]; } # fname = path
    }
    $pkg_obvious = ($all_same_package && !$multiple_btw_importers);
  }

  ##FIXME: Use only ASCII characters if terminal is not UTF enabled? Cf DDI

  my $pfx = "";
  my ($prev_pkg, $prev_n);
  for (reverse @frames) {  # show outer frame at the left
    my ($n, $caller, $pkg, $fname) = @$_{qw/n caller pkg fname/};
    my $lno = $caller->[2];
    my $path = $caller->[1];
    my $s;
    if ($pkg_obvious || (defined($prev_pkg) && $pkg eq $prev_pkg)) {
      $s = $lno;
    } else {
      my $package = $caller->[0];
      no strict 'refs';
      if (my $h = \%{"${package}::SpreadsheetEdit_Log_Options"}) {
        $pkg = $h->{subst_pkg} if $h->{subst_pkg};
      }
      $s = "${pkg}:$lno";
    }
    if ($fname ne "${pkg}.pm" && $path ne $0) {
#warn dvis '###FNCRAM $pkg $fname\n';
      $s = "[${path}]".$s;
    }
    $pfx .= $sep if $pfx;
    if (defined($prev_n)) {
      $pfx .= "«" x (($prev_n-$n)-1); # n.b. reverse order (n high to low)
    }
    $pfx .= $s;
    $prev_pkg = $pkg;
    $prev_n = $n;
  }
  $pfx .= "> ";

  $_ = colorize($_, WARN_COLOR);
  my $msg = "${pfx}${_}\n";
  my $fh = _getoptions()->{logdest};
  print $fh $msg;
}#btwN

sub btw(@) { @_ = (0, @_); goto &btwN; }
sub btwbt(@) { @_ = (\99, @_); goto &btwN; }

# Return ref to hash of effective options (READ-ONLY).
# If the first argument is a hashref it is shifted off and
# used as options which override defaults.
sub _getoptions {
  my $pkg;
  my $N=1; while (($pkg=caller($N)||oops) eq __PACKAGE__) { ++$N }
  no strict 'refs';
  no warnings 'once';
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
become a stand-alone distribution.)

Here are possibly-overkill convenience functions for "verbose logging"
and/or debug tracing of subroutine calls.

Log messages show the name of the I<public> entrypoint called
by the user, not necessarily the immediate caller of the logging
function.

The call stack is searched for the nearest call to a 'public' entrypoint,
which by default is a sub named starting with a lower-case letter.
The I<is_public_api> callback can be used to change this convention.

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
as-is without quote,
and adjacent commas are suppressed (unless the string is empty).
This allows pasting arbitrary text between values.

=item 2.

If an item is an object (blessed reference) then only it's type and
abbreviated address are shown, unless overridden via
the C<fmt_object> option described below.

=back

=head2 $string = fmt_methcall {OPTIONS}, $self, [INPUTS], [RESULTS]

A short-hand for

  $string = fmt_call {OPTIONS, self => $self}, [INPUTS], [RESULTS]

=head2 log_methcall {OPTIONS}, $self, [INPUTS], [RESULTS]

A short-hand for

  log_call {OPTIONS, self => $self}, [INPUTS], [RESULTS]

Note that {OPTIONS} can usualy be omitted for a more succinct form.

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

=head2 {OPTIONS}

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

=back

Although not usually helpful, any of the "Default OPTIONS" listed next
may also be included an {OPTIONS} hash passed to a specific call.

=head2 Default OPTIONS

B<our %SpreadsheetEdit_Log_Options = (...);> in your package
will be used to override the built-in defaults
(but are overridden by C<{OPTIONS}> passed in individual calls
to functions which accept an OPTIONS hash).

=over

=item is_public_api =E<gt> CODE

A callback to recognize a public entry-point.

The sub is called repeatedly with
arguments S<< C<($state, [package,file,line,subname,...])>. >>

The second argument contains results from C<caller(N)>.
Your sub should return true if the frame represents the call to be described
in the message.

The default callback looks for any sub named with an initial lower-case letter;
in other words, it assumes internal subs start with an underscore
or capital letter (such as for constants).
The actual code
is S<<< C<sub{ $_[1][3] =~ /(?:::|^)[a-z][^:]*$/ }> >>>.

=item fmt_object =E<gt> CODE

Format a reference to a blessed thing,
or the value of the C<self> option (if passed) whether blessed or not.

The sub is called with args ($state, $thing).  It should return
either C<$thing> or an alternative representation string.  By default,
the type/classname is shown and an abbreviated address (see C<addrvis>
in L<Data::Dumper::Interp>).

C<$state> is a ref to a hash where you can store anything you want; it persists
only during the current C<fmt_call> invocation.

=item logdest =E<gt> filehandle or *FILEHANDLE

=back

The "logdest" option may also be set globally (affects all pacakges)
by calling

=head3 B<set_logdest($filehandle or *FILEHANDLE)>

Z<>


=head1 DEBUG UTILITIES

(Not related to the log functions above, other than using I<logdest>).

NOTE: None of these are exported by default.

=head2 btw STRING,STRING,...

=head2 btwN LEVELSBACK,STRING,STRING,...

=head2 btwbt STRING,STRING,...

Print debug trace messages.  I<btw> stands for "by the way...".

B<btw> prints a message to STDERR
(or "logdest" - see "Default OPTIONS").
preceeded by "package:linenum> "
giving the location I<of the call to btw>.
A newline is appended to the message unless the last STRING already
ends with a newline.  The message is colorized unless $ENV{NO_COLOR} is true.

In effect, C<btw> does what Perl's C<warn> does when the message omits a final newline,
but with a different presentation.

B<btwN> displays the location of the call LEVELSBACK
in the call stack (0 is the same as C<btw>, 1 for your caller's location etc.)

B<btwbt> displays an inline mini traceback before the message, like this:

  main:42 ⇒ PkgA:565 ⇒ PkgB:330 ⇒ 456 ⇒ 413 : message...

The package name is omitted if it is obvious.

=head2 :btw import tag

imports all three functions (btw, btwN and btwbt).

=head2 oops STRING,STRING,...

Prepends "\n<your package name> oops:\n" to the message and then
chains to Carp::confess for backtrace and death.

=head2 handlish = get_effective_logdest()

Returns the handle or glob specified in
C<$SpreadsheetEdit_Log_Options{logdest}> in your package, or if not set
then the value from calling C<set_logdest()>, or the built-in default.

=head1 COLORIZE TERMINAL TEXT

=head2 $newstring = colorize($string, SUCCESS_COLOR | WARN_COLOR | ERROR_COLOR | BOLD_COLOR);

Insert escape sequences to make the text display in an appropriate
color (and turn coloring off at the end of the string),
provided the process has a tty and $TERM is a terminal type
which supports ansi color escapes.

The second argument indicates
respectively green, yellow, red or a bold version of the
default foreground color.

=head1 ENVIRONMENT VARIABLES

=over

=item NO_COLOR (true to make C<btw> functions and C<colorize> not colorize).

=back


=head1 INCOMPATIBLE CHANGES with v1001.001

=over

=item Import tag ':btw=evalstring' no longer supported

This used to allow customizing the prefix part of
messages from C<btw>, but the code grew too complicated with
only imagined real benefits.

=item Import tags ':color' and ':nocolor' no longer supported.

Please use C<$ENV{NO_COLOR}> instead.  See L<https://no-color.org/>

=back

=head1 SEE ALSO

L<Data::Dumper::Interp>

=head1 AUTHOR

Jim Avera (jim.avera gmail)

=head1 LICENSE

Public Domain or CC0

=for Pod::Coverage oops

=cut


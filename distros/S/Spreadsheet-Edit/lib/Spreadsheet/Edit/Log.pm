# License: http://creativecommons.org/publicdomain/zero/1.0/
# (CC0 or Public Domain).  To the extent possible under law, the author,
# Jim Avera (email jim.avera at gmail dot com) has waived all copyright and
# related or neighboring rights to this document.  Attribution is requested
# but not required.
use strict; use warnings FATAL => 'all'; use utf8;
use feature qw(say state lexical_subs current_sub);
no warnings qw(experimental::lexical_subs);

package Spreadsheet::Edit::Log;

our $VERSION = '3.015'; # VERSION from Dist::Zilla::Plugin::OurPkgVersion
our $DATE = '2023-05-31'; # DATE from Dist::Zilla::Plugin::OurDate

use Exporter 'import';
our @EXPORT = qw/fmt_call log_call fmt_methcall log_methcall
                 nearest_call abbrev_call_fn_ln_subname/;

use Scalar::Util qw/reftype refaddr blessed weaken/;
use List::Util qw/first any all/;
use File::Basename qw/dirname basename/;
use Carp;
sub oops(@) { @_=("\n".__PACKAGE__." oops:\n",@_,"\n"); goto &Carp::confess }
use Data::Dumper::Interp qw/dvis vis visq avis hvis visnew addrvis u/;

my %backup_defaults = (
  logdest         => \*STDERR, 
  is_public_api   => sub{ $_[1][3] =~ /(?:::|^)[a-z][^:]*$/ },

  #fmt_object      => sub{ addrvis($_[1]) },
  # Just show the address, sans class::name.  Note addrvis now wraps it in <...>
  fmt_object      => sub{ addrvis(refaddr($_[1])) },
);

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
use constant _CALLER_OVERRIDE_CHECK_OK =>
     (defined(&Carp::CALLER_OVERRIDE_CHECK_OK) 
      && &Carp::CALLER_OVERRIDE_CHECK_OK);

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
  my @results = @{ &_nearest_call(@_) }[1,2,3]; # (fn, lno, subname)
  $results[0] = basename $results[0]; # filename
  $results[2] =~ s/.*:://;            # subname
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
        $msg .= _fmt_list($rep);  # Data::Dumper
      } else {
        $msg .= $rep;
      }
      $prev_obj = $obj;
      weaken($prev_obj);
    }
    $msg .= ".";
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
  print $fh &_fmt_methcall($opts, @_);
}

1;

__END__
=pod

=head1 NAME

Spreadsheet::Edit::Log - log method/function call, args, and return values

=head1 SYNOPSIS

  use Spreadsheet::Edit::Log;

  sub public_method {
    my $self = shift;
    $self->_internal_method(@_);
  }
  sub _internal_method {
    my $self = shift;
    my @result = (42, $_[0]*1000);
    log_call \@_, [\"Here you go:", @result] if $self->{verbose};
    @result;
  }
  ...
  $obj->public_method(100);  
  #  file::lineno public_method 100 ==> Here you go:42,100000

=head1 DESCRIPTION

(This is generic, no longer specific to Spreadsheet::Edit.  Someday it might
be published as a stand-alone distribution rather than in Spreadsheet-Edit.)

This provides perhaps-overkill convenience for "verbose logging" and/or debug
tracing of subroutein calls.

The resulting message string includes the location of the
call to your code, the name of the public function or method called, 
and a representation of the inputs and outputs.

The "public" function/method name shown is not necessarily the immediate caller of the logging function.

=head2 log_call {OPTIONS}, [INPUTS], [RESULTS]

Prints the result of calling C<fmt_call> with the same arguments.

The message is written to STDERR unless
C<< logdest => FILEHANDLE >> is included in I<OPTIONS>.

=head2 $msgstring = fmt_call {OPTIONS}, [INPUTS], [RESULTS]

{OPTIONS} and [RESULTS] are optional, i.e. may be omitted.

A message string is composed and returned.   The general form is:

  File:linenum funcname input,items,... ==> output,items,...\n
 or
  File:linenum Obj<address>->methname input,items,... ==> output,items,...\n

C<[INPUTS]> and C<[RESULTS]> are each a ref to an array of items or
a single non-aref item, which are used to form a comma-separated list.

Each item is formatted like with I<Data::Dumper>, i.e. strings are "quoted"
and complex structures serialized; printable Unicode characters are shown as
themselves (rather than hex escapes)

... with one exception:

=over

If an item is a reference to a a string then the string is inserted as-is (unquoted),
and unless the string is empty, adjacent commas are suppressed.

=back

This allows concatenating arbitrary text to regular values formatted with Data::Dumper.


B<{OPTIONS}>

(See "Default OPTIONS" below to specify statically)

=over

=item self =E<gt> objref

If your sub is a method, your can pass C<self =E<gt> $self> and the called-upon
object will be displayed separately before the method name.  
To reduce clutter, the object is 
displayed for only the first call in a series of consecutive calls with the 
same C<self> value.

=item fmt_object =E<gt> CODE

Format a reference to a blessed thing, or the value of the C<self> option, if
passed, whether blessed or not.

The sub is called with args C<($state, $thing)>.  It should return
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

The default callback is S<<< C<sub{ $_[1][3] =~ /(?:::|^)[a-z][^:]*$/ }> >>>,
which looks for any sub named with an initial [a-z].

=back

=head2 $string = fmt_methcall {OPTIONS}, $self, [INPUTS], [RESULTS]

=head2 log_methcall {OPTIONS}, $self, [INPUTS], [RESULTS]

These are short-hands for 

   $string = fmt_call {OPTIONS, self => $self}, [INPUTS], [RESULTS]
   log_call {OPTIONS, self => $self}, [INPUTS], [RESULTS]

Usually {OPTIONS} can be omitted, so the short-hand form reduces to
S<< C<log_methcall $self, [INPUTS], [RESULTS]> >>.

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

You can provide OPTIONS to use by default in 

  our %SpreadsheetEdit_Log_Options = (...);

in your package. 

=head1 AUTHOR / LICENSE

Jim Avera (jim.avera gmail) / Public Domain or CC0

=for Pod::Coverage oops

=cut


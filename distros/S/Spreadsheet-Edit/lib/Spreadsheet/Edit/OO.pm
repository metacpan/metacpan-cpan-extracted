# License: http://creativecommons.org/publicdomain/zero/1.0/
# (CC0 or Public Domain).  To the extent possible under law, the author
# Jim Avera (email jim.avera at gmail dot com) has waived all copyright and
# related or neighboring rights to this document.  Attribution is requested
# but not required.
use strict; use warnings FATAL => 'all'; use feature qw(say state);
use utf8;

# TODO FIXME: Integrate with Spreadsheet::Read and provide a formatting API
#
# TODO: Need api to *read* options without changing them

# TODO: Allow & support undef cell values (see Text::CSV_XS), used to 
#       represent "NULL" when interfacing with database systems. 
#       OTOH, this conflicts with failed optional alias keys

# TODO: Add some way to exit an apply() early, e.g. return value?
#       or maybe provide an abort_apply(resultval) function
#       which throws an exception we can catch in apply?
#

# TODO: Use Tie::File to avoid storing entire sheet in memory
# (requires seekable, so must depend on OpenAsCsv
# copying "-" to a temp file if it is not a plain file).

package Spreadsheet::Edit::OO;
$Spreadsheet::Edit::OO::VERSION = '2.102';

=pod

=for nothing Spreadsheet::Edit.pm documents functions with all the same
=for nothing names as methods in here (::OO.pm).  Well, there emight be
=for nothing a few extra undocumented methods here but not worth worrying about

=for Pod::Coverage *EVERYTHING*

=cut

# These global vars (imported into Spreadsheet::Edit where users may set them)
# Provide last-resort defaults for the corresponding (lowercase) options.
our ($Debug, $Verbose, $Silent); 

# Exporting only for Spreadsheet::Edit.pm
use Exporter 'import';
our @EXPORT_OK = qw(cx2let let2cx oops %pkg2currsheet $Debug $Verbose $Silent); 

use Data::Dumper::Interp;

use Carp;
our @CARP_NOT = qw(Spreadsheet::Edit 
                   Tie::Indirect::Array Tie::Indirect::Hash 
                   Tie::Indirect::Scalar
                  );

use Scalar::Util qw(looks_like_number openhandle reftype blessed);
use List::Util qw(min max sum0 first any all pairs pairgrep);
use File::Temp qw(tempfile tempdir);
use File::Basename qw(basename dirname fileparse);
use Symbol qw(gensym);
#use POSIX qw(INT_MAX);

use Text::CSV;

# OUR CUSTOM STUFF: stop using it?
require Tie::Indirect;

#use Text::CSV::Spreadsheet qw(
#   OpenAsCsv @sane_CSV_read_options @sane_CSV_write_options
#   convert_spreadsheet);
use Spreadsheet::Edit::IO qw(
   OpenAsCsv @sane_CSV_read_options @sane_CSV_write_options
   convert_spreadsheet);

#sub __tracecall() {
#  my $s = "";
#  for (my $lvl=1 ; ; ++$lvl) {
#    my ($pkg, $fname, $lno, $called_sub) = caller($lvl);
#    my $calling_subr = (caller($lvl+1))[3];
#    last unless defined $calling_subr;
##    if ($pkg eq "Spreadsheet::Edit") { # omit wrappers
##      $s .= ($s =~ /[^\<]$/s ? " <" : "<");
##      next;
##    }
#    $s .= " < " if $s;
#    $calling_subr =~ s/.*:://;
#    $s .= "${lno}:$calling_subr";
#    last if $pkg eq "main";
#  }
#  $s
#}
sub __tracecall() {
  my $s = "";
  for (my $lvl=1 ; ; ++$lvl) {
    my ($pkg, $fname, $lno, $called_subr) = caller($lvl);
    last if !defined($pkg);
    $fname //= "";
    $lno //= "";
    my $calling_subr = (caller($lvl+1))[3] // "[no sub]";
    $fname =~ s#.*/##;
    $calling_subr =~ s/.*:://;
    $called_subr =~ s/.*:://;
    #$s .= "\n   ".($lvl-1).": ${fname}:${lno} $calling_subr called $called_subr";
    $s .= "\n   ".($lvl-1).": $called_subr called from $calling_subr at ${fname}:${lno}";
  }
  $s .= "\n";
  $s
}

sub oops(@) { unshift @_, "oops - "; goto &Carp::confess; }

use constant DEFAULT_WRITE_ENCODING => 'UTF-8';
#use constant DEFAULT_READ_ENCODINGS => 'UTF-8,windows-1252';

# This global is used by Spreadsheet::Edit::logmsg to infer the current sheet
# if an apply is active, even if logmsg is called indirectly via another pkg
our $_inner_apply_sheet;  # see &_apply_to_rows

# The "current sheet", to which tied globals refer in any given package.
our %pkg2currsheet;

sub __looks_like_aref($) { eval{ 1+scalar(@{$_[0]}) } } #actual or overloaded

sub to_array(@)  { @_ != 1 ? @_ :
                   ref($_[0]) eq "ARRAY" ? @{$_[0]} :
                   ref($_[0]) eq "HASH"  ? @{ %{$_[0]} } :  # (key, value, ...)
                   ($_[0])
                 }
sub to_aref(@)   { [ to_array(@_) ] }
sub to_wanted(@) { goto &to_array if wantarray; goto &to_aref }

sub to_hash(@)   {
  @_==1 && ref($_[0]) eq "HASH" ? $_[0] :
  (@_ % 2)!=0 ? croak("odd arg count, expecting key => value pairs") :
  { to_array(@_) }
}

sub __fmt_colspec_cx($$) {  # "cx NN" or "COLSPEC [cx NN]" or "<colspec> (NOT DEFINED)" if undef cx
  my ($colspec, $cx) = @_;
  if (ref($colspec) eq "Regexp") {
    state $delimsets = [
      [qw(/ /)], [qw({ })], [qw([ ])], [qw<( )>], [qw(< >)], [qw(« »)] ];
    for (@$delimsets) {
      my ($left, $right) = @$_;
      if (index($colspec,$left)<0 && index($colspec,$right)<0) {
        $colspec = "qr${left}${colspec}${right}";
        last;
      }
    }
  } else {
    $colspec = visq($colspec);
  }
  return "$colspec (NOT DEFINED)" 
    if ! defined $cx;
  $colspec eq "$cx" ? "cx $cx" : "$colspec [cx $cx]"
}
sub __fmt_cx($) { my ($cx) = @_; return "(undefined)" unless defined $cx; "cx $cx=".cx2let($cx) }

# Format word,word,... without parenthesis.  Non-barewords will be quoted.
sub __fmt_uqlist(@) { join(",",map{quotekey} @_) }

# Format "(unquoted-item, unquoted-item ...)"
sub __fmt_uqarray(@) { "(" . &__fmt_uqlist . ")" }

# Format a list as key => value pairs without parenthesis
sub __fmt_pairs(@) {
  my $result = "";
  while (@_) {
    confess "Odd arg count, expecting key => value pairs" if @_==1;
    $result .= ", " if $result;
    my $key = shift @_;
    my $val = shift @_;
    $result .= quotekey($key)." => ".vis($val);
  }
  $result
}

# Concatenate strings separated by spaces, folding as necessary
# (strings are never broken; internal newlines go unnoticed).
# All lines (including the first) are indented the specified number of
# spaces.  Explicit line-breaks may be included as "\n".
# A final newline is *not* included unless the last item is "\n".
sub __fill($;$$) {
  my ($items, $indent, $foldwidth) = @_;
  $foldwidth //= 72;
  $indent    //= 4;
  my $buf = "";
  my $llen = 0;
  foreach (@$items) {
    if ($_ eq "\n" or
        ($llen > $indent && ($llen + length($_)) > $foldwidth)) {
      $buf .= "\n";
      $llen = 0;
      next if $_ eq "\n";
    }
    if ($llen == 0) {
      $buf .= (" " x $indent);
      $llen = $indent;
    } else {
      if (substr($buf,-1) =~ /\S/) {
        $buf .= " ";
        ++$llen;
      }
    }
    $buf .= $_;
    $llen += length();
  }
  $buf;
}

# Is a title omitted from colx?
sub __unindexed_title($$) {
  my ($title, $num_cols) = @_;
  $title eq ""
  || $title eq '^'
  || $title eq '$' 
  || ( ($title =~ /^[1-9]\d*$/ || $title eq "0") 
       && $title <= $num_cols )
}
sub _get_indexed_titles {
  my $self = shift;
  my ($rows, $title_rx, $num_cols) = @$$self{qw{rows title_rx num_cols}};
  my $title_row = $rows->[$title_rx // oops];
  return { 
    map{ my $t = $title_row->[$_];
         __unindexed_title($t,$num_cols) ? () : ($t => $_) } 0 .. $num_cols-1 };
}
sub _unindexed_title { #method for test programs
  my $self = shift;
  __unindexed_title(shift(), $$self->{num_cols});
}

# Format defined elements of %colx "intelligently".  cx values are shown only 
# for keys which might be mistaken for absolute column references.  
# Undef values (from alias {optional => 1}) are omitted since they are not currently valid.
# With final newline.
sub _fmt_colx(;$$) {
  my $self = shift;
  my ($indent, $foldwidth) = @_;
  my ($colx, $num_cols) = @$$self{qw{colx num_cols}};
  # copy %$colx omitting keys with undef cx
  my %hash = map{ defined($colx->{$_}) ? ($_ => $colx->{$_}) : () } keys %$colx;
  my sub sortbycx(@) { sort { ($colx->{$a}//-1) <=> ($colx->{$b}//-1) } @_ }
  my sub subset($) { # format items, deleting from %hash
    my $specs = shift;
    my (@items, $curr, $curr_desc);
    my $curr_cx = -1;
    my sub flush() {
      return unless $curr_cx >= 0;
      push @items, $curr.$curr_desc;
      $curr = $curr_desc = undef; ##DEBUGGING
      $curr_cx = -1;
    }
    my sub additem($$) {
      (local $_, my $cx) = @_;
      flush() if $curr_cx != $cx;
      if ($curr_cx >= 0) {
        $curr .= ",".quotekey($_);
      } else {
        $curr_cx = $cx;
        $curr = quotekey($_);
        my $misfit = (/^[A-Z]{1,2}$/ && $colx->{$_} != let2cx($_))
                  || (/^\d+$/        && $colx->{$_} != $_)
                  || (/^\D../) # show titles with cx too
                  ;
        $curr_desc = $misfit ? "(cx ".vis($hash{$_}).")" : "";
      }
    }
    foreach (@$specs) {
      if (ref $_) { 
        push @items, $$_;
      } else {
        additem($_, $hash{$_}//oops);
        delete $hash{$_} // oops;
      }
    }
    flush();
    push @items, "\n" if @items; # wrap before next subset, or at end
    @items
  }
  my @ABCs    = subset [ map{ my $A = cx2let($_); 
                              u($hash{$A}) eq $_ ? $A : \"  " 
                            } 0..$num_cols-1 ];
  __fill [
           @ABCs,
           subset [sortbycx grep{ /^(=.*\D)\w+$/ } keys %hash], # normal titles
           subset [sortbycx grep{ /^\d+$/ } keys %hash],        # numeric titles
           subset [sortbycx keys %hash],                        # oddities
         ], $indent, $foldwidth
}

# 
# "Your caller's caller"; called from arg-checking functions.
# This is the caller(x) result describing the call to your caller
#   (+ specified additional levels)
#  caller(0) describes the call to us, i.e. __callingcaller
#  caller(1) describes the call to our caller, e.g. an arg-checker func
#  caller(2) describes the call to our caller's caller, e.g. a public method
# File and sub names are "edited for simplicity"
# An optional 2nd argument indicates that the calling package must be user code
sub __callingcaller(;$$) {
  my $exlevels = $_[0] // 0;
  my $levels = 2 + $exlevels;
  my @c = caller($levels); 
  oops dvis '$levels is OFF END\n', __tracecall() unless @c;
  if ($_[1]) {
    if ($c[0] =~ /Spreadsheet::Edit($|::OO$)/) {
      oops dvis 'BUG: caller_level too small? [$exlevels $levels @c[0..3]]\n   ',
           __tracecall();
    }
    if ( (caller($levels-1))[0] !~ /Spreadsheet::Edit($|::OO$)/ ) {
      oops dvis 'BUG: caller_level too LARGE? [$exlevels $levels @c[0..3]]\n   ',
           __tracecall();
    }
  }
  $c[1] = basename($c[1]); # filename
  $c[3] =~ s/.*:://;       # subroutine sans package
  @c
}
# "The name of the method calling you";
# Like __callingcaller but returns just the sub/method name 
sub __callingsub(;$) { ( __callingcaller(1 + (shift()//0)) )[3] }

# "Your caller" + {caller_level} additional levels + additional specified.
# {caller_level} must be set so that we reach a user sub
sub _caller { #METHOD
  my ($self, $extra) = @_;
  $extra //= 0;
  my $caller_level = $$self->{caller_level};
  # We are in the "arg-checker func" position for _callingcaller()
  my @c = __callingcaller($caller_level + $extra, 1)
}
sub _caller_pkg { ($_[0]->_caller(1))[0] }

sub __self_opthash { # shift off $self and optional/default-empty {OPTIONS} hash
  my $self = shift;
  my $opthash = ref($_[0]) eq 'HASH' ? shift() : {};
  ($self, $opthash)
}
sub __self_noopthash { # shift off $self; verify no {OPTIONS} hash
  my $self = shift;
  croak __callingsub, " does not accept an {OPTIONS} hash\n"
    if ref($_[0]) eq 'HASH';
  $self
}
sub __selfonly {
  oops "Bug: __selfonly must be called with '&' to preserve args" if @_ == 0;
  confess __callingsub, " expects no arguments!\n" if @_ != 1;
  shift()
}

sub __self_opthash_Nargs($@) {  # (num_expected_args, @_)
  my $Nargs = shift;
  my ($self, $opthash) = &__self_opthash;
  #croak
  croak __callingsub, " expects $Nargs arguments, not ",scalar(@_),"\n"
    if $Nargs != @_;
  ($self, $opthash, @_)
}
sub __self_opthash_0args { unshift @_,0; goto &__self_opthash_Nargs }
sub __self_opthash_1arg  { unshift @_,1; goto &__self_opthash_Nargs }
sub __self_opthash_2args { unshift @_,2; goto &__self_opthash_Nargs }
sub __self_opthash_3args { unshift @_,3; goto &__self_opthash_Nargs }

# N.B. this is exposed to the public via a wriapper in Spreadsheet::Edit
sub __title2ident(_) {
  local $_ = shift;
  s/^\s+//;  s/\s+$//;  s/\W/_/g;  s/^(?=\d)/_/;
  $_
}

sub _validate_ident($) {
  croak "identifier is undef!" unless defined $_[0];
  croak "identifier is empty"  unless $_[0] ne "";
  croak ivisq '"$_[0]" is not a valid identifier\n'
                               unless $_[0] eq __title2ident($_[0]);
  $_[0]
}

# Check that an option hash has only valid keys
sub __validate_opthash($$;$) {
  my ($opthash, $valid_keys, $optdesc) = @_;
  return unless defined $opthash; # silently accept undef
  foreach my $k (keys %$opthash) {
    croak "Unrecognized ",($optdesc//"option")," '$k'" 
      unless first{$_ eq $k} @$valid_keys;
  }
  $opthash
}

sub __validate_nat($;$) {
  croak(($_[1]//"argument")." must be a positive integer",
        " (not ".u($_[0]).")")
    unless defined($_[0]) && "$_[0]" =~ /^\d+$/;
  $_[0]
} 
sub __validate_nat_or_undef($;$) {
  croak(($_[1]//"argument")." must be a positive integer or undef",
        " (not ".u($_[0]).")")
    unless !defined($_[0]) || "$_[0]" =~ /^\d+$/;
  $_[0]
}

sub __validate_pairs(@) {
  unless ((scalar(@_) % 2) == 0) {
    croak __callingsub," does not accept an {OPTIONS} hash"
      if (ref($_[0]) eq "HASH");
    croak "In call to ",__callingsub,
          " : uneven arg count, expecting key => value pairs"
  } 
  foreach (pairs @_) {
    my $key = $_->[0];
    croak "In call to ",__callingsub," the key '$key' looks suspicious"
      unless $key =~ /^\w+$/;
  }
  @_
}

sub _check_rx {
  my ($self, $rx, $one_past_end_ok) = @_;
  confess __callingsub.": Illegal rx ",vis($rx),"\n"
    unless ($rx//"") =~ /^\d+$/;  # non-negative integer
  my $maxrx = $#{$$self->{rows}};
  confess __callingsub.": rx ".vis($rx)." is beyond the last row\n"
                    .dvis(' $$self')
    if $rx > ($one_past_end_ok ? ($maxrx+1) : $maxrx);
}

# Diagnose scalar context if there are no results.
sub __first_ifnot_wantarray(@) {
  my $wantarray = (caller(1))[5];
  return @_ if $wantarray;
  return $_[0] if @_;
  croak __callingsub, " called in scalar context but that method does not return a result.\n"
    if defined($wantarray);
}
sub __validate_not_scalar_context(@) {
  my $wantarray = (caller(1))[5];
  croak __callingsub, " returns an array, not a scalar" 
    unless $wantarray || !defined($wantarray);
  @_
}

sub _carponce { # if not silent
  my $self = shift;
  my $msg = join "",@_;
  return if $$self->{_carponce}->{$msg}++;
  $msg .= "\n" unless $msg =~ /\n\z/s;
  carp($msg)
    unless $$self->{silent}; # never appears even if silent is later unset
}

# Default argument is $_
sub cx2let(_) {
  my $cx = shift;
  my $ABC="A"; ++$ABC for (1..$cx);
  return $ABC
}
sub let2cx(_) {
  my $ABC = shift;
  my $n = ord(substr($ABC,0,1,"")) - ord('A');
  while (length $ABC) {
    my $letter = substr($ABC,0,1,"");
    $n = (($n+1) * 26) + (ord($letter) - ord('A'));
  }
  return $n;
}

###################### METHODS #######################

# Unlike other methods, new() takes key => value pair arguments.
# For consistency with other methods an initial {OPTIONS} hash is
# also allowed, and is merged with any linear args.
sub new {
  my ($classname, $opthash) = &__self_opthash;
  my %opts = (%$opthash, __validate_pairs(@_));

  # Special handling of {caller_level} is needed since there was no object to
  # begin with; instead, internal callers (e.g. Spreadsheet::Edit::new) pass
  # caller_level as a "user" option, which we delete here so it won't be logged.
  my $caller_level = delete($opts{caller_level}) // 0;
  my $cmd_nesting  = delete($opts{cmd_nesting})  // 0;

  my $opts_str = %opts ? Data::Dumper::Interp->new()->Maxdepth(1)->Foldwidth1(40)->hvis(%opts) : "";

  my $self;
  if (my $clonee = delete $opts{clone}) { # untested as of 2/12/14
    croak "Other options not allowed with 'clone'" if %opts;
    require Clone;
    $self = Clone::clone($clonee); # in all its glory
    $$self->{data_source} = "cloned from $$self->{data_source}";
    $$self->{caller_level} = $caller_level;
    $$self->{cmd_nesting}  = $cmd_nesting;
  } else {
    my $hash = {
      attributes       => delete $opts{attributes} // {},
      verbose          => delete $opts{verbose} // $Verbose // $opts{debug} // $Debug,
      debug            => delete $opts{debug} // $Debug,
      silent           => delete $opts{silent} // $Silent,
      linenums         => delete $opts{linenums} // [],
      meta_info        => delete $opts{meta_info} // [], ##### ???? obsolete ???
      data_source      => delete $opts{data_source} // "(none)",
      num_cols         => delete $opts{num_cols} // undef,
      caller_level     => $caller_level,
      cmd_nesting      => $cmd_nesting,
      autodetect_opts  => {},     # enabled by default

      # %colx maps titles, aliases (automatic and user-defined), and
      # spreadsheet column lettercodes to the corresponding column indicies.
      colx             => {},
      colx_desc        => {},     # for use in error messages
      useraliases      => {},     # key exists for user-defined alias names

      title_rx         => undef,
      first_data_rx    => undef,
      last_data_rx     => undef,
      current_rx       => undef,  # valid during apply()

      pkg2tiedvarnames => {},
      pkg2tieall       => {},

    };
    
    # We can not use $hash directly as the object repr because %{} is 
    # overloaded, so we use a scalar ref to it instead.
    $self = bless \$hash, $classname;

    # Create a tied virtual array which creates Magicrows when assigned to.
    my @rows; tie @rows, 'Spreadsheet::Edit::OO::RowsTie', $self;
    $hash->{rows} = \@rows;

    if (my $newdata = delete $opts{rows}) {
      foreach (@$newdata) {
        push @rows, $_;
      }
    }
    # Validate data, default num_cols, pads rows, etc.
    $self->_rows_replaced();
  }

  $self->_logmethifv( \$opts_str, \" : ", \"$self");
  $$self->{caller_level} = 0;
  $$self->{cmd_nesting} = 0;

  croak "Invalid option ",hvis(%opts) if %opts;

  $self
}#new

use overload
  # As an ARRAYref, a sheet acts like \@rows which is (a ref to) a
  #   virtual array of Magicrow objects, each of which is a dual array/hash
  #   ref to cells in a given row (via RowsTie).
  '@{}' => sub { my $hash = ${ shift() }; $hash->{rows}; },

  # As a HASHref, a sheet acts like \%crow which is (a ref to)
  # the hash view of the current row during 'apply'
  '%{}' => sub { my $self = shift;
                 # probably less efficient but avoids repeating code
                 local $$self->{caller_level} = $$self->{caller_level} + 1;
                 \%{ $self->crow() };
               },
  #'""' => sub { shift },
  #'0+' => sub { shift },
  #'==' => sub { my ($self, $other, $swap) = @_; $self == $other },
  #'eq' => sub { my ($self, $other, $swap) = @_; "$self" eq "$other" },
  fallback => 1,
  ;

sub _rows_replaced {  # completely new or replaced rows, linenums, etc.
  my ($self) = @_;
  my $hash = $$self;

  my ($rows, $linenums, $num_cols, $current_rx)
    = @$hash{qw/rows linenums num_cols current_rx/};

  croak "Can not replace sheet content during an apply!\n"
    if defined $current_rx;
  for my $rx (0..$#$rows) {
    my $row = $rows->[$rx];
    croak "rows must contain refs to arrays of cells (row $rx is $row)"
      unless __looks_like_aref($row);
    for my $cx (0..$#$row) {
      croak "New cell at Row ",$rx+1," Column ",cx2let($cx)," contains a ref"
        if ref($row->[$cx]);
    }
  }
  croak '\'linenums\' if present must be (a ref to) an array of numbers, ',
        ' "" or "???"', ivis('\nnot $linenums\n')
    unless ref($linenums) eq "ARRAY" 
      && all{ defined() and looks_like_number($_) || !/[^\?]/ } @$linenums;

  if (@$rows) {  # Determine num_cols and pad short rows
    my $nc = 0;
    foreach (@$rows) { $nc = @$_ if @$_ > $nc }
    if ($num_cols && $num_cols != $nc) {
      croak "num_cols=$num_cols was specified along with initial data, but\n",
            "the value doesn't match the data (which has up to $nc columns)\n"
    } else {
      $hash->{num_cols} = $num_cols = $nc;
    }
    # Pad short rows with empty fields
    foreach my $row (@$rows) {
      push @$row, (("") x ($num_cols - @$row));
    }
    $#$linenums = $#$rows;
    foreach (@$linenums) { $_ //= '???' };
  } else {
    # There is no data. Default num_cols to zero, but leave any
    # user-supplied value so a subsequent insert_rows() will know how
    # many columns to create.
    $hash->{num_cols} //= 0;
  }
  oops unless $hash->{data_source};
  croak "#linenums ($#$linenums) != #rows ($#$rows)\n",
        dvis '$hash->{linenums}\n$hash->{rows}'
    unless @$linenums == @$rows;

  $hash->{title_rx} = undef;
  $hash->{first_data_rx} = undef;
  $hash->{last_data_rx} = undef;
  $hash->{useraliases} = {};
  ##NO autodetect now; give user time to call title_rx {OPTIONS} first.
  local$$self->{autodetect_opts} = {enable => 0};
  $self->_rebuild_colx; # Set up colx colx_desc
  $self
}#_rows_replaced

# Allow user to find out names of tied variables
sub tied_varnames {
  my ($self, $opts) = &__self_opthash;
  my $pkg = $opts->{package} // $self->_caller_pkg;
  # ???
  $self->_autodetect_title_rx_ifneeded_cl1() if !defined $$self->{title_rx};
  my $h = $$self->{pkg2tiedvarnames}->{$pkg} //= {};
  return keys %$h;
}

# Internal: Tie specified variables into a package if not already tied.
# Returns:
sub __TCV_REDUNDANT() { 1 }  # if all were already tied
sub __TCV_OK()        { 2 }  # otherwise (some tied, or no idents specified)
#
sub _tie_col_vars {
  my $self = shift;
  my $pkg  = shift;
  my $parms = shift;
  # Remaining arguments are idents
  
  my ($safe, $file, $lno) = @$parms;
  my @safecheck_pkgs = $pkg eq "main" ? ($pkg) : ($pkg, "main");

  my ($colx, $colx_desc, $debug, $silent)
    = @$$self{qw/colx colx_desc debug silent/};
  
  # FIXME: BUG/ISSUE ...
  #   Why is it correct to keep tiedvarnames PER-SHEET ?
  #   Isn't this a global property of each package?
 
  my $tiedvarnames = ($$self->{pkg2tiedvarnames}->{$pkg} //= {});

#say "#_tie(@_)# ", __tracecall;

  if (@_ > 0 && %$tiedvarnames) {
    SHORTCUT: {
      foreach (@_) {
        last SHORTCUT unless exists $tiedvarnames->{$_};
      }
      return __TCV_REDUNDANT;
    }
  }

  VAR:
  foreach (sort {$a->[0] <=> $b->[0]} # sort for ease of debugging
           map {
             my $cx = $colx->{$_};
             defined($cx)
               ? [ $cx,    $_, $colx_desc->{$_} ]
               : [ 999999, $_, "(currently NOT DEFINED)" ];
           } @_
          )
  {
    my ($cx, $ident, $desc) = @$_;
    oops unless $ident =~ /^\w+$/;

    if (exists $tiedvarnames->{$ident}) {
      $self->log(" Previously tied: \$${pkg}::${ident}\n") if $debug;
      next
    }

    no strict 'refs';
    if ($safe) {
      if (${^GLOBAL_PHASE} ne "START") {
        $self->_carponce("Not tieing new variables because :safe was used and this is not (any longer) during compile time\n") unless $silent; 
        return __TCV_REDUNDANT; ### IMMEDIATE EXIT ###
      }
      foreach my $p (@safecheck_pkgs) {
        # Per 'man perlref' we can not use *foo{SCALAR} to detect a never-
        # declared SCALAR (it's indistinguishable from an existing undef var).
        # So we must insist that the entire glob does not exist.
        no strict 'refs';
        if (exists ${$p.'::'}{$ident}) {
          croak <<EOF ;
'$ident' clashes with an existing variable in package $p .
    Note: This check occurs when tie_column_vars was called with option :safe,
    in this case at ${file}:${lno} .  In this situation you can not 
    explicitly declare the tied variables, and they must be tied and 
    imported before the compiler sees them.
EOF
        }
      }
    }

    $self->log("tie \$${pkg}::${ident} to $desc\n") if $debug;

    $tiedvarnames->{$ident} = 1;

    *{"$pkg\::$ident"} = \${ *{gensym()} };

    tie ${"${pkg}::$ident"}, 'Tie::Indirect::Scalar',
                             \&_tiecell_helper, $pkg, $ident;
  }
  return __TCV_OK;
}
sub _tiecell_helper {
  my($mutating, $pkg, $ident) = @_;
  my $sheet = $pkg2currsheet{$pkg}
                // croak "No sheet is currently valid for package $pkg\n";
  local $$sheet->{caller_level} = $$sheet->{caller_level} + 1;
  $sheet->_onlyinapply("tied variable \$$ident");

  # WRONG... it croaks bc sheet->{rows}->[rx] is a rowhash which doesn't like undef keys
  # WRONG: This returns \undef if $ident is not currently valid
  \( $$sheet->{rows}->[$$sheet->{current_rx}]->{$ident} )
}

sub _all_valid_idents {
  my $self = shift;
  my %valid_idents;
  foreach (keys %{ $$self->{colx} }) {
    if (/^(?:REGERROR|REGMARK|AUTOLOAD)$/) {
      $self->_carponce("WARNING: Column key ",visq($_)," conflicts with a Perl built-in; variable will not be tied.\n");
      next;
    }
    $valid_idents{ __title2ident($_) } = 1;
  }
  return keys %valid_idents;
}

# {option=>value...} may be passed as the first argument
sub tie_column_vars {
  my ($self, $opts) = &__self_opthash;
  # Any remaining args specify variable names matching
  # alias names, either user-defined or automatic.
  
  croak "tie_column_vars without arguments (did you intend to use ':all'?)"
    unless @_;

  local $$self->{silent}  = $opts->{silent} // $$self->{silent};
  local $$self->{verbose} = $opts->{verbose} // $$self->{verbose};
  local $$self->{debug}   = $opts->{debug} // $$self->{debug};

  my $pkg = $opts->{package} // $self->_caller_pkg;

  my (%tokens, @varnames);
  foreach (@_) { if (/:/) { $tokens{$_} = 1 } else { push @varnames, $_ } }
  foreach (@varnames) {
    croak "Invalid variable name '$_'\n" unless /^\$?\w+$/;
    s/^\$//;
  }

  # With ':all' tie all possible variables, now and in the future.
  #
  # CURRENTLY UNDOCUMENTED: With the ":safe" token, a check is made
  # that variables do not already exist immediately before tying them; 
  # otherwise an exception is thrown.
  #
  # When combined with ':all' variables will not be checked & tied 
  # except during compile time, i.e. within BEGIN{...}.  Therefore a 
  # malicious spreadsheet can not cause an exception after the compilation
  # phase.
  my $safe = delete $tokens{':safe'};
  my $parms = [$safe, ($self->_caller())[1,2]]; # [safearg, file, lineno]

  # Why? Obsolete? Only for :all?? [note added Dec22]
  $self->title_rx($opts->{title_rx}) if exists $opts->{title_rx};

  if (delete $tokens{':all'}) {
    # Remember parameters for tie operations which might occur later
    $$self->{pkg2tieall}->{$pkg} = $parms;
    $self->_autodetect_title_rx_ifneeded_cl1();
    push @varnames, sort $self->_all_valid_idents;
  }
  croak "Unrecognized token in arguments: ",avis(keys %tokens) if %tokens;

  my $r = $self->_tie_col_vars($pkg, $parms, @varnames);

  my $pfx = ($r == __TCV_REDUNDANT ? "[ALL REDUNDANT] " : "");
  $self->_logmethifv(\$pfx,\__fmt_uqarray(keys %tokens, @varnames), \" in package $pkg");
}#tie_column_vars

#
# Accessors for misc. sheet data
#

sub attributes { ${&__selfonly}->{attributes} }
sub colx { ${&__selfonly}->{colx} }
sub colx_desc { ${&__selfonly}->{colx_desc} }
sub data_source {
  my $self = shift;
  return $$self->{data_source} if @_ == 0;  # 'get' request
  $self->_logmethifv(@_);
  croak "Too many args" unless @_ == 1;
  $$self->{data_source} = $_[0]
}
sub linenums { ${&__selfonly}->{linenums} }
sub num_cols { ${&__selfonly}->{num_cols} }
sub rows { ${&__selfonly}->{rows} }
sub sheetname { ${&__selfonly}->{sheetname} }

sub iolayers { ${&__selfonly}->{iolayers} }
sub meta_info {${&__selfonly}->{meta_info} }
sub input_encoding {
  # Emulate old API.  We actually store input_iolayers instead now,
  # so as to include :crlf if necessary.
  my $self = &__selfonly;
  local $_;
  return undef unless
    exists(${$self}->{input_iolayers})
    && ${$self}->{input_iolayers} =~ /encoding\(([^()]*)\)/;
  return $1;
}

# See below for title_rx()
sub title_row {
  my $self = $_[0];
  local $$self->{caller_level} = $$self->{caller_level} + 1;
  my $title_rx = &title_rx;  # auto-detects. Pass thru {OPTIONS} if present
  defined($title_rx) ? $$self->{rows}->[$title_rx] : undef
}
sub rx { ${ &__selfonly }->{current_rx} }
sub current_row {
  my $self = &__selfonly;
  my $current_rx = $$self->{current_rx} // return(undef);
  $$self->{rows}->[$current_rx];
}
sub linenum {
  my $self = &__selfonly;
  my $current_rx = $$self->{current_rx} // return(undef);
  $$self->{linenums}->[$current_rx];
}
sub crow {
  my $self = &__selfonly;
  ${ $self->_onlyinapply("row() method") }->{rows}->[$$self->{current_rx}]
}
sub _getref {
  my ($self, $rx, $ident) = @_;
  my ($rows, $colx) = @$$self{qw/rows colx/};
  croak "get/seg: rx $rx is out of range" if $rx < 0 || $rx > $#$rows;
  my $row = $$self->{rows}->[$rx];
  my $cx = $colx->{$ident};
  oops("Invalid cx ".vis($cx)) if ! defined($cx) || $cx < 0 || $cx > $#$row;
  \$row->[$cx];
}
sub get {
  my $ref = &_getref;
  $$ref;
}
sub set {
  my $ref = &_getref;
  $$ref = $_[3];
}

# Call another method, incrementing caller_level
sub submethod {
  my $self = shift;
  my $methname = shift;
  local $$self->{caller_level} = $$self->{caller_level} + 2;
  $self->$methname(@_);
}
sub subcommand {
  my $self = shift;
  my $methname = shift;
  local $$self->{caller_level} = $$self->{caller_level} + 2;
  local $$self->{cmd_nesting} = $$self->{cmd_nesting} + 1;
  $self->$methname(@_);
}
# Call another method, incrementing caller_level and suppressing verbose
sub subcommand_noverbose {
  my $self = shift;
  my $methname = shift;
  local $$self->{verbose} = $$self->{debug}; # keep showing with 'debug'
  local $$self->{caller_level} = $$self->{caller_level} + 2;
  local $$self->{cmd_nesting} = $$self->{cmd_nesting} + 1;
  $self->$methname(@_);
}

# Print segmented log messages:
#   Join args together, prefixing with "> " or ">> " etc.
#   unless the previous call did not end with newline.
# Maintains internal state.  A final call with an ending \n must occur.
sub log {
  my $self = shift;
  state $in_midst;
  print STDERR join "",
                    ($in_midst ? "" : (">" x ($$self->{cmd_nesting}||1))),
                    map{u} @_;
  $in_midst = ($_[$#_] !~ /\n\z/s);
}

# FUNCTION.
# Format a list omitting enclosing brackets, with special annotation handling.
#
# Items are formatted using vis() and separated by commas, except that refs to
# printable strings are de-referenced and included without other formatting and
# adjacent commas are suppressed (this special form is used to intermingle
# fixed annotations among data items).
#
# If the arguments constitute a sequence, then "first..last" is returned
# instead of "arg0,arg1,...,argN" (annotations aren't recognized in this case).
sub _is_annotation($) { ref($_[0]) eq 'SCALAR' }
sub fmt_list(@) {
  oops if wantarray;
  my $is_sequential = (@_ >= 4);
  my $seq;
  foreach(@_) {
    $is_sequential=0,last
      unless defined($_) && /^\w+$/ && ($seq//=$_[0])++ eq $_
  }
  if ($is_sequential) {
    return visq($_[0])."..".visq($_[$#_])
  }

  # Join vis() results with commas except for \"..." annotations
  join "", map{
     _is_annotation($_[$_]) ? ${ $_[$_] } :
     vis($_[$_]) . (($_ < $#_ && !_is_annotation($_[$_+1])) ? "," : "")
              } (0..$#_)
}
## test
#foreach ([], [1..5], ['f'..'i'], ['a'], ['a','x']) {
#  my @items = @$_;
#  warn avis(@items)," -> ", scalar(fmt_list(@items)), "\n";
#  @items = (\"-FIRST-", @items);
#  warn avis(@items)," -> ", scalar(fmt_list(@items)), "\n";
#  splice @items, int(scalar(@items)/2),0, \"-ANN-" if @items >= 1;
#  warn avis(@items)," -> ", scalar(fmt_list(@items)), "\n";
#  push @items, \"-LAST-";
#  warn avis(@items)," -> ", scalar(fmt_list(@items)), "\n";
#}
#die "TEX";

# This is a FUNCITON not method.
#
# Format a log message for a sub call using broken-out
# parameters:  (caller_level, cmd_nesting_level, ITEM...)
# where the ITEMs are formatted with fmt_list, i.e. with annotation support.
#
# Called by related methods and directly in Spreadsheet::Edit.
#
# RETURNS "> [callerfile:callerlineno] calledsubname STRINGIFIED,ITEM,...\n"
#   with repeated ">>..." if cmd_nesting_level > 1.
#
# ITEMs should NOT include a terminal newline.
sub __logfuncmsg($$@) {
  my ($cl, $nesting, @items) = @_;

#  # Don't show the first item if it looks like an empty {OPTIONS} hashref
#  # REALLY??
#  shift @items
#    if @items && ref($items[0]) eq "HASH" && ! %{ $items[0] };
  (my $msg = fmt_list(@items)) =~ s/^ +//; # will follow a space
  my (undef,$fn,$ln,$subname) = caller($cl+1);  # +1 for calling us
  unless (defined($subname) && defined($fn)) {
    #local $Carp::MaxArgNums = '0 but true'; # omit args from backtrace
    oops dvisq('LOG BUG: $cl+1 is off bottom\n  $msg\n');
  }
  if ($fn =~ /\b((?:Edit|OO)\.pm)/) {
    # If an internal location is shown there is a bug somewhere.
    # cl is normally >= 2, but for debugging we might deliberately
    # set cl=0, in which case we don't diagnose this.
    local $Carp::MaxArgNums = '0 but true'; # omit args from backtrace
    oops "*** LOG BUG (showing internal module in $fn : $ln) cl=$cl)\n";
  }
  $fn = basename($fn);
  $subname =~ s/.*:://;
  #Carp::cluck ivis "##LOG $subname cl=$cl n=$nesting ${fn}:$ln \$msg\n";
  oops "terminal newline in final log arg" if $msg =~ /\n\z/s;

  # N.B. fmt_list() handles ref-to-scalar as un-quoted string
  (">" x ($nesting||1))."[$fn:$ln] $subname $msg\n"
}

# $obj->_logmethmsg(extra_levels, STRINGs...)
#
# RETURNS: ">... [callerfile:callerlno] calledsubname STRINGs\n"
#
# Looks back (caller_level + extra_levels + 1) stack frames
# (+1 to account for the call to us).
#
# Unconditionally appends \n.
sub _logmethmsg {  # $self->_logmethmsg($extra_level, @items)
  my $self = shift;
  my $extra_level = shift;
  oops "missing extra_level arg" unless u($extra_level) =~ /^\d+$/;
  __logfuncmsg( $$self->{caller_level}+$extra_level+1,
                $$self->{cmd_nesting},
                @_ );
}
sub _logmeth {
  my $self = shift;
  print STDERR $self->_logmethmsg(1,@_);
}

sub __logfunc($$@) {
  my ($cl, $nesting, @items) = @_;
  print STDERR __logfuncmsg($cl+1, $nesting, @items);
}

sub _logmethifv {
  my $self = $_[0]; # not shifted off
  return unless $$self->{verbose};
  goto &_logmeth;  # goto so {caller_level} is correct
}

sub _call_usercode($$$) {
  my ($self, $code, $cxlist) = @_;
  local $$self->{caller_level} = 0; # Log user's nested calls correctly

  if (@$cxlist) {
    my $row = $self->current_row();
    foreach ($row->[$cxlist->[0]]) { # bind $_ to the first-specified column
      &$code(@$row[@$cxlist]);
    }
  } else {
    $code->();
    ##Simplify backtraces
    #@_ = ();
    #goto &$code;
  }
}

# Do apply, resetting caller_level to 0 and handling COLSPEC args
# If $rxlists or $rxfirst & $rxlast are undef, visit all rows
#
# Calers must increment {caller_level} first unless they goto.
sub _apply_to_rows($$$;$$$) {
  my ($self, $code, $cxlist, $rxlist, $rxfirst, $rxlast) = @_;
  my $hash = $$self;
  my ($linenums,$rows,$num_cols,$cl) = @$hash{qw/linenums rows num_cols caller_level/};

  croak $self->_logmethmsg(0, " Missing or incorrect {code} argument") unless ref($code) eq "CODE";
  foreach (@$cxlist) {
    if ($_ < 0 || $_ >= $num_cols) {
      croak $self->_logmethmsg(0,"cx $_ is out of range")
    }
  }

  { # Temp save "current_rx" from an enclosing apply
    local $hash->{current_rx} = undef;

    # Temp update "current apply sheet" for logmsg()
    local $_inner_apply_sheet = $self;

    if (defined $rxlist) {
      foreach my $rx (@$rxlist) {
        croak "rx $rx is out of range"
          if $rx < 0 || $rx > $#$rows;
        $hash->{current_rx} = $rx;
        _call_usercode($self,$code,$cxlist);
      }
    } else {
      # Do not cache $#$rows so user can call insert_rows() or delete_rows()
      for (my $rx = $rxfirst // 0;
           $rx <= $#$rows && (!defined($rxlast) || $rx <= $rxlast);
           $rx++)
      {
        $hash->{current_rx} = $rx;
        _call_usercode($self,$code,$cxlist);
        $rx = $hash->{current_rx}; # might have been changed by delete_rows()
      }
    }
  }

  croak "After completing apply, an enclosing apply was resumed, but",
        " current_rx=",$hash->{current_rx}," now points beyond the last row!\n"
    if defined($hash->{current_rx}) && $hash->{current_rx} > $#$rows;
}#_apply_to_rows

# Rebuild %colx and %colx_desc, and tie any required new variables.
#
# User-defined column aliases must already be valid in %colx;
# all other entries are deleted and re-created.
#
# Note: the special '^', '$' and numieric cx values (if in 0..num_cols)
# are handled algorithmically in _specs2cxdesclist() before consulting %colx.
#
# When building %colx, conflicts are resolved using these priorities:
#
#   User-defined aliases (ALWAYS valid)
#   Titles
#   Trimmed titles (with leading & trailing spaces removed)
#   Automatic aliases
#   ABC letter-codes
#
# Warnings are issued once for each conflict.
sub _rebuild_colx {
  my $self = shift;
  my $notie = $_[0]; # true during autodetect probing

  my ($silent, $colx, $colx_desc, $useraliases, $num_cols, $title_rx,
      $rows, $debug, $pkg2tieall)
    = @$$self{qw/silent colx colx_desc useraliases num_cols title_rx
                 rows debug pkg2tieall/};

  # Save user-defined Aliases before wiping %colx
  my %useralias;
  foreach my $alias (keys %$useraliases) {
    my $cx = $colx->{$alias};
    # cx may be undef if referenced column was deleted and/or if 
    # an alias was created with {optional => TRUE} with non-matching regex.
    #next if !defined($cx);  # the referenced column was deleted
    $useralias{$alias} = [$cx, $colx_desc->{$alias}];
  }

  # Now re-generate 
  %$colx = ();
  %$colx_desc = ();

  my sub __putback($$$) {
    my ($key, $cx, $desc) = @_;
    if (defined (my $ocx = $colx->{$key})) {
      $self->_carponce("Warning: ",visq($key), " ($desc) is MASKED BY (", $colx_desc->{$key},")")
        unless $cx == $ocx || $silent;
    } else {
      oops if exists $colx->{$key};
      $colx->{$key} = $cx;
      $colx_desc->{$key} = $desc;
    }
  }

  # Put back the user aliases
  while (my ($alias,$aref) = each %useralias) {
    my ($cx, $desc) = @$aref;
    __putback($alias, $cx, $desc);
  }

  if (defined $title_rx) {
    # Add non-conflicting titles
    my $indexed_titles = $self->_get_indexed_titles;
    while (my ($title, $cx) = each %$indexed_titles) {
      __putback($title, $cx, __fmt_cx($cx).": Title");
    }
    # Titles with leading & trailing spaces trimmed off
    while (my ($title, $cx) = each %$indexed_titles) {
      my $key = $title;
      $key =~ s/\A\s+//s; $key =~ s/\s+\z//s;
      if ($key ne $title) {
        __putback($key, $cx, __fmt_cx($cx).": Title trimmed of lead/trailing spaces");
      }
    }
    # Automatic aliases
    # N.B. These come from all titles, not just "normal" ones
    my $title_row = $rows->[$title_rx];
    for my $cx (0 .. $num_cols-1) {  # each @{aref overload} does not work
      my $title = $title_row->[$cx]; 
      next if $title eq "";
      my $ident = __title2ident($title);
      __putback($ident, $cx, __fmt_cx($cx).": Automatic alias for title");
    }
  } else {
    if ($self->_autodetect_enabled) {
#      # Should auto-detect have happened ?
#      say "#__rebuild_colx: autodetect not triggered by ",
#          __tracecall();
    }
  }
  my %abc;
  foreach my $cx ( 0..$num_cols-1 ) {
    my $ABC = cx2let($cx);
    __putback($ABC, $cx, "cx $cx: Standard letter-code");
  }

  unless ($notie) {
    # export and tie newly-defined magic variables to packages which want that.
    if (my @pkglist = grep {defined $pkg2tieall->{$_}} keys %$pkg2tieall) {
      my @idents = $self->_all_valid_idents;
      foreach my $pkg (@pkglist) {
        $self->_tie_col_vars($pkg, $pkg2tieall->{$pkg}, @idents);
      }
    }
  }
  #say dvis '###_reb final $colx';
} # _rebuild_colx

# Move and/or delete column positions.  The argument is a ref to an array
# containing the old column indicies of current (i.e. surviving) columns,
# or undefs for new columns which did not exist previously.
sub _adjust_colx {
  my ($self, $old_colxs) = @_;
  my ($colx, $colx_desc, $num_cols, $useraliases, $debug)
    = @$$self{qw/colx colx_desc num_cols useraliases debug/};
  oops unless @$old_colxs == $num_cols;
  my %old2new;
  foreach my $new_cx (0..$#$old_colxs) {
    my $old_cx = $old_colxs->[$new_cx];
    $old2new{$old_cx} = $new_cx if defined $old_cx;
  }
  # User-defined aliases are for arbitrary columns, so fix them manually
  foreach my $alias (keys %$useraliases) {
    my $cx = $colx->{$alias};
    next unless defined $cx; # e.g. non-unique title; see _rebuild_colx()
    if (defined (my $new_cx = $old2new{$cx})) {
      warn ">adjusting colx{$alias} : $colx->{$alias} -> $new_cx\n" if $debug;
      $colx->{$alias} = $new_cx;
    } else {
      warn ">deleting colx{$alias} (was $colx->{$alias})\n" if $debug;
      delete $colx->{$alias};
      delete $colx_desc->{$alias};
      delete $useraliases->{$alias};
    }
  }
  # Everything else is derived from actual titles
  $self->_rebuild_colx();
}

# Translate list of COLSPECs to a list of [cx,desc].
# Regexes may match multiple columns.
# THROWS if a spec does not indicate any existing column.
# Auto-detects the title row if appropriate.
sub _specs2cxdesclist {
  my $self = shift;
  my ($colx, $colx_desc, $num_cols) = @$$self{qw/colx colx_desc num_cols/};
  my @results;
  foreach my $spec (@_) {
    croak "Column specifier is undef!" unless defined $spec;
    if ($spec eq '^') {
      push @results, [0, "Special '^' specifier for first col"];
      next
    }
    if ($spec eq '$') {
      push @results, [$num_cols-1, "Special '\$' specifier for last col"];
      next
    }
    if (($spec =~ /^[1-9]\d*$/ || $spec eq "0")
                                 && $spec <= $num_cols) { # allow one-past-end
      push @results, [$spec, "Numeric column-index"];
      next
    }
    if (defined (my $cx = $colx->{$spec})) {
      # Is this correct? If spec is ABC-like title we won't autodetect!
      push @results, [$cx, $colx_desc->{$spec}];
      next
    }
    redo if !defined($$self->{title_rx})
              && defined $self->_autodetect_title_rx_ifneeded_cl1( @_ );
    if (ref($spec) eq 'Regexp') {
      my ($title_rx, $rows) = @$$self{qw/title_rx rows/};
      croak "Can not use regex: No title-row is defined!\n"
        unless defined $title_rx;
      my $title_row = $rows->[$title_rx] // oops;
      my $matched;
      for my $cx (0..$#$title_row) {
        my $title = $title_row->[$cx];
        # Note: We can't use /s here!  The regex compiler has already
        # encapsulated /s or lack thereof in the compiled regex
        if ($title =~ /$spec/) {
          push @results, [$cx, "cx $cx: regex matched title '$title'"];
          $matched++;
        }
      }
      if (! $matched) {
        croak "\n--- Title Row (rx $title_rx) ---\n",
               vis($title_row),"\n-----------------\n",
               "Regex $spec\n",
               "does not match any of the titles (see above) in '$$self->{data_source}'\n"
        # N.B. check for "does not match" in alias()
      }
      next
    }
    croak "Invalid column specifier '${spec}'\nnum_cols=$num_cols. Valid keys are:\n",
          $self->_fmt_colx;
  }
  oops unless wantarray;
  @results
}#_specs2cxdesclist
sub _spec2cx {  # return $cx or ($cx, $desc); throws if spec is invalid
  my ($self, $spec) = @_;
  my @list = $self->_specs2cxdesclist($spec);
  if (@list > 1) {
    croak ivis("Regexpr $spec matches multiple titles:\n   "),
          join("\n   ",map{ vis $_->[1] } @list), "\n";
  }
  __first_ifnot_wantarray( @{$list[0]} )  # cx or (cx,desc)
}

sub _colspec2cx {
  my ($self, $colspec) = @_;
  croak "COLSPEC may not be a regex" if ref($colspec) eq 'Regexp';
  goto &_spec2cx
}

# The user-callable API
# THROWS if a spec does not indicate any existing column.
# Auto-detects the title row if appropriate.
# Can return multiple results, either from multple args or Regexp multimatch
# In scalar context returns the first result.
sub spectocx { # the user-callable API
  my $self = shift;
  my @list = $self->_specs2cxdesclist(@_);
  __first_ifnot_wantarray( map{ $_->[0] } @list )
}

# Translate a possibly-relative column specification which
# indicate 1 off the end.
#
# The specification may be
#   >something  (the column after 'something')
# or
#   an absolute column indicator (cx or ABC), possibly 1 off the end
# or
#   refer to an existing column
#
sub _relspec2cx {
  my ($self, $spec) = @_;
  my $colx = $$self->{colx};
  if ($spec =~ /^>(.*)/) {
    my $cx = $self->_colspec2cx($1); # croaks if not an existing column
    return $cx + 1
  }
  $self->_colspec2cx($spec); # croaks if not an existing column
}

sub alias {
  my ($self, $opthash) = &__self_opthash;
  if ($opthash) {
    __validate_opthash($opthash, 
                       [qw(optional)],
                       "alias option");
  }
  croak "'alias' expects an even number of arguments\n"
    unless scalar(@_ % 2)==0;

  my ($colx, $colx_desc, $num_cols, $useraliases, $rows, $silent, $debug)
    = @$$self{qw/colx colx_desc num_cols useraliases rows silent debug/};

  my @cxlist;
  while (@_) {
    my $ident = _validate_ident( shift @_ );
    my $spec  = shift @_;

    croak "'$ident' is already a user-defined alias (for cx ",
          scalar($self->_spec2cx($ident)), ")"
      if $useraliases->{$ident};

    # We must auto-detect to notice titles which mask ABC codes.
    # We can't rely on _spec2cx (and _specs2cxdesclist) to do it because
    # they will not auto-detect if handed an "absolute" colspec like "A".
    $self->_autodetect_title_rx_ifneeded_cl1()
      unless defined($$self->{title_rx}) or __unindexed_title($spec, $num_cols);
    
    my $cx = eval{ $self->_spec2cx($spec) };
    unless(defined $cx) {
      oops unless $@;
      croak $@ unless $opthash->{optional} && $@ =~ /does not match/is;
      # Always throw on other errors, e.g. regex matches more than one title
    };
    $self->_logmethifv(
               (%$opthash ? ($opthash,\" ") : ()),
               \"$ident => ",\__fmt_colspec_cx($spec,$cx));
    $colx->{$ident} = $cx;
    $colx_desc->{$ident} = "alias for ".__fmt_cx($cx)." (".quotekey($spec).")";
    $useraliases->{$ident} = 1;
    push @cxlist, $cx;
  }
  $self->_rebuild_colx();

  __first_ifnot_wantarray( @cxlist )
}#alias

sub unalias(@) {
  my $self = &__self_noopthash;

  my ($colx, $colx_desc, $useraliases)
    = @$$self{qw/colx colx_desc useraliases/};

  foreach (@_) {
    delete $useraliases->{$_} // croak "unalias: '$_' is not a column alias\n";
    $self->_logmethifv(\" Removing alias $_ => ", \$colx_desc->{$_});
    delete $colx->{$_} // oops;
    delete $colx_desc->{$_} // oops;
  }
  $self->_rebuild_colx();
}

# title_rx: Set, or control auto-detection of, the title row
#
#   Note: By default the title row is auto-detected when first referenced.
#
#   title_rx ROWINDEX   sets the title row
#   title_rx undef      reverts to having no title row (use to re-read titles).
#
#   If a return value is wanted (i.e. not called in void context) and no
#   title row has been set yet, then auto-detect it immediately (using
#   any OPTARGS).  Auto-detect may be disabled in {OPTARGS}.
#
#   If called in a void context, {OPTARGS} are simply saved for later use.
#
sub title_rx {
  my $self = shift;
  # We must distinguish omitted {OPTIONS} from {} because {}
  # means reset autodetect_opts to defaults.
  my $opthash = shift() if ref($_[0]) eq 'HASH'; # else undef
  if ($opthash) {
    __validate_opthash($opthash, 
                       [qw(enable required min_rx max_rx first_cx last_cx)],
                       "autodetect option");
    $$self->{autodetect_opts} = $opthash;
  }
  if (@_ == 0) {
    if (defined wantarray) {
      # A return value was requested
      my $rx = $$self->{title_rx} // $self->_autodetect_title_rx_ifneeded_cl1();
      $self->_logmethifv(defined($opthash)?($opthash):\"", @_, \" : ", $rx);
      return $rx;
    } else {
      croak "title_rx called in void context without {OPTARGS} or argument"
        unless defined($opthash);
      $self->_logmethifv($opthash, @_);
      return;
    }
  } else {
    $self->_logmethifv(defined($opthash) ? $opthash : \"", @_);
    my $rx = shift;
    my $notie = shift() if u($_[0]) eq "_notie"; # during auto-detect probes
    croak "Extraneous argument(s) to title_rx" if @_;
    if (defined $rx) {
      croak "Invalid title_rx argument: ",visq($rx) 
        if $rx !~ /^\d+$/;
      croak "Rx $rx is beyond the end of the data",visq($rx) 
        if $rx >= scalar(@{ $$self->{rows} });
    }      
    $$self->{title_rx} = $rx;
    if (defined $rx) {
      $self->_rebuild_colx($notie);
    } else {
      $self->_autodetect_title_rx_ifneeded_cl1() # recurses if enabled
        // $self->_rebuild_colx() # a.d. not enabled; forget old title keys
    }
  }
  $$self->{title_rx}
}#title_rx

# Return title_rx, auto-detecting the title row if necessary and enabled.
#
# undef is returned if autodetect is disabled and there is no current title row.
#
# An exception is thrown if auto-detect was enabled but no plausible title
# row can be found.
#
# Optional parameters in {autodetect_opts} :
#   enable   => BOOL,
#   required => [COLSPEC, ...] # required titles
#   min_rx, max_rx   => NUM    # range of rows which may contain the title row.
#   first_cx => NUM    # first column ix which must contain a valid title
#   last_cx  => NUM    # last  column ix which must contain a valid title
#
# Detection looks for the first row which contains non-empty cells in
# every column (or within the specified range), and which contains
# all "required" titles.
#
# "Required" titles are optional and may be specified in either
# {autodetect_opts}->{required} or as arguments to this function;
# the latter case occurs only when called from _specs2cxdesclist.
sub _autodetect_enabled {
  my $ad_opts = ${shift()}->{autodetect_opts} // oops;
  return (! exists($ad_opts->{enable}) || $ad_opts->{enable})
}
sub _autodetect_title_rx_ifneeded_cl1 {
  # "cl1" means this must be called from a top-level method (caller level 1)
  my ($self, @required_specs) = @_;

  if (! defined($$self->{title_rx}) and $self->_autodetect_enabled) {
    # +2: One for calling us + one for what we call
    local $$self->{caller_level} = $$self->{caller_level} + 2;

    my ($title_rx, $ad_opts, $rows, $colx, $num_cols, $verbose, $debug) =
       @$$self{qw(title_rx autodetect_opts rows colx num_cols verbose debug)};

    # Filter out titles which can not be used as a COLSPEC
    push @required_specs, to_array $ad_opts->{required}//[] ;
    @required_specs = grep{ !__unindexed_title($_, $num_cols) } @required_specs;

    my $min_rx   = __validate_nat($ad_opts->{min_rx}//0, "min_rx");
    my $max_rx   = __validate_nat($ad_opts->{max_rx}//$min_rx+3, "max_rx");
    my $first_cx = __validate_nat($ad_opts->{first_cx}//0, "first_cx");
    my $last_cx  = __validate_nat($ad_opts->{last_cx}//max($num_cols-1,0),
                                  "last_cx");
  
    my @nd_reasons;

    push @nd_reasons, 
      "min_rx ($min_rx) must not be greater than max_rx ($max_rx)"
        if $min_rx > $max_rx;
    # Okay if max_rx is huge
    push @nd_reasons, 
      "first_cx ($first_cx) must not be greater than last_cx ($last_cx)"
        if $first_cx > $last_cx;
    push @nd_reasons, 
      "last_cx ($last_cx) must not exceed num_cols-1 (".($num_cols-1).")"
        if $last_cx > $num_cols-1;

    my $detected;
    unless (@nd_reasons) {
      local $$self->{verbose} = 0; # suppress during trial and error
      local $$self->{silent}  = 1; #
      # Find the first row with all required titles within the column range, 
      # OR non-empty titles in all positions.
      #say '#START autodetect from ',__tracecall(), dvis '\n  : @required_specs $colx' if $debug;
      RX: for my $rx ($min_rx .. min($max_rx,$#$rows)) {
        say "#   ",$nd_reasons[-1] if $debug && @nd_reasons;
        local $$self->{caller_level} = $$self->{caller_level} + 1;
        say ivis '#autodetect: Trying RX $rx ...' if $debug;
        if (! defined eval { $self->title_rx($rx, "_notie") }) {
          oops $@ unless $@ =~ /Auto-detect.*failed/s;
          next
        }
        foreach my $spec (@required_specs) {
          my @cxlist; 
          eval { @cxlist = map{ $_->[0] } $self->_specs2cxdesclist($spec) };
          if (@cxlist == 0) {
            push @nd_reasons, ivis 'rx $rx: Title or Spec $spec not found';
            next RX
          }
          say ivis '    <<Found $spec in cx @cxlist>>' if $debug;
          if (! first{ $_ >= $first_cx && $_ <= $last_cx } @cxlist) {
            push @nd_reasons, ivis 'rx $rx: Matched $spec but in unacceptable cx ' .alvis(@cxlist);
            next RX
          }
          say ivis '    <<cx is within $first_cx .. $last_cx>>' if $debug;
        }
        # Require non-empty titles in all positions withing first_cx..last_cx
        my $row = $rows->[$rx];
        my ($found_nonempty, $empty_cx);
        foreach ($first_cx .. $last_cx) {
          if ($row->[$_] eq "") {
            push @nd_reasons, ivis 'rx $rx: col cx $_ (col '.cx2let($_).') is empty';
            next RX;
          }
        }
        $detected = $rx;
        last
      }
      $$self->{title_rx} = undef; # will re-do below
    }
    if (defined $detected) {
      carp("Auto-detected title_rx = $detected") if $verbose;
      local $$self->{verbose} = 0; # suppress normal logging
      local $$self->{caller_level} = $$self->{caller_level} + 1;
      $self->title_rx($detected); # might still show collision warnings
      oops unless $$self->{title_rx} == $detected;
    } else {
      if (@nd_reasons == 0) {
        push @nd_reasons, ivis '(BUG?) No rows checked! num_cols=$num_cols rows=$$self->{rows}'.dvis '\n##($min_rx $max_rx $first_cx $last_cx)' ;
      }
      croak("In ",qsh($$self->{data_source})," ...\n",
            "  Auto-detect of title_rx with options ",vis($ad_opts),
            dvis ' @required_specs\n',
            " failed because:\n   ", join("\n   ",@nd_reasons),
            "\n"
      );
    }
  }
  $$self->{title_rx};
}

sub first_data_rx {
  my $self = shift;
  my $first_data_rx = $$self->{first_data_rx};
  return $first_data_rx if @_ == 0;    # 'get' request
  my $rx = __validate_nat_or_undef( shift() );
  $self->_logmethifv($rx);
  # Okay if this points to one past the end
  $self->_check_rx($rx, 1) if defined $rx;  # one_past_end_ok=1
  $$self->{first_data_rx} = $rx;
  $rx;
}
sub last_data_rx {
  my $self = shift;
  my $last_data_rx = $$self->{last_data_rx};
  return $last_data_rx if @_ == 0;    # 'get' request
  my $rx = __validate_nat_or_undef( shift() );
  $self->_logmethifv($rx);
  if (defined $rx) {
    $self->_check_rx($rx, 1); # one_past_end_ok=1
    confess "last_data_rx must be >= first_data_rx"
      unless $rx >= ($$self->{first_data_rx}//0);
  }
  $$self->{last_data_rx} = $rx;
  $rx;
}

# move_cols ">COLSPEC",source cols...
# move_cols "absolute-position",source cols...
sub move_cols($@) {
  my $self = shift;
  my ($posn, @sources) = @_;

  my ($num_cols, $rows) = @$$self{qw/num_cols rows/};

  my $to_cx = $self->_relspec2cx($posn);

  my @source_cxs = map { scalar $self->_spec2cx($_) } @sources;
  my @source_cxs_before = grep { $_ < $to_cx } @source_cxs;
  my $insert_offset = $to_cx - scalar(@source_cxs_before);
  my @rsorted_source_cxs = sort { $b <=> $a } @source_cxs;

  $self->_logmethifv(\__fmt_colspec_cx($posn,$to_cx), \" <-- ",
                \join(" ",map{"$source_cxs[$_]\[$_\]"} 0..$#source_cxs));

  croak "move destination is too far to the right\n"
    if $to_cx + @sources - @source_cxs_before > $num_cols;

  my @old_cxs = (0..$num_cols-1);

  foreach my $row (@$rows, \@old_cxs) {
    my @moving_cells = @$row[@source_cxs];             # save
    splice @$row, $_, 1 foreach (@rsorted_source_cxs); # delete
    splice @$row, $insert_offset, 0, @moving_cells;    # put back
  };

  $self->_adjust_colx(\@old_cxs);
}
sub move_col { goto &move_cols; }

# insert_cols ">COLSPEC",new titles (or ""s or undefs if no title row)
# insert_cols "absolute-position",...
# RETURNS: The new colum indicies, or in scalar context the first cx
sub insert_cols {
  my $self = shift;
  my ($posn, @new_titles) = @_;
  my ($num_cols, $rows, $title_rx) = @$$self{qw/num_cols rows title_rx/};

  my $to_cx = $self->_relspec2cx($posn);

  $self->_logmethifv(\__fmt_colspec_cx($posn,$to_cx), \" <-- ", \avis(@new_titles));

  @new_titles = map { $_ // "" } @new_titles; # change undef to ""
  my $have_new_titles = first { $_ ne "" } @new_titles;
  if (!defined($title_rx) && $have_new_titles) {
    $title_rx = $self->_autodetect_title_rx_ifneeded_cl1();
    croak "insert_cols: Can not specify non-undef titles if title_rx is not defined\n"
      if !defined($title_rx);
  }
  my $num_insert_cols = @new_titles;

  foreach my $row (@$rows) {
    if (defined $title_rx && $row == $rows->[$title_rx]) {
      splice @$row, $to_cx, 0, @new_titles;
    } else {
      splice @$row, $to_cx, 0, (("") x $num_insert_cols);
    }
  }
  $$self->{num_cols} += $num_insert_cols;

  $self->_adjust_colx(
    [ 0..$to_cx-1, ((undef) x $num_insert_cols), $to_cx..$num_cols-1 ]
  );

  __first_ifnot_wantarray( $to_cx .. $to_cx+$num_insert_cols-1 )
}
sub insert_col { goto &insert_cols }

# sort_rows {compare function}
# sort_rows {compare function} $first_rx, $last_rx
sub sort_rows {
  my $self = shift;
  croak "bad args" unless @_ == 1;
  my ($cmpfunc, $first_rx, $last_rx) = @_;

  my ($rows, $linenums, $title_rx, $first_data_rx, $last_data_rx)
       = @$$self{qw/rows linenums title_rx first_data_rx last_data_rx/};

  $first_rx //= $first_data_rx
                 // (defined($title_rx) ? $title_rx+1 : 0);
  $last_rx  //= $last_data_rx // $#$rows;

  oops unless defined($first_rx);
  oops unless defined($last_rx);
  my $pkg = $self->_caller_pkg;
  my @indicies = sort {
      my @row_indicies = ($a, $b);
      no strict 'refs';
      local ${ "$pkg\::a" } = $rows->[$a];  # actual row objects
      local ${ "$pkg\::b" } = $rows->[$b];
      $cmpfunc->(@row_indicies)
  } ($first_rx..$last_rx);

  @$rows[$first_rx..$#$rows] = @$rows[@indicies];
  @$linenums[$first_rx..$#$rows] = @$linenums[@indicies];

  __validate_not_scalar_context(0..$first_rx-1, @indicies, $last_rx+1..$#$rows)
}

sub delete_cols {
  my $self = shift;
  my (@cols) = @_;
  my ($num_cols, $rows) = @$$self{qw/num_cols rows/};

  my @cxlist = $self->_colspecs_to_cxs_ckunique(\@cols);

  my @reverse_cxs = sort { $b <=> $a } @cxlist;

  $self->_logmethifv(reverse @reverse_cxs);
  my @old_cxs = (0..$num_cols-1);
  for my $row (@$rows, \@old_cxs) {
    foreach my $cx (@reverse_cxs) {
      oops if $cx > $#$row;
      splice @$row, $cx, 1, ();
    }
  }
  $$self->{num_cols} -= @reverse_cxs;
  $self->_adjust_colx(\@old_cxs);
}
sub delete_col { goto &delete_cols; }

# Set option(s), returning the previous value (of the last one specified)
# Settings may be in an {OPTIONS} hash and/or linear args
sub options {
  my ($self, $opthash) = &__self_opthash;
  my @eff_args = (%$opthash, &__validate_pairs);
  my $prev;
  foreach (pairs @eff_args) {
    my ($key, $val) = @$_;
    $prev = $$self->{$key};
    if ($key eq "silent") {
      if (defined $val) {
        $$self->{$key} = $val;
      }
    }
    elsif ($key eq "verbose") {
      if (defined $val) {
        $$self->{verbose} = $val;
        $$self->{silent} = undef if $val;
      }
    }
    elsif ($key eq "debug") {
      if (defined $val) {
        $$self->{debug}   = $val;
        $$self->{verbose } = 1 if $val;
        $$self->{silent} = undef if $val;
      }
    }
    else { croak "options: Unknown option key '$key' (possible keys: silent verbose debug)\n"; }
  }
  $self->_logmethifv(\__fmt_pairs(@eff_args));
  $prev;
}

sub _colspecs_to_cxs_ckunique {
  my ($self, $colspecs) = @_; oops unless @_==2;
  my @cxlist;
  my %seen;
  foreach (@$colspecs) {
    my $cx = $self->_spec2cx($_);  # auto-detects title_rx if needed
    if ($seen{$cx}) {
      croak "cx $cx is specified by multiple COLSPECs: ", vis($_)," and ",vis($seen{$cx}),"\n";
    }
    $seen{ $cx } = $_;
    push @cxlist, $cx;
  }
  @cxlist
}

sub only_cols {
  my ($self, @cols) = @_;
  my $rows = $self->rows;

  # Replace each row with just the surviving columns, in the order specified
  my @cxlist = $self->_colspecs_to_cxs_ckunique(\@cols);
  for my $row (@$rows) {
    @$row = map{ $row->[$_] } @cxlist;
  }
  $$self->{num_cols} = scalar(@cxlist);
  $self->_adjust_colx(\@cxlist);
}

# obj->join_cols separator_or_coderef, colspecs...
# If coderef:
#   $_ is bound to the first-named column, and is the destination
#   @_ is bound to all named columns, in the order named.
sub join_cols {
  my $self = shift;
  my ($separator, @sources) = @_;
  my $hash = $$self;

  my ($num_cols, $rows) = @$hash{qw/num_cols rows/};

  my @source_cxs = map { scalar $self->_spec2cx($_) } @sources;
  $self->_logmethifv(\"'$separator' ",
                \join(" ",map{"$source_cxs[$_]\[$_\]"} 0..$#source_cxs));

  my $saved_v = $hash->{verbose}; $hash->{verbose} = 0;

  # Merge the content into the first column.  N.B. EXCLUDES title row.
  my $code = ref($separator) eq 'CODE'
               ? $separator
               : sub{ $_ = join $separator, @_ } ;

  # Note first/last_data_rx are ignored
  { my $first_rx = ($hash->{title_rx} // -1)+1;
    local $$self->{caller_level} = $$self->{caller_level} + 1;
    _apply_to_rows($self, $code, \@source_cxs, undef, $first_rx, undef);
  }

  # Delete the other columns
  $self->delete_cols(@source_cxs[1..$#source_cxs]);

  $$self->{verbose} = $saved_v;
}
sub join_cols_sep { goto &join_cols }  # to match the procedural API

sub rename_cols(@) {
  my $self = shift;
  croak "rename_cols expects an even number of arguments\n"
    unless scalar(@_ % 2)==0;
  my $pkg = $self->_caller_pkg;

  my ($num_cols, $rows, $title_rx) = @$$self{qw/num_cols rows title_rx/};

  if (!defined $title_rx) {
    $title_rx = $self->_autodetect_title_rx_ifneeded_cl1();
    croak "rename_cols: No title_rx is defined!\n" if !defined($title_rx);
  }
  my $title_row = $rows->[$title_rx];

  while (@_) {
    my $old_title = shift @_;
    my $new_title = shift @_;
    my $cx = $self->_spec2cx($old_title);
    $self->_logmethifv($old_title, \" -> ", $new_title, \" [cx $cx]");
    croak "rename_cols: Column $old_title is too large\n"
      if $cx > $#$title_row; # it must have been an absolute form
    $title_row->[$cx] = $new_title;

    # N.B. aliases remain pointing to the same columns regardless of names
  }
  $self->_rebuild_colx();
}

# apply {code}, colspec*
#   @_ are bound to the columns in the order specified (if any)
#   $_ is bound to the first such column
#   Only visit rows bounded by first_data_rx and/or last_data_rx,
#   starting with title_rx+1 if a title row is defined.
sub apply {
  my $self = shift;
  my ($code, @cols) = @_;
  my $hash = $$self;
  my @cxs = map { scalar $self->_spec2cx($_) } @cols;

  $self->_autodetect_title_rx_ifneeded_cl1() if !defined $hash->{title_rx};

  my $first_rx = max(($hash->{title_rx} // -1)+1, $hash->{first_data_rx}//0);

  @_ = ($self, $code, \@cxs, undef, $first_rx, $hash->{last_data_rx});
  goto &_apply_to_rows
}

# apply_all {code}, colspec*
#  Like apply, but ALL rows are visited, inluding the title row if any
sub apply_all {
  my $self = shift;
  my ($code, @cols) = @_;
  my $hash = $$self;
  my @cxs = map { scalar $self->_spec2cx($_) } @cols;
  $self->_logmethifv(\"rx 0..",$#{$hash->{rows}},
                    @cxs > 0 ? \(" cxs=".avis(@cxs)) : ());
  @_ = ($self, $code, \@cxs);
  goto &_apply_to_rows
}

sub ArrifyCheckNotEmpty($) {
  local $_ = shift;
  return $_ if ref($_) eq 'ARRAY'; # already an array reference
  croak "Invalid argument ",vis($_)," (expecting [array ref] or single value)\n"
    unless defined($_) && $_ ne "";
  return [ $_ ];
}

# apply_torx {code} rx,        colspec*
# apply_torx {code} [rx list], colspec*
# Only the specified row(s) are visited
# first/last_data_rx are ignored.
sub apply_torx {
  my $self = shift;
  my ($code, $rxlist_arg, @cols) = @_;
  croak "Missing rx (or [list of rx]) argument\n" unless defined $rxlist_arg;
  my $rxlist = ArrifyCheckNotEmpty($rxlist_arg);
  my @cxs = map { scalar $self->_spec2cx($_) } @cols;
  $self->_logmethifv(\vis($rxlist_arg),
                    @cxs > 0 ? \(" cxs=".avis(@cxs)) : ());
  @_ = ($self, $code, \@cxs, $rxlist);
  goto &_apply_to_rows
}

# apply_exceptrx {code} [rx list], colspec*
# All rows EXCEPT the specified rows are visited
sub apply_exceptrx {
  my $self = shift;
  my ($code, $exrxlist_arg, @cols) = @_;
  croak "Missing rx (or [list of rx]) argument\n" unless defined $exrxlist_arg;
  my $exrxlist = ArrifyCheckNotEmpty($exrxlist_arg);
  my @cxs = map { scalar $self->_spec2cx($_) } @cols;
  $self->_logmethifv(\vis($exrxlist_arg),
                    @cxs > 0 ? \(" cxs=".avis(@cxs)) : ());
  my $hash = $$self;
  my $max_rx = $#{ $hash->{rows} };
  foreach (@$exrxlist) {
    croak "rx $_ is out of range\n" if $_ < 0 || $_ > $max_rx;
  }
  my %exrxlist = map{ $_ => 1 } @$exrxlist;
  my $rxlist = [ grep{ ! exists $exrxlist{$_} } 0..$max_rx ];
  @_ = ($self, $code, \@cxs, $rxlist);
  goto &_apply_to_rows
}

# split_col {code} oldcol, newcol_start_position, new titles...
#  {code} is called for each row with $_ bound to <oldcol>
#         and @_ bound to the new column(s).
# The old column is left as-is (not deleted).
sub split_col {
  my $self = shift;
  my ($code, $oldcol_posn, $newcols_posn, @new_titles) = @_;

  my $num_insert_cols = @new_titles;
  my $old_cx = $self->_spec2cx($oldcol_posn);
  my $newcols_first_cx = $self->_relspec2cx($newcols_posn);

  $self->_logmethifv(\"... $oldcol_posn\[$old_cx] -> [$newcols_first_cx]",
                    avis(@new_titles));
  my $saved_v = $$self->{verbose}; $$self->{verbose} = 0;

  $self->insert_cols($newcols_first_cx, @new_titles);

  $old_cx += $num_insert_cols if $old_cx >= $newcols_first_cx;

  $self->apply($code,
               $old_cx, $newcols_first_cx..$newcols_first_cx+$num_insert_cols-1);

  $$self->{verbose} = $saved_v;
}

sub reverse_cols() {
  my $self = shift;
  my ($rows, $num_cols) = @$$self{qw/rows num_cols/};
  $self->_logmethifv();
  for my $row (@$rows) {
    @$row = reverse @$row;
  }
  $self->_adjust_colx([reverse 0..$num_cols-1]);
}

sub transpose() {
  my $self = shift;
  $self->_logmethifv();

  my ($rows, $old_num_cols, $linenums) = @$$self{qw/rows num_cols linenums/};

  $$self->{useraliases} = {};
  $$self->{title_rx} = undef;
  $$self->{first_data_rx} = undef;
  $$self->{last_data_rx} = undef;

  # Save a copy of the data
  my @old_rows = ( map{ [ @$_ ] } @$rows );

  # Rebuild the spreadsheet
  @$rows = ();
  $$self->{num_cols} = scalar @old_rows;

  for (my $ocx=0; $ocx < $old_num_cols; ++$ocx) {
    my @nrow;
    for my $row (@old_rows) {
      push @nrow, $row->[$ocx] // "";
    }
    push @$rows, \@nrow;
  }
  if ($$self->{saved_linenums}) {
    @$linenums = @{ $$self->{saved_linenums} };
    delete $$self->{saved_linenums};
  } else {
    $$self->{saved_linenums} = [ @$linenums ];
    @$linenums = ("?") x scalar @$rows;
  }
  $$self->{data_source} .= " transposed";

  $self->_rows_replaced;
}#transpose

# delete_rows rx ...
# delete_rows 'LAST' ...
# delete_rows '$' ...
sub delete_rows {
  my $self = shift;
  my (@rowspecs) = @_;

  my ($rows, $linenums, $title_rx, $first_data_rx, $last_data_rx, $current_rx, $verbose)
    = @$$self{qw/rows linenums title_rx first_data_rx last_data_rx current_rx verbose/};

  $title_rx //= $self->_autodetect_title_rx_ifneeded_cl1();

  foreach (@rowspecs) {
    $_ = $#$rows if /^(?:LAST|\$)$/;
    croak "Invalid row index '$_'\n" unless /^\d+$/ && $_ <= $#$rows;
  }
  my @rev_sorted_rxs = sort {$b <=> $a} @rowspecs;
  $self->_logmethifv(reverse @rev_sorted_rxs);

  # Adjust if needed...
  if (defined $title_rx) {
    foreach (@rev_sorted_rxs) {
      if ($_ < $title_rx) { --$title_rx }
      elsif ($_ == $title_rx) {
        $self->log("Invalidating titles because rx $title_rx is being deleted\n")
          if $$self->{verbose};
        $title_rx = undef;
        last;
      }
    }
    $$self->{title_rx} = $title_rx;
  }
  if (defined $first_data_rx) {
    foreach (@rev_sorted_rxs) {
      if ($_ <= $first_data_rx) { --$first_data_rx }
    }
    $$self->{first_data_rx} = $first_data_rx;
  }
  if (defined $last_data_rx) {
    foreach (@rev_sorted_rxs) {
      if ($_ <= $last_data_rx) { --$last_data_rx }
    }
    $$self->{last_data_rx} = $last_data_rx;
  }

  # Back up $current_rx to account for deleted rows.
  # $current_rx is left set to one less than the index of the "next" row if
  # we are in an apply().  That is, current_rx will be left still pointing to
  # the same row as before, or if that row has been deleted then the row
  # before that (or -1 if row zero was deleted).
  if (defined $current_rx) {
    foreach (@rev_sorted_rxs) {
      --$current_rx if ($_ <= $current_rx);
    }
    $$self->{current_rx} = $current_rx;
  }

  #warn "### BEFORE delete_rows rx (@rev_sorted_rxs):\n",
  #     map( { "   [$_]=(".join(",",@{$rows->[$_]}).")\n" } 0..$#$rows);

  for my $rx (@rev_sorted_rxs) {
    splice @$rows, $rx, 1, ();
    splice @$linenums, $rx, 1, ();
  }

  #warn "### AFTER delete_rows:\n",
  #     map( { "   [$_]=(".join(",",@{$rows->[$_]}).")\n" } 0..$#$rows);
}#delete_rows
sub delete_row { goto &delete_rows; }

# $firstrx = insert_rows [rx [,count]]
# $firstrx = insert_rows ['$'[,count]]
sub insert_rows {
  my $self = shift;
  my ($rx, $count) = @_;
  $rx //= 'END';
  $count //= 1;

  my ($rows, $linenums, $num_cols, $title_rx, $first_data_rx, $last_data_rx)
    = @$$self{qw/rows linenums num_cols title_rx first_data_rx last_data_rx/};

  $rx = @$rows if $rx =~ /^(?:END|\$)$/;

  $self->_logmethifv(\"at rx $rx (count $count)");

  croak "Invalid new rx '$rx'" unless looks_like_number($rx);
  if (defined($title_rx) && $rx <= $title_rx) {
    $$self->{title_rx} = ($title_rx += $count);
  }
  if (defined($first_data_rx) && $rx <= $first_data_rx) {
    $$self->{first_data_rx} = ($first_data_rx += $count);
  }
  if (defined($last_data_rx) && $rx <= $last_data_rx) {
    $$self->{last_data_rx} = ($last_data_rx += $count);
  }

  for (1..$count) {
    splice @$rows, $rx, 0, [("") x $num_cols];
    splice @$linenums, $rx, 0, "??";
  }

  return $rx;
}
sub insert_row { goto &insert_rows; }

# read_spreadsheet $inpath [Spreadsheet::Edit::IO::OpenAsCSV options...]
# read_spreadsheet $inpath [,iolayers =>...  or encoding =>...]
# read_spreadsheet $inpath [,{iolayers =>...  or encoding =>... }] #OLD API

# read_spreadsheet [{iolayers =>...  or encoding =>... }, ] $inpath #NEW API
sub read_spreadsheet {
  my ($self, $opts, $inpath) = &__self_opthash_1arg;

  my %csvopts = @sane_CSV_read_options;
  # Separate out Text::CSV options from %$opts
  foreach my $key (Text::CSV::known_attributes()) {
    #$csvopts{$key} = delete $opts{$key} if exists $opts{$key};
    $csvopts{$key} = $opts->{$key} if defined $opts->{$key};
    delete $opts->{$key};
  }
  $csvopts{escape_char} = $csvopts{quote_char}; # " : """

  croak "Obsolete {sheet} key in options (use 'sheetname')" 
    if exists $opts->{sheet};

  { my %notok = %$opts;
    delete $notok{$_} foreach (
      qw/iolayers encoding verbose silent debug/,
      # N.B. This used to include 'quiet' but it did not do anything
      qw/tempdir use_gnumeric/,
      qw/sheetname/, # for OpenAsCsv
    );
    croak "Unrecognized OPTION(s): ",alvisq(keys %notok) if %notok;
  }

  # convert {encoding} to {iolayers}
  if (my $enc = delete $opts->{encoding}) {
    #warn "Found OBSOLETE read_spreadsheet 'encoding' opt (use iolayers instead)\n";
    $opts->{iolayers} = ($opts->{iolayers}//"") . ":encoding($enc)";
  }
  # Same as last-used, if any
  # N.B. If user says nothing, OpenAsCsv() defaults to UTF-8
  $opts->{iolayers} //= $$self->{iolayers} // "";

  my ($rows, $linenums, $meta_info, $verbose, $debug)
    = @$$self{qw/rows linenums meta_info verbose debug/};

  ##$self->_check_currsheet;

  my $hash;
  { local $$self->{verbose} = 0;
    $hash = OpenAsCsv(
                   inpath => $inpath,
                   debug => $$self->{debug},
                   verbose => ($$self->{verbose} || $$self->{debug}),
                   %$opts, # all our opts are valid here
             );
  }
  $self->_logmethifv($inpath, $hash);

  # Save possibly-defaulted iolayers for use in subsequent write_csv
  $$self->{iolayers} //= $hash->{iolayers};

  my $fh = $hash->{fh};

  $csvopts{keep_meta_info} = 1;
  my $csv = Text::CSV->new (\%csvopts)
              or croak "read_spreadsheet: ".Text::CSV->error_diag ()
                      .dvis('\n## %csvopts\n');

  undef $$self->{num_cols};
  @$rows = ();
  @$linenums = ();
  my $lnum = 1;
  while (my $F = $csv->getline( $fh )) {
    push(@$linenums, $lnum);
    my @minfo = $csv->meta_info();
    # Force quoting of fields which look like negative numbers with an ascii
    # minus (\x{2D}) rather than Unicode math minus (\N{U+2212}).
    # This prevents conversion to the Unicode math minus when LibreOffice
    # reads the CSV.  The assumption is that if the input, when converted
    # TO a csv, has an ascii minus then the original spreadsheet cell format
    # was "text" not numeric.
    for my $cx (0..$#$F) {
      #...TODO   $minfo[$cx] |= 0x0001 if $F->[$cx] =~ /^-[\d.]+$/a;
    }
    push(@$meta_info, \@minfo);
    $lnum = $.+1;
    push(@$rows, $F);
  }
  close $fh || croak "Error reading $hash->{csvpath}: $!\n";

  $$self->{data_source} = $hash->{inpath}
    .($hash->{sheetname} ? "!".$hash->{sheetname} : "");
  $$self->{sheetname} = $hash->{sheetname}; # possibly undef

  $self->_rows_replaced;
}#read_spreadsheet

# write_csv {OPTHASH} "/path/to/output.csv"
# Cells will be quoted if the input was quoted, i.e. if indicated by meta_info.
sub write_csv {
  my ($self, $opts, $dest) = &__self_opthash_1arg;

  my %csvopts = ( @sane_CSV_write_options,
                  quote_space => 0,  # dont quote embedded spaces
                );
  # Separate out Text::CSV options from {OPTIONS}
  foreach my $key (Text::CSV::known_attributes()) {
    $csvopts{$key} = $opts->{$key} if defined $opts->{$key};
    delete $opts->{$key};
  }

  { my %notok = %$opts;
    delete $notok{$_} foreach (
      #removed above... Text::CSV::known_attributes(),
      qw/verbose silent debug/,
    );
    croak "Unrecognized OPTION(s): ",alvisq(keys %notok) if %notok;
  }

  $opts->{iolayers} //= $$self->{iolayers} // "";
  # New API: opts->{iolayers} may have all 'binmode' arguments.
  # If it does not include encoding(...) then insert default
  if ($opts->{iolayers} !~ /encoding\(|:utf8/) {
    $opts->{iolayers} .= ":encoding(".
            ($self->input_encoding() || DEFAULT_WRITE_ENCODING)
                                     .")";
  }
  if ($opts->{iolayers} !~ /:(?:crlf|raw)\b/) {
    # Use platform default
    #$opts->{iolayers} .= ":crlf";
  }

  my ($rows, $meta_info, $num_cols, $verbose, $debug)
    = @$$self{qw/rows meta_info num_cols verbose debug/};

  my $fh;
  if (openhandle($dest)) { # an already-open file handle?
    $self->_logmethifv($opts, \("<file handle specified> $opts->{iolayers} "
                                .scalar(@$rows)." rows, $num_cols columns)"));
    $fh = $dest;
  } else {
    $self->_logmethifv($opts, \($dest." $opts->{iolayers} ("
                             .scalar(@$rows)." rows, $num_cols columns)"));
    croak "Output path suffix must be *.csv, not\n  ",qsh($dest),"\n"
      if $dest =~ /\.([a-z]*)$/ && lc($1) ne "csv";
    open $fh,">$dest" or croak "$dest: $!\n";
  }

  binmode $fh, $opts->{iolayers} or die "binmode:$!";

  # Arrgh.  Although Text::CSV is huge and complex and implements a complicated
  # meta_info mechanism to capture quoting details on input, there is no way to
  # use the captured info to specify quoting of output fields!
  # So we implement writing CSVs by hand here.
  #my $csv = Text::CSV->new (\%csvopts)
  #            or die "write_csv: ".Text::CSV->error_diag ();
  #foreach my $row (@$rows) {
  #  oops "UNDEF row" unless defined $row;  # did user modify @rows?
  #  $csv->print ($fh, $row);
  #};
  
  # 5/2/22 FIXME: Maybe meta_info could be used when writing, albiet in
  # a grotesque way:
  #   If keep_meta_info is set > 9, then the output quotation style is
  #   "like it was used in the input of the the last parsed record"; so
  #   we could "parse" a dummy record to set the quote style before writing
  #   each record, like this (see perldoc Text::CSV_XS "keep_meta_info"):
  #     my $csv = Text::CSV_XS->new({ binary=>1, keep_meta_info=>11, 
  #                                   quote_space => 0 });
  #     apply_all {
  #       my $minfo = $meta_info[$rx];
  #       my @dummy = map{ '', 'x', '""' or '"x'' } @$minfo; # HOW?
  #       $csv->parse(join ",", @dummy); # set saved meta_info
  #       $csv->print(*OUTHANDLE, $row);
  #     }
  #   

  # Much of the option handling code was copied from Text::CSV_PP.pm
  # which depends on default values of options we don't specify explicitly.
  # So create a Text::CSV object just to get the effective option values...
  { my $o = Text::CSV->new( \%csvopts );
    foreach my $key (Text::CSV::known_attributes()) {
      $csvopts{$key} = $o->{$key};
    }
  }

  my $re_esc = ($csvopts{escape_char} ne '' and $csvopts{escape_char} ne "\0")
                 ? ($csvopts{quote_char} ne '') ? qr/(\Q$csvopts{quote_char}\E|\Q$csvopts{escape_char}\E)/ : qr/(\Q$csvopts{escape_char}\E)/
                 : qr/(*FAIL)/;
  for my $rx (0..$#$rows) {
    my $row = $rows->[$rx];
    my $minfo = $meta_info->[$rx];
    my @results;
    for my $cx (0..$num_cols-1) {
      my $value = $row->[$cx];
      confess "ERROR: rx $rx, cx $cx : undef cell value" unless defined($value);
      my $mi = $minfo->[$cx]; # undef if input was missing columns in this row
      my $must_be_quoted = $csvopts{always_quote} ||
                             (($mi//0) & 0x0001); # was quoted on input
      unless ($must_be_quoted) {
        if ($value eq '') {
          $must_be_quoted = 42 if $csvopts{quote_empty};
        } else {
          if ($csvopts{quote_char} ne '') {
            use bytes;
            $must_be_quoted=43 if
                    ($value =~ /\Q$csvopts{quote_char}\E/) ||
                    ($csvopts{sep_char} ne '' and $csvopts{sep_char} ne "\0" and $value =~ /\Q$csvopts{sep_char}\E/) ||
                    ($csvopts{escape_char} ne '' and $csvopts{escape_char} ne "\0" and $value =~ /\Q$csvopts{escape_char}\E/) ||
                    ($csvopts{quote_binary} && $value =~ /[\x00-\x1f\x7f-\xa0]/) ||
                    ($csvopts{quote_space} && $value =~ /[\x09\x20]/);
          }
        }
      }
      $value =~ s/($re_esc)/$csvopts{escape_char}$1/g;
      if ($csvopts{escape_null}) {
        $value =~ s/\0/$csvopts{escape_char}0/g;
      }
      if ($must_be_quoted) {
        $value = $csvopts{quote_char} . $value . $csvopts{quote_char};
      }
      $fh->print($csvopts{sep_char}) unless $cx==0;
      $fh->print($value);
    }
    $fh->print($csvopts{eol});
  }

  if (! openhandle $dest) {
    close $fh || croak "Error writing $dest : $!\n";
  }
}#write_csv

# Write spreadsheet with specified column formats
# {col_formats} is required
# Unless {sheetname} is specified, the sheet name is the outpath basename
#   sans any suffix
sub write_spreadsheet {
  my ($self, $opts, $outpath) = &__self_opthash_1arg;
  my $colx = $$self->{colx};

  $self->_logmethifv($opts, $outpath);

  # {col_formats} may be [list of formats in column order]
  #   or { COLSPEC => fmt, ..., __DEFAULT__ => fmt }
  # Transform the latter to the former...
  my $cf = $opts->{col_formats} // croak "{col_formats} is required";
  if (ref($cf) eq "HASH") {
    my ($default, @ary);
    while (my ($key, $fmt) = each %$cf) {
      ($default = $fmt),next if $key eq "__DEFAULT__";
      my $cx = $colx->{$key} // croak("Invalid COLSPEC '$key' in col_formats");
      $ary[$cx] = $fmt;
    }
    foreach (@ary) { $_ = $default if ! defined; }
    $cf = \@ary;
  }
  local $opts->{col_formats} = $cf;

  my ($csvfh, $csvpath) = tempfile(SUFFIX => ".csv");
  { local $$self->{verbose} = 0;
    $self->write_csv($csvfh, silent => 1, iolayers => ':encoding(UTF-8)',
                             @sane_CSV_write_options);
  }
  close $csvfh or die "Error writing $csvpath : $!";

  # Default sheet name to output file basename sans suffix
  $opts->{sheetname} //= fileparse($outpath, qr/\.\w+/);

  convert_spreadsheet($csvpath,
                      %$opts,
                      iolayers => ':encoding(UTF-8)',
                      cvt_from => "csv",
                      outpath => $outpath,
                     );
}

#====================================================================
# These helpers are used by predefined magic sheet variables.
# See code in Spreadsheet::Edit::import()

# Return $self if during an apply, or if being examined by Data::Dumper ;
# otherwise croak
sub _onlyinapply {
  my ($self, $accessor) = @_;
  unless (defined $$self->{current_rx}) {
    foreach (2..7) {
      my $pkg = (caller($_))[0];
      return $self
        if defined($pkg) && $pkg->isa("Data::Dumper") # perldoc UNIVERSAL
    }
    croak "Can't use $accessor now: Not during apply*\n"
  }
  $self
}
sub __getsheet($$$$) {
  my ($mutating, $pkg, $uvar, $onlyinapply) = @_;
  my $sheet = $pkg2currsheet{$pkg};
  croak("Modifying variable $uvar is not allowed\n") 
    if $mutating;
  croak("Can not use $uvar: No sheet is currently valid for package $pkg\n")
    unless defined $sheet;
  $onlyinapply ? _onlyinapply($sheet, $uvar) : $sheet
}
sub _scal_tiehelper {  # access a scalar sheet variable
  my($mutating, $pkg, $uvar, $ident, $onlyinapply) = @_;
  my $sheet = __getsheet($mutating, $pkg, $uvar, $onlyinapply);
  confess avisq(@_) unless exists $$sheet->{$ident};
  return \$$sheet->{$ident}; # return ref to the scalar
}
sub _aryelem_tiehelper { # access an element of an array sheet variable
  # *** SPECIAL HANDLING for title_rx 
  my($mutating, $pkg, $uvar, $index_ident, $array_ident, $onlyinapply) = @_;
  # E.g. for $title_row : index_ident="title_rx" and array_ident="rows"
  my $sheet = __getsheet($mutating, $pkg, $uvar, $onlyinapply);
  my $aref = $$sheet->{$array_ident} // oops dvisq '$array_ident @_'; # e.g. {rows}
  my $index = $$sheet->{$index_ident} // do{
    return \($sheet->_autodetect_title_rx_ifneeded_cl1())
      if $index_ident eq "title_rx";  # for title_row (aref->rows ix>title_rx)
    return \undef
      if $index_ident eq "current_rx"; # During Data::Dumper inspection?
    oops dvis '$array_ident $index_ident'; # otherwise it's a bug
  };
  oops(dvisq '@_ $index') if $index > $#$aref;
  return \$aref->[$index]; # return ref to scalar (the element in the array)
}
sub _refval_tiehelper { # access a sheet variable which is a ref of some kind
  my($mutating, $pkg, $uvar, $field_ident, $onlyinapply, $mutable) = @_;
  $mutating = 0 if $mutable;
  my $sheet = __getsheet($mutating, $pkg, $uvar, $onlyinapply);
  return $$sheet->{$field_ident}; # return the value, which is itself a ref
}

#====================================================================
package 
  Spreadsheet::Edit::OO::RowsTie; # implements @rows and @$sheet
use parent 'Tie::Array';

use Carp;
#our @CARP_NOT = qw(Tie::Indirect Tie::Indirect::Array
#                   Tie::Indirect::Hash Tie::Indirect::Scalar);
use Data::Dumper::Interp;
use Scalar::Util qw(looks_like_number weaken);
sub oops(@) { goto &Spreadsheet::Edit::OO::oops }

sub TIEARRAY {
  my ($classname, $sheet) = @_;
  my $o = bless [ [], $sheet], $classname;
  weaken $o->[1];
  $o
}
sub FETCH {
  my ($this, $index) = @_;
  my $aref = $this->[0];
  croak "Index ",u($index)," is invalid or out of range"
    unless $index >= 0 && $index <= $#$aref;
  $aref->[$index];
}
sub STORE {
  my ($this, $index, $val) = @_;
  my ($aref, $sheet) = @$this;
  croak "Index ",u($index)," is invalid or out of range"
    unless $index >= 0 && $index <= $#$aref+1;
  croak "Value must be a ref to array of cell values (not $val)"
    if ! Spreadsheet::Edit::OO::__looks_like_aref($val);
  croak "Cell values may not be undef"
    if grep{! defined} @$val;
  croak "Cell values must be strings or numbers"
    if grep{ ref($_) && !looks_like_number($_) } @$val;
  if (my $num_cols = $$sheet->{num_cols}) { 
    croak "New row must contain $num_cols cells (not ", $#$val+1, ")"
      if @$val != $num_cols;
  }
  # else (0 or undef) someone promises to set it later
  
  # Store a *copy* of the data to dispose of a Magicrow wrapper, if present
  my $cells = [ @$val ];
  $aref->[$index] = Spreadsheet::Edit::OO::Magicrow->new($sheet, $cells);
}
sub FETCHSIZE { scalar @{ $_[0]->[0] } }
sub STORESIZE {
  my ($this, $newlen) = @_;
  $#{ $this->[0] } = $newlen-1;
}
# End packageSpreadsheet::Edit::OO::RowsTie

#====================================================================
package 
  Spreadsheet::Edit::OO::Magicrow;

use Carp;
our @CARP_NOT = qw(Spreadsheet::Edit::OO);
use Scalar::Util qw(weaken blessed looks_like_number);
sub oops(@) { goto &Spreadsheet::Edit::OO::oops }
use Data::Dumper::Interp;

sub new {
  my ($classname, $sheet, $cells) = @_;
  my %hashview; tie %hashview, __PACKAGE__, $cells, $sheet;
  bless \ [$cells, \%hashview], $classname;
}
use overload  '@{}' => sub { ${ shift() }->[0] },
              '%{}' => sub { ${ shift() }->[1] },
              #'""'  => sub { shift }, # defeats vis overload eval!
  #'0+' => sub { shift },
  #'==' => sub { my ($self, $other, $swap) = @_; $self == $other },
  #'eq' => sub { my ($self, $other, $swap) = @_; "$self" eq "$other" },
              fallback => 1, # for "" etc. FIXME: is this really ok?
              ;

sub TIEHASH { 
  my ($pkg, $cells, $sheet) = @_;
  my $o = bless \ [$cells, $sheet], $pkg; 
  weaken $$o->[1];
  $o
}
sub _cellref {
  my ($cells, $sheet) = @{ ${ shift() } };  # First arg is 'self'
  my $key = shift;                          # Second arg is key
  my $mutating = @_;                        # Third arg exists only for STORE
  my $colx = $$sheet->{colx};
  my $cx = $colx->{$key};
  if (! defined $cx) {
    $sheet->_autodetect_title_rx_ifneeded_cl1();
    $cx = $colx->{$key};
  }
  if (! defined $cx) {
    exists($colx->{$key})
      or croak "'$key' is an unknown COLSPEC.  The valid keys are:\n",
               $sheet->_fmt_colx();
    # Undef colx results from alias({optional => TRUE},...) which failed,
    # or from an alias which became invalid because the column was deleted.
      croak "Attempt to write to 'optional' alias '$key' which is currently NOT DEFINED"
        if $mutating;
    return \undef # Reading such a column returns undef
  }
  $cx <= $#{$cells}
    // croak "BUG?? key '$key' maps to cx $cx which is out of range!";
  \$cells->[$cx] 
}
sub FETCH {
  ${ &_cellref }
}
sub STORE {
  my $r = &_cellref;
  $$r = shift;
}
sub NEXTKEY {
  my (undef, $sheet) = @{ ${ shift() } };
  each %{ $$sheet->{colx} }
}
sub FIRSTKEY {
  my (undef, $sheet) = @{ ${ shift() } };
  my $colx = $$sheet->{colx};
  my $a = scalar keys %$colx;  # reset iterator
  each %$colx;
}
sub EXISTS {
  my (undef, $sheet) = @{ ${ shift() } };
  my $key = shift;
  exists $$sheet->{colx}->{$key}
}
sub SCALAR {
  my (undef, $sheet) = @{ ${ shift() } };
  scalar %{ $$sheet->{colx} }
}
sub DELETE { confess "DELETE not allowed for ".__PACKAGE__ }
sub CLEAR  { confess "CLEAR not allowed for ".__PACKAGE__ }

# End package Spreadsheet::Edit::OO::Magicrow;
#====================================================================

1;

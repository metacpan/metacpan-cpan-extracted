# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and
# related or neighboring rights.  Attribution is requested but is not required.

# Pod documentation is below (use perldoc to view)

use strict; use warnings FATAL => 'all'; use utf8;
use feature qw(say state lexical_subs);
no warnings qw(experimental::lexical_subs);

package Spreadsheet::Edit;
our $VERSION = '3.005'; # VERSION from Dist::Zilla::Plugin::OurPkgVersion
our $DATE = '2023-04-04'; # DATE from Dist::Zilla::Plugin::OurDate

# TODO FIXME: Integrate with Spreadsheet::Read and provide a formatting API
#
# TODO: Need api to *read* options without changing them

# TODO: Allow & support undef cell values (see Text::CSV_XS), used to
#       represent "NULL" when interfacing with database systems.
#       OTOH, this conflicts with failed optional alias keys

# TODO: Add some way to exit an apply() early, e.g. return value?
#       or maybe provide an abort_apply(resultval) function
#       which throws an exception we can catch in apply?

# TODO: Use Tie::File to avoid storing entire sheet in memory
# (requires seekable, so must depend on OpenAsCsv
# copying "-" to a temp file if it is not a plain file).

#########################################
# sub NAMING CONVENTION:
#   sub public_method_or_function
#   sub _internal_method
#   sub __internal_function
#########################################

# If these globals are *defined* then the corresponding
# (downcased) options default accordingly when new sheets are created.
our ($Debug, $Verbose, $Silent);

############################## Exporting stuff ############################
#
use Exporter::Tiny 1.001_000 (); # just to require version with non-sub generator support
use parent "Exporter::Tiny";         # make us be a derived class

require mro; # makes next::can available

sub import {
  # copied from List::Util
  # (RT88848) Touch the caller's $a and $b, to avoid the warning of
  #   'Name "main::a" used only once: possible typo'
  my $pkg = caller;
  no strict 'refs';
  ${"${pkg}::a"} = ${"${pkg}::a"};
  ${"${pkg}::b"} = ${"${pkg}::b"};

  my $this = $_[0];
  goto &{ $this->next::can }; # see 'perldoc mro'
  #goto &maybe::next::method ; ???
}

use Symbol qw/gensym/;

our @EXPORT = qw(
  alias apply apply_all apply_exceptrx apply_torx attributes
  spectocx data_source delete_col delete_cols delete_row delete_rows
  first_data_rx transpose join_cols join_cols_sep last_data_rx move_col
  move_cols insert_col insert_cols insert_row insert_rows new_sheet only_cols
  options read_spreadsheet rename_cols reverse_cols
  sheet sheetname sort_rows split_col tie_column_vars title2ident title_row
  title_rx unalias write_csv write_spreadsheet );

my @stdvars = qw( $title_rx $first_data_rx $last_data_rx $num_cols
                  @rows @linenums @meta_info %colx %colx_desc $title_row
                  $rx $linenum @crow %crow );

our @EXPORT_OK = (@stdvars, qw/logmsg cx2let let2cx fmt_sheet/);

our %EXPORT_TAGS = (
      STDVARS => [@stdvars],
      FUNCS   => [@EXPORT],
      default => [':FUNCS'],
      DEFAULT => [':default'],
      #all     => [qw(:STDVARS :FUNCS cx2let let2cx logmsg)],
      all     => [qw(:STDVARS :FUNCS)],
);

# Although the magic globals $row, $rx and friends are "imported" by 'use',
# they can not simply alias variables in Spreadsheet::Edit becuase they
# need to be tied with parameters specific to the user's package
# so that each package has its own 'current sheet'.
#
# To accomplish this, we use Exporter:Tiny's "generator" mechanism to
# create a new, unique variables tied appropriately for each import.
# See perldoc Exporter::Tiny::Manual::QuickStart .
#
# If "methods" named _generate_SUBNAME, _generateScalar_SCALARNAME,
# _generateArray_ARRAYNAME or _generateHash_HASHNAME exist in the
# exporting package (that's us), then they are called to obtain
# a ref to an object to export as SUBNAME, SCALARNAME, ARRAYNAME or HASHNAME.
#
# For example _generateScalar_rx() is called to get a ref to an $rx variable.

sub __gen_x {
  my ($myclass, $sigilname, $args, $globals,  # supplied by Exporter::Tiny
      $Type, $helpersub, @args) = @_;
  my $sigl = $Type eq 'Hash' ? '%' : $Type eq 'Array' ? '@' : '$';
  my $tieclassname = 'Tie::Indirect::'.$Type;
  my $ref = *{gensym()}{uc($Type)}; # e.g. "ARARY"
  # e.g.  tie $$ref, 'Tie::Indirect::Scalar', \&_scal_tiehelper, ...
  eval "tie ${sigl}\$ref, \$tieclassname, \$helpersub,
           \$globals->{into}, \$sigilname, \@args";
  die $@ if $@;
  $ref
}
sub __gen_scalar {
  my ($myclass, $sigilname, $args, $globals,
      $canon_ident, $onlyinapply) = @_;
  __gen_x($myclass, $sigilname, $args, $globals,
          "Scalar", \&Spreadsheet::Edit::_scal_tiehelper,
          $canon_ident, $onlyinapply);
}
sub _generateScalar_num_cols      { __gen_scalar(@_, "num_cols") }
sub _generateScalar_first_data_rx { __gen_scalar(@_, "first_data_rx") }
sub _generateScalar_last_data_rx  { __gen_scalar(@_, "last_data_rx") }
sub _generateScalar_rx            { __gen_scalar(@_, "current_rx", 1) }

#sub _generateScalar_title_rx      { __gen_scalar(@_, "title_rx") }
sub _generateScalar_title_rx      {
  __gen_x(@_, "Scalar",
          sub{
            my ($mutating, $pkg, $uvar, $onlyinapply)=@_;
            my $sheet = &Spreadsheet::Edit::__getsheet(@_);
            \$$sheet->{title_rx}
          }, 0 # onlyinapply
         )
}

sub __gen_aryelem {
  my ($myclass, $sigilname, $args, $globals,
      $index_ident, $array_ident, $onlyinapply) = @_;
  # N.B. _aryelem_tiehelper has special logic for 'current_rx' and 'title_rx'
  __gen_x($myclass, $sigilname, $args, $globals,
          "Scalar", \&Spreadsheet::Edit::_aryelem_tiehelper,
          $index_ident, $array_ident, $onlyinapply);
}
sub _generateScalar_title_row     { __gen_aryelem(@_, "title_rx", "rows") }
sub _generateScalar_linenum { __gen_aryelem(@_, "current_rx", "linenums", 1) }

sub __gen_hash {
  my ($myclass, $sigilname, $args, $globals,
      $field_ident, $onlyinapply) = @_;
  __gen_x($myclass, $sigilname, $args, $globals,
          "Hash", \&Spreadsheet::Edit::_refval_tiehelper,
           $field_ident, $onlyinapply, 0); # mutable => 0
}
sub _generateHash_colx { __gen_hash(@_, "colx", 0) }
sub _generateHash_colx_desc { __gen_hash(@_, "colx_desc", 0) }

sub __gen_array{
  my ($myclass, $sigilname, $args, $globals,
      $field_ident, $onlyinapply, $mutable) = @_;
  __gen_x($myclass, $sigilname, $args, $globals,
          "Array", \&Spreadsheet::Edit::_refval_tiehelper,
           $field_ident, $onlyinapply, $mutable);
}
sub _generateArray_rows     { __gen_array(@_, "rows", 0, 1) }

# Currently @linenums is not mutable but maybe it should be?
sub _generateArray_linenums { __gen_array(@_, "linenums", 0) }

## FIXME: is meta_info still valid?
sub _generateArray_meta_info { __gen_array(@_, "meta_info", 0) }

sub __get_currentrow {
  my ($mutating, $pkg, $uvar) = @_;
  # Ignore mutating, as it applies to the element not the container
  my $sheet = &Spreadsheet::Edit::__getsheet(0, $pkg, $uvar, 1);
  # Returns the dual-typed ref (Magicrow) for the current row
  $$sheet->{rows}->[$$sheet->{current_rx}]
}
sub _generateArray_crow {  # @crow aliases the current row during apply
  my ($myclass, $sigilname, $args, $globals) = @_;
  my $aref = *{gensym()}{ARRAY};
  tie @$aref, 'Tie::Indirect::Array',
              \&__get_currentrow, $globals->{into}, $sigilname ;
  $aref
}
sub _generateHash_crow {  # %crow indexes cells in the current row during apply
  my ($myclass, $sigilname, $args, $globals) = @_;
  my $href = *{gensym()}{HASH};
  tie %$href, 'Tie::Indirect::Hash',
              \&__get_currentrow, $globals->{into}, $sigilname ;
  $href
}
#
########################### End of Exporting stuff ##########################

#use Data::Dumper::Interp 5.000;
use Data::Dumper::Interp;

use Carp;
our @CARP_NOT = qw(Spreadsheet::Edit
                   Tie::Indirect::Array Tie::Indirect::Hash
                   Tie::Indirect::Scalar
                  );

use Scalar::Util qw(looks_like_number openhandle reftype refaddr blessed);
use List::Util qw(min max sum0 first any all pairs pairgrep);
use File::Temp qw(tempfile tempdir);
use File::Basename qw(basename dirname fileparse);
use Symbol qw(gensym);
use POSIX qw(INT_MAX);
use Guard qw(scope_guard);

require Tie::Indirect; # OUR CUSTOM STUFF: stop using it?

use Text::CSV 1.90_01; # 1st version with known_attributes()
use Spreadsheet::Edit::IO qw(
   OpenAsCsv @sane_CSV_read_options @sane_CSV_write_options
   convert_spreadsheet);

sub oops(@) { unshift @_, "oops - "; goto &Carp::confess; }

my $mypkg = __PACKAGE__;

use constant _CALLER_OVERRIDE_CHECK_OK =>
     (! defined(&Carp::CALLER_OVERRIDE_CHECK_OK) 
      || &Carp::CALLER_OVERRIDE_CHECK_OK);

sub __mytraceback() {
  my $foldwidth = 80;
  my $indent = "  ";
  my $s = "";
  for (my $lvl=1 ; ; ++$lvl) {
    # A Perl panic sometimes occurs because element(s) of @DB::args are
    # freed, due to a refcounting bug somewhere.  It seems, at least for us,
    # to be related to args-less calls like &__self ;  Avoiding referencing
    # @DB::args if hasargs is not true seems to circumvent this.
    # https://github.com/Perl/perl5/issues/11758#issuecomment-1430576569
    # Carp has some work-arounds like pre-setting DB::args 
    # to "a sentinel which no-one else has the address of" and using eval;
    # there are some contentious bugreps about this; see comments in Carp.pm 
    @DB::args = \$lvl if _CALLER_OVERRIDE_CHECK_OK; # work-around from Carp
    my ($pkg, $fname, $lno, $called_subr,$hasargs,$wantarray,$evaltext) =
      do{ package
            DB; caller($lvl) };
    last if !defined($pkg);
    my $calling_subr = (caller($lvl+1))[3];
    ($fname //= "") =~ s#.*/##;
    $lno //= "";
    foreach ($calling_subr, $called_subr) {
      s/^\Q${mypkg}::\E// if defined;
    }

    my $line1 = $indent.($lvl-1).": ";
    if ($called_subr eq '(eval)') {
      $line1 .= defined($evaltext) ? "eval ".vis($evaltext) : "eval{...}";
    }
    elsif (! $hasargs) {
      $line1 .= '&'.$called_subr;
    } else {
      my @args = eval { @DB::args };
      $line1 .= $called_subr.($@ ? "(sorry: perl bug prevents arg retrieval)"
                                 : avis(@args));
    }

    my $line2 = " called".($calling_subr ? " from $calling_subr" : "")
               ." at ${fname}:${lno}";

    $s .= "\n" if $s ne "";
    $s .= (length($line1)+length($line2) <= $foldwidth)
            ? $line1.$line2 : $line1."\n".$indent." ".$line2;
  }
  $s .= "\n";
}

use constant DEFAULT_WRITE_ENCODING => 'UTF-8';
#use constant DEFAULT_READ_ENCODINGS => 'UTF-8,windows-1252';

# This global is used by logmsg() to infer the current sheet if an apply is
# active, even if logmsg is called indirectly via another pkg
our $_inner_apply_sheet;  # see &_apply_to_rows

# The "current sheet", to which tied globals refer in any given package.
our %pkg2currsheet;

sub __looks_like_aref($) { eval{ 1+scalar(@{$_[0]}) } } #actual or overloaded

# Utility FUNCTIONS
#
sub to_array(@)  { @_ != 1 ? @_   # 0 or multiple values
                   : ref($_[0]) eq "ARRAY" ? @{$_[0]}
                   : ref($_[0]) eq "HASH"  ? @{ %{$_[0]} } # (key, value, ...)
                   : $_[0]        # just 1 value
                 }
sub to_aref(@)   { [ to_array(@_) ] }
sub to_wanted(@) { goto &to_array if wantarray; goto &to_aref }

sub to_hash(@)   {
  @_==1 && ref($_[0]) eq "HASH" ? $_[0] :
  (@_ % 2)!=0 ? croak("odd arg count, expecting key => value pairs") :
  { to_array(@_) }
}

sub cx2let(_) { # default arg is $_
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

# Produce the "automatic alias" identifier for an arbitrary title
sub title2ident($) {
  local $_ = shift;
  s/^\s+//;  s/\s+$//;  s/\W/_/g;  s/^(?=\d)/_/;
  $_
}

# Get a Data::Dumper::Interp object configured to not show objects.
sub __DDInew() {
  my ($href) = @_;
  # Data::Dumper::Interp v5.000 has the Objects feature which never
  # shows object internals, but earlier versions had an Overloads feature
  # which only used operators overloaded by an object; in the latter case 
  # limit depth
  # (VERSION is undef in my development version)
  if ( ($Data::Dumper::Interp::VERSION//5.000) >= 5.000 ) {
    visnew()->Foldwidth(40)->Objects(1)
  } else {
    visnew()->Foldwidth(40)->Overloads(1)->Maxdepth(1)
  }
}

# Format list as "word,word,..." without parens ;  Non-barewords are "quoted".
sub __fmt_uqlist(@) { join(",",map{quotekey} @_) }
sub __fmt_uqarray(@) { "(" . &__fmt_uqlist . ")" }

# Format list as without parens with barewords in qw/.../
sub __fmt_uqlistwithqw(@) {
  my $barewords;
  my $s = "";
  foreach (map{quotekey} @_) {
    if (/^\w/) {
      if ($barewords++) {
        $s .= " ";
      } else {
        $s .= ", " if $s;
        $s .= "qw/";
      }
    } else {
      if ($barewords) {
        $s .= "/";
        $barewords = 0;
      }
      $s .= ", " if $s;
    }
    $s .= $_;
  }
  $s .= "/" if $barewords;
  $s
} 
sub __fmt_uqarraywithqw(@) { "(" . &__fmt_uqlistwithqw . ")" }

# Format list of pairs as "key1 => val1, key2 => val2, ..."  without parens
sub __fmt_pairlist(@) {
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
sub __fmt_pairs(@) {
  __fmt_pairlist( map{ @$_ } @_ );
}

# Concatenate strings separated by spaces, folding as necessary
# (strings are never broken; internal newlines go unnoticed).
# All lines (including the first) are indented the specified number of
# spaces.  Explicit line-breaks may be included as "\n".
# A final newline is *not* included unless the last item ends with "\n".
sub __fill($;$$) {
  my ($items, $indent, $foldwidth) = @_;
  $indent    //= 4;
  $foldwidth //= 72;
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

sub __fmt_colspec_cx($$) {
  # "cx NN" or "COLSPEC [cx NN]" or "COLSPEC (NOT DEFINED)" if undef cx
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
sub __fmt_cx($) {
  my ($cx) = @_;
  defined($cx) ? "cx $cx=".cx2let($cx) : "(undefined)"
}

# Format %colx keys "intelligently".  cx values are not shown for keys which are
# absolute column refs.  Keys with undef values (from alias {optional => 1})
# are omitted since they are not currently valid.  A final newline IS included.
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
        push @items, $$_; # \"string" means insert "string" literally
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

# Is a title a special symbol or looks like a cx number?
sub __unindexed_title($$) {
  my ($title, $num_cols) = @_;
oops unless defined $title;
  $title eq ""
  || $title eq '^'
  || $title eq '$'
  || ( ($title =~ /^[1-9]\d*$/ || $title eq "0") # not with leading zeros
       && $title <= $num_cols )
}
sub _unindexed_title { #method for use by tests
  my $self = shift;
  __unindexed_title(shift(), $$self->{num_cols});
}

# Return (normals, unindexed) where each is [title => cx, ...] sorted by cx
sub _get_usable_titles { 
  my $self = shift;
  my ($rows, $title_rx, $num_cols) = @$$self{qw{rows title_rx num_cols}};
  my $title_row = $rows->[$title_rx // oops];
  my @unindexed;
  my @normals;
  my %seen;
  for my $cx (0 .. $num_cols-1) {
    my $title = $title_row->[$cx];
    next if $title eq "";
    if ($seen{$title}++) {
      $self->_carponce("Warning: Non-unique title ", visq($title), " will not be usable for COLSPEC\n") unless $$self->{silent};
      @normals = grep{ $_->[0] ne $title } @normals;
      @unindexed = grep{ $_->[0] ne $title } @unindexed;
      next;
    }
    if (__unindexed_title($title, $num_cols)) {
      push @unindexed, [$title, $cx];
    } else {
      push @normals, [$title, $cx];
    }
  }
  [sort { $a->[1] <=> $b->[1] } @normals],
    [sort { $a->[1] <=> $b->[1] } @unindexed]
}

# Non-OO api: Explicitly create a new sheet and make it the "current sheet".
# Options (e.g. to specify initial content) may be specified in an
# initial {OPTHASH} and/or as linear key => value pairs.
#
# Note: Most functions automatically create an empty sheet if no sheet
# exists, so this is only really needed when using more than one sheet
# or if you want to initialize a sheet from data in memory.
# N.B. the corresponding OO interface is Spreadsheet::Edit->new(...)
#
sub new_sheet(@) {
  my $opthash = &__opthash;
  my %opts = (%$opthash, %{to_hash(@_)}); # new() merges these anyway

  my ($userpkg, $fn, $lno, $subname) = @{ __filter_frame(__usercall_info()) };

  $userpkg = delete $opts{package} if exists $opts{package};
  croak "Invalid 'package' ",u($userpkg),"\n"
    unless defined($userpkg) && $userpkg =~ /^[a-zA-Z][:\w]*$/a;

  $opts{data_source} ||= "Created at ${fn}:$lno by $subname";

  my $sheet = __silent_new(\%opts);

  if ($$sheet->{verbose}) {
    __logmethret([$opthash,@_], $sheet);
  }

  $pkg2currsheet{$userpkg} = $sheet
}

# logmsg() - Concatenate strings to form a "log message", possibly
#   prefixed with a description of a "focus" sheet and optionally
#   a specific row.  A final \n is appended if needed.
#
# The "focus" sheet and row, if any, are determined as follows:
#
#   If the first argument is a sheet object, [sheet_object],
#   [sheet_object, rx], or [sheet_object, undef] then the indicated
#   sheet and (optionally) row are used.  Note that if called as a method
#   the first arg will be the sheet object.
#
#   Otherwise the first arg is not special and is included in the message.
#
#   If no sheet is identified above, then the caller's package active
#   sheet is used, if any.
#
#   If still no sheet is identified, then the sheet of the innermost apply
#   currently executing (anywhere up the stack) is used, if any; this sheet
#   is internally saved in a global by the apply* methods.
#
#   If a sheet is identified but no specific rx, then the
#   "current row" of an active apply on that sheet is used, if any.
#
# If a focus sheet or sheet & row were identified, then the caller-supplied
# message is prefixed by "(<description>):" or "(row <num> <description>):"
# where <description> comes from:
#
#   1) If the sheet attribute {logmsg_pfx_gen} is defined to a subref,
#      the sub is called and all returned items other than undef are
#      concatenated (any undefs in the returned list are ignored); otherwise
#
#   2) The "sheetname" property is used, if defined; otherwise
#
#   3) the "data_source" property is used, which defaults to the name of the
#      spreadsheet read by read_spreadsheet().
#
# FIXME: I should either rename logmsg_pfx_gen as logmsg_sheetdesc_gen
#        to reflect that it only generated the sheet-description part,
#        or else make prefix generators produce the entire message prefix
#        including any row number.
#
sub _default_pfx_gen($$) {
  my ($sheet, $rx) = @_;
  confess "bug" unless ref($sheet) =~ /^Spreadsheet::Edit\b/;
  ($sheet->sheetname() || $sheet->data_source())
}
sub logmsg(@) {
  my ($sheet, $rx);
  if (@_ > 0 && ref($_[0])) {
    if (ref($_[0]) =~ /^Spreadsheet::Edit\b/) {
      $sheet = shift;
    }
    elsif (ref($_[0]) eq "ARRAY"
           && @{ $_[0] } <= 2
           && ref($_[0]->[0])."" =~ /^Spreadsheet::Edit\b/) {
      ($sheet, $rx) = @{ shift @_ };
    }
  }
  if (! defined $sheet) {
    $sheet = $pkg2currsheet{scalar(caller)};
  }
  if (! defined $sheet) {
    $sheet = $Spreadsheet::Edit::_inner_apply_sheet;
  }
  if (! defined $rx) {
    $rx = eval{ $sheet->rx() } if defined($sheet);
  }
  my @prefix;
  if (defined $sheet) {
    push @prefix, "(";
    if (defined($rx) && ($rx < 0 || $rx > $#{$sheet->rows})) {
      push @prefix, "Row ".($rx+1)."[INVALID RX $rx] ";
      $rx = undef; # avoid confusing user's prefix generator
    } else {
      push @prefix, "Row ".($rx+1)." " if defined($rx);
    }
    my $pfxgen = $sheet->attributes->{logmsg_pfx_gen} // \&_default_pfx_gen;
    push @prefix, (&$pfxgen($sheet, $rx)), "): ";
  }
  my $suffix = (@_ > 0 && $_[-1] =~ /\n\z/s ? "" : "\n");
  return join "", grep{defined} @prefix, @_, $suffix;
}

#####################################################################
# Locate the nearest call to a public method/function in the call stack.
#
# Basically we search for a call to any of our subs with a name not starting
# with underscore, excluding a few public utilities we might call internally.
#
# RETURNS
#   ([frame], [called args]) in array context
#   [frame] in scalar context
#
# "frame" means caller(n) results:
#   0       1        2       3
#   package filename linenum subname ...
#
sub __usercall_info() {
  for (my $lvl=1 ; ; ++$lvl) {
    @DB::args = \$lvl if _CALLER_OVERRIDE_CHECK_OK; # see mytraceback()
    my @frame = do{ package
                      DB; caller($lvl) };
    oops dvis('$lvl @frame') unless defined($frame[0]);
    if ($frame[3] =~ /^\Q${mypkg}::\E([a-z][^:]*)/
         # && $1 ne "internal_utility_1" ...
         # && $1 ne "internal_utility_2" ...
       ) {
      return \@frame unless wantarray;
      my @args;
      my $hasargs = $frame[4];
      if ($hasargs) {
        eval{ @args = @DB::args }; 
        @args=() if $@; # perl bug?
      }
      return (\@frame, \@args)
    }
  }
}

sub __filter_frame($) { #clean-up/abbreviate for display purposes
  my @frame = @{shift @_};
  $frame[1] = basename $frame[1]; # filename
  $frame[3] =~ s/.*:://;          # subname
  \@frame
}
sub __fn_ln_methname() {
  @{ __filter_frame(__usercall_info()) }[1,2,3]; # (fn, lno, subname)
}

sub __methname() {
  (&__fn_ln_methname())[2]
}

sub __find_userpkg() {
  ${ __usercall_info() }[0];
}

# This always returns the caller's caller's package but also 
# checks that it is not an internal call, which should never happen
sub __callerpkg() {
  my $pkg = (caller(1))[0];
  oops if $pkg =~ /^$mypkg/;
  $pkg
}

# Create a new object without allowing any logging.  This is used when
# new() is called implicitly by something else and new's log messages
# might display an internal filename (namely Edit.pm).
#
# debug/verbose args are removed from the arguments passed to new()
# and put back into the object after it is created.
sub __silent_new(@) {
  my $opthash = &__opthash; 
  my $new_args = to_hash(@_);

  my %saved;
  foreach my $key (qw/verbose debug/) {
    $saved{$key} = $opthash->{$key} if exists($opthash->{$key});
    $opthash->{$key} = 0; # force off
    $saved{$key} = delete($new_args->{$key}) if exists($new_args->{$key});
  } 

  my $self = Spreadsheet::Edit->new($opthash, %$new_args);

  delete @$$self{qw/verbose debug/};
  $self->_set_verbose_debug_silent(%saved);

  $self
}

#####################################################################
# Get "self" for a function/method combo sub:
#   If the first arg is an object ref we shift it off and use that
#   (i.e. assume it is called as a method); otherwise we assume it's a
#   functional-API function call and use the caller's "current sheet"
#   (if none exists, __self creates one but __selfmust throws).
#
# This must be used with special syntax like
#    my $self = &__self;
# which re-uses @_ so we can shift @_ as seen by our caller.

sub __self_ifexists {

  # If the first arg is an object ref, shift it off and return it;
  # Otherwise, if the caller's "current sheet" exists, return that;
  # otherwise return undef.

  (defined(blessed($_[0])) && $_[0]->isa(__PACKAGE__) && shift(@_))
    || $pkg2currsheet{__find_userpkg()};
}
sub __selfmust { # sheet must exist, otherwise throw
  &__self_ifexists || do{
    my $pkg = caller(1);
    croak __methname()," : No sheet is defined in $pkg\n"
  };
}

sub __self { # a new empty sheet is created if necessary
  &__self_ifexists || do{
    # Create a new empty sheet and make it the caller's "current sheet".
    my %opts;
    my ($frame, $args) = __usercall_info();

    my ($userpkg, $fn, $lno, $subname) = @{ __filter_frame($frame) };
    $opts{data_source} = "(Created implicitly by $subname at ${fn}:$lno)";
    
    my $self = $pkg2currsheet{$userpkg} = __silent_new(\%opts);
    $self
  }
}


## Helpers...

sub __opthash { 
  ref($_[0]) eq "HASH" ? shift(@_) : {} 
}
sub __selfmust_opthash {
  my $self = &__selfmust;
  my $opthash = &__opthash;
  ($self, $opthash)
}
sub __self_opthash {
  my $self = &__self;
  my $opthash = &__opthash;
  ($self, $opthash)
}
sub __selfonly {
  my $self = &__self;
  confess __methname, " expects no arguments!\n" if @_;
  $self
}
sub __selfmustonly {
  my $self = &__selfmust;
  confess __methname, " expects no arguments!\n" if @_;
  $self
}

sub __self_opthash_Nargs($@) {  # (num_expected_args, @_)
  my $Nargs = shift;
  my ($self, $opthash) = &__self_opthash;
  #croak
  croak __methname, " expects $Nargs arguments, not ",scalar(@_),"\n"
    if $Nargs != @_;
  ($self, $opthash, @_)
}
sub __self_opthash_0args { unshift @_,0; goto &__self_opthash_Nargs }
sub __self_opthash_1arg  { unshift @_,1; goto &__self_opthash_Nargs }
sub __self_opthash_2args { unshift @_,2; goto &__self_opthash_Nargs }
sub __self_opthash_3args { unshift @_,3; goto &__self_opthash_Nargs }

# Check that an option hash has only valid keys, and values aren't undef
sub __validate_opthash($$;@) {
  my ($opthash, $valid_keys, %opts) = @_;
  return unless defined $opthash; # silently accept undef
  foreach my $k (keys %$opthash) {
    croak "Unrecognized ",($opts{desc}//"option")," '$k'"
      unless first{$_ eq $k} @$valid_keys;
    confess "Option '$k' must be defined"
      if $opts{undef_ok} && !defined($opthash->{$k})
                         && !grep{$_ eq $k} @{$opts{undef_ok}};
  }
  $opthash
}

# Copy verbose/debug/silent options into $self, deleting them from
# the provided options hash.  
# RETURNS: Hash of original values to pass to _restore_stdopts()
#
# This is used by methods which accept {verbose} etc. options
# which override what is in the object for the duration of that method call.
sub _set_stdopts {
  my ($self, $opthash) = @_;
  my $previous = {};
  foreach my $key (qw/verbose debug silent/) {
    if (exists $opthash->{$key}) {
      $previous->{$key} = $$self->{$key};
      $$self->{$key} = delete($opthash->{$key});
    }
  }
  $previous
}
sub _restore_stdopts {
  my $self = shift;
  my $saved = shift;
  @$$self{keys %$saved} = values %$saved;
}

sub _validate_ident($) {
  croak "identifier is undef!" unless defined $_[0];
  croak "identifier is empty"  unless $_[0] ne "";
  croak ivisq '"$_[0]" is not a valid identifier\n'
                               unless $_[0] eq title2ident($_[0]);
  $_[0]
}

# Check that an option hash has only valid keys
sub __validate_4pthash($$;$) {
  my ($opthash, $valid_keys, $optdesc) = @_;
  return unless defined $opthash; # silently accept undef
  foreach my $k (keys %$opthash) {
    croak "Unrecognized ",($optdesc//"option")," '$k'"
      unless first{$_ eq $k} @$valid_keys;
  }
  $opthash
}

sub __validate_nonnegi($;$) {
  croak(($_[1]//"argument")." must be a non-negative integer",
        " (not ".u($_[0]).")")
    unless defined($_[0]) && "$_[0]" =~ /^\d+$/;
  $_[0]
}
sub __validate_nonnegi_or_undef($;$) {
  croak(($_[1]//"argument")." must be a non-negative integer or undef",
        " (not ".u($_[0]).")")
    unless !defined($_[0]) || "$_[0]" =~ /^\d+$/;
  $_[0]
}

sub __validate_pairs(@) {
  unless ((scalar(@_) % 2) == 0) {
    croak __methname," does not accept an {OPTIONS} hash here"
      if (ref($_[0]) eq "HASH");
    confess "In call to ",__methname,
          " : uneven arg count, expecting key => value pairs"
  }
  foreach (pairs @_) {
    my $key = $_->[0];
    confess "In call to ",__methname," the key '$key' looks suspicious"
      unless $key =~ /^\w+$/;
  }
  @_
}

sub _check_rx {
  my ($self, $rx, $one_past_end_ok) = @_;
  confess __methname.": Illegal rx ",vis($rx),"\n"
    unless ($rx//"") =~ /^\d+$/;  # non-negative integer
  my $maxrx = $#{$$self->{rows}};
  confess __methname.": rx ".vis($rx)." is beyond the last row\n"
                    .dvis(' $$self')
    if $rx > ($one_past_end_ok ? ($maxrx+1) : $maxrx);
}

# Diagnose scalar context if there are no results.
sub __first_ifnot_wantarray(@) {
  my $wantarray = (caller(1))[5];
  return @_ if $wantarray;
  return $_[0] if @_;
  croak __methname, " called in scalar context but that method does not return a result.\n"
    if defined($wantarray);
}
sub __validate_not_scalar_context(@) {
  my $wantarray = (caller(1))[5];
  croak __methname, " returns an array, not a scalar"
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

###################### METHODS/FUNCTIONS #######################

# Unlike other methods, new() takes key => value pair arguments.
# For consistency with other methods an initial {OPTIONS} hash is
# also allowed, but it is not special in any way and is merged 
# with any linear args (linear args override {OPTIONS}).

sub new { # Strictly OO, this does not affect caller's "current sheet".
          # The corresponding functional API is new_sheet() which explicitly
          # creates a new sheet and makes it the 'current sheet'.
  my $classname = shift;
  croak "Invalid/missing CLASSNAME (i.e. \"this\") arg" 
    unless defined($classname) && $classname =~ /^[\w_:]+$/;

  my $opthash = &__opthash;
  # Special handling of {cmd_nesting) since there was no object to begin with:
  #   Internal callers may pass this as a "user" option in {OPTARGS}; 
  #   we won't log it, but we plant it into the object below.
  #   **THE CALLER MUST DECREMENT IT LATER IF NEEDED*
  my $cmd_nesting = delete($opthash->{cmd_nesting}) // 0;

  my %opts = (verbose => $Verbose, debug => $Debug, silent => $Silent,
              %$opthash, 
              __validate_pairs(@_));
  
  my $self;
  if (my $clonee = delete $opts{clone}) { # untested as of 2/12/14
    delete @opts{qw/verbose debug silent/};
    croak "Other options not allowed with 'clone': ",hvis(%opts) if %opts;
    require Clone;
    $self = Clone::clone($clonee); # in all its glory
    $$self->{data_source} = (delete $opts{data_source})
                            // "cloned from $$self->{data_source}";
  } else {
    my $hash = {
      attributes       => delete $opts{attributes} // {},
      linenums         => delete $opts{linenums} // [],
      meta_info        => delete $opts{meta_info} // [], ##### ???? obsolete ???
      data_source      => delete $opts{data_source} // "(none)",
      num_cols         => delete $opts{num_cols}, # possibly undef

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

    # We can not use $hash directly as the object representation because %{}
    # is overloaded, so we use a scalar ref (pointing to the hashref)
    # as the object.
    $self = bless \$hash, $classname;

    # Create a tied virtual array which creates Magicrows when assigned to.
    my @rows; tie @rows, 'Spreadsheet::Edit::RowsTie', $self;
    $hash->{rows} = \@rows;

    if (my $newdata = delete $opts{rows}) {
      foreach (@$newdata) {
        push @rows, $_;
      }
    }
  }# not cloning

  $$self->{cmd_nesting} = $cmd_nesting;

  $self->_set_verbose_debug_silent(%opts); # croaks if other keys remain

  # Validate data, default num_cols, pad rows, etc.
  $self->_rows_replaced();

  $self->_logmethretifv([$opthash,@_], $self);

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
  $self->_rebuild_colx; # Set up colx colx_desc
  $self
}#_rows_replaced

#########################################################
# Combination FUNCTION/METHOD
#   These are declared with signatures for use as functional-API FUNCTIONs
#   which use the caller's "current sheet" as the implicit object.
#
#   However they may also be called as METHODs with an explicit object.
#########################################################

# Allow user to find out names of tied variables
sub tied_varnames(;@) {
  my ($self, $opts) = &__selfmust_opthash;
  my $pkg = $opts->{package} // __callerpkg();
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

#say "#_tie(@_)# ", __mybacktrace;

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
      $self->_log(" Previously tied: \$${pkg}::${ident}\n") if $debug;
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

    $self->_log("tie \$${pkg}::${ident} to $desc\n") if $debug;

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
    $valid_idents{ title2ident($_) } = 1;
  }
  return keys %valid_idents;
}

sub tie_column_vars(;@) {
  my ($self, $opts) = &__self_opthash;
  # Any remaining args specify variable names matching
  # alias names, either user-defined or automatic.

  croak "tie_column_vars without arguments (did you intend to use ':all'?)"
    unless @_;

  local $$self->{silent}  = $opts->{silent} // $$self->{silent};
  local $$self->{verbose} = $opts->{verbose} // $$self->{verbose};
  local $$self->{debug}   = $opts->{debug} // $$self->{debug};

  my $pkg = $opts->{package} // __callerpkg();

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
  # When ':safe' is combined with ':all', variables will not be checked & tied
  # except during compile time, i.e. within BEGIN{...}.  Therefore a
  # malicious spreadsheet can not cause an exception after the compilation
  # phase.
  my $safe = delete $tokens{':safe'};
  my ($file, $lno) = __fn_ln_methname();
  my $parms = [$safe, $file, $lno];

  # Why? Obsolete? Only for :all?? [note added Dec22]
  # FIXME TODO: is this bogus?
  $self->title_rx($opts->{title_rx}) if exists $opts->{title_rx};

  if (delete $tokens{':all'}) {
    # Remember parameters for tie operations which might occur later
    $$self->{pkg2tieall}->{$pkg} = $parms;

    push @varnames, sort $self->_all_valid_idents;
  }
  croak "Unrecognized token in arguments: ",avis(keys %tokens) if %tokens;

  my $r = $self->_tie_col_vars($pkg, $parms, @varnames);

  my $pfx = ($r == __TCV_REDUNDANT ? "[ALL REDUNDANT] " : "");
  $self->_logmethifv(\$pfx,\__fmt_uqarraywithqw(keys %tokens, @varnames), \" in package $pkg");
}#tie_column_vars

#
# Accessors for misc. sheet data
#

sub attributes(@) { ${&__selfonly}->{attributes} }
sub colx() { ${&__selfmustonly}->{colx} }
sub colx_desc() { ${&__selfmustonly}->{colx_desc} }
sub data_source(;$) {
  my $self = &__selfmust;
  if (@_ == 0) { # 'get' request
    $self->_logmethretifv([], $$self->{data_source});
    return $$self->{data_source}
  }
  $self->_logmethifv(@_);
  croak "Too many args" unless @_ == 1;
  $$self->{data_source} = $_[0];
  $self
}
sub linenums() { ${&__selfmustonly}->{linenums} }
sub num_cols() { ${&__selfmustonly}->{num_cols} }
sub rows() { ${&__selfmustonly}->{rows} }
sub sheetname() { ${&__selfmustonly}->{sheetname} }

sub iolayers() { ${&__selfmustonly}->{iolayers} }
sub meta_info() {${&__selfmustonly}->{meta_info} }
sub input_encoding() {
  # Emulate old API.  We actually store input_iolayers instead now,
  # so as to include :crlf if necessary.
  my $self = &__selfmustonly;
  local $_;
  return undef unless
    exists(${$self}->{input_iolayers})
    && ${$self}->{input_iolayers} =~ /encoding\(([^()]*)\)/;
  return $1;
}

# See below for title_rx()
sub title_row() {
  my $self = &__selfmust;
  my $title_rx = $self->title_rx(@_);
  defined($title_rx) ? $$self->{rows}->[$title_rx] : undef
}
sub rx() { ${ &__selfmustonly }->{current_rx} }
sub crow() {
  my $self = &__selfmustonly;
  ${ $self->_onlyinapply("crow() method") }->{rows}->[$$self->{current_rx}]
}
sub linenum() {
  my $self = &__selfmustonly;
  my $current_rx = $$self->{current_rx} // return(undef);
  $$self->{linenums}->[$current_rx];
}
sub _getref {
  my ($self, $rx, $ident) = @_;
  my ($rows, $colx) = @$$self{qw/rows colx/};
  croak "get/set: rx $rx is out of range" if $rx < 0 || $rx > $#$rows;
  my $row = $$self->{rows}->[$rx];
  my $cx = $colx->{$ident};
  oops("Invalid cx ".vis($cx)) if ! defined($cx) || $cx < 0 || $cx > $#$row;
  \$row->[$cx];
}
# get/set a cell given by (rx,COLSPEC)
sub get($$) {
  my $self = &__selfmust;
  my $ref = $self->_getref(@_);
  $$ref;
}
sub set($$$) {
  my $self = &__selfmust;
  my ($rx, $colspec, $newval) = @_;
  my $ref = $self->_getref($rx, $colspec);
  $$ref = $newval;
  $self
}

# Print segmented log messages:
#   Join args together, prefixing with "> " or ">> " etc.
#   unless the previous call did not end with newline.
# Maintains internal state.  A final call with an ending \n must occur.
sub _log {
  my $self = shift;
  state $in_midst;
  print STDERR join "",
                    ($in_midst ? "" : (">" x ($$self->{cmd_nesting}||1))),
                    map{u} @_;
  $in_midst = ($_[$#_] !~ /\n\z/s);
}

# Format a usually-comma-separated list sans enclosing brackets.
#
# Items are formatted by vis() and thus strings will be "quoted", except that
# \"ref to string" inserts the string value without quotes and suppresses
# adjacent commas (for inserting fixed annotations).
# Object refs in the top two levels are not visualized.
#
# If the arguments are recognized as a sequence then they are formatted as
# Arg0..ArgN instead of Arg1,Arg2,...,ArgN.
#
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

sub __validate_sheet_arg($) {
  my $sheet = shift;
  croak "Argument '${\u($sheet)}' is not a Spreadsheet::Edit sheet object"
    if defined($sheet) and
        !blessed($sheet) || !$sheet->isa("Spreadsheet::Edit");
  $sheet;
}

my $trunclen = 200;
sub fmt_sheet($) {
  my $sheet = __validate_sheet_arg( shift ) // return("undef");
  local $$sheet->{verbose} = 0;
  my $s = $sheet->sheetname() || $sheet->data_source() || "(unk)";
  #if (length($s) > $trunclen) { $s = "...".substr($s,-($trunclen-3)) }
  if (length($s) > $trunclen) { $s = substr($s,($trunclen-3))."..." }
  #sprintf("0x%x (%s)", refaddr($sheet), $s);
  sprintf("%s (%s)", $sheet, $s);
}

# __methretmsg([ITEMS...])
# __methretmsg([ITEMS...], RETVAL)
# __methretmsg([ITEMS...], [RETVALS...])
#
# Returns a message string relating to the current function or method call:
#
#   ">[callers_file:callers_lno] calledsubname ITEMS\n"
# or
#   ">[callers_file:callers_lno] calledsubname ITEMS -> RETURNVALS\n"
#
# with ITEMS and RETURNVALS formatted by fmt_list, with \n unconditionally 
# appended to the overall result.
#
# Special case: The first ITEM is ignored if it is a ref to an empty hash;
#   This assumes the first ITEM is from __opthash and prevents showing {}
#   when the user actually did not pass any {OPTARGS} argument.  
#
sub __methretmsg($;$) {
  my $items = $_[0];
  oops unless ref($items) eq "ARRAY";
  my $showitems =
    (ref($items->[0]) eq "HASH" && !(keys %{$items->[0]}))
       ? [@$items[1..$#$items]] : $items;

  my ($fn, $lno, $subname) = __fn_ln_methname();
  my $msg = ">[$fn:$lno] $subname";
  $msg .= " " if @$showitems;
  if (@_ > 1) {
    my $retvals = to_aref($_[1]);
    oops unless @$retvals;
    $msg .= @$showitems == 0 ? "()" : fmt_list(@$showitems);
    oops "terminal newline in final log item" if $msg =~ /\n"?\z/s;
    $msg .= " -> ";
    $msg .= fmt_list(@$retvals);
  } else {
    $msg .= fmt_list(@$showitems);
  }
  oops "terminal newline should not be included" if $msg =~ /\n"?\z/s;
  $msg."\n"
}
sub __logmethret($$) {
  print STDERR &__methretmsg;
}

sub _methretmsg {
  my $self = shift;
  # Prepend additional ">"s according to {cmd_nesting}
  my $extraprefix = ">" x ($$self->{cmd_nesting});
  $extraprefix . &__methretmsg(@_);
}

sub _logmethret { # returns $self for chaining
  my $self = shift;
  print STDERR $self->_methretmsg(@_);
  $self
}
sub _logmethretifv {
  return unless ${$_[0]}->{verbose};
  goto &_logmethret;
}

#-----------------------------------------------
# Simpler API for when no RETVALs
sub _methmsg(@) { 
  my $self = shift;
  $self->_methretmsg(\@_);
}
sub _logmeth(@) { 
  my $self = shift;
  print STDERR $self->_methretmsg(\@_);
  $self
}
sub _logmethifv {
  return unless ${$_[0]}->{verbose};
  goto &_logmeth;
}
sub __logmeth(@) { 
  print STDERR __methretmsg(\@_);
}
#-----------------------------------------------

sub _call_usercode($$$) {
  my ($self, $code, $cxlist) = @_;

  if (@$cxlist) {
    my $row = $self->crow();
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

# Do apply, handling COLSPEC args.
# If $rxlists or $rxfirst & $rxlast are undef, visit all rows.
sub _apply_to_rows($$$;$$$) {
  my ($self, $code, $cxlist, $rxlist, $rxfirst, $rxlast) = @_;
  my $hash = $$self;
  my ($linenums,$rows,$num_cols,$cl) = @$hash{qw/linenums rows num_cols/};

  croak $self->_methmsg("Missing or incorrect {code} argument")
    unless ref($code) eq "CODE";
  foreach (@$cxlist) {
    if ($_ < 0 || $_ >= $num_cols) {
      croak $self->_methmsg("cx $_ is out of range")
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
  $self
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
#   Titles (if unique)
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

  my sub __putback($$$;$) {
    my ($key, $cx, $desc, $nomasking) = @_;
    if (defined (my $ocx = $colx->{$key})) {
      if ($cx != $ocx) {
        oops if $nomasking; # _get_usable_titles should have screen out
        $self->_carponce("Warning: ", visq($key), " ($desc) is MASKED BY (",
                         $colx_desc->{$key}, ")") unless $silent;
      }
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
    my ($normal_titles, $unindexed_titles) = $self->_get_usable_titles;
    foreach (@$normal_titles) {
      my ($title, $cx) = @$_;
      __putback($title, $cx, __fmt_cx($cx).": Title", 1); # nomasking==1
    }
    # Titles with leading & trailing spaces trimmed off
    foreach (@$normal_titles) {
      my ($title, $cx) = @$_;
      my $key = $title;
      $key =~ s/\A\s+//s; $key =~ s/\s+\z//s;
      if ($key ne $title) {
        __putback($key, $cx, __fmt_cx($cx).": Title sans lead/trailing spaces",1);
      }
    }
    # Automatic aliases
    # N.B. These come from all titles, not just "normal" ones
    foreach (@$normal_titles, @$unindexed_titles) {
      my ($title, $cx) = @$_;
      my $ident = title2ident($title);
      __putback($ident, $cx, __fmt_cx($cx).": Automatic alias for title");
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
      push @results, [$cx, $colx_desc->{$spec}];
      next
    }
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
# Can return multiple results, either from multple args or Regexp multimatch
# In scalar context returns the first result.
sub spectocx(@) { # the user-callable API
  my $self = &__selfmust;
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

sub alias(@) {
  my $self = &__selfmust;
  my $opthash = ref($_[0]) eq 'HASH' ? shift() : {};
  if ($opthash) {
    __validate_opthash($opthash, [qw(optional)],
                       desc => "alias option");
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

    my $cx = eval{ $self->_spec2cx($spec) };
    unless(defined $cx) {
      oops unless $@;
      croak $@ unless $opthash->{optional} && $@ =~ /does not match/is;
      # Always throw on other errors, e.g. regex matches more than one title
    };

    # Log each pair individually
    $self->_logmethifv($opthash, \"$ident => ",\__fmt_colspec_cx($spec,$cx));

    $colx->{$ident} = $cx;
    $colx_desc->{$ident} = "alias for ".__fmt_cx($cx)." (".quotekey($spec).")";
    $useraliases->{$ident} = 1;
    push @cxlist, $cx;
  }
  $self->_rebuild_colx();

  __first_ifnot_wantarray( @cxlist )
}#alias

sub unalias(@) {
  my $self = &__selfmust;
  croak __methname, " does not accept an {OPTIONS} hash\n"
    if ref($_[0]) eq 'HASH';

  my ($colx, $colx_desc, $useraliases)
    = @$$self{qw/colx colx_desc useraliases/};

  foreach (@_) {
    delete $useraliases->{$_} // croak "unalias: '$_' is not a column alias\n";
    $self->_logmethifv(\" Removing alias $_ => ", \$colx_desc->{$_});
    delete $colx->{$_} // oops;
    delete $colx_desc->{$_} // oops;
  }
  $self->_rebuild_colx();
  $self
}

# title_rx: Get/set the title row index
#
#   $rx = title_rx ;    # Retrieve
#
#   title_rx undef      # Set to no titles
#
#   title_rx ROWINDEX   # Set to specified rx
#
#   title_rx 'auto'     # Auto-detect the title row; an exception is thrown
#                       # if a plausible row is not found.
#
#   {OPTARGS} may contain
#     verbose, silent, debug (temporarily override the object's settings)
#
#    Auto-detect options:
#     required => [COLSPEC, ...] # required titles
#     min_rx, max_rx   => NUM    # range of rows which may contain the row
#     first_cx => NUM    # first column ix which must contain a valid title
#     last_cx  => NUM    # last  column ix which must contain a valid title
#
# Note: This is called internally by read_spreadsheet(), passing 'auto'
#   by default.  Therefore users need not call this method explicitly
#   except to change title row or if read_spreadsheet was not used at all.
#
sub title_rx(;$@) {
  my ($self, $opthash_arg) = &__selfmust_opthash;
  my $opthash = { %$opthash_arg }; # make copy so we can modify it
  my @orig_args = @_;

  my $saved_stdopts = $self->_set_stdopts($opthash);
  scope_guard{ $self->_restore_stdopts($saved_stdopts) };

  __validate_opthash( $opthash,
                      [qw(required min_rx max_rx first_cx last_cx)],
                      desc => "autodetect option",
                      undef_ok => [] );
  my $rx = -999;
  if (@_ == 0) {
    # A return value was requested
    croak '{OPTARGS} passed to title_rx with no operator (get request?)'
      if %$opthash;
    $rx = $$self->{title_rx};
    $self->_logmethretifv([], $rx);
  } else {
    # N.B. undef arg means there are no titles
    $rx = shift;
    my $notie = shift() if u($_[0]) eq "_notie"; # during auto-detect probes
    croak "Extraneous argument(s) to title_rx: ".avis(@_) if @_;
    if (defined $rx) {
      if ($rx eq 'auto') {
        $rx = $self->_autodetect_title_rx($opthash);
      }
      elsif ($rx !~ /^\d+$/) {
        croak "Invalid title_rx argument: ", visq($rx);
      }
      elsif ($rx > $#{ $$self->{rows} }) {
        croak "Rx $rx is beyond the end of the data", visq($rx);
      }
    }
    $$self->{title_rx} = $rx;
    $self->_logmethretifv([$opthash_arg, @orig_args], $rx);
    $self->_rebuild_colx($notie);
  }
  $rx;
}#title_rx

sub _autodetect_title_rx {
  my ($self, $opthash) = @_;

  my ($title_rx, $rows, $colx, $num_cols, $verbose, $debug) =
     @$$self{qw(title_rx rows colx num_cols verbose debug)};

  # Filter out titles which can not be used as a COLSPEC
  my @required_specs = $opthash->{required}
                         ? to_array($opthash->{required}) : ();
  croak "undef value in {required}" if grep{! defined} @required_specs;
  @required_specs = grep{ !__unindexed_title($_, $num_cols) } @required_specs;

  my $min_rx   = __validate_nonnegi($opthash->{min_rx}//0, "min_rx");
  my $max_rx   = __validate_nonnegi($opthash->{max_rx}//$min_rx+3, "max_rx");
  $max_rx = $#$rows if $max_rx > $#$rows;

  my $first_cx = __validate_nonnegi($opthash->{first_cx}//0, "first_cx");
  my $last_cx  = __validate_nonnegi($opthash->{last_cx}//INT_MAX, "last_cx");
  $last_cx = $num_cols-1 if $last_cx >= $num_cols;

  my @nd_reasons;
  if ($min_rx > $#$rows) {
    push @nd_reasons, "min_rx ($min_rx) is out of range";
  }
  elsif ($min_rx > $max_rx) {
    push @nd_reasons,
      "min_rx ($min_rx) is greater than max_rx ($max_rx)"
  }
  if ($first_cx >= $num_cols) {
    push @nd_reasons, "first_cx ($first_cx) is out of range"
  }
  elsif ($first_cx > $last_cx) {
    push @nd_reasons,
      "first_cx ($first_cx) is less than last_cx ($last_cx)"
  }

  my $detected;
  unless (@nd_reasons) {
    local $$self->{verbose} = 0; # no logging  during trial and error
    local $$self->{silent}  = 1; # no warnings during trial and error
    RX: for my $rx ($min_rx .. $max_rx) {
      say "#   ",$nd_reasons[-1] if $debug && @nd_reasons;
      say ivis '#autodetect: Trying RX $rx ...' if $debug;

      # Make $rx the title_rx so __specs2cxdesclist() can be used
      # e.g. to handle regex COLSPECS.  Pass special option to not tie
      # user variables yet.
      $self->title_rx($rx, "_notie");
      oops unless $rx == $$self->{title_rx};

      my $row = $rows->[$rx];
      for my $cx ($first_cx .. $last_cx) {
        if ($row->[$cx] eq "") {
          push @nd_reasons, "rx $rx: col ".__fmt_cx($cx)." is empty";
          next RX;
        }
      }
      foreach my $spec (@required_specs) {
        my @list; # A regex might match multiple titles
        eval { @list = $self->_specs2cxdesclist($spec) };
        say ivis '    found $spec in @list' if $debug;
        if (@list == 0) {
          push @nd_reasons, ivis 'rx $rx: Required column \'$spec\' not found';
          next RX
        }
        my @shortlist = grep{ $_->[0] >= $first_cx && $_->[0] <= $last_cx }
                        @list;
        if (@shortlist == 0) {
          push @nd_reasons, ivis 'rx $rx: Matched \'$spec\' but in unacceptable cx '.alvis(map{$_->[0]} @list);
          next RX
        }
        if (! grep{ $_->[1] =~ /title/i } @shortlist) {
          ### ??? Can this actually happen ???
          push @nd_reasons, ivis 'rx $rx: \'$spec\' resolved to something other than a title: '.__fmt_pairs(@shortlist);
          next RX;
        }
        say ivis '    <<cx is within $first_cx .. $last_cx>>' if $debug;
      }
      $detected = $rx;
      last
    }
    $$self->{title_rx} = undef; # will re-do below
  }
  if (defined $detected) {
    if ($verbose) { # should be $debug ??
      my ($fn, $lno, $methname) = __fn_ln_methname();
      print STDERR "[Auto-detected title_rx = $detected at ${fn}:$lno]\n";
    }
    local $$self->{cmd_nesting} = $$self->{cmd_nesting} + 1;
    local $$self->{verbose} = 0; # suppress normal logging
    $self->title_rx($detected);  # shows collision warnings unless {silent}
    return $detected;
  } else {
    if (@nd_reasons == 0) {
      push @nd_reasons, ivis '(BUG?) No rows checked! num_cols=$num_cols rows=$$self->{rows}'.dvis '\n##($min_rx $max_rx $first_cx $last_cx)' ;
    }
    croak("In ",qsh($$self->{data_source})," ...\n",
          "  Auto-detect of title_rx with options ",vis($opthash),
          dvis ' @required_specs\n',
          " failed because:\n   ", join("\n   ",@nd_reasons),
          "\n"
    );
  }
}

sub first_data_rx(;$) {
  my $self = &__self;
  my $first_data_rx = $$self->{first_data_rx};
  if (@_ == 0) { # 'get' request
    $self->_logmethretifv([], $first_data_rx);
    return $first_data_rx;
  }
  my $rx = __validate_nonnegi_or_undef( shift() );
  $self->_logmethretifv([$rx]);
  # Okay if this points to one past the end
  $self->_check_rx($rx, 1) if defined $rx;  # one_past_end_ok=1
  $$self->{first_data_rx} = $rx;
  $self
}
sub last_data_rx(;$) {
  my $self = &__self;
  my $last_data_rx = $$self->{last_data_rx};
  if (@_ == 0) { # 'get' request
    $self->_logmethretifv([], $last_data_rx);
    return $last_data_rx;
  }
  my $rx = __validate_nonnegi_or_undef( shift() );
  $self->_logmethretifv([$rx]);
  if (defined $rx) {
    $self->_check_rx($rx, 1); # one_past_end_ok=1
    confess "last_data_rx must be >= first_data_rx"
      unless $rx >= ($$self->{first_data_rx}//0);
  }
  $$self->{last_data_rx} = $rx;
  $self
}

# move_cols ">COLSPEC",source cols...
# move_cols "absolute-position",source cols...
sub move_cols($@) {
  my $self = &__selfmust;
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
  $self
}
sub move_col($$) { goto &move_cols; }

# insert_cols ">COLSPEC",new titles (or ""s or undefs if no title row)
# insert_cols "absolute-position",...
# RETURNS: The new colum indicies, or in scalar context the first cx
sub insert_cols($@) {
  my $self = &__selfmust;
  my ($posn, @new_titles) = @_;
  my ($num_cols, $rows, $title_rx) = @$$self{qw/num_cols rows title_rx/};

  my $to_cx = $self->_relspec2cx($posn);

  $self->_logmethifv(\__fmt_colspec_cx($posn,$to_cx), \" <-- ", \avis(@new_titles));

  @new_titles = map { $_ // "" } @new_titles; # change undef to ""
  my $have_new_titles = first { $_ ne "" } @new_titles;
  if (!defined($title_rx) && $have_new_titles) {
    croak "insert_cols: Can not specify non-undef titles if title_rx is not defined\n"
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
sub insert_col($$) { goto &insert_cols }

# sort_rows {compare function}
# sort_rows {compare function} $first_rx, $last_rx
sub sort_rows(&) {
  my $self = &__selfmust;
  croak "bad args" unless @_ == 1;
  my ($cmpfunc, $first_rx, $last_rx) = @_;

  my ($rows, $linenums, $title_rx, $first_data_rx, $last_data_rx)
       = @$$self{qw/rows linenums title_rx first_data_rx last_data_rx/};

  $first_rx //= $first_data_rx
                 // (defined($title_rx) ? $title_rx+1 : 0);
  $last_rx  //= $last_data_rx // $#$rows;

  oops unless defined($first_rx);
  oops unless defined($last_rx);
  my $pkg = caller;
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

sub delete_cols(@) {
  my $self = &__selfmust;
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
  $self
}
sub delete_col($) { goto &delete_cols; }

# Logic which forces verbose on when debug is on, etc.
# Used by new() and options()
sub _set_verbose_debug_silent(@) {
  my $self = shift;
  foreach (pairs @_) {
    my ($key, $val) = @$_;
    if ($key eq "silent") {
      $$self->{$key} = $val;
    }
    elsif ($key eq "verbose") {
      $$self->{$key} = $val;
      $$self->{silent} = 0 if $val; #?? might still want to suppress warnings
    }
    elsif ($key eq "debug") {
      $$self->{$key} = $val;
      if ($val) {
        $$self->{silent} = 0;
        $$self->{verbose} = "forced by {debug}";
      } else {
        $$self->{verbose} = 0 if u($$self->{verbose}) eq "forced by {debug}";
      }
    }
    else { croak "options: Unknown option key '$key'\n"; }
  }
}

# Get or set option(s).
# New settings may be in an {OPTIONS} hash and/or linear args.
# With _no_ arguments, returns a list of key => value pairs.
sub options(@) {
  my $self = &__self_ifexists;
  if (@_ == 0) {
    my $self = &__selfmust; # 'retrieve' is valid only if object exists
    my @result;
    foreach my $key (qw/verbose debug silent/) {
      push(@result, $key, $$self->{$key}) if exists $$self->{$key};
    }
    croak "(list) returned but called in scalar/void context"
      unless wantarray;
    return @result;
  }
  my $opthash = &__opthash; # shift off 1st arg iff it is a hashref
  my @eff_args = (%$opthash, &__validate_pairs);
  $self->_set_verbose_debug_silent(@eff_args);
  $self->_logmethifv(\__fmt_pairlist(@eff_args)); # returns $self
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

sub only_cols(@) {
  my $self = &__selfmust;
  my @cols = @_;
  my $rows = $self->rows;

  # Replace each row with just the surviving columns, in the order specified
  my @cxlist = $self->_colspecs_to_cxs_ckunique(\@cols);
  for my $row (@$rows) {
    @$row = map{ $row->[$_] } @cxlist;
  }
  $$self->{num_cols} = scalar(@cxlist);
  $self->_adjust_colx(\@cxlist);
  $self
}

# obj->join_cols separator_or_coderef, colspecs...
# If coderef:
#   $_ is bound to the first-named column, and is the destination
#   @_ is bound to all named columns, in the order named.
sub join_cols(&@) {
  my $self = &__selfmust;
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
    _apply_to_rows($self, $code, \@source_cxs, undef, $first_rx, undef);
  }

  # Delete the other columns
  $self->delete_cols(@source_cxs[1..$#source_cxs]);

  $$self->{verbose} = $saved_v;
  $self
}
sub join_cols_sep($@) { goto &join_cols }  # to match the functional API

sub rename_cols(@) {
  my $self = &__selfmust;
  croak "rename_cols expects an even number of arguments\n"
    unless scalar(@_ % 2)==0;

  my ($num_cols, $rows, $title_rx) = @$$self{qw/num_cols rows title_rx/};

  croak "rename_cols: No title_rx is defined!\n"
    unless defined $title_rx;

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
  $self
}

# apply {code}, colspec*
#   @_ are bound to the columns in the order specified (if any)
#   $_ is bound to the first such column
#   Only visit rows bounded by first_data_rx and/or last_data_rx,
#   starting with title_rx+1 if a title row is defined.
sub apply(&;@) {
  my $self = &__selfmust;
  my ($code, @cols) = @_;
  my $hash = $$self;
  my @cxs = map { scalar $self->_spec2cx($_) } @cols;

  my $first_rx = max(($hash->{title_rx} // -1)+1, $hash->{first_data_rx}//0);

  @_ = ($self, $code, \@cxs, undef, $first_rx, $hash->{last_data_rx});
  goto &_apply_to_rows
}

# apply_all {code}, colspec*
#  Like apply, but ALL rows are visited, inluding the title row if any
sub apply_all(&;@) {
  my $self = &__selfmust;
  my ($code, @cols) = @_;
  my $hash = $$self;
  my @cxs = map { scalar $self->_spec2cx($_) } @cols;
  $self->_logmethifv(\"rx 0..",$#{$hash->{rows}},
                    @cxs > 0 ? \(" cxs=".avis(@cxs)) : ());
  @_ = ($self, $code, \@cxs);
  goto &_apply_to_rows
}

sub __arrify_checknotempty($) {
  local $_ = shift;
  my $result = ref($_) eq 'ARRAY' ? $_ : [ $_ ];
  croak "Invalid argument ",vis($_)," (expecting [array ref] or single value)\n"
    unless @$result > 0 && !grep{ref($_) || $_ eq ""} @$result;
  $result
}

# apply_torx {code} rx,        colspec*
# apply_torx {code} [rx list], colspec*
# Only the specified row(s) are visited
# first/last_data_rx are ignored.
sub apply_torx(&$;@) {
  my $self = &__selfmust;
  my ($code, $rxlist_arg, @cols) = @_;
  croak "Missing rx (or [list of rx]) argument\n" unless defined $rxlist_arg;
  my $rxlist = __arrify_checknotempty($rxlist_arg);
  my @cxs = map { scalar $self->_spec2cx($_) } @cols;
  $self->_logmethifv(\vis($rxlist_arg),
                    @cxs > 0 ? \(" cxs=".avis(@cxs)) : ());
  @_ = ($self, $code, \@cxs, $rxlist);
  goto &_apply_to_rows
}

# apply_exceptrx {code} [rx list], colspec*
# All rows EXCEPT the specified rows are visited
sub apply_exceptrx(&$;@) {
  my $self = &__selfmust;
  my ($code, $exrxlist_arg, @cols) = @_;
  croak "Missing rx (or [list of rx]) argument\n" unless defined $exrxlist_arg;
  my $exrxlist = __arrify_checknotempty($exrxlist_arg);
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
sub split_col(&$$$@) {
  my $self = &__selfmust;
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
  $self
}

sub reverse_cols() {
  my $self = &__selfmust;
  my ($rows, $num_cols) = @$$self{qw/rows num_cols/};
  $self->_logmethifv();
  for my $row (@$rows) {
    @$row = reverse @$row;
  }
  $self->_adjust_colx([reverse 0..$num_cols-1]);
  $self
}

sub transpose() {
  my $self = &__selfmust;
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
  $self
}#transpose

# delete_rows rx ...
# delete_rows 'LAST' ...
# delete_rows '$' ...
sub delete_rows(@) {
  my $self = &__selfmust;
  my (@rowspecs) = @_;

  my ($rows, $linenums, $title_rx, $first_data_rx, $last_data_rx, $current_rx, $verbose)
    = @$$self{qw/rows linenums title_rx first_data_rx last_data_rx current_rx verbose/};

  foreach (@rowspecs) {
    $_ = $#$rows if /^(?:LAST|\$)$/;
    __validate_nonnegi($_, "rx to delete");
    croak "Invalid row index '$_'\n" unless $_ <= $#$rows;
  }
  my @rev_sorted_rxs = sort {$b <=> $a} @rowspecs;
  $self->_logmethifv(reverse @rev_sorted_rxs);

  # Adjust if needed...
  if (defined $title_rx) {
    foreach (@rev_sorted_rxs) {
      if ($_ < $title_rx) { --$title_rx }
      elsif ($_ == $title_rx) {
        $self->_log("Invalidating titles because rx $title_rx is being deleted\n")
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
  $self
}#delete_rows
sub delete_row($) { goto &delete_rows; }

# $firstrx = insert_rows [rx [,count]]
# $firstrx = insert_rows ['$'[,count]]
sub insert_rows(;$$) {
  my $self = &__selfmust;
  my ($rx, $count) = @_;
  $rx //= 'END';
  $count //= 1;

  my ($rows, $linenums, $num_cols, $title_rx, $first_data_rx, $last_data_rx)
    = @$$self{qw/rows linenums num_cols title_rx first_data_rx last_data_rx/};

  $rx = @$rows if $rx =~ /^(?:END|\$)$/;

  $self->_logmethifv(\"at rx $rx (count $count)");
  __validate_nonnegi($rx, "new rx");

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

  $rx;
}
sub insert_row(;$) { goto &insert_rows; }

# read_spreadsheet $inpath [Spreadsheet::Edit::IO::OpenAsCSV options...]
# read_spreadsheet $inpath [,iolayers =>...  or encoding =>...]
# read_spreadsheet $inpath [,{iolayers =>...  or encoding =>... }] #OLD API
# read_spreadsheet [{iolayers =>...  or encoding =>... }, ] $inpath #NEW API
#
# Titles are auto-detected by default, but this may be controlled
# via {OPTIONS}:
#   title_rx => rx    # Don't autodetect; set the specified title_rx
#   title_rx => undef # Don't autodetect; no titles
#   OR: autodetect options, passed thru to title_rx()
#
sub read_spreadsheet($;@) {
  my ($self, $opthash, $inpath) = &__self_opthash_1arg;

  my $saved_stdopts = $self->_set_stdopts($opthash);
  scope_guard{ $self->_restore_stdopts($saved_stdopts) };

  my %csvopts = @sane_CSV_read_options;
  # Separate out Text::CSV options from %$opthash
  foreach my $key (Text::CSV::known_attributes()) {
    #$csvopts{$key} = delete $opthash{$key} if exists $opthash{$key};
    $csvopts{$key} = $opthash->{$key} if defined $opthash->{$key};
    delete $opthash->{$key};
  }
  $csvopts{escape_char} = $csvopts{quote_char}; # " : """

  croak "Obsolete {sheet} key in options (use 'sheetname')"
    if exists $opthash->{sheet};

  __validate_opthash( $opthash,
                      [
      qw/title_rx/,
      qw/iolayers encoding verbose silent debug/,
      qw/tempdir use_gnumeric sheetname/, # for OpenAsCsv
      qw/required min_rx max_rx first_cx last_cx/, # for title_rx
                      ],
      desc => "read_spreadsheet option",
      undef_ok => [qw/title_rx verbose silent debug use_gnumeric/] );

  # convert {encoding} to {iolayers}
  if (my $enc = delete $opthash->{encoding}) {
    #warn "Found OBSOLETE read_spreadsheet 'encoding' opt (use iolayers instead)\n";
    $opthash->{iolayers} = ($opthash->{iolayers}//"") . ":encoding($enc)";
  }
  # Same as last-used, if any
  # N.B. If user says nothing, OpenAsCsv() defaults to UTF-8
  $opthash->{iolayers} //= $$self->{iolayers} // "";

  my ($rows, $linenums, $meta_info, $verbose, $debug)
    = @$$self{qw/rows linenums meta_info verbose debug/};

  ##$self->_check_currsheet;

  my $hash;
  { local $$self->{verbose} = 0;
    $hash = OpenAsCsv(
                   inpath => $inpath,
                   debug => $$self->{debug},
                   verbose => ($$self->{verbose} || $$self->{debug}),
                   %$opthash, # all our opts are valid here
             );
  }

  ### TODO: Split off the following into a separate read_csvdata() method
  ###       which takes a file handle?  This might be useful so users
  ###       can open arbitrary sources (even a pipe) and parse the data
  ###       (e.g. /etc/passwd with : as the separator).
  ###       ...but unclear how to handle encoding

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

  # Set title_rx, either to a value explicitly given in OPTIONS (possibly 
  # undef, meaning no titles) or else auto-detect.
  my %autodetect_opts;
  foreach (qw/required min_rx max_rx first_cx last_cx/) {
    $autodetect_opts{$_} = $opthash->{$_} if exists($opthash->{$_});
  }
                          
  my $arg = exists($opthash->{title_rx}) ? $opthash->{title_rx} : 'auto';
  { local $$self->{cmd_nesting} = $$self->{cmd_nesting} + 1;
    $autodetect_opts{verbose} = 0; # suppress logging
    $self->title_rx(\%autodetect_opts, $arg);
  } 

  $self->_logmethifv($opthash, $inpath,
                     \" [title_rx set to ",vis($$self->{title_rx}),\"]");

  $self
}#read_spreadsheet

# write_csv {OPTHASH} "/path/to/output.csv"
# Cells will be quoted if the input was quoted, i.e. if indicated by meta_info.
sub write_csv(*;@) {
  my $self = &__selfmust;
  my $opts = ref($_[0]) eq 'HASH' ? shift() : {};
  my $dest = shift;

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
  $self
}#write_csv

# Write spreadsheet with specified column formats
# {col_formats} is required
# Unless {sheetname} is specified, the sheet name is the outpath basename
#   sans any suffix
sub write_spreadsheet(*;@) {
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
  $self
}

#====================================================================
# These helpers are used by predefined magic sheet variables.
# See code in Spreadsheet::Edit::import()

# Return $self if during an apply, or if being examined by Data::Dumper ;
# otherwise croak
sub _onlyinapply {
  my ($self, $accessor) = @_;
  unless (defined $$self->{current_rx}) {
    for (my $lvl=2; ;$lvl++) {
      my $pkg = (caller($lvl))[0] || last;
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
  my($mutating, $pkg, $uvar, $index_ident, $array_ident, $onlyinapply) = @_;
  # E.g. for $title_row : index_ident="title_rx" and array_ident="rows"
  my $sheet = __getsheet($mutating, $pkg, $uvar, $onlyinapply);
  my $aref = $$sheet->{$array_ident} // oops dvisq '$array_ident @_'; # e.g. {rows}
  my $index = $$sheet->{$index_ident} // do{
    if ($index_ident eq "current_rx" or $index_ident eq "title_rx") {
      return \undef  # During Data::Dumper inspection of current_row?
    }
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

# Retrieve the sheet currently accessed by the functional API & tied globals
# in the caller's package (or the specified package).
# If an argument is passed, change the sheet to the specified sheet.
#
# Always returns the previous sheet (or undef)
#
# Logging is enabled if 'verbose' is on in either the initial or final
# sheet object (if any).
sub sheet(;$$) {
  my $opthash = &__opthash;
  my $pkg = $opthash->{package} // caller();
   oops if $pkg =~ /$mypkg/;
  my $pkgmsg = $opthash->{package} ? " [for pkg $pkg]" : "";
  my $curr = $pkg2currsheet{$pkg};
  my $verbose = ($curr && $$curr->{verbose});
  if (@_) {
    my $new = __validate_sheet_arg(shift @_);
    croak "Extraneous argument(s) in call to sheet()" if @_;
    if (defined $new) {
      oops if $$new->{cmd_nesting};
      $verbose ||= $new && $$new->{verbose};
    }

    __logmeth($opthash,
             \(" ".fmt_sheet($new)),
             \(u($curr) eq u($new)
               ? " [no change]" : " [previous: ".fmt_sheet($curr)."]"),
             \$pkgmsg)
      if $verbose;

    $pkg2currsheet{$pkg} = $new;
  } else {
    __logmethret([$opthash], \(fmt_sheet($curr).$pkgmsg))
      if $verbose;
  }
  $curr
}

#====================================================================
package
  Spreadsheet::Edit::RowsTie; # implements @rows and @$sheet
use parent 'Tie::Array';

use Carp;
#our @CARP_NOT = qw(Tie::Indirect Tie::Indirect::Array
#                   Tie::Indirect::Hash Tie::Indirect::Scalar);
use Data::Dumper::Interp;
use Scalar::Util qw(looks_like_number weaken);
sub oops(@) { goto &Spreadsheet::Edit::oops }

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
    if ! Spreadsheet::Edit::__looks_like_aref($val);
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
  $aref->[$index] = Spreadsheet::Edit::Magicrow->new($sheet, $cells);
}
sub FETCHSIZE { scalar @{ $_[0]->[0] } }
sub STORESIZE {
  my ($this, $newlen) = @_;
  $#{ $this->[0] } = $newlen-1;
}
# End packageSpreadsheet::Edit::RowsTie

#====================================================================
package
  Spreadsheet::Edit::Magicrow;

use Carp;
our @CARP_NOT = qw(Spreadsheet::Edit);
use Scalar::Util qw(weaken blessed looks_like_number);
sub oops(@) { goto &Spreadsheet::Edit::oops }
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

# End package Spreadsheet::Edit::Magicrow;
#====================================================================

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Edit - Slice and dice spreadsheets, optionally using tied variables.

=head1 NON-OO SYNOPSIS

  use Spreadsheet::Edit qw(:all);

  # Examples assume a spreadsheet with these titles in the first row:
  # "Account Number"  "Customer's Name"  "Email"  "Home-phone"  "Income"

  read_spreadsheet "mailing_list.xls!Sheet1";

  # alias an identifier to a long or complicated title
  alias Name => qr/customer/i;  # matches "Customer's Name"

  # ------------ without tied column variables -----------

  # Print the data
  printf "%20s %8s %8s %-13s %s\n", "Name","A/N","Income","Phone","Email";
  apply {
    printf "%20s %8d %8.2f %-13s %s\n",
           $crow{Name},              # this key is an explicit alias
           $crow{"Account Number"},  #   ...actual title
           $crow{Income},            #   ...actual title
           $crow{Home_phone},        #   ...auto-generated alias
           $crow{Email} ;            #   ...actual title
  };

  # Randomly access rows.
  print "Row 42: Column 'C' is ",      $rows[41]{C},    "\n";
  print "Row 42: Customer's Name is ", $rows[41]{Name}, "\n";
  print "Row 42: 3rd column is ",      $rows[41][2],    "\n";

  # Split the "Customer's Name" into separate FName and LName columns
  insert_cols '>Name', "FName", "LName";
  apply {
    ($crow{FName}, $crow{LName}) = ($crow{Name} =~ /(.*) (.*)/)
      or die logmsg "Could not parse Name"; # logmsg adds current row number
  };
  delete_cols "Name";

  # Sort by last name
  sort_rows { $a->{LName} cmp $b->{LName} };

  # ------------ using tied column variables -----------

  our $Name;            # 'Name' is the explicit alias created above
  our $Account_Number;  # Auto-generated alias for "Account Number"
  our $Home_phone;      #   ditto
  our $Income;          # 'Income' is an actual title
  our $Email;           #   ditto
  our ($FName, $LName); # These columns do not yet exist

  tie_column_vars "Name", "Account_Number", qr/phone/, qr/^inc/i, "FName", "LName";

  # Print the data
  printf "%20s %8s %8s %-13s %s\n", "Name","A/N","Income","Phone","Email";
  apply {
    printf "%20s %8d %8.2f %-13s%s\n",
           $Name, $Account_Number, $Income, $Home_phone, $Email;
  };

  # Split the "Customer's Name" into separate FName and LName columns
  insert_cols '>Name', "FName", "LName";
  apply {
    ($FName, $LName) = ($Name =~ /^(\S+) (\S+)$/)
      or die logmsg "Could not parse Name";
  };
  delete_cols "Name";

  # Simple mail-merge
  use POSIX qw(strftime);
  apply {
    return
      if $Income < 100000;  # not in our audience
    open SENDMAIL, "|sendmail -t -oi" || die "pipe:$!";
    print SENDMAIL "To: $FName $LName <$Email>\n";
    print SENDMAIL strftime("Date: %a, %d %b %y %T %z\n", localtime(time));
    print SENDMAIL <<EOF ;
  From: sales\@example.com
  Subject: Help for the 1%

  Dear $FName,
    If you have disposable income, we can help with that.
  Sincerely,
  Your investment advisor.
  EOF
    close SENDMAIL || die "sendmail failed ($?)\n";
  };

  # ------------ multiple sheets --------------

  our ($Foo, $Bar, $Income);

  read_spreadsheet "file1.csv";
  tie_column_vars;              # tie all vars that ever become valid

  my $s1 = sheet undef ;        # Save ref to current sheet & forget it

  read_spreadsheet "file2.csv"; # Auto-creates sheet bc current is undef
  tie_column_vars;

  my $s2 = sheet ;              # Save ref to second sheet

  print "$Foo $Bar $Income\n";  # these refer to $s2, the current sheet

  sheet $s1 ;
  print "$FName $LName $Income\n"; # these now refer to the original sheet

  # ------------ create sheet from memory --------------

  my $s3 = new_sheet
      data_source => "my own data",
      rows => [
        ["This is a row before the title row"                       ],
        ["Full Name",  "Address",         "City",   "State", "Zip"  ],
        ["Joe Smith",  "123 Main St",     "Boston", "CA",    "12345"],
        ["Mary Jones", "999 Olive Drive", "Fenton", "OH",    "67890"],
      ],
      title_rx => 1
      ;
  ...

=head1 OO SYNOPSIS

  use Spreadsheet::Edit ();

  my $sheet = Spreadsheet::Edit->new();
  $sheet->read_spreadsheet("mailing_list.xls!sheet name");
  $sheet->alias( Name => qr/customer/i );  # matches "Customer's Name"

  # Randomly access rows.
  # Sheet objects, when used as an ARRAYref, act like \@rows
  print "Row 42: Name is ",     $sheet->[41]{Name}, "\n";
  print "Row 42, Column 3 is ", $sheet->[41][2],    "\n";

  # Print the data.
  # Sheet objects, when used as an HASHref, act like \%crow
  printf "%20s %8s %8s %-13s %s\n", "Name","A/N","Income","Phone","Email";
  $sheet->apply( sub{
      printf "%20s %8d %8.2f %-13s%s\n",
             $sheet->{Name},
             $sheet->{"Account Number"},
             $sheet->{Income},
             $sheet->{Home_phone},
             $sheet->{Email} ;
  });

  # Another way:
  $sheet->apply( sub{
      my $r = $sheet->crow();
      printf "%20s %8d %8.2f %-13s%s\n",
             $r->{Name}, $r->{"Account Number"}, $r->{Income},
             $r->{Home_phone}, $r->{Email} ;
  });

  # Another way:
  $sheet->apply( sub{
      my $r = $sheet->crow();
      printf "%20s %8d %8.2f %-13s%s\n",
             $r->[0], $r->[1], $r->[4], $r->[3], $r->[2] ;
  });

  # Split the "Customer's Name" into separate FName and LName columns
  $sheet->insert_cols('>Name', "FName", "LName");
  $sheet->apply( sub {
      my $r = $sheet->crow();
      ($r->{FName}, $r->{LName}) = ($r->{Name} =~ /(.*) (.*)/)
        or die Spreadsheet::Edit::logmsg("Could not parse Name");
  });
  $sheet->delete_cols( "Name" );


=head1 INTRODUCTION

=over


Skip ahead to "FUNCTIONS" for a list of operations (OO methods are
named the same).

=back

Columns may be referenced by title without knowing their absolute positions.
Optionally global (package) variables may be tied to columns.  
Tabular data can come
from Spreadsheets, CSV files, or your code, and be written similarly.
Both Functional and Object-Oriented (OO) APIs are provided.

A table in memory is stored in a C<sheet> object, which contains
an array of rows, each of which is an array of cell values.

Cells within a row may be accessed by name (e.g. column titles) or
by absolute position (letter code like "A", "B" etc. or zero-based index).

The usual paradigm is to iterate over rows applying a function
to each, vaguely inspired by 'sed' and 'awk' (see C<apply> below).
Random access is also supported.

Tied variables can be used with the functional API.  These variables
refer to columns in the current row during a C<apply> operation.

Note: Only cell I<values> are handled; there is no provision
for processing formatting information from spreadsheets.
The author has a notion to add support for formats,
perhaps integrating with Spreadsheet::Read and Spreadsheet::Write
or the packages they use.  Please contact the author if you want to help.

=head3 HOW TO IMPORT

By default only functions are imported, but most people will

  use Spreadsheet::Edit ':all';

to import functions and helper variables (see STANDARD SHEET VARIABLES
and VARIABLES USED DURING APPLY).

You can rename imported items using the '-as' notation shown in
C<Exporter::Tiny::Manual::QuickStart>.

Purely-OO applications can C<use Spreadsheet::Edit ();>.

=head1 THE 'CURRENT SHEET'

The I<Functions> and helper variables implicitly operate on a
package-global "current sheet" object, which can be switched at will.
OO I<Methods> operate on the C<sheet> object they are called on.

Every function which operates on the "current sheet" has a
corresponding OO method with the same name and the same arguments.

=head1 TIED COLUMN VARIABLES

Package variables can refer directly to columns in the 'current sheet'
during C<apply>.  For example C<$Email> and C<$FName> in
the SYNOPSIS above.

See C<tie_column_vars> for details.

=head1 THE FUNCTIONS

In the following, {OPTIONS} refers to an optional first argument
which, if present, is a hashref giving additional parameters.
For example in

   read_spreadsheet {sheetname => 'Sheet1'}, '/path/to/file.xlsx';

the {...} hash is optional and specifies the sheet name.

=head2 $curr_sheet = sheet ;

=head2 $prev_sheet = sheet $another_sheet ;

=head2 $prev_sheet = sheet undef ;

[Functional API only]
Retrieve, change, or forget the 'current sheet' object used
by the functional API.

Changing the current sheet immediately changes what is referenced by
tied column variables and STANDARD SHEET VARIABLES (described later).

{OPTIONS} may specify C<< package => 'pkgname' >> to operate on the specified
package instead of the caller's package (useful in library code).

=head2 read_spreadsheet CSVFILEPATH

=head2 read_spreadsheet SPREADSHEETPATH

=head2 read_spreadsheet "SPREADSHEETPATH!SHEETNAME"

Replace any existing data with content from the given file.

The Functional API will create a new sheet object if
there is no "current sheet".

The file may be a .csv or any format supported by Libre Office or gnumeric.

By default column titles are auto-detected and
an exception is thrown if a plausible title row can not be found.

{OPTIONS} may include:

Auto-detection options:

=over 2

 required   => COLSPEC or [COLSPEC,...]  # any required title(s)
 min_rx     => NUM,  # first rx which may contain the title row.
 max_rx     => NUM,  # maximum rx which may contain the title row.
 first_cx   => NUM,  # first column ix which must contain required titles
 last_cx    => NUM,  # last column ix which must contain required titles

=back

The first row is used which includes the C<required> title(s), if any,
and has non-empty titles in all columns.
If C<first_cx> and/or C<last_cx> are specified then columns outside that
range are ignored and may by empty.

=over 2

  title_rx => rx     # specify title row (first row is 0)
  title_rx => undef  # no title row

=back

These disable auto-detection and explicitly specify the title row
index, or with C<undef>, that there are no titles.
See also the C<title_rx> function/method.

Other options:

=over 6

=item sheetname => SHEETNAME

Specify which sheet in a multi-sheet workbook (i.e. spreadsheet file) to read.
Alternatively, the sheet name may be appended to the input
path after '!' as shown in the example.

If no SHEETNAME is given then the sheet which was "active" when the
workbook was saved will be retrieved.

=item silent => bool

=item verbose => bool

=item debug => bool

=item Other C<< key => value >> pairs override details of CSV parsing.

See Text::CSV.  UTF-8 encoding is assumed by default.

=back

Due to bugs in Libre/Open Office, spreadsheet files can not
be read if LO/OO is currently running, even
for unrelated purposes (see "BUGS").
This problem does not occur with .csv files

=head2 alias IDENT => COLSPEC, ... ;

=head2 alias IDENT => qr/regexp/, ... ;

Create alternate identifiers for specified columns.

Each IDENT, which must be a valid Perl identifier, will henceforth
refer to the specified column even if the identifier is the same
as the title or letter code of a different column.

C<$row{IDENT}> and a tied variable C<$IDENT> will refer to the specified column.

Aliases automatically track the column if it's position changes.

Regular Expressions are matched against titles only, and must match
exactly one column or else an exception is thrown.
Other kinds of COLSPECs may be titles, existing alias names, column letters, etc.
(see "COLUMN SPECIFIERS" for details).

The COLSPEC is evaluated before the alias is created, so

   alias B => "B";

would make "B" henceforth refer to the current second column (or a different
column which has title "B" if such exists) even if that column later moves.

RETURNS: The 0-based column indices of the aliased column(s).

=head2 unalias IDENT, ... ;

Forget alias(es).  Any masked COLSPECs become usable again.

=head2 tie_column_vars VARNAME, ...

Create tied package variables (scalars) for use during C<apply>.

Each variable is a scalar corresponding to a column, and reading or writing
it accesses the corresponding cell in the row being visited during C<apply>.

The '$' may be omitted in the VARNAME arguments to C<tie_column_vars>;

You must separately declare these variables with C<our $NAME>,
except in the special case described
in "Use in BEGIN() or module import methods" later.

The variable name itself implies the column it refers to.

Variable names may be:

=over

=item * User-defined alias names (see "alias")

=item * Titles which happen to be valid Perl identifiers

=item * Identifiers derived from titles by replacing offending characters
with underscrores (see "AUTOMATIC ALIASES"),

=item * Spreadsheet column letters like "A", "B" etc.

=back

See "CONFLICT RESOLUTION" about name clashes.

Multiple calls accumulate, including with different sheets.

Variable bindings are dynamically evaluated during each access by using the
variable's identifier as a COLSPEC with the 'current sheet' in your package.
This means that it does not matter which sheet
was 'current' when C<tie_column_vars> was called with a particular name;
it only matters that the name of a tied variable is a valid COLSPEC in
the 'current sheet' when that variable is referenced
(otherwise a read returns I<undef> and a write throws an exception).
[*Need clarification*]

B<{OPTIONS}> may specify:

=over

=item package => "pkgname"

Tie variables in the specified package instead of the caller's package.

=item verbose => bool

=item debug => bool

Print trace messages.

=back

=head2 tie_column_vars ':all'

With the B<:all> token I<all possible variables> are tied, corresponding
to the aliases, titles, non-conflicting column letters etc.  which exist
for the current sheet.

In addition, variables will be tied in the future I<whenever new identifiers
become valid> (for example when a new C<alias> is created, column added,
or another file is read into the same sheet).

Although convenient this is B<insecure> because malicious
titles could clobber unintended globals.

If VARNAMES are also specified, those variables will be tied
immediately even if not yet usable; an exception occurs if a tied variable
is referenced before the corresponding alias or title exists.
[*Need clarification* -- exception even for reads??]

=head2 Use in BEGIN{} or module import methods

C<tie_column_vars> B<imports> the tied variables into your module,
or the module specified with package => "pkgname" in {OPTIONS}.

It is unnecessary to declare tied variables if the import
occurs before code is compiled which references the variables.  This can
be the case if C<tie_column_vars> is called in a BEGIN{} block or in the
C<import> method of a module loaded with C<use>.

C<Spreadsheet::Edit::Preload> makes use of this.

=head2 $rowindex = title_rx ;

Retrieve the current title row rx, or undef if there are no titles

=head2 title_rx ROWINDEX ;

Make the specified row be the title row.  Titles in that row are
immediately (re-)examined and the corresponding COLSPECs become valid,
e.g. you can reference a column by it's title or a derived identifier.

Note: Setting C<title_rx> this way is rarely needed because
C<read_spreadsheet> automatically sets the title row.

=head2 title_rx undef ;

Titles are disabled and any existing COLSPECs derived from
titles are invalidated.  Auto-detection is I<disabled>.

=head2 title_rx {AUTODETECT_OPTIONS} 'auto';

Immediately perform auto-detection of the title row using
C<< {AUTODETECT_OPTIONS} >> to modify any existing auto-detect options
(see C<read_spreadsheet> for a description of the options).


=head2 apply {code} [COLSPEC*] ;

=head2 apply_all {code} [COLSPEC*] ;

=head2 apply_torx {code} RX-OR-RXLIST [,COLSPEC*] ;

=head2 apply_exceptrx {code} RX-OR-RXLIST [,COLSPEC*] ;

Execute the specified code block (or referenced sub) once for each row.

Note that there is no comma after a bare {code} block.

While executing your code, tied column variables and
the sheet variables C<@crow>, C<%crow>, C<$rx> and C<$linenum>
and corresponding OO methods will refer to the row being visited.

If a list COLSPECs is specified, then

=over 2

  @_ is bound to the columns in the order specified
  $_ is bound to the first such column

=back

C<apply> normally visits all rows which follow the title row, or all rows
if there is no title row.
C<first_data_rx> and C<last_data_rx>, if defined, further limit the
range visited.

C<apply_all> unconditionally visits every row, including any title row.

C<apply_torx> or C<apply_exceptrx> visit exactly the indicated rows.
RX-OR-RXLIST may be either a single row index or a [list of rx];

Rows may be safely inserted or deleted during 'apply';
rows inserted after the currently-being-visited row will be visited
at the proper time.

An 'apply' sub may change the 'current sheet', after which
tied column variables will refer to the other sheet and
any C<apply> active for that sheet.  It should take care to restore
the original sheet before returning
(perhaps using Guard::scope_guard).
Nested and recursive C<apply>s are allowed.

B<MAGIC VARIABLES USED DURING APPLY>

These variables refer to the row currently being visited:

=over 2

C<$rx> is the 0-based index of the current row.

C<@crow> is an array aliased to the current row's cells.

C<%crow> is a hash aliased to the same cells,
indexed by alias, title, letter code, etc. (any COLSPEC).

C<$linenum> is the starting line number of the current row if the
data came from a .csv file.

For example, the "Account Number" column in the SYNOPSIS may be accessed
many ways:

  alias AcNum => "Account Number";
  apply {

    $crow{"Account Number"}           # %crow indexed by title
    $crow{AcNum}                      #   using an explicit alias
    $crow{Account_Number}             #   using the AUTOMATIC ALIAS

    $crow[ $colx{"Account Number"} ]; # @crow indexed by a 0-based index
    $crow[ $colx{"AcNum"} ];          #  ...obtained from %colx
    $crow[ $colx{"Account_Number"} ]; #

    $rows[$rx]->[ $colx{Account_Number} ] # Directly accessing @rows

    # See "TIED COLUMN VARIABLES" for a sweeter alternative
  };

=back

=head2 delete_col COLSPEC ;

=head2 delete_cols COLSPEC+ ;

The indicated columns are removed.  Remaining title bindings
are adjusted to track shifted columns.

=head2 only_cols COLSPEC+ ;

All columns I<except> the specified columns are deleted.

=head2 move_col  POSITION, SOURCE ;

=head2 move_cols POSITION, SOURCES... ;

Relocate the indicated column(s) (C<SOURCES>) so they are adjacent, in
the order specified, starting at the position C<POSITION>.

POSITION may be ">COLSPEC" to place moved column(s)
immediately after the indicated column (">$" to place at the end),
or POSITION may directly specify the destination column
using an unadorned COLSPEC.

A non-absolute COLSPEC indicates the initial position of the referenced column.

=head2 insert_col  POSITION, newtitle ;

=head2 insert_cols POSITION, newtitles... ;

One or more columns are created starting at a position
specified the same way as in C<move_cols> (later columns
are moved rightward).

POSITION may be ">$" to place new column(s) at the far right.

A new title must be specified for each new column.
If there is no title row, specify C<undef> for each position.

Returns the new column index or indices.

=head2 split_col {code} COLSPEC, POSITION, newtitles... ;

New columns are created starting at POSITION as with C<insert_cols>,
and populated with data from column COLSPEC.

C<{code}> is called for each row with $_ bound to the cell at COLSPEC
and @_ bound to cell(s) in the new column(s).  It is up to your code to
read the old column ($_) and write into the new columns (@_).

The old column is left as-is (not deleted).

If there is no title row, specify C<undef> for each new title.

=head2 sort_rows {rx cmp function}

=head2 sort_rows {rx cmp function} $first_rx, $last_rx

If no range is specified, then the range is the
same as for C<apply> (namely: All rows after the title row unless
limited by B<first_data_rx> .. B<last_data_rx>).

In the comparison function globals $a and $b will contain row objects, which
are dual-typed to act as either an array or hash ref to the cells
in their row.  The corresponding original row indicies are also passed
as parameters in C<@_>.

Rows are not actually moved until after all comparisons have finished.

RETURNS: A list of the previous row indicies of all rows in the sheet.

    # Sort on the "LName" column using row indicies
    # (contrast with the example in SYNOPSIS which uses $a and $b)
    sort_rows { my ($rxa, $rxb) = @_;
                $rows[$rxa]{LName} cmp $rows[$rxb]{LName}
              };

=head2 rename_cols COLSPEC, "new title", ... ;

Multiple pairs may be given.  Title cell(s) are updated as indicated.

Existing user-defined aliases are I<not> affected, i.e.,
they continue to refer to the same columns as before.

=head2 join_cols_sep STRING COLSPEC+ ;

=head2 join_cols {code} COLSPEC+ ;

The specified columns are combined into the first-specified column and the other
columns are deleted.

The first argument of C<join_cols_sep> should be a fixed separator.
The first argument of C<join_cols> may be a {code} block or subref;

If a separator string is specified it is used to join column content
together.

If a {code} block or sub ref is specified,
it is executed once for each row following the title row,
with $_ bound to the first-named column, i.e. the surviving column,
and @_ bound to all named columns in the order given.

It is up to your code to combine the data by reading
@_ and writing $_ (or, equivalently, by writing $_[0]).

C<first_data_rx> and C<last_data_rx> are ignored, and the title
is I<not> modified.

=head2 reverse_cols

The order of the columns is reversed.

=head2 insert_row

=head2 insert_row 'END' [,$count]

=head2 insert_rows $rowx [,$count]

Insert one or more empty rows at the indicated position
(default: at end).  C<$rowx>, if specified, is either a 0-based offset
for the new row or 'END' to add the new row(s) at the end.
Returns the index of the first new row.

=head2 delete_rows $rowx,... ;

=head2 delete_rows 'LAST',... ;

The indicated data rows are deleted.  C<$rowx> is a zero-based row index
or the special token "LAST" to indicate the last row (same as C<$#rows>).
Any number of rows may be deleted in a single command, listed individually.

=for Pod::Coverage delete_row

=head2 transpose

Invert the relation, i.e. rotate and flip the table.
Cells A1,B1,C1 etc. become A1,A2,A3 etc.
Any title_rx is forgotten.

=head2 $href = read_workbook SPREADSHEETPATH

**NOT YET IMPLEMENTED**

[Function only, not callable as a method]
All sheets in the specified document are read into memory
without changing the 'current sheet'.  A hashref is returned:

  {
    "sheet name" => (Spreadsheet::Edit object),
    ...for each sheet in the workbook...
  }

To access one of the workbook sheets, execute

  sheet $href->{"sheet name"};  # or call OO methods on it

If SPREADSHEETPATH was a .csv file then the resulting hash will have only
one member with an indeterminate key.

=head2 new_sheet

[functional API only]
Create a new empty sheet and make it the 'current sheet', returning the
sheet object.

Rarely used because a new sheet is automatically created by
C<read_spreadsheet> if your package has no current sheet.

{OPTIONS} may include:

=over 6

=item data_source => "text..."

This string will be returned by the C<data_source> method,
overriding any default.

=item rows => [[A1_value,B1_value,...], [A2_value,B2_value,...], ...],

=item linenums => [...]  #optional

This makes the C<sheet> object hold data already in memory.
The data should not be modified directly while the sheet C<object> exists.

=item clone => $existing_sheet

A deep copy of an existing sheet is made.

=item num_cols => $number  # with no initial content

An empty sheet is created but with a fixed number of columns.
When rows are later created they will be immediately padded with empty cells
if necessary to this width.

=back


=head2 write_csv *FILEHANDLE

=head2 write_csv $path

Write the current data to the indicated path or open file handle as
a CSV text file.
The default encoding is UTF-8 or, if C<read_spreadsheet> was most-recently
used to read a csv file, the encoding used then.

{OPTIONS} may include

=over 6

=item options for Text::CSV

Usually none need be specified because we supply sane defaults.

=item silent => bool

=item verbose => bool

=item debug => bool

=back

=head2 write_spreadsheet OUTPUTPATH

Write the current data to a spreadsheet (.ods, .xlsx, etc.) by
first writing to a temporary CSV file and then importing that file into
a new spreadsheet.

{OPTIONS} may include

=over 6

=item col_formats => [ LIST ]

EXPERIMENTAL, likely to change when Spreadsheet::Read is integrated!

Elements of LIST may be "" (Standard), "Text", "MM/DD/YY", "DD/MM/YY", or
"YY/MM/DD" to indicate the format of the corresponding column.  The meaning
of "Standard" is not well documented but appears to mean "General Number"
in most cases.  For details, see "Format Codes" in L<this old Open Office
documentation|https://wiki.openoffice.org/wiki/Documentation/DevGuide/Spreadsheets/Filter_Options#Filter_Options_for_the_CSV_Filter>.

=item silent => bool

=item verbose => bool

=item debug => bool

=back


=head2 options NAME => EXPR, ... ;

=head2 options NAME ;

Set or retrieve miscellaneous sheet-specific options.
When setting, the previous value of
the last option specified is returned.  The only options currently defined
are I<silent>, I<verbose> and I<debug>.

=head2 $hash = attributes ;

Returns a reference to a hash in which you may store arbitrary data
associated with the sheet object.

=head2 spectocx COLSPEC or qr/regexp/, ... ;

Returns the 0-based indicies of the specified colomn(s).
Throws an exception if there is no such column.
A regexp may match multiple columns.
See also C<%colx>.

=head2 logmsg [FOCUSARG,] string, string, ...

(must be explicitly imported)

Concatenate strings, prefixed by a description
of the 'current sheet' and row during C<apply>, if any (or with the
sheet and/or row given by FOCUSARG).

The resulting string is returned, with "\n" appended if it was not
already terminated by a newline.

The first argument is used as FOCUSARG if it is
a sheet object, [sheet_object], or [sheet_object, rowindex], and specifies
the sheet and/or row to describe in the message prefix.
Otherwise the first argument is not special and is simply
the first message string.

The details of formatting the sheet may be customized with a call-back
given by a {logmsg_pfx_gen} attribute.  See comments
in the source for how this works.

=head1 STANDARD SHEET VARIABLES

These variables magically access the 'current sheet' in your package.

=over

=item @rows

The spreadsheet data as an array of row objects.

Each row object is "dual-typed" (overloaded) to act as either an ARRAY or HASH
reference to the cells in that row.

When used as a HASH ref, the key may be a
alias, column title, letter-code etc. (any COLSPEC).
When used as an ARRAY ref, the 0-based index specifies the column.

=item @linenums

The first line numbers of corresponding rows (a row can contain
multiple lines if cells contain embedded newlines). Valid only if
the data came from a CSV file.

=item $num_cols

The number of columns in the widest input row.  Shorter rows are
padded with empty cells when read so that all rows have the same number
of columns in memory.

=item $title_rx and $title_row

C<$title_rx> contains the 0-based row index of the title row
and C<$title_row> is an alias for C<$rows[ $title_rx ]>.

The title row is auto-detected by default.
See C<title_rx> for how to control this.

If a column title is modified, set C<$title_rx = undef;> to force re-detection.

=item $first_data_rx and $last_data_rx

Optional limits on the range of rows visited by C<apply()>
or sorted by C<sort_rows()>.  By default $first_data_rx
is the first row following the title row (or 0 if no title row).

=item %colx (column key => column index)

C<< %colx >> maps aliases, titles, etc. (all currently-valid COLSPECs)
to the corresponding zero-based column indicies.   See "COLSPECS" .

=item %colx_desc (column key => "debugging info")

=back

=head1 COLSPECs (COLUMN SPECIFIERS)

Arguments which specify columns may be:

=over

=item (1) a user-defined alias identifier

=item (2) an actual "column title" **

=item (3) a title with any leading & trailing spaces removed *

=item (4) an AUTOMATIC ALIAS identifier *


=item (6) a Regexp (qr/.../) which matches an actual title

=item (7) a numeric column index (0-based)

=item (8) '^' or '$' (means first or last column, respectively)


=back

*These may only be used if they do not conflict with an
item listed higher up.

**Titles may be used directly if they can not be confused with
a user-defined alias, the special names '^' or '$' or a numeric
column index.  See "CONFLICT RESOLUTION".

B<AUTOMATIC ALIASES> are Perl I<identifiers> derived from column titles by
first removing leading or trailing spaces, and then
replacing non-word characters with underscores and prepending
an underscore if necessary.
For example:

    Title             Automatic Alias

    "Address"         Address (no change needed)
    "  First Name  "  First_Name
    "First & Last"    First___Last
    "+sizes"          _sizes
    "1000s"           _1000s  (underscore avoids leading digit)

Aliases (both automatic and user-defined) are valid identifiers,
so can be used as the names of tied variables,
bareword keys to C<%colx> and C<%crow>, and related OO interfaces,

CONFLICT RESOLUTION

A conflict occurs when a column key potentially refers to multiple
columns. For example, "A", "B" etc. are standard column
names, but they might also be titles of other columns in which
case those names refer to the other columns.
Warnings are printed about conflicts unless the C<silent> option
is true (see C<options>).

=over

B<User alias identifiers> (defined using C<alias>) are always valid.

'^' and '$' always refer to the first and last column.

Numeric "names" 0, 1, etc. always give a 0-based column index
if the value is between 0 and num_cols (i.e. one past the end).

B<Actual Titles> refer to to their columns, except if they:

=over

are the same as a user-defined alias

are '^' or '$'

consist only of digits (without leading 0s) corresponding
to a valid column index.

=back

B<Automatic Aliases> and B<Standard column names> ("A", "B", etc.)
are available as column keys
unless they conflict with a user-defined alias or an actual title.

=back

Note: To unconditionally refer to numeric titles or titles which
look like '^' or '$', use a Regexp B<qr/.../>.
Automatic Aliases can also refer to such titles if there are no conflicts.

Column positions always refer to the data before a command is
executed. This is relevant for commands which re-number or delete columns.

=head1 OO DESCRIPTION (OBJECT-ORIENTED INTERFACE)

All the Functions listed above (except for C<new_sheet>) have
corresponding methods with the same arguments.

However arguments to methods must be enclosed in parenthesis
and bare {code} blocks may not be used; a sub{...} ref
should be passed to C<apply> etc.

=head1 OO-SPECIFIC METHODS

=head2 Spreadsheet::Edit->new(OPTIONS...)

Creates a new "sheet" object.

OPTIONS are the same as described for the C<new_sheet> Function above,
except that they may be specified as key => value pairs of arguments
instead of (or in addition to) an {OPTIONS} hashref.

=head2 $sheet->rows() ;             # Analogous to to \@rows

=head2 $sheet->linenums() ;         # Analogous to \@linenums

=head2 $sheet->num_cols() ;         # Analogous to $num_cols

=head2 $sheet->colx() ;             # Analogous to \%colx

=head2 $sheet->colx_desc() ;        # Analogous to \%colx_desc

=head2 $sheet->first_data_rx() ;    # Analogous to $first_data_rx

=head2 $sheet->last_data_rx() ;     # Analogous to $last_data_rx

=head2 $sheet->title_row() ;        # Analogous to $title_row

=head2 $sheet->rx() ;               # Current rx in apply, analogous to to $rx

=head2 $sheet->crow();              # Current row in apply (a dual-typed row object)

=head2 $sheet->linenum() ;          # Analogous to to $linenum

=head2 $sheet->title_rx() ;         # Analogous to to $title_rx

=head2 $sheet->title_rx(rxvalue) ;  # (Re-)set the title row index

=head2 $sheet->get(rx,ident) ;      # Analogous to to $rows[rx]{ident}

=head2 $sheet->set(rx,ident,value); # Analogous to to $rows[rx]{ident} = value

=head2 $sheet->data_source();       # "description of sheet" (e.g. path read)

=head2 $sheet->sheetname();         # valid if input was a spreadsheet, else undef

=head2


=head1 SEE ALSO

Spreadsheet::Edit::Preload

=head1 BUGS

Some vestigial support for formats remains from an earlier implementation,
but this support is likely to be entirely replaced at some point.

Spreadsheets are currently read using the external programs C<gnumeric>
or C<unoconv> to convert to a temporary CSV file.
C<unoconv> has a bug where reading will fail if Open/Libre Office
is currently running, even on an unrelated document.
This may be fixed in the future by using Spreadsheet::Read instead,
although it uses modules based on Twig which are quite slow.

=head1 THREAD SAFETY

Unknown, and probably not worth the trouble to find out.
The author wonders whether tied variables are compatible with
the implementation of threads::shared.
Even the OO API uses tied variables (for the magical row objects
which behave as either an array or hash reference).

=head1 FUTURE IDEAS

=over 4

=item Add format-processing support.

=item Add "column-major" views, to access a whole column as an array.
Perhaps C<@cols> and C<%cols> would be sets of column arrays
(@cols indexed by column index, %cols indexed by any COLSPEC).
And C<tie_column_vars '@NAME'> would tie user array variables to columns.

=back

=head1 AUTHOR / LICENSE

Jim Avera (jim.avera at gmail)  /   Public Domain or CC0.

=for Pod::Coverage meta_info

=for Pod::Coverage iolayers input_encoding

=for Pod::Coverage oops fmt_sheet fmt_list

=for Pod::Coverage to_aref to_array to_wanted to_hash

=for Pod::Coverage tied_varnames title2ident let2cx cx2let

=cut


# License: http://creativecommons.org/publicdomain/zero/1.0/
# (CC0 or Public Domain).  To the extent possible under law, the author, 
# Jim Avera (email jim.avera at gmail dot com) has waived all copyright and 
# related or neighboring rights to this document.  Attribution is requested
# but not required.

# Pod documentation is below (use perldoc to view)

use strict; use warnings FATAL => 'all'; use utf8;
use feature qw(say state);

package Spreadsheet::Edit;
$Spreadsheet::Edit::VERSION = '2.102';
# If the globals $Debug etc. are *defined* then the corresponding
# (downcased) options default accordingly when new sheets are created.
use Spreadsheet::Edit::OO qw(cx2let let2cx 
           oops %pkg2currsheet $Debug $Verbose $Silent);

use parent "Exporter::Tiny";
require mro; # makes next::can available
use Data::Dumper::Interp;

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
  options package_active_sheet read_spreadsheet rename_cols reverse_cols 
  sheet sheetname sort_rows split_col tie_column_vars title2ident title_row 
  title_rx unalias write_csv write_spreadsheet );

my @stdvars = qw( $title_rx $first_data_rx $last_data_rx $num_cols
                  @rows @linenums @meta_info %colx %colx_desc $title_row
                  $rx $linenum @crow %crow );

our @EXPORT_OK = (@stdvars, qw/logmsg cx2let let2cx/);

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
# create a new, unique variable tied appropriately for each import.
# This is done by defining methods _generateScalar_rx() and so forth.

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
          "Scalar", \&Spreadsheet::Edit::OO::_scal_tiehelper, 
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
            my $sheet = &Spreadsheet::Edit::OO::__getsheet(@_); 
            #$$sheet->{title_rx}
            \($sheet->_autodetect_title_rx_ifneeded_cl1())
          }, 0 # onlyinapply
         )
}

sub __gen_aryelem {
  my ($myclass, $sigilname, $args, $globals,   
      $index_ident, $array_ident, $onlyinapply) = @_;
  # N.B. _aryelem_tiehelper has special logic for 'current_rx' and 'title_rx'
  __gen_x($myclass, $sigilname, $args, $globals,   
          "Scalar", \&Spreadsheet::Edit::OO::_aryelem_tiehelper,
          $index_ident, $array_ident, $onlyinapply);
}
sub _generateScalar_title_row     { __gen_aryelem(@_, "title_rx", "rows") }
sub _generateScalar_linenum { __gen_aryelem(@_, "current_rx", "linenums", 1) }

sub __gen_hash {
  my ($myclass, $sigilname, $args, $globals,   
      $field_ident, $onlyinapply) = @_;
  __gen_x($myclass, $sigilname, $args, $globals,
          "Hash", \&Spreadsheet::Edit::OO::_refval_tiehelper,
           $field_ident, $onlyinapply, 0); # mutable => 0
}
sub _generateHash_colx { __gen_hash(@_, "colx", 0) }
sub _generateHash_colx_desc { __gen_hash(@_, "colx_desc", 0) }

sub __gen_array{
  my ($myclass, $sigilname, $args, $globals,   
      $field_ident, $onlyinapply, $mutable) = @_;
  __gen_x($myclass, $sigilname, $args, $globals,
          "Array", \&Spreadsheet::Edit::OO::_refval_tiehelper, 
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
  my $sheet = &Spreadsheet::Edit::OO::__getsheet(0, $pkg, $uvar, 1);
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

use Carp;
our @CARP_NOT = qw(Spreadsheet::Edit::OO
                   Tie::Indirect::Array Tie::Indirect::Hash 
                   Tie::Indirect::Scalar
                  );
use File::Basename qw(basename dirname);
use Scalar::Util qw(blessed refaddr);

sub __validate_sheet_arg($) {
  my $sheet = shift;
  croak "Argument '${\u($sheet)}' is not a Spreadsheet::Edit sheet object"
    if defined($sheet) and
        !blessed($sheet) || !$sheet->isa("Spreadsheet::Edit::OO");
  $sheet;
}

my $trunclen = 40;
sub fmt_sheet($) {
  my $sheet = __validate_sheet_arg( shift ) // return("undef");
  oops($sheet) unless blessed($sheet);
  my $s = $sheet->sheetname() || $sheet->data_source();
  if (length($s) > $trunclen) { $s = "...".substr($s,-($trunclen-3)) }
  sprintf("REF(%x) %s", refaddr($sheet), vis($s));
}

# subname calling caller of caller (or specified level's caller)
sub __callingsub(;$) {
  my ($levels_back) = @_;
  local $_ = (caller(($levels_back // 1)+1))[3] // oops;
  s/.*:://;
  $_;
}

sub __default_options_cl1($$) {
  my ($opts, $cl) = @_;
  # Default from previous 'current sheet', if any.
  # N.B. The global variables $Verbose etc. are used in the "new" method
  if (my $sheet = $pkg2currsheet{scalar(caller(1+$cl))}) {
    foreach my $key (qw/verbose silent debug/) {
      unless (defined $opts->{$key}) {
        $opts->{$key} = $$sheet->{$key};
      }
    }
  }
}

sub _newsheet($$$@) {
  my ($pkg, $caller_level_adj, $dont_log, @rest) = @_;
  my $opthash = ref($rest[0]) eq "HASH" ? shift(@rest) : {};
  croak "In call to ",__callingsub,
        " : uneven arg count, expecting key => value pairs"
    unless (@rest % 2)==0;

  __default_options_cl1($opthash, 1);
  %$opthash = (%$opthash, @rest);
  $opthash->{caller_level} = 1+$caller_level_adj;

  my $sheet;
  if ($dont_log) {
    { local $opthash->{verbose} = 0;
      $sheet = Spreadsheet::Edit::OO->new($opthash);
    }
    # Ugly.  Simulate what happens inside new() after the fact
    $$sheet->{verbose} = $opthash->{verbose} // $Verbose;
  } else {
    $sheet = Spreadsheet::Edit::OO->new($opthash);
  }

  # Make the sheet the caller's "current" sheet for procedural API 
  $pkg2currsheet{$pkg} = $sheet;

  return $sheet;
}

# OO api "new" This is so users do not have to
# know about the :OO subclass, and can just write
#
#   my $obj = Spreadsheet::Edit->new(...)
#
# Unlike other methods, new() takes key => value pair arguments.
# For consistency with other methods an initial {OPTIONS} hash is
# also allowed, and is merged with any linear args in ::OO::new()
sub new {
  shift(); # our classname (ignored)
  Spreadsheet::Edit::OO->new(@_, caller_level => 1);
}

sub __callmethod($@) {
  my $methname = shift;
  my $pkg = caller(1);

  my $sheet = $pkg2currsheet{$pkg};
  if (! $sheet) {
    $sheet = _newsheet($pkg,2,1);
  } else {
    if ($methname eq "read_spreadsheet" && @{$sheet->rows} > 0) {
      my $silent = ref($_[0]) eq 'HASH' && $_[0]->{silent};
      $silent ||= $$sheet->{silent};
      carp "WARNING: $methname will over-write existing data",
           " (",$sheet->data_source,")\n(Set 'silent' to avoid this warning)\n"
        unless $silent;
    }
  }
  # +1 for call to us (__callmethod)
  # +1 for the eval below
  # +1 for the call to the OO method
  confess "bug" if ($$sheet->{caller_level} += 3) != 3;

  my ($result, @result);
  if (wantarray) {
   eval { @result = $sheet->${methname}(@_) };
  }
  elsif (defined wantarray) {
    eval { $result = $sheet->${methname}(@_) };
  } 
  else {
    eval { $sheet->${methname}(@_) };
  }
  if ($@) {
    $$sheet->{caller_level} = 0;
    croak $@
  }

  ($$sheet->{caller_level} -= 3)
    == 0 or confess "bug";
  
  # Only user packages should ever have a "current sheet"
  confess "bug" if $pkg2currsheet{__PACKAGE__};

  wantarray ? @result : $result;
}

sub __callmethod_checksheet($@) {
  my $pkg = caller(1);
  croak $_[0],": No sheet is defined for package $pkg\n" unless $pkg2currsheet{$pkg};
  goto &__callmethod;
}

sub alias(@) { __callmethod_checksheet("alias", @_) }
sub apply_all(&;@) { __callmethod_checksheet("apply_all", @_) }
sub apply(&;@) { __callmethod_checksheet("apply", @_) }
sub apply_exceptrx(&$;@) { __callmethod_checksheet("apply_exceptrx", @_) }
sub apply_torx(&$;@) { __callmethod_checksheet("apply_torx", @_) }
sub attributes(@) { __callmethod("attributes", @_) }
sub spectocx(@) { __callmethod("spectocx", @_) }
sub data_source(;$) { __callmethod("data_source", @_) }
sub delete_col($)  { goto &delete_cols; }
sub delete_cols(@) { __callmethod_checksheet("delete_cols", @_) }
sub delete_row($)  { goto &delete_rows; }
sub delete_rows(@) { __callmethod_checksheet("delete_rows", @_) }
#sub forget_title_rx() { __callmethod_checksheet("forget_title_rx", @_) }
sub transpose() { __callmethod_checksheet("transpose", @_) }
sub join_cols(&@) { __callmethod_checksheet("join_cols", @_) }
sub join_cols_sep($@) { goto &join_cols; }
sub move_col($$) { goto &move_cols }
sub move_cols($@) { __callmethod_checksheet("move_cols", @_) }
sub insert_col($$) { goto &insert_cols }
sub insert_cols($@) { __callmethod("insert_cols", @_) }
sub insert_row(;$) { goto &insert_rows; }
sub insert_rows(;$$) { __callmethod("insert_rows", @_) }
sub only_cols(@) { __callmethod_checksheet("only_cols", @_) }
sub options(@) { __callmethod("options", @_) }
# FIXME: Can package_active_sheet be replaced by
#    $result = sheet {package => "pkgname"}   ???
sub package_active_sheet($) { $pkg2currsheet{shift()} }
sub read_spreadsheet($;@) { __callmethod("read_spreadsheet", @_) }
sub rename_cols(@) { __callmethod_checksheet("rename_cols", @_) }
sub reverse_cols() { __callmethod_checksheet("reverse_cols", @_) }
sub sort_rows(&) { __callmethod_checksheet("sort_rows", @_) }
sub sheetname() { __callmethod_checksheet("sheetname", @_) }
sub split_col(&$$$@) { __callmethod_checksheet("split_col", @_) }
sub tie_column_vars(;@) { __callmethod("tie_column_vars", @_) }
sub tied_varnames(;@) { __callmethod("tied_varnames", @_) }
sub title_row() { __callmethod_checksheet("title_row", @_) }
sub title_rx(;$@) { __callmethod_checksheet("title_rx", @_) }
sub first_data_rx(;$) { __callmethod_checksheet("first_data_rx", @_) }
sub last_data_rx(;$) { __callmethod_checksheet("last_data_rx", @_) }
sub unalias(@) { __callmethod_checksheet("unalias", @_) }
sub write_csv(*;@) { __callmethod_checksheet("write_csv", @_) }
sub write_spreadsheet(*;@) { __callmethod_checksheet("write_spreadsheet", @_) }
sub write_fixedwidth(*;$) { __callmethod_checksheet("write_fixedwidth", @_) }

# Shift {OPTHASH} arg, if present (returns undef if not)
sub __opthash {
  ref($_[0]) eq 'HASH' ? shift() : undef
}

sub __logfuncifv($$@) {   # ($cl, $nesting, @items)
  my $cl = $_[0];
  my $pkg = caller(1 + $cl);
  my $curr = $pkg2currsheet{$pkg};
  return unless ($curr ? $$curr->{verbose} : $Verbose);
  goto &Spreadsheet::Edit::OO::__logfunc;
}

# Retrieve the sheet currently accessed by the procedural API & tied globals
# in the caller's package (each package is independent).
# If an argument is passed, change the sheet to the specified sheet.
#
# Always returns the previous sheet (or undef)
sub sheet(;$$) {
  my $opthash = &__opthash // {};  # shifts iff {OPTIONS}
  my $pkg = $opthash->{package} // caller();
  my $pkgmsg = $opthash->{package} ? " (pkg $pkg)" : "";
  my $curr = $pkg2currsheet{$pkg};
  if (@_) {
    __validate_sheet_arg(my $new = shift);
    #local ${$curr//\{}}->{verbose} ||= (
             #($new ? $new->{verbose} : 0) || $opthash->{verbose} );

    __logfuncifv(0,0,\fmt_sheet($new),
                     \(u($curr) eq u($new) 
                     ? " [no change]" : " [previous: ".fmt_sheet($curr)."]"),
                     \$pkgmsg);

    $pkg2currsheet{$pkg} = $new;
  } else {
    __logfuncifv(0,0,\(": ".fmt_sheet($curr)), \$pkgmsg);
  }
  $curr
}

# FUNCTION to produce the "automatic alias" identifier for an arbitrary title
sub title2ident($) {
  goto &Spreadsheet::Edit::OO::__title2ident;
}

# Non-OO api: Explicitly create a new sheet, optionally specifying options
# (possibly including the initial content).
# All the regular functions automatically create an empty sheet if no sheet
# exists, so this is only really needed when using more than one sheet,
# or if you want to initialize a sheet from data in memory.
sub new_sheet(@) {
  my $opthash = &__opthash // {};  # shifts iff {OPTIONS} if present
  my ($pkg, $fname, $line) = caller;

  $pkg = delete $opthash->{package} if $opthash->{package};

  $opthash->{data_source} 
    //= "(Sheet created with new_sheet at ".basename($fname).":$line)";

  return _newsheet($pkg, 1,             0,         $opthash, @_);
  #                pkg   $caller_level, $dont_log, @rest
}

# logmsg() - Concatenate strings to form a "log message", 
#   prefixed with a description of the "focus" sheet, optionally 
#   indicating a specific row, and suffixed by a final \n if needed.
#
# The "focus" sheet and row, if any, are determined as follows:
#
#   If the first argument is a sheet object, [sheet_object],
#   [sheet_object, rx], or [sheet_object, undef] then the indicated
#   sheet and (optionally) row are used.
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
#   If a sheet is identified but no specific rx specified, then the
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
           && @{ $_[0] } == 2 
           && ref($_[0]->[0])."" =~ /^Spreadsheet::Edit\b/) {
      ($sheet, $rx) = @{ shift @_ };
    }
  }
  if (! defined $sheet) {
    $sheet = $pkg2currsheet{caller};
  }
  if (! defined $sheet) {
    $sheet = $Spreadsheet::Edit::OO::_inner_apply_sheet; 
  }
  if (! defined $rx) {
    $rx = eval{ $sheet->rx() } if defined($sheet);
  }
  my @prefix;
  if (defined $sheet) {
    my $pfxgen = $sheet->attributes->{logmsg_pfx_gen} // \&_default_pfx_gen;
    push @prefix, "(", 
                  (defined($rx) ? "Row ".($rx+1)." " : undef),
                  (grep{defined} &$pfxgen($sheet, $rx)),
                  "): ";
  }
  my $suffix = (@_ > 0 && $_[-1] =~ /\n\z/s ? "" : "\n");
  return join "", @prefix, @_, $suffix;
}

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
      ] ;
  title_rx 1;
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


=head1 DESCRIPTION

This package allows easy manipulation of CSV data (or data from a spreadsheet)
referring to columns by title or absolute position.  Rows and
columns may be inserted, deleted, or moved. 

The usual paradigm is to iterate over rows applying a function 
to each, vaguely inspired by 'sed' and 'awk' (see C<apply> below).
Random access is also supported.

There is both a procedural and object-oriented API, which can work together.

Optionally, tied variables can be used with the procedural API.

Note: Only cell I<values> are handled; there is no provision 
for processing formatting information from spreadsheets.
The author has a notion to add format support,
perhaps integrating with Spreadsheet::Read and Spreadsheet::Write
or the packages they use.  Please contact the author if you want to help.

=head3 HOW TO IMPORT

By default only functions are imported, but most people will

  use Spreadsheet::Edit ':all';

to import both functions and helper variables (see STANDARD SHEET VARIABLES 
and VARIABLES USED DURING APPLY).

You can rename imported variables using the '-as' feature shown in 
C<Exporter::Tiny::Manual::QuickStart>.

=head1 THE 'CURRENT SHEET'

Functions and helper variables (the procedural API) implicitly operate 
on a 'current sheet' object.  
Each package has its own 'current sheet'.

A new sheet is created by any operation if there no 'current sheet'.

The 'current sheet' may be saved, changed or forgotten (i.e. unset).

Except where noted, each function has a corresponding 
OO method which operates on the specified object instead of the 'current sheet'.

See "OO DESCRIPTION" for a summary of all methods.

=head1 TIED COLUMN VARIABLES

Package variables can refer directly to columns in the 'current sheet'
during C<apply>.  For example C<$Email> and C<$FName> in 
the SYNOPSIS above.

I<tie> is used to bind these variables to the corresponding
cell in the current row of the 'current sheet' during execution of C<apply>;

See C<tie_column_vars> for details.

=head1 THE FUNCTIONS

In the following descriptions, {OPTIONS} refers to an optional first argument
which, if present, is a hashref giving additional parameters.
For example in 

   read_spreadsheet {sheetname => 'Sheet1'}, '/path/to/file.xlsx';

the {...} hash is optional and specifies the sheet name.

=head2 $curr_sheet = sheet ;

=head2 $prev_sheet = sheet $another_sheet ;

=head2 $prev_sheet = sheet undef ; 

[Procedural API only] 
Retrieve, change, or forget the 'current sheet' object used 
by the procedural API.  

Changing the current sheet immediately changes what is referenced by 
tied column variables and STANDARD SHEET VARIABLES (described later).

{OPTIONS} may specify C<< package => 'pkgname' >> to operate on the specified
package instead of the caller's package (useful for library packages).

=head2 read_spreadsheet CSVFILEPATH

=head2 read_spreadsheet SPREADSHEETPATH

=head2 read_spreadsheet "SPREADSHEETPATH!SHEETNAME"

Replace any existing data with content from the given file.  
The file may be a .csv or any format supported by Libre Office or gnumeric.

{OPTIONS} may include:

=over 6

=item sheetname => SHEETNAME

Specify which sheet in a workbook (i.e. spreadsheet file) to read.  
Alternatively, the sheet name may be appended to the input path after '!' as shown in the example.

If no SHEETNAME is given, the "last used" is read, i.e. the "active" 
sheet when the spreadsheet was saved.

=item (other options as in C<read_workbook>)

=back

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

{OPTIONS} may include:

=over 6

=item silent => bool

=item verbose => bool

=item debug => bool

=item Other C<< key => value >> pairs override details of CSV parsing.

See Text::CSV.  UTF-8 encoding is assumed by default.

=back

Due to bugs in Libre/Open Office, spreadsheet files can not
be read if LO/OO is currently running, even
for unrelated purposes (might be fixed in the future, see "BUGS").
This problem does not occur with .csv files

=head2 new_sheet  

[procedural API only] 
Create a new empty sheet and make it the 'current sheet', returning the 
sheet object.

Rarely used because a new sheet is automatically created by any operation 
if the package has no current sheet.  

{OPTIONS} may contain any of
the OPTIONS which may be passed to the OO C<new> method.

=head2 alias IDENT => COLSPEC, ... ;

=head2 alias IDENT => qr/regexp/, ... ;

Create alternate identifiers for specified columns.

Each IDENT, which must be a valid Perl identifier, will henceforth
refer to the specified column even if the identifier is the same
as the title or letter code of a different column.

C<$row{IDENT}>, C<$colx{IDENT}> etc., and a 
tied variable C<$IDENT> will refer to the specified column.

Once created, aliases automatically track the column if it's position
changes.

Regular Expressions are matched against titles only, and must match
exactly one column or else an exception is thrown.   
Other kinds of COLSPECs may be titles, existing alias names, column letters, etc.
(see "COLUMN SPECIFIERS" for details).

The COLSPEC is evaluated before the alias is created, so

   alias B => "B";

would make "B" henceforth refer to the current second column (or a different
column which has title "B" if such exists) even if that column later moves.

RETURNS: In array context, the 0-based column indices of the aliased columns;
in scalar context the column index of the first alias.

=head2 unalias IDENT, ... ;

Forget alias(es).  Any masked COLSPECs become usable again.

=head2 spectocx COLSPEC or qr/regexp/, ... ;

Returns the 0-based indicies of the specified colomn(s).
Throws an exception if there is no such column.
A regexp may match multiple columns.
See also C<%colx>.

=head2 tie_column_vars VARNAME, ...

Create tied package variables (scalars) for use during C<apply>.

Each variable is a scalar corresponding to a column, and reading or writing
it accesses the corresponding cell in the row being visited during C<apply>.
The variable name itself implies which column it refers to.
The '$' may be omitted in the VARNAME arguments to C<tie_column_vars>;

Normally you must separately declare these variables with C<our $NAME>.
However not if imported or if C<tie_column_vars> is called in 
a BEGIN block as explained below).

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
This means that it does not matter which sheet was 'current' when C<tie_column_vars>
was called with a particular name; 
it only matters that the name of a tied variable is a valid COLSPEC in 
the 'current sheet' when that variable is referenced
(otherwise a read returns I<undef> and a write throws an exception).
[*Need further clarification*]

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

=head2 Use in BEGIN{} or module import methods

C<tie_column_vars> I<imports> the tied variables into your module,
or the module specified with package => "pkgname" in {OPTIONS}.

It is unnecessary to declare tied variables if the import
occurs before code is compiled which references the variables.  This can
be the case if C<tie_column_vars> is called in a BEGIN{} block or in the
C<import> method of a module loaded with C<use>.

C<Spreadsheet::Edit::Preload> makes use of this.

=head2 title_rx {AUTODETECT_OPTIONS} ;

=head2 title_rx ROWINDEX ;

=head2 $rowindex = title_rx ;

Set or auto-detect the row containing titles.
Titles are used to generate column-selection keys (COLSPECs).

It is not necessary to call C<title_rx> unless you want to change 
auto-detect options from the defaults (including to disable auto-detect),
or to specify a title row explicitly.  By default, the title row
is auto-detected the first time any operation needs it.

If C<title_rx> I<is> called, it should be done immediately 
after calling C<read_spreadsheet> or directly modifying title cells.

An optional initial {AUTODETECT_OPTIONS} argument may contain:

=over 2

 enable     => BOOL, # False to disable auto-detect 
 min_rx     => NUM,  # first rx which may contain the title row.
 max_rx     => NUM,  # maximum rx which may contain the title row.
 required   => COLSPEC or [COLSPEC,...]  # any required title(s)
 first_cx   => NUM,  # first column ix which must contain required titles
 last_cx    => NUM,  # last column ix which must contain required titles

=back

The default options are {enable => 1, max_rx => 4}.

The first row is used which includes the C<required> title(s), if any,
and has non-empty titles in all positions.  
If C<first_cx> and/or C<last_cx> are specified then columns outside that
range are ignored and may contain anything.

An exception is thrown when auto-detect is attempted
if a plausible title row can not be found.

If you specify {AUTODETECT_OPTIONS} they will also be saved for later re-use,
for example after reading a different spreadsheet.
Specifying C<{}> restores the default options.

=head2 apply {code} ;

=head2 apply_all {code} ;

=head2 apply_torx {code} RX-OR-RXLIST ;

=head2 apply_exceptrx {code} RX-OR-RXLIST ;

Execute the specified code block (or referenced sub) once for each row.

While executing the code block, tied column variables and
the sheet variables C<@crow>, C<%crow>, C<$rx> and C<$linenum> 
and corresponding OO methods will refer to the row being visited.

C<apply> normally visits all rows which follow the title row, or all rows
if there is no title row. 
If B<first_data_rx> and B<last_data_rx> are defined, then they
further limit the range visited.  

C<apply_all> unconditionally visits every row, including any title row.

C<apply_torx> or C<apply_exceptrx> visit exactly the indicated rows.
RX-OR-RXLIST may be either a single row index or a [list of rx];

Rows may be safely inserted or deleted during 'apply';
rows inserted after the currently-being-visited row will be visited 
at the proper time.

An 'apply' sub may change the 'current sheet', after which
global variables will refer to the other sheet and
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


For example, the "FIRST NAME" column may be accessed
many ways:

  alias Name => "FIRST NAME";
  apply {

    $crow{"FIRST NAME"}            # %crow indexed by title
    $crow{Name}                    #   using an explicit alias
    $crow{FIRST_NAME}              #   using the AUTOMATIC ALIAS
  
    $crow[ $colx{"FIRST NAME"} ];  # @crow indexed by a 0-based index
    $crow[ $colx{"Name"} ];        #  ...obtained from %colx
    $crow[ $colx{"FIRST_NAME"} ];  # 
  
    $rows[$rx]->[ $colx{FIRST_NAME} ] # Directly accessing @rows

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

Returns a list of the previous row indicies of all rows in the sheet.

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

=head2 transpose

Invert the relation, i.e. rotate and flip the table.  
Cells A1,B1,C1 etc. become A1,A2,A3 etc.
Any title_rx is forgotten.

=head2 logmsg [FOCUSARG,] string, string, ...

(not exported by default)

Concatenate strings, prefixed by a description
of the 'current sheet' and row during C<apply>, if any (or with FOCUSARG,
the specified sheet and/or row).

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

=head2 write_csv CSVFILEPATH

=head2 write_csv *FILEHANDLE

=head2 write_csv $filehandle

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

Set or retrieve miscellaneous sheet-global options.   
When setting, the previous value of
the last option specified is returned.  The only options currently defined
are I<silent>, I<verbose> and I<debug>.

=head2 $hash = attributes ;

Returns a reference to a hash in which you may store arbitrary data
in the sheet object in memory.

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
and C<$title_row> is the same as C<$rows[ $title_rx ]>.

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

=item (5) a spreadsheet letter code (A,B,...Z, AA etc.) *

=item (6) a Regexp (qr/.../) which matches an actual title

=item (7) a numeric column index (0-based)

=item (8) '^' or '$' (means first or last column, respectively)


=back

*These may only be used if they do not conflict an
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
so can be used as the names of tied variables
and as bareword keys to C<%colx>, C<%crow> and related OO interfaces,

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

=head2 Spreadsheet::Edit->new(OPTIONS...)

=head2 Spreadsheet::Edit->new(clone => $existing_sheet)

=head2 Spreadsheet::Edit->new(rows => [rowref,rowref,...], 
         linenums => [...], 
         data_source => "where this came from");

=head2 Spreadsheet::Edit->new(num_cols => $number)  # no initial content

          
Creates a new "sheet" object.

=head2 METHODS

Sheet objects have methods named identically to all the functions
described previously (except for C<sheet>, C<new_sheet>, 
C<read_workbook> and C<logmsg>).
Note that Perl always requires parenthesis around method arguments.


Besides all those, the following methods are available:

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

Jim Avera (jim.avera at gmail).   Public Domain or CC0.

=for Pod::Coverage fmt_sheet write_fixedwidth delete_row package_active_sheet

=for Pod::Coverage tied_varnames title2ident

=cut


#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Setup;  # parses @ARGV and sets $debug, $verbose and $silent
use t_Utils;


use Spreadsheet::Edit qw(:all);

my @saved_data;
sub test_autodetect($$) {
  my ($opthash, $expected_rx) = @_;
  my $error_expected = ! defined $expected_rx;
  my $lno = (caller)[2];
  my $msg = ivis 'Line $lno: Testing $opthash';
  $msg .= ivis ' expecting $expected_rx' unless $error_expected;
  my $got;
  sheet undef;
  new_sheet rows => \@saved_data;
  options debug => $debug, verbose => $verbose||$debug, silent => $silent && !$debug;
  title_rx $opthash      # void context, should not auto-detect
    if defined $opthash;
  die if defined ${sheet()}->{title_rx};
  eval{ $got = title_rx; }; verif_eval_err if $error_expected;
  if ($error_expected) {
    say $@ if $debug;
    say "$msg [expected error observed]" unless $silent;
    return;
  }
  confess "ERROR: $msg (num_cols=$num_cols) ...\n$@" if $@;
  croak "$msg, got ",u($got) unless u($got) eq $expected_rx;
  die unless ${sheet()}->{title_rx} == $expected_rx;
  say $msg, " (succeeded)" unless $silent;
}

my $inpath = create_testdata(
    rows => [
      [ "Rowx 0 pre-title-row with only one non-empty column" ],
      [ "A title1", "bee title", "Ctitle", "Dtitle" ],     # missing "E" cell
      [ "A title2", "bee title", "Ctitle", "Dtitle", "" ], # empty "E" cell
      [ "A title3", "Btitle",    "Ctitle", "Dtitle", "Etitle" ], # **TITLES**
      [ "A title4", "Btitle",    "Ctitle", "Dtitle", "Etitle" ], # duplicate
      [ "A title5", "Btitle",    "Ctitle", "Dtitle", ""       ],
      [ "A title6", "Btitle",    "Ctitle", "",       "Etitle" ], 
      [ "A title7", "Btitle",    "Ctitle", "Dtitle", "not e"  ],
      [ "A title8", "Btitle",    "Ctitle", "Dtitle", "Especial" ], # alternate
      [ "A title9", "Btitle",    "Ctitle", "Dtitle", ""       ],
    ],
    gen_rows => 4,  # some more data rows
);
read_spreadsheet $inpath;
@saved_data = (@rows);

sub renew_curr_sheet() {  # restores to pre-autodetected state
  read_spreadsheet {silent => 1}, $inpath;
  die "bug" if defined ${sheet()}->{title_rx};
  #${sheet()}->{title_rx} = undef;  # faster, but very white-box
}

test_autodetect undef, 3;
test_autodetect {min_rx=>3}, 3;
test_autodetect {min_rx=>3, max_rx=>3}, 3;
test_autodetect {min_rx=>3, max_rx=>4}, 3;
test_autodetect {min_rx=>4, max_rx=>4}, 4;
test_autodetect {min_rx=>5}, 7; # skips rx5 & rx6 with an empty title
foreach my $reqd ("Ctitle", qr/^Ctitle$/, qr/^C/) {
  test_autodetect {required => $reqd}, 3; # rx 0-2 contain empties
}
test_autodetect {required => "Etitle"}, 3;
test_autodetect {required => "Etitle", max_rx => 3}, 3;
test_autodetect {required => "Etitle", min_rx => 4}, 4;
test_autodetect {min_rx=>5, max_rx=>4}, undef;

test_autodetect {first_cx=>3}, 3;
test_autodetect {first_cx=>3, last_cx=>3}, 1; # empties in other cols ignored
test_autodetect {first_cx=>3, last_cx=>4}, 3;
test_autodetect {first_cx=>4, last_cx=>4}, 3;
test_autodetect {first_cx=>4, last_cx=>4, required => "Ctitle"}, undef;
test_autodetect {first_cx=>4, last_cx=>4, required => "Etitle"}, 3;
test_autodetect {first_cx=>4,             required => "Etitle"}, 3;
test_autodetect {             last_cx=>3, required => "Etitie"}, undef; # Etitle is in cx 4
test_autodetect {first_cx=>5}, undef; # first_cx exceeds num_cols-1

test_autodetect {first_cx=>3,             required => qr/^C/ }, undef; # Ctitle is in cx 2
test_autodetect {first_cx=>3, last_cx=>4, required => qr/^C/ }, undef;
test_autodetect {first_cx=>3,             required => qr/^D/ }, 3; # rx 0-2 contain empties >=cx3
test_autodetect {first_cx=>3, last_cx=>5, required => qr/^D/ }, undef; # last_cx >= num_cols
test_autodetect {first_cx=>3, last_cx=>6, required => qr/^D/ }, undef; # last_cx >= num_cols
test_autodetect {first_cx=>4,             required => qr/^[CD]/ }, undef; # Dtitle is in cx 3
test_autodetect {first_cx=>3, last_cx=>4, required => qr/^[CD]/ }, 3; # only one Regex match required
test_autodetect {first_cx=>3,             required => qr/^[CD]/ }, 3;
test_autodetect {first_cx=>3, last_cx=>5, required => qr/^D/ }, undef; # last_cx >= num_cols
test_autodetect {first_cx=>3, last_cx=>6, required => qr/^D/ }, undef; # last_cx >= num_cols
test_autodetect {required => qr/^Notmatched/}, undef;

# The above "test_autodetct" all first call in void context to set {OPTIONS},
# then just "$result = title_rx()" to trigger auto-detect.
#
# Test other combinations of {OPTIONS} and ROWINDEX argument...

# Void-context call with an undef arg should immediately auto-detect.
read_spreadsheet {silent => 1}, $inpath;  
die "bug" if defined ${sheet()}->{title_rx};
title_rx {first_cx=>3,             required => qr/^[CD]/ }, undef;
die "bug" unless ${sheet()}->{title_rx} == 3;

# Ditto if result requested
renew_curr_sheet();
die unless 3==title_rx {first_cx=>3,             required => qr/^[CD]/ }, undef;
die "bug" unless ${sheet()}->{title_rx} == 3;
die unless 3==title_rx;

# Re-use saved options
renew_curr_sheet();
die unless 3==title_rx;

# Change saved options; No effect on current title row
title_rx {required => "Especial", max_rx => 999}; # void context
die "bug" unless ${sheet()}->{title_rx} == 3;
die unless 3==title_rx;

# But saved options are used when re-detecting
renew_curr_sheet();
die unless 8==title_rx;

# No auto-detect if ROWINDEX is specified 
die unless 4==title_rx 4;

# But saved options are still there
renew_curr_sheet();
die unless 8==title_rx;


# Test other functions which should auto-detect if needed.

sub check_autodetect($) {
  my $code = shift;
  my $lno = (caller)[2];
  my $s = sheet;
  local $$s->{debug} = $debug;
  local $$s->{verbose} = $verbose||$debug;
  local $$s->{silent } = $silent && !$debug;
  croak "bug(already has title_rx)" if defined ${sheet()}->{title_rx};
  my $r = eval $code; 
  die "Line ${lno}: '$code' --> Exception: $@" if $@;
  die ivisq 'Line ${lno}: $code : BUG--did not autodetect (r=$r)\n${sheet()}\n'
    unless defined ${sheet()}->{title_rx};
  confess "bug--unexpected title_rx" unless ${sheet()}->{title_rx} == 8;
  say "Line ${lno}: $code  ...autodetects as expected" unless $silent;
}
sub check_no_autodetect($) {
  my $code = shift;
  my $lno = (caller)[2];
  my $s = sheet;
  local $$s->{debug} = $debug;
  local $$s->{verbose} = $verbose||$debug;
  local $$s->{silent } = $silent && !$debug;
  croak "bug(already has title_rx)" if defined ${sheet()}->{title_rx};
  eval $code; 
  die "Line ${lno}: '$code' --> Exception: $@" if $@;
  die "Line ${lno}: BUG--unexpected autodetect after '$code'" if defined ${sheet()}->{title_rx};
  say "Line ${lno}: $code  ...does NOT autodetect (as expected)" unless $silent;
}

renew_curr_sheet();
{ my $dummy = title_rx; }
die "bug" unless ${sheet()}->{title_rx} == 8;

${sheet()}->{title_rx} = undef;
check_autodetect 'alias Foo => "Btitle";';
say "Line ",__LINE__,dvis ': $colx{Foo} $colx{Btitle} $colx{Especial}' 
  unless $silent;

move_col 0, "Btitle";
die unless $colx{Foo} == 0;  # aliases track
say "Line ",__LINE__,dvis ': $colx{Foo} $colx{Btitle} $colx{Especial}'
  unless $silent;

renew_curr_sheet(); # removes alias Foo
check_autodetect 'my $d = spectocx("Btitle");';

# insert/delete_cols should not autodetect with only absolutes or aliases 
renew_curr_sheet();
check_no_autodetect 'insert_cols ">\$", undef';

eval{ my $d = spectocx 'Btitle'; }; verif_eval_err; # cx 5 is empty
$rows[8][-1] = "Especial";
die unless 8 == title_rx;                           # now it's golden

${sheet()}->{title_rx} = undef;
check_no_autodetect 'delete_cols "\$"';

check_no_autodetect 'insert_cols ">\$", undef';
eval{ my $d = spectocx 'Btitle'; }; verif_eval_err; # cx 5 is empty

$rows[8][-1] = "Especial";
check_no_autodetect 'alias FFF => "\$"'; # unindexed spec
check_no_autodetect 'alias GGG => 0';    # unindexed spec
check_no_autodetect 'alias HHH => 1';    # unindexed spec

${sheet()}->{title_rx} = undef;
check_no_autodetect 'delete_cols "FFF"';
check_no_autodetect 'alias EEE => "\$"';
check_no_autodetect 'insert_cols ">EEE", undef';
eval{ my $d = spectocx 'Btitle'; }; verif_eval_err; # cx 5 is empty
$rows[8][-1] = "Especial";
#say avis @{ sheet() };
die unless 8 == title_rx; # rx 3 is still beautiful

${sheet()}->{title_rx} = undef;
check_no_autodetect '#nop';
check_no_autodetect 'only_cols 0,"EEE"';
die unless $colx{EEE} == 1; # column relocated
check_autodetect 'rename_cols "EEE","Extra"';
die unless $colx{Extra} == 1; 
die unless $colx{EEE} == 1;  # old aliases remain also
${sheet()}->{title_rx} = undef;
check_no_autodetect 'die unless $colx{EEE}==1;'; # alias, still
check_no_autodetect 'sheet->[4]{EEE} = 42';
check_no_autodetect 'die unless sheet->get(4,"EEE")==42;'; 
check_no_autodetect 'die unless sheet->set(4,"EEE",43)==43;'; 
check_no_autodetect 'die unless $rows[4]{EEE} == 43;';

exit 0;

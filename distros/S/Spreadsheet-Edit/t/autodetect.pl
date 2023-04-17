#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops mytempfile mytempdir/; # strict, warnings, Carp etc.
use t_TestCommon  # Test::More etc.
         qw/$verbose $silent $debug dprint dprintf
            bug checkeq_literal expect1 check 
            verif_no_internals_mentioned
            insert_loc_in_evalstr verif_eval_err
            arrays_eq hash_subset
            string_to_tempfile
            @quotes/;
use t_SSUtils;

use Spreadsheet::Edit qw(:all);

my $inpath = create_testdata(
    rows => [
      [ "Rowx 0 pre-title-row with only one non-empty column" ], # [0] B..E missing
      [ "A title1", "bee title", "Ctitle", "Dtitle" ],           # [1] cell E missing
      [ "A title2", "bee title", "Ctitle", "Dtitle", "" ],       # [2] cell E empty
      [ "A title3", "Btitle",    "Ctitle", "Dtitle", "Etitle" ], # [3] **TITLES**
      [ "A title4", "Btitle",    "Ctitle", "Dtitle", "Etitle" ], # [4] duplicate
      [ "A title5", "Btitle",    "Ctitle", "Dtitle", ""       ], # [5]
      [ "A title6", "Btitle",    "Ctitle", "",       "Etitle" ], # [6]
      [ "A title7", "Btitle",    "Ctitle", "Dtitle", "not e"  ], # [7]
      [ "A title8", "Btitle",    "Ctitle", "Dtitle", "Especial" ], # [8] alternate
      [ "A title9", "Btitle",    "Ctitle", "Dtitle", ""       ],
    ],
    gen_rows => 4,  # some more data rows
);
#warn dvis '### $debug $verbose $silent $Spreadsheet::Edit::Verbose';
read_spreadsheet $inpath;
defined(sheet()) or die "read_spreadsheet did not create current_sheet";
! ${sheet()}->{cmd_nesting} or die "non-zero cmd_nesting";
my @saved_data = (@rows); # for construct-from-memory tests
#sheet(undef);  
sheet({verbose => 1}, undef);  

sub test_autodetect($$;$) {
  my ($rs_opthash, $expected_rx, $expected_err_re) = @_;
  my $error_expected = defined($expected_err_re) 
                       || (!defined($expected_rx) && !$rs_opthash)
                       || (!defined($expected_rx) && $rs_opthash && defined($rs_opthash->{title_rx}));
  confess "missing expected_err_re" 
    if $error_expected && ref($expected_err_re) ne "Regexp";
  my $have_opthash = defined($rs_opthash); # possibly {}

  my $lno = (caller)[2];
  my $msg = ivis 'Line $lno:';
  $msg .= "Testing ".vis($rs_opthash) if $have_opthash; # {...}
  $msg .= ivis ' Expecting $expected_rx' unless $error_expected;
  my $got;
  
  # %$rs_opthash is for read_spreadsheet() and may contain title_rx => ...
  # but when calling title_rx() this is passed as a separate argument.
  my %t_opts;
  my $t_arg = 'auto';
  if ($have_opthash) {
    %t_opts = %$rs_opthash;
    $t_arg = delete($t_opts{title_rx}) if exists($t_opts{title_rx});
  }

  #################################################################
  # Test explicit title_rx() call after creating sheet from memory
  #################################################################
  
  new_sheet rows => \@saved_data;
  die "$msg : wrong initial title_rx()" if defined title_rx(); 
  die "$msg : wrong initial {title_rx}" if defined ${sheet()}->{title_rx};
  die "$msg : wrong data" unless $rows[8]{A} eq "A title8";

  my ($got1, @targs);
  $@ = "should never see this";
  if ($have_opthash) {
    @targs = (\%t_opts, $t_arg);
    eval{ $got1 = title_rx(\%t_opts, $t_arg) }; verif_eval_err($expected_err_re) if $error_expected;
  } else {
    @targs = ($t_arg);
    eval{ $got1 = title_rx(          $t_arg) }; verif_eval_err($expected_err_re) if $error_expected;
  }
  my $ex = $@;
  if ($ex) {
    if ($error_expected) {
      say $ex if $debug;
      $msg .= "\n  ".($expected_err_re ? "[title_rx() got expected err]" : "[title_rx() failed as expected]");
    } 
    else {
      croak "$msg, but UNEXPECTED ERROR from title_rx(...): $ex\n";
    }
  } else {
    croak "$msg, title_rx() Unexpectedly had NO ERROR" if $error_expected;
    croak "$msg, but after title_rx",avis(@targs)," title_rx=",u(title_rx)
      unless u(title_rx) eq u($expected_rx);
    croak "$msg, but title_rx",avis(@targs)," returned ",u($got1) 
      unless u($got1) eq u($expected_rx);
    croak "$msg, but after title_rx",avis(@targs)," title_rx=",u(title_rx)
      unless u(title_rx) eq u($got1);
  }

  #################################################################
  # Test read_spreadsheet 
  #################################################################
  
  # sheet();

  my (@rsargs);
  $@ = "should never see this #2";
  if ($have_opthash) {
    @rsargs = ($rs_opthash, $inpath);
    eval{ read_spreadsheet($rs_opthash, $inpath) }; verif_eval_err($expected_err_re) if $error_expected;
  } else {
    @rsargs = ($inpath);
    eval{ read_spreadsheet(             $inpath) }; verif_eval_err($expected_err_re) if $error_expected;
  }
  $ex = $@;
  if ($ex) {
    if ($error_expected) {
      say $ex if $debug;
      $msg .= "\n  ".($expected_err_re ? "[read_spreadsheet() got expected err]" : "[read_spreadsheet() failed as expected]");
    } else {
      croak "$msg, but UNEXPECTED ERROR from read_spreadsheet(...): $ex\n";
    }
  } else {
    ! ${sheet()}->{cmd_nesting} or die "$msg : non-zero cmd_nesting";
    croak "$msg, read_spreadsheet() Unexpectedly had NO ERROR" if $error_expected;
    croak "$msg, but after read_spreadsheet, title_rx=",u($title_rx) 
      unless u(title_rx) eq u($expected_rx);
  }

  say $msg, " (test succeeded)" unless $silent;
}#test_autodetect

########################
# Success cases
########################
test_autodetect {title_rx => undef}, undef;
test_autodetect undef, 3;
test_autodetect {}, 3;
test_autodetect {min_rx=>3}, 3;
test_autodetect {min_rx=>3, max_rx=>3}, 3;
test_autodetect {min_rx=>3, max_rx=>4}, 3;
test_autodetect {min_rx=>4, max_rx=>4}, 4;
test_autodetect {min_rx=>5}, 7; # skips rx5 & rx6 with an empty title
foreach my $reqd ("Ctitle", qr/^Ctitle$/, qr/^C/) {
  test_autodetect {required => $reqd}, 3; # rx 0-2 contain empties
}
test_autodetect {first_cx=>3,             required => qr/^D/ }, 3; # rx 0-2 contain empties >=cx3
test_autodetect {first_cx=>3,             required => qr/^[CD]/ }, 3;
test_autodetect {first_cx=>3, last_cx=>3}, 1; # empties in other cols ignored
test_autodetect {first_cx=>3, last_cx=>4, required => qr/^[CD]/ }, 3; # only one Regex match required
test_autodetect {first_cx=>3, last_cx=>4}, 3;
test_autodetect {first_cx=>3}, 3;
test_autodetect {first_cx=>4,             required => "Etitle"}, 3;
test_autodetect {first_cx=>4, last_cx=>4, required => "Etitle"}, 3;
test_autodetect {first_cx=>4, last_cx=>4}, 3;
test_autodetect {required => "Etitle", max_rx => 3}, 3;
test_autodetect {required => "Etitle", min_rx => 4}, 4;
test_autodetect {required => "Etitle"}, 3;

########################
# Failure cases
########################
test_autodetect {min_rx=>5, max_rx=>4}, undef, qr/min_rx.*greater.*max_rx/s;
test_autodetect {first_cx=>4, last_cx=>4, required => "Ctitle"}, undef, 
                qr/matched.*but.*unacceptable.*cx/is;
test_autodetect {             last_cx=>3, required => "Etitie"}, undef, 
                qr/^(?!.*rx [4-9]).*Etitie.*not found/s; # Etitle is in cx 4
test_autodetect {first_cx=>5}, undef, 
                qr/cx.*out of range/;                    # first_cx exceeds num_cols-1
test_autodetect {first_cx=>3,             required => qr/^C/ }, undef, 
                qr/matched.*unacceptable.*cx/is;         # Ctitle is in cx 2
test_autodetect {first_cx=>3, last_cx=>4, required => qr/^C/ }, undef, 
                qr/matched.*unacceptable.*cx/is;         # Ctitle is in cx 2
test_autodetect {first_cx=>4,             required => qr/^[CD]/ }, undef, 
                qr/matched.*unacceptable.*cx/is;         # Dtitle is in cx 3
test_autodetect {first_cx=>3, last_cx=>2, required => qr/^D/ }, undef, 
                qr/first_cx.*is less than.*last_cx/s;    # last_cx < first_cx
test_autodetect {first_cx=>0, last_cx=>1, required => qr/^D/ }, undef, 
                qr/^(?!.*rx [4-9]).*matched.*unacceptable.*cx/is; # Etitle is in cx 4
test_autodetect {required => qr/^Notmatched/}, undef, 
                qr/Notmatch.*not found/s; 

#TODO: Various operations which (with new implementation) should not auto-detect

exit 0;

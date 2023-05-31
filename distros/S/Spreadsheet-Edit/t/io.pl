#!/usr/bin/perl
# *** DO NOT USE Test2 FEATURES becuase this is a sub-script ***
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp etc.

use t_TestCommon  # Test::More etc.
         qw/$verbose $silent $debug dprint dprintf
            bug mycheckeq_literal expect1 mycheck 
            verif_no_internals_mentioned
            insert_loc_in_evalstr verif_eval_err
            arrays_eq hash_subset
            @quotes/;

use t_SSUtils;
use Capture::Tiny qw/capture_merged tee_merged/;
use Encode qw/encode decode/;

use Spreadsheet::Edit qw/:all logmsg fmt_sheet cx2let let2cx sheet/;
use Spreadsheet::Edit::IO qw/convert_spreadsheet/;

use Test::Deep::NoTest qw/eq_deeply/;

{ my $path; eval{ $path = Spreadsheet::Edit::IO::_openlibre_path() };
  if (!$path && $@ =~ /not find.*Libre/i) {
    say __FILE__,": Skipping all because LibreOffice is not installed"
      unless $silent;
    exit 0
  }
  die "$@ " if $@;
  say "Using $path" unless $silent;
}

my $cwd = fastgetcwd;
my $input_xlsx_path = abs2rel(fast_abs_path("$Bin/../tlib/Test.xlsx"), $cwd);

sub verif_Sheet1(;$){
  my $msg = $_[0] // "";
  eq_deeply(title_rx(), 0) or die "${msg} title_rx is not 0";
  eq_deeply([@{ title_row() }],["First Name","Last Name","Email","Date"])
    or die "${msg} Sheet1 titles wrong";
  eq_deeply([@{ $rows[3] }],["Françoise-Athénaïs","de Rochechouart","","10/05/1640"])
  #eq_deeply([@{ $rows[3] }],["Françoise-Athénaïs","de Rochechouart","","Oct 5, 1640"])
    or confess "${msg} Sheet1 row 4 is wrong, got: ",avis(@{ $rows[3] });
}
sub verif_Another_Sheet(;$) {
  my $msg = $_[0] // "";
  eq_deeply(title_rx(), 0) or confess "${msg} title_rx is not 0";
  eq_deeply([@{ title_row() }],["Input","Output"])
    or confess "Another Sheet titles wrong;",vis([@{ title_row() }]);
  apply {
    my $exp = 100 + $rx - 1;
    eq_deeply($crow{B}, $exp) 
      or confess "$msg Another Sheet:Col B, rx $rx is $exp";
  }
}

sub doconvert(@) {
  if (@_ % 2 == 0) {
    convert_spreadsheet(verbose => $verbose, debug => $debug, @_);
  } else {
    my $inpath = shift;
    convert_spreadsheet($inpath, verbose => $verbose, debug => $debug, @_);
  }
}
sub doread($$) {
  my ($opts, $inpath) = @_;
  sheet undef;
  eq_deeply(sheet(), undef) or confess "sheet() did not return undef";

  eq_deeply(eval{my $dum=$num_cols},undef) or confess "num_cols unexpectedly valid";
  read_spreadsheet {debug => $debug, verbose => $verbose, %$opts}, $inpath;
  confess "num_cols is not positive" unless $num_cols > 0;
}
# Test the various ways of specifying a sheet name
doread({}, $input_xlsx_path."!Sheet1"); verif_Sheet1();
doread({sheetname => "Sheet1"}, $input_xlsx_path); verif_Sheet1;
doread({sheetname => "Sheet1"}, $input_xlsx_path."!Sheet1"); verif_Sheet1;
doread({sheetname => "Another Sheet"}, $input_xlsx_path."!Another Sheet"); verif_Another_Sheet;

# Confirm that conflicting specs are caught
eval{my $dum=read_spreadsheet {sheetname => "Sheet1", verbose => $verbose}, $input_xlsx_path."!Another Sheet" };
die "Conflicting sheetname opt and !suffix not caught" if $@ eq "";

# Extract all sheets
my $dirpath = Path::Tiny->tempdir;
doconvert(outpath => $dirpath, allsheets => 1, inpath => $input_xlsx_path, cvt_to => "csv");
say dvis '###BBB $dirpath ->children : ',avis($dirpath->children) if $debug;
my $got = [sort map{$_->basename} $dirpath->children];
my $exp = [sort "Sheet1.csv", "Another Sheet.csv"];
eq_deeply($got, $exp) or die dvis 'Missing or extra sheets: $got $exp';

#say "### Sheet1.csv content ###";
#print $dirpath->child("Sheet1.csv")->slurp_utf8;
#say "##########################";

my $testcsv_path = $dirpath->child("Sheet1.csv");
my $exp_chars = $testcsv_path->slurp_utf8();

# Round-trip csv -> ods -> csv check
{
  my $h1 = doconvert(inpath => $testcsv_path, cvt_to => "ods");
  my $h2 = doconvert(inpath => $h1->{outpath}, cvt_to => "csv");
  my $got_chars = path($h2->{outpath})->slurp_utf8;
  if ($got_chars eq $exp_chars) {
    say "Round-trip csv->ods->csv succeeded!\n" unless $silent;
  } else {
    $Data::Dumper::Interp::Foldwidth = 20;
    die "Round-trip csv->ods->csv mismatch:\n",
        ivis('Original: $exp_chars\n'),
        ivis('Result:   $got_chars\n') ;
  }
}

# "Read" a csv; should be a pass-thru without conversion
{
  read_spreadsheet {verbose => $verbose}, $testcsv_path;
  verif_Sheet1 "(extracted csv)";
  my $hash = doconvert(inpath=>$testcsv_path, cvt_to => 'csv');
  die "expected null converstion" unless $hash->{outpath} eq $testcsv_path;
}

# csv-to-csv with transcoding
{
  my $tdir = Path::Tiny->tempdir();
  for my $enc (qw/UTF-8 UTF-16 UTF-32/) {
    say "------------- Transcode to/from $enc -------------" if $debug;
    my $fromutf8_result;
    { 
      my $h = doconvert(inpath => $testcsv_path,
                        outpath => $tdir->child("${enc}.csv"),
                        output_encoding => $enc);
      my $got_octets = path($h->{outpath})->slurp_raw;
      my $got_chars = decode($enc,$got_octets,Encode::FB_CROAK|Encode::LEAVE_SRC);
      die "transcoding to $enc did not work\n",dvis('$got_octets\n$got_chars\n$exp_chars\n') unless $got_chars eq $exp_chars;
      $fromutf8_result = $h->{outpath};
    }
    { my $h = doconvert(inpath => $fromutf8_result,
                        cvt_to => "csv", 
                        input_encoding => $enc,
                        #output_encoding => 'utf8'
                       );
      my $got_octets = path($h->{outpath})->slurp_raw;
      my $got_chars = decode("UTF-8",$got_octets,Encode::FB_CROAK|Encode::LEAVE_SRC);
      die "transcoding back to utf8 did not work\n",dvis('$got_octets\n$got_chars\n$exp_chars\n') unless $got_chars eq $exp_chars;
    }
  }
}

say "Done." unless $silent;
exit 0;


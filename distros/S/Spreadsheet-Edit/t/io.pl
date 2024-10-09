#!/usr/bin/perl
# *** DO NOT USE Test2 FEATURES becuase this is a sub-script ***
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp etc.

use t_TestCommon ':no-Test2',
         qw/$verbose $silent $debug dprint dprintf
            bug mycheckeq_literal expect1 mycheck
            verif_no_internals_mentioned
            insert_loc_in_evalstr verif_eval_err
            arrays_eq hash_subset
            @quotes/;

### This doesn't break the no-internals-mentioned test in t/60_all.t
### because 'carp' is never (normally) called, i.e. no warnings to users occur
##$Carp::Verbose = 1; # show backtrace on errors

use t_SSUtils;
use Encode qw/encode decode/;

use Spreadsheet::Edit qw/:all logmsg fmt_sheet cx2let let2cx sheet/;
use Spreadsheet::Edit::IO qw/convert_spreadsheet OpenAsCsv/;
use File::BOM qw/open_bom/;
use Data::Hexify qw/Hexify/;

use Test::Deep::NoTest qw/eq_deeply/;

my $cwd = fastgetcwd;
#my $input_xlsx_path = abs2rel(fast_abs_path("$Bin/../tlib/Test.xlsx"), $cwd);
my $tlib = path("$Bin/../tlib")->absolute;
my $input_xlsx_path = $tlib->child("Test.xlsx");

# Is LibreOffice (or some substitute) installed?
my $can_cvt_spreadsheets    = Spreadsheet::Edit::IO::can_cvt_spreadsheets();
my $can_extract_named_sheet = Spreadsheet::Edit::IO::can_extract_named_sheet();
my $can_extract_allsheets   = Spreadsheet::Edit::IO::can_extract_allsheets();

sub verif_Sheet1(;$){
  my $msg = $_[0] // "";
  eq_deeply(title_rx(), 0) or die "${msg} title_rx is not 0";
  eq_deeply([@{ title_row() }],["First Name","Last Name","Email","Date"])
    or confess "${msg} Sheet1 titles wrong\n", dvis('${\title_rx()} @{ title_row() }');
  #eq_deeply([@{ $rows[3] }],["Françoise-Athénaïs","de Rochechouart","","Oct 5, 1640"])
  my $exp = ["Françoise-Athénaïs","de Rochechouart","","10/05/1640"];
  eq_deeply([@{ $rows[3] }],$exp)
    or confess "${msg} Sheet1 row 4 is wrong,\n",
               "  got: ",avis(@{ $rows[3] }),"\n",
               "  exp: ",avis(@{ $exp }),
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
    #convert_spreadsheet(verbose => $verbose, debug => $debug, @_);
    unshift @_, (verbose => $verbose, debug => $debug, silent => $silent);
    goto &convert_spreadsheet;
  } else {
    my $inpath = shift;
    #convert_spreadsheet($inpath, verbose => $verbose, debug => $debug, @_);
    unshift @_, (verbose => $verbose, debug => $debug, silent => $silent);
    unshift @_, $inpath;
    goto &convert_spreadsheet;
  }
}
sub doread($$) {
  my ($opts, $inpath) = @_;
  sheet undef;
  eq_deeply(sheet(), undef) or confess "sheet() did not return undef";

  eq_deeply(eval{my $dum=$num_cols},undef) or confess "num_cols unexpectedly valid";
  read_spreadsheet {debug => $debug, verbose => $verbose, silent => $silent, %$opts}, $inpath;
  confess "num_cols is not positive" unless $num_cols > 0;
}

#my $testcsv_path = $dirpath->child("Sheet1.csv");
my $testcsv_path = $tlib->child("Sheet1_unquoted.csv");
my $exp_chars = $testcsv_path->slurp({binmode => ":raw:encoding(UTF-8):crlf"});
my $exp_CRLFchars = $exp_chars =~ s/\n/\x0D\x0A/gr;

# Well, we can't prevent CR,LF line endings on Windows.  So first
# convert the test data .csv to "local" line endings so it will match.
my $local_testcsv_UTF8 = Path::Tiny->tempfile("local_testcsv_UTF8_XXXXX");
$local_testcsv_UTF8->spew({binmode => ":perlio:encoding(UTF-8)"}, $exp_chars);

(my $local_testcsv_UTF8CRLF = Path::Tiny->tempfile("local_testcsv_UTF8CRLF_XXXXX"))
  ->spew({binmode => ":perlio:encoding(UTF-8)"}, $exp_CRLFchars);

(my $local_testcsv_UTF16 = Path::Tiny->tempfile("local_testcsv_UTF16_XXXXX"))
  ->spew({binmode => ":perlio:encoding(UTF-16)"}, $exp_chars);

(my $local_testcsv_UTF16BECRLF = Path::Tiny->tempfile("local_testcsv_UTF16BECRLF_XXXXX"))
  ->spew({binmode => ":perlio:encoding(UTF-16BE)"}, $exp_CRLFchars);

(my $local_testcsv_UTF16LE = Path::Tiny->tempfile("local_testcsv_UTF16LE_XXXXX"))
  ->spew({binmode => ":perlio:encoding(UTF-16LE)"}, $exp_chars);

my $local_testcsv_UTF8CRLFWithBOM = Path::Tiny->tempfile("local_testcsv_UTF8CRLFWithBOM_XXXXX");
{
  $local_testcsv_UTF8CRLF->spew({binmode => ":perlio:encoding(UTF-8)"}, $exp_CRLFchars);
  $local_testcsv_UTF8CRLFWithBOM->spew({binmode => ":perlio:encoding(UTF-8)"}, "\N{U+feff}");
  $local_testcsv_UTF8CRLFWithBOM->append_utf8($exp_CRLFchars);
}

# Confirm that conflicting specs are caught
eval{my $dum=read_spreadsheet {sheetname => "Sheet1", verbose => $verbose}, $input_xlsx_path."!Another Sheet" };
die "Conflicting sheetname opt and !suffix not caught" if $@ eq "";

# "Read" a csv; should be a pass-thru without conversion when possible
foreach (
   #  path              exp_passthru  input_encoding     output_encoding
   [$local_testcsv_UTF8,           1, undef             ,undef           ],
   [$local_testcsv_UTF8CRLF,       1, undef             ,undef           ],
   [$local_testcsv_UTF8,           0, undef             ,"UTF-16BE"      ],
   [$local_testcsv_UTF8CRLFWithBOM,0, undef             ,undef           ],
   [$local_testcsv_UTF8CRLFWithBOM,0,"UTF-32"           ,undef           ], # BOM overrides
   [$local_testcsv_UTF16,          0,"UTF-32"           ,undef           ], # BOM overrides
   [$local_testcsv_UTF16BECRLF,    0,"UTF-32,UTF-16BE"  ,undef           ], # no BOM
   [$local_testcsv_UTF16BECRLF,    1,"UTF-32,UTF-16BE"  ,"UTF-16BE"      ], # no BOM
   [$local_testcsv_UTF16LE,        0,"UTF-16LE,UTF-32"  ,"UTF-32"        ], # no BOM
   [$local_testcsv_UTF16LE,        0,"UTF-16LE,UTF-32"  ,"UTF-16BE"      ], # no BOM
       ) {
  my ($input_csvpath, $exp_passthru, $input_enc, $output_enc) = @$_;
  my @inenc_opts  = ($input_enc  ? (input_encoding  => $input_enc ) : ());
  my @outenc_opts = ($output_enc ? (output_encoding => $output_enc) : ());

  warn "--- Expect passthru=",!!$exp_passthru," for $input_csvpath ienc=",u($input_enc)," oenc=",u($output_enc),"\n"
    if $verbose;

  ### This is sometimes failing to detect $local_testcsv as a CSV on Solaris ;
  ### try to show enough information to debug it...
  my sub _passthru_test(@) {
    my %debug_opts = @_;

    # Call convert_spreadsheet() directly, passing inpath as an option
    my $h_cs = doconvert(inpath => $input_csvpath, cvt_to => 'csv',
                         @inenc_opts, @outenc_opts, %debug_opts);
    my $got_passthru = ($h_cs->{outpath} eq $input_csvpath);
    if (!!$got_passthru ne !!$exp_passthru) {
      die( ($exp_passthru
             ? "Expected null conversion but output is different"
             : "Expected differing output but got pass-thru"),
           qx/set -x; ls -ld $input_csvpath/,
           qx/set -x; ls -ld $h_cs->{outpath}/,
           qx/set -x; od -t x1a $h_cs->{outpath}/
      );
    }
    # Re-read the file ourself and check the data
    my $input_data = do{
      my ($benc,$spill) = open_bom(my $inFH, $input_csvpath, ":raw");
      oops if $spill;
      my $enc = $benc || ($input_csvpath =~ s/.*UTF/UTF-/r =~ s/WithBOM|CRLF|_.*//gr);
      binmode($inFH, ":raw:encoding($enc):crlf") or die $!;
      warn dvis '##BBB $input_csvpath $enc $benc $spill\n' if $debug;
      local $/; <$inFH>
    };
    my $reslurp_data = do{
      my $oenc = $h_cs->{encoding} // die "{encoding} not set in result";
      path($h_cs->{outpath})->slurp( {binmode => ":encoding($oenc):crlf"} );
    };
    die dvis 'Data from slurp with result encoding does not match!\n'
          .'$input_csvpath $h_cs\n@inenc_opts @outenc_opts\n $input_data\n$reslurp_data'
    unless $input_data eq $reslurp_data;

    # Try OpenAsCsv, which by the way calls convert_spreadsheet with a
    # separate inpath arg. It returns a file descriptor to read the data.
    my $h_oac = OpenAsCsv(inpath => $input_csvpath,
                          @inenc_opts, @outenc_opts, %debug_opts);
    die dvis 'OpenAsCsv result {inpath} wrong\n$h_oac\n$h_cs'
      unless $h_oac->{inpath} eq $input_csvpath;
    die dvis 'OpenAsCsv result {encoding} wrong\n$h_oac\n$h_cs'
      unless $h_oac->{encoding} eq $h_cs->{encoding};
    my $oac_fh_data = do{
      my $fh = $h_oac->{fh};
      local $/;
      <$fh>
    };
    die dvis 'Data from OpenAsCsv result fh does not match!\n'
          .'$input_csvpath $h_oac\n@inenc_opts @outenc_opts\n $input_data\n$oac_fh_data'
    unless $input_data eq $oac_fh_data;

    # Try via read_spreadsheet
    read_spreadsheet {@inenc_opts, %debug_opts}, $input_csvpath;
    warn qx/set -x; hexdump -C $input_csvpath/ if $debug && $^O eq 'linux';
    warn dvis '## @${\sheet()}' if $debug;
    verif_Sheet1 "($input_csvpath)";
  };

  eval { _passthru_test(debug => $debug, verbose => $verbose) };
  if ($@) {
    warn __FILE__,":",__LINE__," - failed: $@\nRE_TRYING WITH DEBUG...\n";
    $Carp::Verbose = 1;
     _passthru_test(debug => 1, verbose => 1);
    die "should have died by now";
  }

  print "> Passthru test ok for $input_csvpath ienc=",u($input_enc)," oenc=",u($output_enc),"\n"
    unless $silent;
}

{
### This is failing to auto-detect $local_testcsv_UTF8 as a CSV on Solaris ;
### try to show enough information to debug it...
eval {
  read_spreadsheet {debug => $debug, verbose => $verbose}, $local_testcsv_UTF8;
};
if ($@) {
  warn __FILE__,":",__LINE__," - failed: $@\nRE_TRYING WITH DEBUG...\n";
  read_spreadsheet {debug => 1, verbose => 1}, $local_testcsv_UTF8;
  die "should have died by now";
}

  verif_Sheet1 "(extracted csv)";
  my $hash = doconvert(inpath=>$local_testcsv_UTF8, cvt_to => 'csv');
  die "expected null conversion" unless $hash->{outpath} eq $local_testcsv_UTF8;
}

# Extract "allsheets" from a csv (symlink or copy into outdir)
{ my $h3 = doconvert(allsheets => 1, inpath => $local_testcsv_UTF8, cvt_to => 'csv');
  warn dvis '##YY $h3' if $debug;
  my @got = path($h3->{outpath})->children;
  unless (@got==1 && (my $got_chars=$got[0]->slurp_utf8) eq $exp_chars) {
    die "'allsheets' from csv did not work",
        dvis '\n$local_testcsv_UTF8\n$h3\n@got\n$got_chars'
  }
}

# csv-to-csv with transcoding
{
  my $tdir = Path::Tiny->tempdir();
  for my $enc (qw/UTF-8 UTF-16 UTF-32/) {
    say "------------- Transcode to/from $enc -------------" if $debug;
    my $fromutf8_result;
    {
      my $h = doconvert(inpath => $local_testcsv_UTF8,
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

# Test the various ways of specifying a sheet name
if ($can_cvt_spreadsheets) {
  if ($can_extract_named_sheet) {
    doread({}, $input_xlsx_path."!Sheet1"); verif_Sheet1();
    doread({sheetname => "Sheet1"}, $input_xlsx_path); verif_Sheet1;
    doread({sheetname => "Sheet1"}, $input_xlsx_path."!Sheet1"); verif_Sheet1;
    doread({sheetname => "Another Sheet"}, $input_xlsx_path."!Another Sheet"); verif_Another_Sheet;
  } else {
    warn "# Skipping extract-by-sheetname because soffice is too old\n" unless $silent;
  }
  if ($can_extract_allsheets) {
    # Extract all sheets
    my $dirpath = Path::Tiny->tempdir;
    doconvert(outpath => $dirpath, allsheets => 1, inpath => $input_xlsx_path, cvt_to => "csv");
    say dvis '###BBB $dirpath ->children : ',avis($dirpath->children) if $debug;
    my $got = [sort map{$_->basename} $dirpath->children];
    my $exp = [sort "Sheet1.csv", "Another Sheet.csv"];
    eq_deeply($got, $exp) or die dvis 'Missing or extra sheets: $got $exp';
  } else {
    warn "# Skipping 'allsheets' test because soffice is too old\n" unless $silent;
  }

  # Round-trip csv -> ods -> csv check
  {
    my $h1 = doconvert(inpath => $local_testcsv_UTF8, cvt_to => "ods");
    my $h2 = doconvert(inpath => $h1->{outpath}, cvt_to => "csv");
    my $got_chars = path($h2->{outpath})->slurp_utf8;
    if ($got_chars eq $exp_chars) {
      say "> Round-trip csv->ods->csv succeeded!" unless $silent;
    } else {
      $Data::Dumper::Interp::Foldwidth = 20;
      die "Round-trip csv->ods->csv mismatch:\n",
          ivis('Original: $exp_chars\n'),
          ivis('Result:   $got_chars\n') ;
    }
  }
} else {
  warn "# Spreadsheet tests skipped because soffice is not installed\n" unless $silent;
}

say "Done." unless $silent;
exit 0;


#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon # Test2::V0 etc.
  qw/$silent $verbose $debug run_perlscript/;
use t_SSUtils qw/create_testdata/;
use Capture::Tiny qw/capture/;

our ($tdata1_path, $withARGV_path, $opthash_comma);
BEGIN{
  $tdata1_path = create_testdata(
   name => "tdata1",
   rows => [
     [ "TitleA",  "TitleB"  ],  # default title row
     [ "TitleA2", "TitleB2" ],  # for testing title_rx => 1
     [ 100,       200       ],
   ]
  );
  
  $withARGV_path = create_testdata(
   name => "tdata1",
   rows => [
     [ "TitleA", "ARGV" ],
     [ 100,      200      ],
   ]
  );

  $opthash_comma = $debug ? ' {debug => 1},' : '';
}

# Still in package main

{ my ($out, $err) = capture {
    run_perlscript('-wE', '
       package Foo::Clash1; 
       sub TitleA { 42 };
       use Spreadsheet::Edit::Preload '.$opthash_comma.vis($main::tdata1_path->stringify).';
       ');
  };
  like($err, qr/TitleA.*clash.*Existing.*sub/s, "Detect clash with sub name");
  is($out, "", "Clash diags on stderr, not stdout");
}

{ my ($out, $err) = capture {
    run_perlscript('-wE', '
       package Foo::Clash1; 
       use Spreadsheet::Edit::Preload '.$opthash_comma.vis($main::withARGV_path->stringify).';
       ');
  };
  like($err, qr/ARGV.*clash.*Existing.*Array/s, "Detect clash with main::ARGV");
}

package Foo::Default;

use Spreadsheet::Edit::Preload ($main::debug ? ({debug => 1}) : ()), $main::tdata1_path;
use Test2::V0;
is(scalar(@rows), 3, "Foo::Default - tdata1 #rows");
is(title_rx, 0, "Foo::Default - title_rx autodetected correctly");
is($rows[1]{TitleA}, "TitleA2", "Foo::Default - data correct");
apply_torx {
  is($TitleA, "100", "Foo::Default - apply");
} 2;

package Foo::SpecTR;

use Spreadsheet::Edit::Preload {title_rx => 1, debug => $main::debug}, $main::tdata1_path;
use Test2::V0;
is(scalar(@rows), 3, "Foo::SpecTR - tdata1 #rows");
is(title_rx, 1, "Foo::SpecTR - title_rx autodetected correctly");
is($rows[2]{TitleA2}, "100", "Foo::SpecTr - data correct");
apply {
  is($TitleA2, "100", "Foo::SpecTR - apply");
};

done_testing();
exit 0;

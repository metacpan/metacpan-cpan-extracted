use strict; use warnings; use feature qw/say/;
use open ':std', ':encoding(UTF-8)';
use utf8;

my $mypkg = __PACKAGE__;

use Test2::V0;
use Carp;
use Data::Dumper::Interp qw/vis visq dvis dvisq u visnew/;

use Spreadsheet::Edit qw/:all logmsg/;

use Spreadsheet::Edit::Log ':btw=L=${lno} F=${fname} P=${pkg} ::';

use File::Basename qw/basename/;
use Capture::Tiny qw/capture/;

die "oops" unless ! %Spreadsheet::Edit::pkg2currsheet;
die "oops" unless ! defined $Spreadsheet::Edit::_inner_apply_sheet;

sub wrapper($@) {
  my $N = shift;
  btwN $N,@_;
}
{ my $baseline = __LINE__;
  my ($out, $err, $exit) = capture {
    { package Foo; main::btw "A1 btw from line ",$baseline+2; }
    btw "A2 btw from line ",$baseline+3;
    btwN 0,"BB btwN(0...) from line ",$baseline+4;
    btwN 0,"B2 btwN(0...) from line ",$baseline+6;
    wrapper 1,"CC btwN(1,...) from line ",$baseline+6;
  };
  local $_ = $out.$err;  # don't care which it goes to
  #note "OUT:$out\nERR:$err";
  my $fname = basename(__FILE__);
  like($_, qr/^\s*L=(\d+) F=\Q$fname\E P=Foo :: A1 .* from line (\1)/m,
      "A1 btw with custom prefix");
  like($_, qr/^\s*L=(\d+) F=\Q$fname\E P=main :: A2 .* from line (\1)/m,
      "A2 btw with custom prefix");
  like($_, qr/^\s*L=(\d+) F=\Q$fname\E P=main :: BB btwN\(0...\) from line (\1)/m,
      "BB btwN(0,...) with custom prefix");
  like($_, qr/^\s*L=(\d+) F=\Q$fname\E P=main :: CC btwN\(1,...\) from line (\1)/m,
      "CC btwN(1,...) with custom prefix");
}

my $ds1 = "My Source";
my $sheet1 = new_sheet
  data_source => $ds1,
  rows => [
    [ "First Name", "Last Name", "Address", "Phone" ],
    [ "Joe",        "Smith",     "123 Main St.", "555-1212" ],
    [ "Mary",       "Jones",     "456 Main St.", "999-9999" ],
  ] ;
title_rx 0;
our ($First_Name, $Last_Name, $Address, $Phone);
tie_column_vars ':all';

my $ds2 = "Sheet2";
my $sheet2 = new_sheet
  data_source => $ds2,
  rows => [
    [ "Phony", "Balony"],
    [ "AAA", 100 ],
    [ "BBB", 200 ],
  ] ;
title_rx 0;

sheet $sheet1;

#while (my ($k,$v) = each %Spreadsheet::Edit::pkg2currsheet) {
#  diag "AAA pkg2currsheet{$k} = u($v)\n";
#}
die "oops" unless $Spreadsheet::Edit::pkg2currsheet{$mypkg} == $sheet1;
die "oops" unless sheet() == $sheet1;

sheet undef;  # forget package 'active sheet'

die "oops" unless ! defined $Spreadsheet::Edit::_inner_apply_sheet;
die "oops" unless ! defined $Spreadsheet::Edit::pkg2currsheet{$mypkg};
die "oops" unless ! defined sheet();

sub run_tests(@) {
  my %opts = @_;
  #warn "##run_tests ",visnew()->Maxdepth(2)->Overloads(0)->dvis('%opts');
  my $tname       = delete $opts{tname};
  my $curr_sheet  = delete $opts{curr_sheet};
  my $cs_tag      = delete $opts{cs_tag};
  my $cs_rx       = delete $opts{cs_rx};
  my $asheet      = delete $opts{asheet};
  my $as_tag      = delete $opts{as_tag};
  my $as_rx       = delete $opts{as_rx};
  my $outerasheet = delete $opts{outerasheet};
  my $oas_tag     = delete $opts{oas_tag};
  my $oas_rx      = delete $opts{oas_rx};
  confess dvis 'Unknown %opts' if %opts;
  local $Data::Dumper::Interp::Useqq = "unicode"; # with '\n' for newline etc.
  foreach ([], ["Arg1"], ["Two\nlines"], ["Arg1","Two\nlines"]) {
    my @uargs = @$_;
    my $expmsg = join("", @uargs)."\n";
    my $justargs = join(",", map{vis} @uargs);
    my $comargs = join(",", "", map{vis} @uargs); # with leading comma
    #diag dvis '### @uargs $expmsg\n';
    # First, test logmsg() with NO explicit 'focus' argument
    my ($imp_sheet, $imp_tag, $imp_rx, $imp_desc);
    if ($curr_sheet) {
      ($imp_sheet, $imp_tag, $imp_rx, $imp_desc) = ($curr_sheet, $cs_tag, $cs_rx, "cs");
    }
    elsif ($asheet) {
      ($imp_sheet, $imp_tag, $imp_rx, $imp_desc) = ($asheet, $as_tag, $as_rx, "as");
    }
    elsif ($outerasheet) {
      ($imp_sheet, $imp_tag, $imp_rx, $imp_desc) = ($outerasheet, $oas_tag, $oas_rx, "oas");
    }
    if ($imp_sheet) {
      # diag "### asheet=", u($asheet), "  outerasheet=", u($outerasheet), "  curr_sheet=", u($curr_sheet), "  imp_sheet=", u($imp_sheet), "\n";
      if (defined $imp_rx) {
        is( logmsg(@uargs),
            "(Row ".($imp_rx+1)." $imp_tag): $expmsg",
            "logmsg $justargs ($imp_desc implied)($tname, auto-newline)" );
        is( logmsg(@uargs,"\n"),
            "(Row ".($imp_rx+1)." $imp_tag): $expmsg",
            "logmsg $justargs ($imp_desc implied)($tname, final \\n-only arg)" );
        unless (@uargs == 0) {
          is( logmsg(@uargs[0..($#uargs-1)],$uargs[-1]."\n"),
              "(Row ".($imp_rx+1)." $imp_tag): $expmsg",
              "logmsg $justargs\\n ($imp_desc implied)($tname, final newline in last arg)"
            );
        }
      } else {
        is( logmsg(@uargs),
            "($imp_tag): $expmsg",
            "logmsg $justargs ($imp_desc implied, no rx)($tname, auto-newline)" );
        is( logmsg(@uargs,"\n"),
            "($imp_tag): $expmsg",
            "logmsg $justargs ($imp_desc implied, no rx)($tname, final \\n-only arg)" );
        unless (@uargs == 0) {
          is( logmsg(@uargs[0..($#uargs-1)],$uargs[-1]."\n"),
              "($imp_tag): $expmsg",
              "logmsg $justargs\\n ($imp_desc implied, no rx)($tname, final newline in last arg)"
            );
        }
      }
    } else {
      is( logmsg(@uargs), $expmsg,
          "logmsg $justargs (no relevant sheet)($tname, auto-newline)" );
      is( logmsg(@uargs,"\n"), $expmsg,
          "logmsg $justargs (no relevant sheet)($tname, final \\n-only arg)" );
      unless (@uargs == 0) {
        is( logmsg(@uargs[0..($#uargs-1)],$uargs[-1]."\n"), $expmsg,
            "logmsg $comargs\\n (no relevant sheet)($tname, final newline in last arg)" );
      }
    }

    # Now test WITH a 'focus' arg of various sorts
    my %already_tested;
    foreach ([$sheet1, $ds1], [$curr_sheet, $cs_tag], [$asheet, $as_tag]) {
      my ($sh, $tag) = @$_;
      next
        if !defined($sh) or $already_tested{$sh}++;
      if (u($asheet) ne $sh) {
        # An explicitly specified sheet is different that that of
        # the inner-most apply and/or current sheet, and the rx
        # will be shown only if some other apply is active on that sheet.
        if (u($sh) eq u($outerasheet)) {
          die "oops" unless $tag eq $oas_tag;
          is( logmsg($sh, @uargs),
              "(Row ".($oas_rx+1)." $tag): $expmsg",
              "logmsg \$sh$comargs (sh is outerapply)($tname)" );
          is( logmsg([$sh], @uargs),
              "(Row ".($oas_rx+1)." $tag): $expmsg",
              "logmsg [\$sh]$comargs (sh is outerapply)($tname)" );
        } else {
          is( logmsg($sh, @uargs),
              "($tag): $expmsg",
              "logmsg \$sh$comargs (sh != apply or outerapply)($tname)" );
          is( logmsg([$sh], @uargs),
              "($tag): $expmsg",
              "logmsg [\$sh]$comargs (sh != apply or outerapply)($tname)" );
        }
      }
      is( logmsg([$sh,0], @uargs), "(Row 1 $tag): $expmsg",
          "logmsg [\$sh,0]$comargs ($tname)" );
      is( logmsg([$sh,2], @uargs), "(Row 3 $tag): $expmsg",
          "logmsg [\$sh,2]$comargs ($tname)" );
      is( logmsg([$sh,-1], @uargs), "(Row 0[INVALID RX -1] $tag): $expmsg",
          "logmsg [\$sh,-1]$comargs ($tname)" );
      is( logmsg([$sh,999], @uargs), "(Row 1000[INVALID RX 999] $tag): $expmsg",
          "logmsg [\$sh,999]$comargs ($tname)" );
    }
  }
}

sheet undef;
run_tests tname => "outer1", curr_sheet => undef; # no current sheet

sheet $sheet1;

run_tests tname => "outer2",
          curr_sheet => $sheet1, cs_tag => $ds1, cs_rx => undef;
          # no applys active

apply_torx {
  run_tests tname => "in apply",
            asheet => $sheet1, as_tag => $ds1, as_rx => $rx,
            curr_sheet => $sheet1, cs_tag => $ds1, cs_rx => $rx;
  my $saved_rx = $rx;
  my $saved = sheet(undef);
  run_tests tname => "in apply",
            asheet => $sheet1, as_tag => $ds1, as_rx => $sheet1->rx()
            # no current sheet
            ;
  sheet($saved);
} [2];

apply_torx {
  my $saved = sheet($sheet2);
  run_tests tname => "in apply but curr changed",
            asheet => $sheet1, as_tag => $ds1, as_rx => $sheet1->rx(),
            curr_sheet => $sheet2, cs_tag => $ds2, cs_rx => undef;
  sheet($saved);
} [2];

sheet $sheet1;
apply_torx {
  die "oops" unless $rx == 2;
  my $outer_rx = $rx;
  $sheet2->apply_torx(sub{
    #warn dvis '### $$sheet1->{current_rx} $$sheet2->{current_rx}';
    die "oops ".vis($sheet2->rx()) unless $sheet2->rx() == 1;
    run_tests tname => "nested apply",
            outerasheet => $sheet1, oas_tag => $ds1, oas_rx => $outer_rx,
            curr_sheet  => $sheet1, cs_tag  => $ds1, cs_rx  => $outer_rx,
            asheet => $sheet2, as_tag => $ds2, as_rx => $sheet2->rx() ;
    }, 1);
} [2];

sheet $sheet2;
run_tests tname => "outer3", curr_sheet => $sheet2, cs_tag => $ds2;


done_testing();

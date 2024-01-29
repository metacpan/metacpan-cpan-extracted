#!/usr/bin/perl
# *** DO NOT USE Test2 FEATURES becuase this is a sub-script ***
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp etc.
use t_TestCommon  # Test2::V0 etc.
         qw/$verbose $silent $debug dprint dprintf
            bug mycheckeq_literal expect1 mycheck
            verif_no_internals_mentioned
            insert_loc_in_evalstr verif_eval_err
            arrays_eq hash_subset
            @quotes/;
use t_SSUtils;

use Spreadsheet::Edit qw/fmt_sheet cx2let let2cx sheet/;
use Test::Deep::NoTest qw/eq_deeply/;

##########################################################################
package Other {
  use t_Common;
  use t_TestCommon qw/:DEFAULT $silent $debug $verbose dprint dprintf/;

  use Spreadsheet::Edit ':FUNCS', # don't import stdvars
                        '@rows' => { -as, '@myrows' },
                        qw(%colx @crow %crow $num_cols @linenums),
                        qw/fmt_sheet/,
                        ;
  our $Gtitle;
  $Gtitle = "Other::Gtitle before being tied";

#$Spreadsheet::Edit::Debug = 1;
  new_sheet
            data_source => "Othersheet",
            rows => [ [qw(OtitleA OtitleB OtitleC)],
                      [   9,      000,    26      ],
                      [   314,    159,    26      ],
                      [   77,     888,    999     ],
                    ],
            linenums => [ 1..4 ],
            silent => $silent,
            ;
  title_rx 0;
  tie_column_vars qw(OtitleA OtitleB);

  # N.B. "our" only applies within lexical scope
  our ($OtitleA, $OtitleB, $OtitleC);

  dprint "Othersheet = ${\sheet()}\n";
} #package Other
##########################################################################

# continuing in package main ...

use Spreadsheet::Edit ':all';

# Use to not prefix rows with "(Spreadsheet::Edit::Magicrow)"
my $myvisobj = visnew->Objects({objects => 1, show_classname => 0});

my ($testdata, $inpath) = create_testdata(
    name => "in1",
    rows => [
              [ "Pre-title-row stuff (this is rowx 0)" ],
              [ "A title  ",   # trailing spaces
                "Btitle",
                "  Multi-Word Title C",
                "",  # empty title in column D
                "H", # instead of "E", looks like ABC code
                "F", # same as this column's ABC code
                "Gtitle",
                "Z", # instead of "H", looks like ABC code but > num_cols-1
                "0", # numeric title "0"
                "003", # numeric with leading zeroes "003"
                "999", # numeric title "999"
                "-1",  # negative numeric title "-1"
              ],
            ],
    gen_rows => 5, # Generate [A2..H2],[A3..H3],...[A6..H6]
);
# Pre-title-row stuff (this is rowx 0)
# "A title  ",Btitle,"  Multi-Word Title C",,H,F,Gtitle,Z,"0","003","999","-1"
# A2,B2,C2,D2,E2,F2,G2,H2,I2,J2,K2,L2
# A3,B3,C3,D3,E3,F3,G3,H3,I2,J2,K2,L2
# A4,B4,C4,D4,E4,F4,G4,H4,I2,J2,K2,L2
# A5,B5,C5,D5,E5,F5,G5,H5,I2,J2,K2,L2
# A6,B6,C6,D6,E6,F6,G6,H6,I2,J2,K2,L2

# Determine which column keys should be usable for column cx.
# Input: $L indicates the *original* position of the column ('A' .. 'L'),
#   and therefore the column data values (e.g. L="D" implies D2/D3/D4/D5/D6).
# Output:
#   $title_L contains a letter which should be in the title, or "" if
#     the title should be empty.
#   $ABC_usable is true if the cx2let($cx) is a valid key for this column.
#   $title_usable is true if the title is a valid colx key for this column
sub title_info($$) {
  my ($L,$cx) = @_;
  my ($title_L, $ABC_usable, $title_usable) = ($L,1,1,1);
  my $ABC = cx2let($cx);
  if ($ABC eq "H") {
    $ABC_usable = ($L eq "E"); # Title "H" was originally in col E
  }
  elsif ($ABC eq "F") {
    $ABC_usable = ($L eq "F"); # Title "F" was originally in col F
  }
  elsif ($ABC eq "Z") {
    $ABC_usable = ($L eq "H"); # Title "Z" was originally in col H
  }

  if ($L =~ /^[DRUV]$/) {
    # Original col D had no title
    # Cols PQRSTU are used in the second test spreadsheet (see "inpath2")
    $title_L = "";  # Title should be empty
  }
  elsif ($L eq 'E') {
    $title_L = "H"; # Title "H" should match this column
  }
  elsif($L eq 'F') {
    # $title_L = "F";  # FIXME: Why commented out???
  }
  elsif($L eq 'H') {
    $title_L = "Z";  # Title "Z" should match this column
    $ABC_usable = ($cx == let2cx("E")); # originally in col E
  }
  elsif($L eq 'I') {
    $title_L = "0";    # Title "0" should be in this column
    $title_usable = 0; # and can not be used as a colx key
  }
  elsif($L eq 'J') {
    $title_L = "003";  # Title "003" should be in this column
  }
  elsif($L eq 'K') {
    $title_L = "999";  # Title "999" should be in this column
  }
  elsif($L eq 'L') {
    $title_L = "-1";  # Title "-1" should be in this column
  }
  elsif($L eq 'Z') { # in case many columns are added...
    $ABC_usable = ($cx == let2cx("H")); # originally in col H
  }

  return ($title_L, $ABC_usable, $title_usable);
}

# Return value of a cell in the 'current' row, verifying that various access
# methods return the same result (including undef if the item is not defined).
# RETURNS ($value, undef or "bug description");
sub getcell_bykey($;$) { # title, ABC name, alias, etc.
  my ($key, $err) = @_;
  bug unless defined $rx;  # not in apply?

  my $v;
  if (sheet->_unindexed_title($key)) {
    bug "for now";
  } else {
    $v = $crow{$key};
  }
  my $vstr = vis( $v );
  { my $ovstr = vis( sheet()->{$key} );
    $err //= "\$crow{$key} returned $vstr but sheet()->{$key} returned $ovstr"
      if $vstr ne $ovstr;
  }
  my $magicrow = sheet()->[$rx];
  { my $mr2 = sheet()->rows->[$rx];
    $err //= " sheet()->[$rx] and sheet()->rows->[$rx] are DIFFERENT!"
      unless $magicrow == $mr2;
  }
  { my $ovstr = vis( $magicrow->{$key} );
    $err //= "\$crow{$key} returned $vstr but sheet()->[$rx]->{$key} returned $ovstr"
      if $vstr ne $ovstr;
  }
  { my $cx = $colx{$key};
    $err //= "%colx does not match sheet()->colx for key $key"
      if u($cx) ne u(sheet()->colx->{$key});
    my $ovstr = vis( defined($cx) ? $magicrow->[$cx] : undef );
    $err //= "\$crow{$key} returned $vstr but sheet()->[$rx]->[$cx] returned $ovstr"
      if $vstr ne $ovstr;
  }

  return ($v, $err);
}
sub getcell_byident($;$) { # access by imported $variable + all other ways
  my ($ident, $inerr) = @_;
  my ($v, $err) = getcell_bykey($ident, $inerr);
  my $vstr = vis($v);

  my $id_v = eval insert_loc_in_evalstr("\$$ident"); # undef if not defined, not in apply(), etc.
  my $id_vstr = vis($id_v);
  $err //= "\$$ident returned $id_vstr but other access methods returned $vstr"
    if $vstr ne $id_vstr;

  return ($v, $err);
}

sub check_currow_data($) {
  my $letters = shift;  # specifies order of columns. "*" means don't check
  confess dvis 'WRONG #COLUMNS $letters @crow $rx'
    if length($letters) != @crow;
  die "\$rx not right" unless ${ sheet() }->{current_rx} == $rx;

  for (my $cx=0, my $ABC="A"; $cx < length($letters); $cx++, $ABC++) {
    my $L = substr($letters, $cx, 1);
    my $v = $rows[$rx]->[$cx]; # manually locate the cell

    my $err;
    $err //= "crow[cx] does not match rowx[rx]->[cx]" if $crow[$cx] ne $v;

    # 'A', 'B' etc. are all valid but some are titles, not column letters
    (my $ABC_v, $err) = getcell_byident($ABC, $err);
    if ($@) { $err //= "ABC $ABC aborts ($@)" }
    elsif (! defined $ABC_v) { $err //= "ABC $ABC is undef" }

    # The Titles    H, F, and Z mask the same-named ABC codes, and refer to
    # orig. columns E, F, and H .
    if ($L ne "*") { # data not irregular
      my $exp_v = "$L$rx"; # expected data value

      if ($v ne $exp_v) {
        $err //= ivis 'WRONG DATA accessed by cx: Expecting $exp_v, got $v';
      }

      if (defined $title_row) { # Access the cell by title
        # ̶T̶i̶t̶l̶e̶s̶ ̶a̶r̶e̶ ̶a̶l̶w̶a̶y̶s̶ ̶v̶a̶l̶i̶d̶ ̶[̶w̶i̶t̶h̶ ̶n̶e̶w̶ ̶i̶m̶p̶l̶e̶m̶e̶n̶t̶a̶t̶i̶o̶n̶.̶.̶.̶]
        # Titles are valid unless they conflict with ^ $ or cx values
        my $title = $title_row->[$cx];
        my ($title_L, $ABC_usable, $title_usable) = title_info($L, $cx);
        if ($title_L ne "") {
          $err //= dvis('$title_L is TRUE but $title is EMPTY')
            if $title eq "";
          if ($title_usable) {
            (my $vt, $err) = getcell_bykey($title, $err);
            if (u($vt) ne $exp_v) {
              $err //= ivis('row{Title=$title} yields $vt but expecting $exp_v')
            }
          }
        }
      }
    }

    if (defined $err) {
      confess "BUG DETECTED...\n", fmtsheet(), "\n",
              #dvis('$rx $letters $cx $ABC $L $man_v $crow[$cx]\n@crow\n'),
              $err;
    }
  }
}#check_currrow_data

sub check_titles($) {
  my $letters = shift;  # specifies current column order; implies *data* values
  confess "bug" unless length($letters) == $num_cols;
  confess "UNDEF title_row!\n".fmtsheet() unless defined $title_row;
  for (my $cx=0; $cx < length($letters); $cx++) {
    my $L = substr($letters, $cx, 1);
    my ($title_L, $ABC_usable, $title_usable) = title_info($L, $cx);
    # $title_L is a letter which must appear in the title
    #   or "" if the title should be empty
    # $ABC_usable means the column can be accessed via its ABC letter code.
    die "bug" unless $rows[$title_rx]->[$cx] eq $title_row->[$cx];
    my $title = $title_row->[$cx];
    my $err;
    if ($title_L eq "") {
      $err //= ivis 'SHOULD HAVE EMPTY TITLE, not $title'
        unless $title eq "";
    } else {
      if ($title !~ /\Q$title_L\E/) {
        $err //= ivis 'WRONG TITLE $title (expecting to contain $title_L)'
      }
      if (! defined $colx{$title}) {
        $err //= ivis 'colx{$title} is undefined !!!!'
          if $title_usable;
      }
      elsif ($colx{$title} != $cx) {
        $err //= ivis 'colx{$title} wrong (expecting cx $cx)'
      }
    }
    apply_torx {
      if ($crow[$cx] ne $title) {
        $err //= ivis 'apply_torx title_rx : row->[$cx] is WRONG'
          if $title_usable;
      }
    } $title_rx;
    if ($ABC_usable) {
      my $ABC = cx2let($cx);
      my $v = $colx{$ABC};
      $err //= ivis('WRONG colx{ABC=$ABC} : Got $v, expecting $cx')
        unless u($v) eq $cx;
    }
    if (defined $err) {
      confess $err, dvis('\n$L $cx $title_L\n'), fmtsheet();
    }
  }
}#check_titles

sub check_both($) {
  my $letters = shift;  # current column ordering
  croak "Expected $num_cols columns" unless length($letters) == $num_cols;

  my %oldoptions  = options();
  my %oldoptions2 = options(verbose => 0);
  eq_deeply(\%oldoptions, \%oldoptions2)
    or die "MISMATCH: ", dvis('%oldoptions\n%oldoptions2');
  scope_guard { options(verbose => $oldoptions2{verbose}) };

  check_titles $letters;
  apply {
    die "rx wrong" unless $rx > $title_rx;
    check_currow_data($letters)
  };
}

# Verify %colx entries, e.g. aliases.  Arguments are any mixture of
# [ $Ident, $CxorABC] or "Ident_CxorABC".
sub check_colx(@) {
  my $colx = sheet()->colx;
  foreach (@_) {
    my ($ident, $cx_or_abc);
    if (ref) {
      ($ident, $cx_or_abc) = @$_
    } else {
      ($ident, $cx_or_abc) = (/^(\w+)_(.*)$/);
    }
    my $cx = ($cx_or_abc =~ /\d/ ? $cx_or_abc : let2cx($cx_or_abc));
    my $actual_cx = $colx->{$ident};
    croak ivis 'colx{$ident}=$actual_cx, expecting $cx'
      unless u($cx) eq u($actual_cx);
    my $exp_celldata_rx2 = cx2let($cx)."2";
    die "bug" unless sheet()->[2]{$ident} eq $exp_celldata_rx2;
  }
}

####### MAIN ######

# Column variables named after (trimmed) titles or auto-aliases
# "A title  ",Btitle,"  Multi-Word Title C",,H,F,Gtitle,Z,"0","003","999","-1"
# A=0         B=1       C=2                  E F G=6    H  I   J     K     L
our ($A_title, $Btitle, $Multi_Word_Title_C, $H, $F, $Gtitle, $Z, $_0, $_003, $_999, $_1);
# And column letter codes (if they aren't titles)
our ($A,$B,$C,$D,$E,   $G,   $I,$J,$K,$L);

check_no_sheet;

# Auto-tie all columns, current and future.
# Note that tie_column_vars has it's own separate comprehensive test
tie_column_vars ':all';

options silent => $silent, verbose => $verbose, debug => $debug;

# Verify options() actually works
{ my @keys = qw/debug verbose silent/;
  my $s = sheet();
  my %orig = (map{$_ => $$s->{$_}} @keys);
  for my $key (@keys) {
    # Note: Setting debug or verbose affects silent...
    #warn dvis '###START $key';
    my $old = $$s->{$key};
    bug(dvis '$key $old %orig') unless !!$orig{$key} eq !!$old;
    for my $k (@keys) {
      bug(dvis '$k (direct access!) disturbed by ???; $orig{$k} $$s->{$k}')
        unless !!$orig{$k} == !!$$s->{$k};
    }
    my %opts = options();
    for my $k (@keys) {
      bug(dvis '$k (direct access!) DISTURBED by calling options(); $orig{$k} $$s->{$k}')
        unless !!$orig{$k} == !!$$s->{$k};
    }
    for my $k (@keys) {
      bug(dvis 'FETCHED unexpected value: $k $orig{$k} $opts{$k}')
        unless !!$orig{$k} == !!$opts{$k};
    }
    bug() unless !!$opts{$key} == !!$old;
    my $new = !$old;

    # To suppress log messages to not break 'silent is really silent' tests,
    # this used to use a nested capture_merged { ... };  However some wierd
    # crashes occurred with Perl 5.18.0; not sure why but control seemed
    # to spontaneously jump to exit from previously-exited subs.
    #
    # Now I'm manually saving & restoring STDERR.
    open my $saved_STDERR, ">&STDERR" or die "dupERR: $!";
    use File::Spec ();
    open STDERR, ">", File::Spec->devnull() or die "reopenErr: $!";
    eval {
        options($key => $new);
        { my %nopts = options(); bug() unless !!$nopts{$key} == !!$new; }
        options($key => $old);
        { my %nopts = options(); bug() unless !!$nopts{$key} eq !!$old && !!$nopts{$key} ne $new; }
        $s->options($key => $new);
        { my %nopts = options(); bug() unless $nopts{$key} eq $new; }
        $s->options($key => $old);
        { my %nopts = options(); bug() unless !!$nopts{$key} eq !!$old && !!$nopts{$key} ne $new; }

        # There was a bug where $sheet->options() used current sheet instead of $sheet
        # (and died if there was no current sheet)
        { package Baloney; my %nopts = $s->options;
          main::bug unless main::u($nopts{$key}) eq main::u($old) && main::u($nopts{$key}) ne $new;
        }
    };
    my $err = $@;
    open STDERR, ">&", $saved_STDERR or die "dup back: $!";
    close $saved_STDERR;
    bug "Someting went wrong:\n$err\n" if $err;

    for my $k (@keys) {
      bug("{$k} disturbed by TESTING $key!")
        unless !!$orig{$k} == !!$opts{$k};
      #warn "### BOTTOM ($key): ",dvis("\$\$s->{$k}\n")
    }
  }
}

# Verify that no-titles mode works
read_spreadsheet {title_rx => undef}, $inpath->stringify;

die "title_rx with no titles returns defined value" if defined(title_rx());
my $expected_rx = 0;
apply { # should visit all rows
  die dvis 'Wrong $rx' unless $rx == $expected_rx++;
  if    ($rx == 0) { die dvis '$rx Wrong $A' unless $A =~ /^Pre-title-row/; }
  elsif ($rx == 1) { die dvis '$rx Wrong $A' unless $A =~ /^A title/; }
  elsif ($rx == 2) { die dvis '$rx Wrong $A' unless $A eq "A2"; }
  elsif ($rx == 3) { die dvis '$rx Wrong $A' unless $A eq "A3" && $B eq "B3"; }
};
die dvis '$expected_rx' unless $expected_rx == 7;

# Can't auto-detect because it would skip the title row due to the empty title
title_rx 1;

{ my $s=sheet(); dprint $myvisobj->dvis('After reading $inpath->stringify\n   $$s->{rows}\n   $$s->{colx_desc}\n'); }


alias Aalias => '^';
alias Aalia2 => 0;
alias Dalias => 'D';
alias Ealias => 'E';
alias Falias => 'F';
alias Falia2 => 5;
alias Galias => 'G';
alias Halias => 'H'; # actually column E/cx 4
alias Lalias => 'L';
alias Lalia2 => '$';

check_colx qw(Aalias_0 Aalia2_0 Dalias_D Ealias_E Falias_F
              Falia2_F Galias_G Halias_E Lalias_L Lalia2_L);

{ my $cxliststr = join " ", spectocx qw(Aalias Aalia2 Dalias Ealias Falias
                                        Falia2 Galias Halias Lalias Lalia2);
  die "Wong spectocx before title valid: $cxliststr"
    unless $cxliststr eq "0 0 3 4 5 5 6 4 11 11";
}

# alias to title which is defined but no variable yet tied to it
alias MWTCalia => qr/Multi.Word .*C/;

apply_torx {
  die unless $A         eq "A2";
  die unless $A_title   eq "A2";
  die unless $B         eq "B2";
  die unless $Btitle    eq "B2";
  die unless $C         eq "C2";
  die unless $Multi_Word_Title_C   eq "C2";
  die unless $D         eq "D2"; # Empty title for column D
  die unless $E         eq "E2";
  die unless $H         eq "E2";
  die unless $F         eq "F2";
  die unless $G         eq "G2";
  die unless $Gtitle    eq "G2";
  die unless $Z         eq "H2";
  die unless $I         eq "I2";
  die unless $_0        eq "I2";
  die unless $J         eq "J2";
  die unless $_003      eq "J2";
  die unless $K         eq "K2";
  die unless $_999      eq "K2";
  die unless $L         eq "L2";
  die unless $_1        eq "L2";
} [2];

# spectocx, with title defined
{ # "A title  ",Btitle,"  Multi-Word Title C",,H,F,Gtitle,Z,"0","003","999","-1"
  my $cxliststr = join " ",
      spectocx qw(Aalias Aalia2 Dalias Ealias Falias),
                  qr/^[A-Z].*title/;
  die "Wong spectocx after title valid: $cxliststr"
    unless $cxliststr eq "0 0 3 4 5 0 1 6";
}

apply_torx {
  our $MWTCalia;
  die dvis '$MWTCalia is wrong' unless u($MWTCalia) eq "C2";
} 2;

# "H" is now a title for col E (cx 4), so it masks the ABC code "H".
# Pre-existing aliases remain pointing to their original columns.
alias Halia3 => 'H';

{ my $cxliststr = join " ", spectocx qw(Aalias Aalia2 Dalias Ealias Falias
                                        Falia2 Galias Halias Lalia2 Halia3);
  die "Wong spectocx before title valid: $cxliststr"
    unless $cxliststr eq "0 0 3 4 5 5 6 4 11 4";
}
die "Halia3 gave wrong val"  unless sheet()->[2]->{Halia3} eq "E2";
die "Halias stopped working" unless sheet()->[2]->{Halias} eq "E2";
die "Lalias stopped working" unless sheet()->[2]->{Lalias} eq "L2";
die "Lalia2 stopped working" unless sheet()->[2]->{Lalia2} eq "L2";
die "Falias stopped working" unless sheet()->[2]->{Falias} eq "F2";

# "F" is also now the title for cx 5, but is the same as the ABC code
alias Falia3 => 'F';
die "Falia3 gave wrong val"  unless sheet()->[2]->{Falia3} eq "F2";
die "Falias stopped working" unless sheet()->[2]->{Falias} eq "F2";

our $Halia4 = "before being tied";
die "bug" unless $Halia4 eq "before being tied";
apply_torx {
  die "bug2" unless $Halia4 eq "before being tied";
} 3;

# Regexp COLSPECS always match titles, not other things
# "A title  ",Btitle,"  Multi-Word Title C",,H,F,Gtitle,Z,"0","003","999","-1"

# With tie_column_vars ':all' new identifiers are tied whenever created
die "Halia4" unless 4==alias Halia4 => qr/^H$/;  # H is title in cx 4
eval { $_ = $Halia4 }; verif_eval_err;
apply_torx {
  die dvis '$Halia4 is wrong' unless u($Halia4) eq "E2";
} 2;

alias Zalia1 => qr/^Z$/;
  die "wrong Zalia1 alias result" unless spectocx('Zalia1') == 7;

# Regexp always match numeric titles
die "Numtl0"   unless 8 == alias Numtl0 => qr/^0$/;
die "Numtl003" unless 9 == alias Numtl003 => qr/^003$/;
die "Numtl000" unless 10 == alias Numtl999 => qr/^999$/;
die "Minus1" unless 11 == alias Minus1 => qr/^-1$/;

# But numbers are treated as absolute cx values if <= num_cols
die "Cx0_alias" unless 0 == alias Cx0_alias => "0";
die "Cx3_alias" unless 3 == alias Cx3_alias => 3;

# Numtlbers beyond num_cols are just "title"s
die "Col999_alias" unless 10 == alias Col999_alias => 999;
die "Colminus1_alias" unless 11 == alias Colminus1_alias => -1;

# Leading zeroes makes them just "title"s (except for "0")
die "Col003_alias" unless 9 == alias Col003_alias => "003";

apply_torx {
  die dvis '$Halia4 is wrong' unless u($Halia4) eq "E2";
  our $Numtl0;
  die dvis '$Numtl0 is wrong'   unless u($Numtl0)   eq "I2";
} 2;

# Create user alias "A" to another column.  This succeeds because
# ABC codes are hidden by user aliases
die unless 2 == alias A => 2;
die "alias 'A' gave wrong val" unless sheet()->[2]->{A} eq "C2";

alias A_alias2 => "A";
die "A_alias2 gave wrong val" unless sheet()->[2]->{A_alias2} eq "C2";

unalias 'A';
die "unaliased 'A' is wrong" unless sheet()->[2]->{A} eq "A2";

die "A_alias2 stopped working " unless sheet()->[2]->{A_alias2} eq "C2";

alias A => "C";
die "alias 'A' gave wrong val" unless sheet()->[2]->{A} eq "C2";

# Removing an alias re-exposes a previously-hidden ABC letter code
unalias 'A';
die "'A' after unalias gave wrong val" unless sheet()->[2]->{A} eq "A2";
alias A_al => "A";
die "A_al wrong val" unless sheet()->[2]->{A_al} eq "A2";
unalias "A_al";
die "unaliased 'A' is wrong" unless sheet()->[2]->{A} eq "A2";

# Try to access the now-undefined alias in a magicrow
eval { $_ = sheet()->[2]->{A_al} }; verif_eval_err;

die "Aalias gave wrong val" unless sheet()->[2]->{Aalias} eq "A2";
die "Dalias gave wrong val" unless sheet()->[2]->{Dalias} eq "D2";
die "Ealias gave wrong val" unless sheet()->[2]->{Ealias} eq "E2";
die "Falias gave wrong val" unless sheet()->[2]->{Falias} eq "F2";
die "Falia2 gave wrong val" unless sheet()->[2]->{Falia2} eq "F2";
die "Galias gave wrong val" unless sheet()->[2]->{Galias} eq "G2";
die "Halias gave wrong val" unless sheet()->[2]->{Halias} eq "E2";
die "Lalia2 gave wrong val" unless sheet()->[2]->{Lalia2} eq "L2";


# "A title  ",Btitle,"  Multi-Word Title C",,H,F,Gtitle,Z,"0","003","999","-1"
check_both('ABCDEFGHIJKL');

# Reading and writing whole rows
{ my $r2  = [ map{ "${_}2" } "A".."L" ];
  my $r2x = [ map{ "${_}x" } @$r2 ];
  die dvis 'bug $r2 $rows[2]' unless arrays_eq($rows[2], $r2);
  $rows[2] = $r2x;
  die dvis 'bug $rows[2]\n$r2x' unless arrays_eq($rows[2], $r2x);
  $rows[2] = \@{$r2};
  die dvis 'bug $rows[2]\n$r2x' unless arrays_eq($rows[2], $r2);
}

# Verify error checks
foreach ([f => 0], [flt => 0, f => 1, flt => undef], [lt => $#rows],
        )
{
  my @pairs = @$_;
  my @saved = ($first_data_rx, $last_data_rx, $title_rx);
  scope_guard {
    first_data_rx $saved[0];
    last_data_rx  $saved[1];
    title_rx      $saved[2];
  };

  while (@pairs) {
    my ($key,$val) = @pairs[0,1]; @pairs = @pairs[2..$#pairs];
    if ($key =~ s/f//) {
      first_data_rx $val;
      die 'bug:first_data_rx as getter' unless u(first_data_rx) eq u($val);
    }
    if ($key =~ s/l//) {
      last_data_rx $val;
      die 'bug:last_data_rx as getter' unless u(last_data_rx) eq u($val);
    }
    if ($key =~ s/t//) {
      title_rx $val;
      die 'bug:title_rx as getter' unless u(title_rx) eq u($val);
    }
    die "BUG $key" if $key ne "";

    # rx out of range
    eval { apply_torx {  } [0..$#rows+1]; }; verif_eval_err;
    eval { apply_torx {  } [-1..$#rows]; }; verif_eval_err;
    eval { apply_exceptrx {  } [0..$#rows+1]; }; verif_eval_err;
    eval { apply_exceptrx {  } [-1..$#rows]; }; verif_eval_err;

    # Attempt to modify read-only sheet variables
    eval { $num_cols = 33 }; verif_eval_err;
    eval { $title_rx = 33 }; verif_eval_err;

    # Access apply-related sheet vars outside apply
    eval { my $i = $rx }; verif_eval_err;
    eval { my $i = $crow[0] }; verif_eval_err;
    eval { my $i = $linenum }; verif_eval_err;
    eval { my $i = $crow{A} }; verif_eval_err;
  }
}

# Flavors of apply
    my %visited;
    sub ck_apply(@) {
      my %actual = map{ $_ => 1 } @_;
      my $visited_str = join ",", sort { $a <=> $b } grep{$visited{$_}}
                                                     keys %visited;
      foreach(@_){
        confess "ck_apply:FAILED TO VISIT $_ (visited $visited_str)"
          unless $visited{$_};
      }
      foreach(keys %visited){
        confess "ck_apply:WRONGLY VISITED $_" unless $actual{$_};
      }
      while (my($rx,$count) = each %visited) {
        confess "ck_apply:MULTIPLE VISITS TO $rx" if $count != 1;
      }
      %visited = ();
    }
    sub ck_applyargs($$) {
      my ($count, $uargs) = @_;
      die "ck_coldata:WRONG ARG COUNT" unless @$uargs == $count;
      return if $rx <= $title_rx;
      my $L = 'A';
      for my $cx (0..$count-1) {
        my $expval = "${L}$rx";
        confess "ck_coldata:WRONG COL rx=$rx cx=$cx exp=$expval act=$uargs->[$cx]"
          unless $expval eq $uargs->[$cx];
        $L++;
      }
    }
    apply { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(2..6);

    first_data_rx 3;
    apply { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(3..6);
    first_data_rx undef;
    apply { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(2..6);

    last_data_rx 4;
    apply { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(2..4);
    last_data_rx undef;
    apply { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(2..6);

    first_data_rx 0;  # no-op for apply() because <= title_rx
    apply { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(2..6);
    last_data_rx 4;
    apply { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(2..4);
    apply_all { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(0..6);
    first_data_rx undef;
    last_data_rx undef;
    apply { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(2..6);

    last_data_rx 0; # less than title_rx+1
    apply { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply();
    last_data_rx undef;

    apply_all { $visited{$rx}++; ck_applyargs(0,\@_); } ; ck_apply(0..6);
    foreach my $i (0..6) {
      apply_torx { $visited{$rx}++; ck_applyargs(1,\@_); } $i, 0 ; ck_apply($i);
      apply_torx { $visited{$rx}++; ck_applyargs(2,\@_); } [$i],"A title",1 ; ck_apply($i);
      apply_exceptrx { $visited{$rx}++; ck_applyargs(0,\@_); } $i ; ck_apply(0..$i-1,$i+1..6);
      apply_exceptrx { $visited{$rx}++; ck_applyargs(2,\@_); } $i,0,"Btitle" ; ck_apply(0..$i-1,$i+1..6);
      apply_exceptrx { $visited{$rx}++; } [$i] ; ck_apply(0..$i-1,$i+1..6);
    }
    apply_torx { $visited{$rx}++; } [0..6] ; ck_apply(0..6);
    apply_exceptrx { $visited{$rx}++; } [0..6] ; ck_apply();
    apply_exceptrx { $visited{$rx}++; } [0..5] ; ck_apply(6);

# Change title_rx
    title_rx 3;
      bug unless $title_row->[0] eq "A3";
      apply { $visited{$rx}++; } ; ck_apply(4..6);
    title_rx 4;
      bug unless $title_row->[0] eq "A4";
      bug unless $rows[$title_rx]->[1] eq "B4";
      apply { $visited{$rx}++; } ; ck_apply(5..6);
    title_rx undef; #forget_title_rx;
      apply { $visited{$rx}++; } ; ck_apply(0..6);
    title_rx 0;
      apply { $visited{$rx}++; } ; ck_apply(1..6);

    title_rx 1;  # the correct title row
      apply { $visited{$rx}++; } ; ck_apply(2..6);

# Add and drop rows
    insert_rows 3,4;
    delete_rows 3,4,5,6;
    check_both('ABCDEFGHIJKL');

    insert_rows 0,3;      # insert 3 rows at the top

    delete_rows 0..2;  # take them back out
    bug if $title_row->[5] ne 'F';
    check_both('ABCDEFGHIJKL');

# Append a new column.  We will insert 2 before it later.
    our $Otitle;  # will be tied
    insert_cols '>$', "Otitle";
    apply {
      $Otitle = "O$rx";
    };
    check_both('ABCDEFGHIJKLO');

# Insert two new columns before that one
    our ($Mtitle, $Ntitle); # will be tied
    insert_cols 'Otitle', qw(Mtitle Ntitle);
    apply {
      bug "rx=$rx" if $rx <= $title_rx;
      $Mtitle = "M$rx"; $Ntitle = "N$rx";
      bug unless $Otitle eq "O$rx";
    };
    check_both('ABCDEFGHIJKLMNO');

# Swap A <-> K

    move_cols ">O", "A";
    check_both('BCDEFGHIJKLMNOA');

    move_cols 0, "Otitle";
    check_both('OBCDEFGHIJKLMNA');

# And back and forth

    move_cols ">".($num_cols-1), qw(A);  # 'A' means cx 0, i.e. Otitle
    check_both('BCDEFGHIJKLMNAO');

    move_cols "^", "A title";
    check_both('ABCDEFGHIJKLMNO');

    move_cols '>$', "Multi-Word Title C";
    check_both('ABDEFGHIJKLMNOC');

    move_cols '>B', '$';
    check_both('ABCDEFGHIJKLMNO');

# Delete columns

    apply_torx { bug unless $Gtitle eq "G$rx" } [2,3];
    delete_cols 'G';
    apply_torx { check_colspec_is_undef('Gtitle') } 2;
    check_both('ABCDEFHIJKLMNO');

    delete_cols '^', 'Dalias', '$';
    check_both('BCEFHIJKLMN');


# Put them back


    insert_cols '^', "A title  " ; apply { $A_title = "A$rx" };
    check_both('ABCEFHIJKLMN');

    apply_all { return unless $rx==0; $crow[0] = "Restored initial stuff" };

    insert_cols '>C',""; apply { $crow[3] = "D$rx" };
    check_both('ABCDEFHIJKLMN');

    insert_cols '>F', qw(Gtitle); apply { $Gtitle = "G$rx" };
    check_both('ABCDEFGHIJKLMN');
    apply_torx { bug unless $Gtitle eq "G$rx" } 2;

    insert_cols '>$', qw(Otitle); apply { $Otitle = "O$rx" };
    check_both('ABCDEFGHIJKLMNO');
    apply_torx { bug unless $Gtitle eq "G$rx" } 3;

    # Check that clash with existing is diagnosed
    eval { insert_cols '>$', qw(Otitle) }; verif_eval_err(qr/clash/);

    # Check that non-unique new titles are detected
    eval { insert_cols '>$', qw(Foo Foo) }; verif_eval_err(qr/more than once/);

# only_cols

    only_cols qw(A B C D E F G Z I J K L M N O);   # (no-op)
    check_both('ABCDEFGHIJKLMNO');
    apply_torx { bug unless $Gtitle eq "G$rx" } 4;

#sub ttt($) {
#  my $tag = shift;
#  say "### $tag ", join(" ", map{vis} @{ $rows[title_rx] }),"\n";
#  #say dvis '  %colx\n';
#  my %shown;
#  foreach(qw/A B C D E F G H I J K L Z/) {
#    my $cx = $colx{$_};
#    say "  $_ →  ",u($colx_desc{$_}),
#         (defined($cx) && !$shown{$cx}++
#            ? (",  rx2[$cx]=",vis($rows[2]->[$cx])) : ()), "\n"
#  };
#  foreach my $mycx (0..10) {
#    my @hits = grep{ $colx{$_} == $mycx } keys %colx;
#    say "  cx $mycx <- ", join(" ", map{vis} @hits), "\n";
#  }
#}
    #only_cols qw(K J I Z F E D C A B); # (re-arrange, deleting G)
    #check_both('KJIHFEDCAB');

    only_cols qw(O N M L K J I Z F E D C A B); # (re-arrange, deleting G)
    check_both('ONMLKJIHFEDCAB');

    apply_torx { check_colspec_is_undef('Gtitle') } 2;

    only_cols qw(12 13 11 10 9 8 7 6 5 4 3 2 1 0); # (un-re-arrange;still no G)
    check_both('ABCDEFHIJKLMNO');
    apply_torx { check_colspec_is_undef('Gtitle') } 2;

    # Restore col G
    insert_cols '>F', "Gtitle" ; apply { $Gtitle = "G$rx" };
    check_both('ABCDEFGHIJKLMNO');
    apply_torx { bug unless $Gtitle eq "G$rx" } 4;


# Reverse

    reverse_cols;
    check_both('ONMLKJIHGFEDCBA');
    apply_torx { bug unless $Gtitle eq "G$rx" } 4;

    reverse_cols;
    check_both('ABCDEFGHIJKLMNO');
    apply { bug unless $Gtitle eq "G$rx" };

# Rename

    our ($AAAtitle, $AAAtitle_alias);  # not initially imported
    bug if defined $AAAtitle;
    bug if defined $AAAtitle_alias;

    rename_cols "A title" => "AAAtitle";
    bug unless ${ sheet() }->{rows}->[1]->[0] eq 'AAAtitle';
    bug unless $title_row->[0] eq 'AAAtitle';
    apply_torx { bug unless $AAAtitle eq "A$rx" } 3;
    check_both('ABCDEFGHIJKLMNO');

    alias AAAtitle_alias => "AAAtitle";
    apply_torx { bug unless $AAAtitle_alias eq "A$rx" } 3;

    rename_cols AAAtitle => "A title  ";
    check_both('ABCDEFGHIJKLMNO');
    apply_torx { bug unless $Gtitle eq "G$rx" } 3;

    # After rename removed a title, automatic alias is no longer valid
    apply_torx { eval {my $x = $AAAtitle}; verif_eval_err; } 3;

    # However user-defined aliases remain valid
    apply_torx { bug unless $AAAtitle_alias eq "A$rx" } 3;

# switch sheet

    my $sheet1 = sheet();
    my $p = sheet();
    bug unless defined($p) && $p == $sheet1;
    bug unless $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__} == $sheet1;
    bug unless sheet({package => __PACKAGE__}) == $sheet1;
    bug if defined sheet({package => "bogopackage"});

    # replace with no sheet
    $p = sheet(undef);
    bug unless defined($p) && $p == $sheet1;
    bug if defined $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__};
    bug if defined eval { my $x = $num_cols; } ; # expect undef or croak
    bug if defined eval { my $x = $A_title;   } ; # expect undef or croak
    bug if defined $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__};
    $p = sheet();
    bug if defined $p;
    bug if defined $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__};
    bug if defined sheet();

    # put back the first sheet
    $p = sheet($sheet1);
    bug if defined $p;
    bug unless $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__} == $sheet1;
    apply_torx { bug unless $Gtitle eq "G$rx" } 4;
    check_both('ABCDEFGHIJKLMNO');

    # switch to a different sheet
    new_sheet silent => $silent;
    options silent => $silent, verbose => $verbose, debug => $debug;
    my $sheet2 = $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__};

#-----------------------------------
    (my $inpath2 = Path::Tiny->tempfile("in2_XXXXX", SUFFIX=>".csv"))->spew(<<'EOF');
TitleP,TitleQ,,TitleS,TitleT
P1,Q1,R1,S1,T1,U1
P2,Q2,R2,S2,T2,U2
P3,Q3,R3,S3,T3,U3,V3
P4,Q4,R4,S4,T4,U4
P5,Q5,R5,S5,T5,U5
EOF
    read_spreadsheet $inpath2->stringify;

    bug unless sheet() == $sheet2;
    apply { check_colspec_is_undef('Gtitle') };
    title_rx 0;
    apply { check_currow_data('PQRSTU*'); };
    apply{ our $TitleP; bug if defined $TitleP; };
    # 10/8/2021: tie_column_vars(Regex args) no longer supported!
    #tie_column_vars qr/^Title/;
    tie_column_vars '$TitleP';
    apply { our $TitleP; bug unless $TitleP eq "P$rx";
            check_colspec_is_undef('Gtitle');
          };
    apply { check_currow_data('PQRSTU*'); };

    # switch back to original sheet
    $p = sheet($sheet1);
    bug unless $p == $sheet2;
    bug unless $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__} == $sheet1;
    apply { our $TitleP; bug unless $Gtitle eq "G$rx";
            check_colspec_is_undef('TitleP');
          };
    check_both('ABCDEFGHIJKLMNO');

    # and back and forth
    sheet($sheet2);
    apply { our $TitleP; bug unless $TitleP eq "P$rx";
            check_colspec_is_undef('Gtitle');
          };
    sheet($sheet1);
    apply { our $TitleP; bug unless $Gtitle eq "G$rx";
            check_colspec_is_undef('TitleP');
          };

    # Verify that the OO api does not do anything to the "current package"
    sheet(undef);
    { my $obj = Spreadsheet::Edit->new();
      bug if defined $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__};
    }
    bug if defined sheet();

    # Test attaching to another package's sheet
    sheet($sheet1);
    { my $tmp;
      apply_torx { die "bug($Gtitle)" unless $Gtitle eq "G2" } [2];
      sheet( sheet({package => "Other"}) );
      apply_torx {
        ## With Perl v5.20.1 the following eval does not catch the exception
        #die "bug($Gtitle)" if defined eval{ $Gtitle };
        die "bug($Gtitle)" if defined eval{ my $dummy = $Gtitle };
      } [2];
      bug unless $Other::Gtitle eq "Other::Gtitle before being tied";
      eval { my $i = defined $Gtitle }; verif_eval_err;
      apply_torx { bug unless $Other::OtitleA == 314 } [2];
      bug unless $num_cols == 3;
      bug unless @rows==4 && $rows[2]->[0]==314;
      bug unless @Other::myrows==4 && $Other::myrows[2]->[1]==159;
      sheet(undef);
      bug if defined $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__};
      bug if defined sheet({package => __PACKAGE__});
      bug if defined sheet();
      bug if defined $Spreadsheet::Edit::pkg2currsheet{"".__PACKAGE__};
      bug if defined sheet();
    }

    # Create an empty sheet with defined num_cols, then add new rows
    my $old_num_cols = $sheet1->num_cols;
    my $old_rows = $sheet1->rows;
    my $old_linenums = $sheet1->linenums;
    my $old_num_rows = scalar @$old_rows;
    new_sheet(num_cols => $old_num_cols, silent => $silent);
      bug unless $num_cols == $old_num_cols;
      bug unless @rows == 0;
    insert_rows 0, $old_num_rows;
      bug unless @rows == $old_num_rows;
    foreach (0..$old_num_rows-1) {
      $rows[$_] = $old_rows->[$_];
    }
    title_rx 1;
    check_both('ABCDEFGHIJKLMNO');

    # Create a sheet from existing data
    #new_sheet(rows => $old_rows, silent => $silent);
    new_sheet(rows => $old_rows, linenums => $old_linenums, silent => $silent);

    # Put back sheet1
    sheet($sheet1);

# User-defined attributes
    { my $hash = attributes;
      expect1(ref($hash), "HASH");
      expect1(scalar(keys %$hash),0);
      attributes->{key1} = "val1";
      expect1(ref($hash), "HASH");
      expect1(scalar(keys %$hash),1);
      expect1($hash->{key1}, "val1");
      expect1(scalar(keys %{ attributes() }),1);
    }

# transpose

    if ($debug) { print "Before transpose:\n"; write_csv *STDOUT }
    transpose;
    die if defined eval('$title_rx');
    if ($debug) { print "After  transpose:\n"; write_csv *STDOUT }

    transpose;
    die if defined eval('$title_rx');
    apply {
      return if $rx < 2;  # omit header rows
      check_currow_data('ABCDEFGHIJKLMNO');
    };
    title_rx 1;
    check_both('ABCDEFGHIJKLMNO');

#FIXME: Add tests of more error conditions, e.g.
#  magic $cellvar throws if column was deleted (and not if not)

# Get rid of changes

    delete_cols qw(M N O);

# write_csv

    my $outfile = Path::Tiny->tempfile("output_XXXXX", SUFFIX => ".csv");
    write_csv "$outfile";

    { local $/ = undef; # slurp
      open(CHK, "<:crlf", $outfile) || die "Could not open $outfile : $!";
      my $finaldata = <CHK>;
      close CHK;
      my $finald = $finaldata;
      my $testd = $testdata;
      $finald =~ s/"(([^"\\]|\\.)*)"/index($1," ") >= 0 ? "\"$1\"" : $1/esg;
      $finald =~ s/^[^\n]*\n//s; # remove pre-header which we changed
      $testd =~ s/^[^\n]*\n//s;  # ditto
      unless ($finald eq $testd) {
        my $badoff;
        for my $off (0 .. max(length($finaldata),length($testdata))) {
          $badoff=$off, last
            if u(substr($finald,$off,1)) ne u(substr($testd,$off,1));
        }
        #die dvisq('\nWRONG DATA WRITTEN (diff starts at offset $badoff)\n\n$finald\n---\n $testd\n===\n$finaldata\n---\n $testdata\n').fmtsheet()
        die visnew->Useqq('unicode:controlpic:qq={}')->ivis('\nWRONG DATA WRITTEN (diff starts at offset $badoff)\n'
                .'f=$finald\n---\nt=$testd\n')
                .(" " x (5+$badoff))."^\n"
                .'\n'.fmtsheet()
      }
    }

# sort
{ package Other;
  our ($OtitleA, $OtitleB, $OtitleC);

  dprint "> Running sort_rows test\n";

  #  Original data:
  #     [qw(OtitleA OtitleB OtitleC)],
  #     [   9,      000,    26      ],
  #     [   314,    159,    26      ],
  #     [   77,     888,    999     ],
  sort_rows {
              my ($p, $q)=@_;
              Carp::confess("bug1") unless defined($p);
              Carp::confess("bug2") unless $myrows[$p] == $a;
              Carp::confess("bug3") unless $myrows[$q] == $b;
              $a->{OtitleA} <=> $b->{OtitleA} # numeric!
            };
  die "rows wrong after sort\n",vis([map{$_->[0]} @myrows])
    unless arrays_eq [map{$_->[0]} @myrows], ["OtitleA",9,77,314];
  die dvis 'linenums wrong after sort: @linenums'
    unless arrays_eq \@linenums, [1,2,4,3];

  my @Bs;
  apply { push @Bs, $OtitleB };
  die "apply broken after sort" unless arrays_eq \@Bs, [000, 888, 159];
}

say "Done." unless $silent;
exit 0;


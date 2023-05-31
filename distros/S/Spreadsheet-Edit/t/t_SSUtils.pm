package t_SSUtils;

# Utilities used by Spreadsheet::Edit tests

require Exporter;
use parent 'Exporter';

our @EXPORT = qw( fmtsheet
                  check_colspec_is_undef
                  check_no_sheet 
                  create_testdata
                );

use t_Common;
use t_TestCommon qw/bug
                    verif_eval_err insert_loc_in_evalstr
                    dprint dprintf/;
use Spreadsheet::Edit qw/fmt_sheet cx2let let2cx sheet/;

sub fmtsheet(;$) {
  my $s = $_[0] // sheet({package => caller});
  return "sheet=undef" if ! defined $s;
  "sheet->".Spreadsheet::Edit::fmt_sheet($s);
  #"sheet->".visnew->Maxdepth(1)->vis($$s)
  #"sheet->".visnew->Maxdepth(2)->vis($$s)
  #"sheet->".vis(hash_subset($$s, qw(colx rows linenums num_cols current_rx title_rx)))
}

# Verify that a column title, alias, etc. is NOT defined
sub check_colspec_is_undef(@) {
  my $pkg = caller;
  no strict 'refs';
  my $s = sheet({package => caller});
  foreach(@_) {
    bug "Colspec ".vis($_)." is unexpectedly defined" 
      if defined ${"$pkg\::colx"}{$_};
    eval{ $s->spectocx($_) }; verif_eval_err;
  }
}

sub check_no_sheet() {
  my $pkg = caller;
  for (1,2) {
    confess "current sheet unexpected in $pkg"
      if defined eval( insert_loc_in_evalstr("do{ package $pkg; sheet() }") );
    confess "bug2 $pkg"
      if defined sheet({package => $pkg});
  }
}

# Returns ($testdata, $csvpath Path::Tiny object)
#   WARNING: When $csvpath goes out of scope the file will be deleted!
#
sub create_testdata(@) {
  my %args = @_;
  my @rows = @{ $args{rows} // croak "{rows} is required" };
  if ($args{gen_rows}) {
    # Generate extra systematic rows with cell values like "C4"
    my $num_cols = $args{num_cols} // scalar @{ $rows[-1] };
    for my $rx (scalar(@rows) .. scalar(@rows)+$args{gen_rows}-1) {
      push @rows, [ map{ cx2let($_).$rx } 0..$num_cols-1 ];
    }
  }
  my $td = join("", map{ join(",",map{/[\s'",]/ ? quotekey : $_} @$_)."\n" } @rows);

  (my $path = Path::Tiny->tempfile("td_".($args{name}//"")."_XXXXX", SUFFIX=>".csv"))->spew($td);
  wantarray ? ($td, $path) : $path
}

1;

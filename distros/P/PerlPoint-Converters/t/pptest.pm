package pptest;

# some functions used in all test scripts

use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw( read_file cmp_files ltx_unlink);

sub ltx_unlink { #{{{-----------------------------------------------
  my $name = shift;
  unlink "t/d_$name/ltx_$name.tex";
  unlink "t/d_$name/ltx_$name.aux";
  unlink "t/d_$name/ltx_$name.log";
  unlink "t/d_$name/ltx_$name.idx";
  unlink "t/d_$name/ltx_$name.log";
  unlink "t/d_$name/ltx_$name.toc";
  unlink "t/d_$name/ltx_$name.dvi";
} # ltx_unlink }}}

sub read_file { #{{{------------------------------------------------
  my $file = shift;
  my $res = "";
  open(F, $file) or die "cannot open $file :!\n";
  while (<F>) {
    next if /^<!-- .*Created by/;
    next if /<!-- ZOOMRESTART -->/;
    next if /<!-- ZOOMSTOP -->/;
    next if /^%.*Created by/;
    next if /^\s*$/;
    if ($file =~ /ltx_/){
      $res .= $_;
    } else {
      $res .= norm($_);
    }
  }
  close(F);
  return $res;
} # read_file }}}

sub cmp_files { #{{{------------------------------------------------
  my ($f1) = @_;
  my $ref = $f1;
  $ref =~ s#html?#ref#;
  $ref =~ s#\.tex#.ref#;

  my $s1 = read_file($f1);
  my $s2 = read_file($ref);
  if ($s1 ne $s2) {
    print "l1: ", $s1, "\n";
    print "l2: ", $s2, "\n";
    return 0;
  } else {
    return 1;
  }
} # cmp_files }}}

sub norm { #{{{-----------------------------------------------------
  # normalize HTML lines
  my $line = shift;
  $line =~ s/^\s+//; # trim leading white space
  $line =~ s/\s+$//; # trim trailing white space
  $line =~ s/\s+/ /g; # compress white space
# $line =~ tr/a-z/A-Z/;
  return $line;
} # norm }}}
1;
__END__

# vim:foldmethod=marker:foldcolumn=4

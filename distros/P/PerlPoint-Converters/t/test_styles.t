
# Test of pp2html styles
my $n;
my $ns;
my @styles;
BEGIN{ 
  # number of slides in test_styles.pp:
  my $h = $^O =~ /win/i ? '"' : "'";
  $ns = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h t/test_styles.pp` + 2;
  @styles = qw(big_blue pp_book orange_slides);
  $n = $ns * scalar(@styles);
}


use strict;
use Test::Simple tests => $n;

use lib "./t";
use pptest;

my $ok;

foreach my $test( @styles ) {
  system "$^X -Iblib/lib ./pp2html --slide_prefix $test -slide_dir t/d_styles --quiet \@t/$test.cfg t/test_styles.pp";

  for(my $i=1; $i < $ns; $i++){
    my $nn = sprintf "%04d", $i-1;
    my $ok =ok( cmp_files("t/d_styles/$test$nn.htm"), "Test style $test");
    unlink "t/d_styles/$test$nn.htm" unless $ENV{PP_DEBUG} or !$ok;
  }
  unlink "t/d_styles/index.htm";
  unlink "t/d_styles/frame_set.html";
  my $ok =ok( cmp_files("t/d_styles/${test}_idx.htm"), "Test index $test");
  unlink "t/d_styles/${test}_idx.htm" unless $ENV{PP_DEBUG} or !$ok;
  
}
  unlink "t/d_styles/pp_book_start.htm" unless $ENV{PP_DEBUG};
  unlink "t/d_styles/pp_book-top.htm" unless $ENV{PP_DEBUG};
  unlink "t/d_styles/pp_book-bot.htm" unless $ENV{PP_DEBUG};
  unlink "t/d_styles/orange_slides-top.htm" unless $ENV{PP_DEBUG};
  unlink "t/d_styles/orange_slides-bot.htm" unless $ENV{PP_DEBUG};

# vim:ft=perl

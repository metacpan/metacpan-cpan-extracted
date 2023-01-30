use strict;
use warnings;
use Test::More;

use PDL::Graphics::Gnuplot qw(gpwin);
use File::Temp qw(tempfile);
use PDL;


my @terms_with_aa = map {
  my $tab = $_;
  grep exists $tab->{$_}{opt}[0]{aa}, keys %$tab
} $PDL::Graphics::Gnuplot::termTab;

my @valid_terms = grep $PDL::Graphics::Gnuplot::valid_terms->{$_}, @terms_with_aa;

if( @valid_terms ) {
  plan tests => scalar @valid_terms;
} else {
  plan skip_all => 'No terminals with anti-aliasing';
}

for my $term (sort @valid_terms) {
  subtest "Terminal $term" => sub {
    my ($suffix) = $PDL::Graphics::Gnuplot::termTab->{$term}{default_output} =~ /(\.[^.]+)$/;

    ok $suffix, 'have suffix';

    my (undef, $testoutput) = tempfile('pdl_graphics_gnuplot_test_aa_XXXXXXX',
      SUFFIX => $suffix);

    my $x = zeroes(50)->xlinvals(0, 7);
    my $w = gpwin($term, output => $testoutput, aa => 2);
    $w->plot(with => 'lines', $x, $x->sin);
    $w->close;
    ok -s $testoutput, 'File has size';

    unlink($testoutput) or warn "\$!: $!";
  };
}

done_testing;

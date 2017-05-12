use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::TestAnalyse;

test_distribution {
  my ($mca, $dir) = @_;

  my $content = join "\n\n", (
    '=pod',
    '=encoding utf-8;',
    '=head1 NAME',
    'Module::CPANTS::Analyse::Test - test abstract',
    '=cut',
  );

  write_pmfile("$dir/lib/Module/CPANTS/Analyse/Test.pm", $content);

  my $stash = $mca->run;
  like $stash->{error}{has_abstract_in_pod} => qr/^unknown encoding: utf-8;/;
  is $stash->{abstracts_in_pod}{'Module::CPANTS::Analyse::Test'} => 'test abstract';
};

done_testing;

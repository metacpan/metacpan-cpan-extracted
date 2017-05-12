use strict;
package Devel::Pod;
use Filter::Simple;
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::PPIHTML;

FILTER {
  # $_ =~ s/^=cut$//gm;
  my $doc = Pod::Elemental->read_string($_);
  my $ppi = Pod::Elemental::Transformer::PPIHTML->new;
  Pod::Elemental::Transformer::Pod5->new->transform_node($doc);

  my @hunks;
  for my $child (@{ $doc->children }) {
    next unless my $args = $ppi->synhi_params_for_para($child);
    push @hunks, $args->[0];
  }

  $_ = join "\n", @hunks;
};

sub DB::DB { }

1;

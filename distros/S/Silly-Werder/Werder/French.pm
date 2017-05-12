
package Silly::Werder::French;

$Silly::Werder::French::VERSION='0.90';

use strict;
use Exporter;
use Storable;
use File::Spec::Functions;

use vars qw($VERSION $PACKAGE
            @ISA
            @EXPORT @EXPORT_OK);

@ISA = 'Exporter';

my @export_functions = qw(LoadGrammar
                         );

@EXPORT_OK = (@export_functions);

sub LoadGrammar {
  my $which = shift;
  my ($locate_ref, $grammar_ref);

  # Prepend the variant with a - if it exists
  if($which) { $which = "-" . $which; }
  else { $which = ""; }

  (my $dir = $INC{'Silly/Werder.pm'}) =~ s/\.pm//;
  $dir = catdir($dir, 'data');
  my $grammar_file = catfile($dir, 'french' . $which);

  $grammar_ref = retrieve($grammar_file);

  my $count = scalar(@{$grammar_ref});

  for(my $i = 0; $i < $count; $i++) {
    $locate_ref->{$grammar_ref->[$i][0]} = $i;
  }
  return($grammar_ref, $locate_ref);
}

1;

__END__


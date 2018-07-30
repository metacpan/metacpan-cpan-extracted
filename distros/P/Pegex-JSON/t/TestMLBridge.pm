use strict; use warnings;
package TestMLBridge;
use base 'TestML::Bridge';

use YAML::XS;

use Pegex::JSON;

# $Pegex::Parser::Debug = 1;
sub load {
  my ($self, $str) = @_;

  return Pegex::JSON->new->load($str);
}

sub yaml {
  my ($self, $str) = @_;
  my $yaml = YAML::XS::Dump($str);

  $yaml =~ s/^---\s+//;
  $yaml =~ s{!!perl/scalar:boolean }{};

  return $yaml;
}

1;

use strict; use warnings;
package TestMLBridge;
use base 'TestML::Bridge';

use YAML::PP;

use Pegex::JSON;

# $Pegex::Parser::Debug = 1;
sub load {
  my ($self, $str) = @_;

  return Pegex::JSON->new->load($str);
}

sub yaml {
  my ($self, $str) = @_;
  my $yaml = YAML::PP->new(schema => [qw'Core Perl'])->dump($str);

  $yaml =~ s/^---\s+//;
  $yaml =~ s{!perl/scalar:boolean\s+=: ([01])}{$1};

  return $yaml;
}

1;

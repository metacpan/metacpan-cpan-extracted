use strict; use warnings;
package TestMLBridge;
use base 'TestML::Bridge';

use Pegex::TOML;
use TOML;
use YAML::PP;

sub pegex_toml_load {
  my ($self, $toml) = @_;

  Pegex::TOML->new->load($toml);
}

sub toml_parse {
  my ($self, $toml) = @_;

  TOML::from_toml($toml);
}

sub yaml {
  my ($self, $data) = @_;

  YAML::PP->new->dump_string($data);
}

1;

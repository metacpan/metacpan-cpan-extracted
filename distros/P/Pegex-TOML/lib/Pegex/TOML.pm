package Pegex::TOML;
BEGIN { $ENV{PERL_PEGEX_AUTO_COMPILE} = 'Pegex::TOML::Grammar' }
our $VERSION = '0.0.1';

use Pegex::Base;

use Pegex::Parser;
use Pegex::TOML::Grammar;
use Pegex::TOML::Data;

sub load {
    my ($self, $toml) = @_;
    Pegex::Parser->new(
        grammar => Pegex::TOML::Grammar->new,
        receiver => Pegex::TOML::Data->new,
        # debug => 1,
    )->parse($toml);
}

1;

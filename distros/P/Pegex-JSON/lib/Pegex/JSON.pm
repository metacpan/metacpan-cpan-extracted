package Pegex::JSON;
BEGIN { $ENV{PERL_PEGEX_AUTO_COMPILE} = 'Pegex::JSON::Grammar' }
our $VERSION = '0.31';

use Pegex::Base;

use Pegex::Parser;
use Pegex::JSON::Grammar;
use Pegex::JSON::Data;

sub load {
    my ($self, $json) = @_;
    Pegex::Parser->new(
        grammar => Pegex::JSON::Grammar->new,
        receiver => Pegex::JSON::Data->new,
        # debug => 1,
    )->parse($json);
}

1;

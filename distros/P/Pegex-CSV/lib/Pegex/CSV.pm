package Pegex::CSV;
our $VERSION = '0.0.4';

use Pegex::Base;

use Pegex::Parser;
use Pegex::CSV::Grammar;
use Pegex::CSV::LoL;
use Encode;

sub load {
    my ($self, $csv) = @_;

    my $parser = Pegex::Parser->new(
        grammar => Pegex::CSV::Grammar->new,
        receiver => Pegex::CSV::LoL->new,
        # debug => 1,
    );

    return $parser->parse(decode_utf8 $csv);
}

1;

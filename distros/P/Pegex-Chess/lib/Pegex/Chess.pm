package Pegex::Chess;
our $VERSION = '0.0.8';

use Pegex::Base;
use Pegex::Parser;
use Pegex::Chess::Grammar;
use Pegex::Chess::Data;
use IO::All;

sub parse_chess_board_file {
    my ($self, $chess_board_file, $debug) = @_;
    my $input = io->file($chess_board_file)->all;
    my $parser = Pegex::Parser->new(
        grammar => Pegex::Chess::Grammar->new,
        receiver => Pegex::Chess::Data->new,
        debug => $debug,
    );
    return $parser->parse($input);
}

1;

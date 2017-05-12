use Test::More tests => 2;

use Perl6::Perldoc::Parser;

$result = Perl6::Perldoc::Parser->parse( \<<END );
=END
pod

more pod
END


ok @{ [$result->{tree}->content] } == 1
        => 'Correct number of blocks';
is ref($result->{tree}->content), 'Perl6::Perldoc::Block::END'
        => 'Correct type of block';

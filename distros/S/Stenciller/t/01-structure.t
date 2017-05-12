use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Stenciller;

ok 1;

my $stenciller = Stenciller->new(filepath => 't/corpus/test-1.stencil');

is $stenciller->count_stencils, 1, 'Correct number of stencils';

is joiner($stenciller->all_header_lines), "Intro text\ngoes  here\n", 'Got header text';

my $stencil = $stenciller->get_stencil(0);


cmp_deeply $stencil->before_input, ['thing', '', 'here', ''], 'Correct before input' or diag '';

cmp_deeply $stencil->input, ['other thing', ''], 'Correct input';

cmp_deeply $stencil->between, ['in between', 'is three lines', 'in a row', ''], 'Got between input and output';

cmp_deeply $stencil->output, ['expecting this', ''], 'Got output';

cmp_deeply $stencil->after_output, ['A text after output'], 'Got after output';

done_testing;

sub joiner {
    return join "\n" => @_;
}

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Differences;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';
use Stenciller;

ok 1;

my $stenciller = Stenciller->new(filepath => 't/corpus/test-2.stencil');

is $stenciller->count_stencils, 1, 'Found stencils';

eq_or_diff $stenciller->transform(plugin_name => 'ToUnparsedText'), result(), 'Unparsed pod';

done_testing;

sub result {
    return qq{

Header
lines

If you write this:

    <%= badge '3' %>
    <!-- a badge -->

It becomes this:

    <span class="badge">3</span>
    <!-- a badge -->

};
}

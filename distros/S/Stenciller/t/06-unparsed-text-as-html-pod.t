use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Differences;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';
use Stenciller;

ok 1;

my $stenciller = Stenciller->new(filepath => 't/corpus/test-6.stencil');

is $stenciller->count_stencils, 1, 'Found stencils';

eq_or_diff $stenciller->transform(plugin_name => 'ToUnparsedText', constructor_args => { text_as_html_pod => 1 }), result(), 'Unparsed pod';

done_testing;

sub result {
    return qq{

=begin html

If you <code>write</code> this:

=end html

    <%= badge \'3\' %>
    <!-- a badge -->

=begin html

It becomes <b>this</b>:

=end html

    <span class="badge">3</span>
    <!-- a badge -->

};
}

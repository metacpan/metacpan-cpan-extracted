use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Differences;

use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';
use lib('t/corpus/lib');
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Splint;

eval "use MooseX::AttributeDocumented";
plan skip_all => 'These tests need MooseX::AttributeDocumented' if $@;

my $pod5 = Pod::Elemental::Transformer::Pod5->new;
my $splint = Pod::Elemental::Transformer::Splint->new;


my $doc = Pod::Elemental->read_file('t/corpus/lib/SplintTestAttributes.pm');
$pod5->transform_node($doc);
$splint->transform_node($doc);

eq_or_diff $doc->as_pod_string, expected_test1(), 'Correct parse of attributes';

sub expected_test1 {

return q{=pod

=cut
use 5.10.1;
use strict;
use warnings;

package SplintTestAttributes;

use Moose;
use MooseX::AttributeDocumented;

has testattr => (
    is => 'ro',
    isa => 'Int',
    documentation => 'A fine attribute',
    documentation_order => 2,
    documentation_alts => {
        1 => 'a good number',
        2 => 'also a good number',
    },
);

1;

__END__

=pod


=encoding utf-8




=head2 testattr

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/1#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read-only</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
    <td style="padding-left: 12px;">a good number</td>
</tr>
<tr>
    <td>&#160;</td>
    <td>&#160;</td>
    <td>&#160;</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>2</code>:</td>
    <td style="padding-left: 12px;">also a good number</td>
</tr>
</table>

<p>A fine attribute</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/1#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read-only</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>2</code>:</td>
    <td style="padding-left: 12px;">also a good number</td>
</tr>
</table>

<p>A fine attribute</p>

=end markdown

=cut
};
}

done_testing;

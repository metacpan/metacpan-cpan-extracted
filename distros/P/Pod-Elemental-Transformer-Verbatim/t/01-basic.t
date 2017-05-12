use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Pod::Elemental;
use Pod::Elemental::Transformer::Verbatim;

my @tests = (
    {
        test_name => 'multiple verbatim paragraphs',
        got => <<GOT_POD,
=pod

=head1 FOO

blah.

=begin :verbatim

Here is verbatim text
and more verbatim text

and more, after a blank line

=end :verbatim

=head1 BAR

more blah.

=cut
GOT_POD
        want => <<WANT_POD,
=pod

=head1 FOO

blah.

    Here is verbatim text
    and more verbatim text

    and more, after a blank line

=head1 BAR

more blah.

=cut
WANT_POD
    },

    {
        test_name => 'verbatim line inside nested elements',
        got => <<GOT_POD,
=pod

=over 4

=over 4

=for :verbatim
This is a single verbatim line

=back

=back

=cut
GOT_POD
        want => <<WANT_POD,
=pod

=over 4

=over 4

    This is a single verbatim line

=back

=back

=cut
WANT_POD
    },
);

my $pod5 = Pod::Elemental::Transformer::Pod5->new;
my $verbatim = Pod::Elemental::Transformer::Verbatim->new;

foreach my $test (@tests)
{
    my $document = Pod::Elemental->read_string($test->{got});

    $pod5->transform_node($document);
    $verbatim->transform_node($document);

    # TODO: use Test::Deep::Text
    is($document->as_pod_string, $test->{want}, $test->{test_name});
}

done_testing;

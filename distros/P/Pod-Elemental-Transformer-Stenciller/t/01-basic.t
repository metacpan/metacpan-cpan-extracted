use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Differences;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Stenciller;

ok 1;

my $pod5 = Pod::Elemental::Transformer::Pod5->new;
my $stenciller = Pod::Elemental::Transformer::Stenciller->new(directory => 't/corpus/source');

my $doc = Pod::Elemental->read_file('t/corpus/lib/Test/For/StencillerFromUnparsedText.pm');
$pod5->transform_node($doc);
$stenciller->transform_node($doc);
eq_or_diff $doc->as_pod_string, result(), 'Correct';

done_testing;

sub result {
    return q{=pod

=cut
package Test::For::StencillerFromUnparsedText;

1;

__END__

=pod


=head1 NAME

=head1 DESCRIPTION



Intro text
goes  here

thing

here

    other thing

in between
is three lines
in a row

    expecting this

A text after output

Header stencil 3

    Input stencil 3

Between stencil 3

    Output stencil 3

After stencil 3

Header stencil 5

    Input stencil 5

Between stencil 5

    Output stencil 5

After stencil 5



Intro text
goes  here


<p>html stencil</p>
<pre>&lt;%= badge &#39;3&#39; %&gt;</pre>
<pre>&lt;span class=&quot;badge&quot;&gt;3&lt;/span&gt;&lt;/a&gt;</pre>

=cut
};
}

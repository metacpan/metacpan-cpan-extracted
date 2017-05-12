use strict;
use warnings;

use Test::More;
use Test::Differences 'eq_or_diff';

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Weaver::Plugin::Ditaa;

my $str = do { local $/; <DATA> };

my $doc = Pod::Elemental->read_string($str);

Pod::Elemental::Transformer::Pod5->new->transform_node($doc);
Pod::Elemental::Transformer::Ditaa->new->transform_node($doc);

my $expected = <<'POD';
=pod

=begin text

Figure 1

    +--------+   +-------+    +-------+
    |        | --+ ditaa +--> |       |
    |  Text  |   +-------+    |diagram|
    |Document|   |!magic!|    |       |
    |     {d}|   |       |    |       |
    +---+----+   +-------+    +-------+
        :                         ^
        |       Lots of work      |
        +-------------------------+

=end text

=for html <p><i>Figure 1</i><img src="data:image/png;base64,HERP"></img></p>

=cut
POD

# filter out generated png
my $got = $doc->as_pod_string =~ s(data:image/png;base64,.*?")(data:image/png;base64,HERP")r;

eq_or_diff($got, $expected, 'generated pod!');

done_testing;

__DATA__
=pod

=begin ditaa

    +--------+   +-------+    +-------+
    |        | --+ ditaa +--> |       |
    |  Text  |   +-------+    |diagram|
    |Document|   |!magic!|    |       |
    |     {d}|   |       |    |       |
    +---+----+   +-------+    +-------+
        :                         ^
        |       Lots of work      |
        +-------------------------+

=end ditaa

use strict;
use warnings;

use Test::Differences;
use Test::More;

use Silki::Formatter::HTMLToWiki::Table;

{

    package FakeNode;

    use strict;
    use warnings;
    use namespace::autoclean;

    use Moose;

    has tag => (
        is  => 'ro',
        isa => 'Str',
    );

    has _attr => (
        traits   => ['Hash'],
        is       => 'ro',
        isa      => 'HashRef',
        handles  => { attr => 'get' },
        init_arg => 'attr',
    );

    sub BUILDARGS {
        my $class = shift;

        return { tag => shift, attr => {@_} };
    }

    __PACKAGE__->meta()->make_immutable();
}

{
    my $table = table(
        head => [ [ 'Header A', 'Header B' ] ],
        body => [
            [
                [ 'Body 1A', 'Body 1B' ],
                [ 'Body 2A', 'Body 2B' ],
            ],
        ],
    );

    my $expected = <<'EOF';
+------------+------------+
| Header A   | Header B   |
+------------+------------+
| Body 1A    | Body 1B    |
| Body 2A    | Body 2B    |
+------------+------------+
EOF

    eq_or_diff(
        $table->as_markdown(), $expected,
        'wikitext matches expected table -> wikitext result'
    );
}

{
    my $table = table(
        head => [
            [ 'H 1A', 'H 1B' ],
            [ 'H 2A', 'H 2B' ],
        ],
        body => [
            [
                [
                    { content => 'Body 1A', align => 'center' },
                    { content => 'Body 1B', align => 'right' },
                ],
                [
                    { content => 'Body 2A', align => 'right' },
                    { content => 'Body 2B', align => 'center' },
                ],
            ],
        ],
    );

    my $expected = <<'EOF';
+-----------+-----------+
| H 1A      | H 1B      |
| H 2A      | H 2B      |
+-----------+-----------+
|  Body 1A  |   Body 1B |
|   Body 2A |  Body 2B  |
+-----------+-----------+
EOF

    eq_or_diff(
        $table->as_markdown(), $expected,
        'wikitext matches expected table -> wikitext result'
    );
}

{
    my $table = table(
        head => [
            [ 'H 1A', 'H 1B' ],
        ],
        body => [
            [
                [
                    { content => 'Body 1A', colspan => 2 },
                ],
                [
                    { content => 'Body 2A', colspan => 2, align => 'center' },
                ],
                [
                    { content => 'Body 3A', colspan => 2, align => 'right' },
                ],
            ],
        ],
    );

    my $expected = <<'EOF';
+-----------+--------+
| H 1A      | H 1B   |
+-----------+--------+
| Body 1A           ||
|  Body 2A          ||
|           Body 3A ||
+-----------+--------+
EOF

    eq_or_diff(
        $table->as_markdown(), $expected,
        'wikitext matches expected table -> wikitext result'
    );
}

{
    my $table = table(
        body => [
            [
                [
                    { content => 'Body 1A', colspan => 2 },
                    { content => 'Body 1C' },
                ],
                [
                    { content => 'Body 2A' },
                    { content => 'Body 2B', colspan => 2 },
                ],
                [ 'Body 3A', 'Body 3B', 'Body 3C' ],
            ],
        ],
    );

    my $expected = <<'EOF';
| Body 1A              || Body 1C   |
| Body 2A   | Body 2B              ||
| Body 3A   | Body 3B   | Body 3C   |
EOF

    eq_or_diff(
        $table->as_markdown(), $expected,
        'wikitext matches expected table -> wikitext result'
    );
}

{
    my $table = table(
        head => [ [ 'Header A', 'Header B' ] ],
        body => [
            [
                [ 'Body 1A', 'Body 1B' ],
            ],
            [
                [ 'Body 2A', 'Body 2B' ],
            ],
        ],
    );

    my $expected = <<'EOF';
+------------+------------+
| Header A   | Header B   |
+------------+------------+
| Body 1A    | Body 1B    |

| Body 2A    | Body 2B    |
+------------+------------+
EOF

    eq_or_diff(
        $table->as_markdown(), $expected,
        'wikitext matches expected table -> wikitext result'
    );
}

{
    my $table = table(
        head => [ [ 'Header A', "Header B\ncont" ] ],
        body => [
            [
                [ "Body 1A\ncont", 'Body 1B' ],
                [ 'Body 2A',       "Body 2B\ncont\nmore" ],
            ],
        ],
    );

    my $expected = <<'EOF';
+----------------+---------------------+
| Header A       | Header B cont       |
+----------------+---------------------+
| Body 1A cont   | Body 1B             |
| Body 2A        | Body 2B cont more   |
+----------------+---------------------+
EOF

    eq_or_diff(
        $table->as_markdown(), $expected,
        'wikitext matches expected table -> wikitext result'
    );
}

sub table {
    my %p = @_;

    my $table = Silki::Formatter::HTMLToWiki::Table->new();

    if ( $p{head} ) {
        $table->_start_thead();

        for my $row ( @{ $p{head} } ) {
            $table->_start_tr();
            cell( $table, 'th', $_ ) for @{$row};
            $table->_end_tr();
        }

        $table->_end_thead();
    }

    for my $body ( @{ $p{body} } ) {
        $table->_start_tbody();

        for my $row ( @{$body} ) {
            $table->_start_tr();
            cell( $table, 'td', $_ ) for @{$row};
            $table->_end_tr();
        }

        $table->_end_tbody();
    }

    $table->finalize();

    return $table;
}

sub cell {
    my $table = shift;
    my $type  = shift;
    my $cell  = shift;

    my $content = ref $cell ? delete $cell->{content} : $cell;

    my $start = '_start_' . $type;
    my $end   = '_end_' . $type;
    $table->$start( FakeNode->new( $type, ref $cell ? %{$cell} : () ) );
    $table->print($content);
    $table->$end();
}

done_testing();

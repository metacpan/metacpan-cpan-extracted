use strict;
use warnings;

use Test::More;

use SQL::Tokenizer;

use constant SPACE => ' ';
use constant COMMA => ',';
use constant NL    => "\n";

my $query;
my @query;
my @tokenized;

my @tests= (
    {
        description => q{Selecting all fields from db.table},
        query       => q{INSERT INTO test (id, name) VALUES (?, '0000-00-00 11:11:11')},
        wanted      => [
            'INSERT', SPACE, 'INTO', SPACE, 'test', SPACE, '(', 'id', COMMA, SPACE, 'name', ')',
            SPACE, 'VALUES', SPACE, '(', '?', COMMA, SPACE, q{'0000-00-00 11:11:11'}, ')'
        ],
    },
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized= SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}

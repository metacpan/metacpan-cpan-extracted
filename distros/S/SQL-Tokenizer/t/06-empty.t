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

my @tests = (
    {
        description => qq{empty single quotes, RT #27797},
        query       => q{nvl(reward_type,'')='' and group_code = 'XXXX'},
        wanted      => [ 'nvl', '(', 'reward_type', ',', q{''}, ')', '=', q{''}, SPACE, 'and', SPACE, 'group_code', SPACE, '=', SPACE, q{'XXXX'} ],
    },
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized = SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}

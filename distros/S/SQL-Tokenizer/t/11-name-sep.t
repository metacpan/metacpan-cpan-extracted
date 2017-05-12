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
        description => q{PostgreSQL style},
        query       => qq{SELECT "foo"."bar"},
        wanted      => [ 'SELECT', SPACE, '"foo"', '.', '"bar"' ],
    }, {
        description => q{MySQL style},
        query       => qq{SELECT `foo`.`bar`},
        wanted      => [ 'SELECT', SPACE, '`foo`', '.', '`bar`' ],
    }

);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized= SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}

__END__


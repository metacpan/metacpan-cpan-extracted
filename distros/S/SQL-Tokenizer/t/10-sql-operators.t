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
        description => q{!},
        query       => qq{SELECT !1},
        wanted      => [ 'SELECT', SPACE, '!', 1 ],
    }, {
        description => q{Negative number},
        query       => qq{SELECT -1},
        wanted      => [ 'SELECT', SPACE, '-', 1 ],
    }

);

for my $operator (qw( - + / * <=> <= >= < > <> != = == % ~ & ^ & && | || << >> )) {
    push @tests, {
        description => qq{$operator operator},
        query       => qq{SELECT 1${operator}2},
        wanted      => [ 'SELECT', SPACE, 1, $operator, 2 ],
      };
}

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized= SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}

__END__

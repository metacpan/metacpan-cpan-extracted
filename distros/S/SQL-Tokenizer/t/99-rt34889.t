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
        description => q{rt34889},
        query       => q{SELECT t.* FROM table t},
        wanted      => [ 'SELECT', SPACE, 't.*', SPACE, 'FROM', SPACE, 'table', SPACE, 't' ],
    }, {
        description => q{Selecting all fields from db.table},
        query       => q{SELECT t.* FROM db.table t},
        wanted      => [ 'SELECT', SPACE, 't.*', SPACE, 'FROM', SPACE, 'db.table', SPACE, 't' ],
    }, {
        description => q{Selecting all fields from db.table},
        query       => q{SELECT db.table.* FROM db.table},
        wanted      => [ 'SELECT', SPACE, 'db.table.*', SPACE, 'FROM', SPACE, 'db.table' ],
    }, {
        description => q{Storing to a variable},
        query       => q{SELECT @id = column FROM db.table},
        wanted =>
          [ 'SELECT', SPACE, '@id', SPACE, '=', SPACE, 'column', SPACE, 'FROM', SPACE, 'db.table' ],
    }, {
        description => q{Declare a variable},
        query       => q{DECLARE @id INT},
        wanted      => [ 'DECLARE', SPACE, '@id', SPACE, 'INT' ],
    }, {
        description => q{Declare a variable with two @},
        query       => q{DECLARE @@id INT},
        wanted      => [ 'DECLARE', SPACE, '@@id', SPACE, 'INT' ],
    }, {
        description => q{SQL full notation for DATABASE.SCHEMA.TABLE},
        query       => q{SELECT SUM(column) FROM database..table},
        wanted      => [ 'SELECT', SPACE, 'SUM', '(', 'column', ')', SPACE,'FROM', SPACE, 'database..table' ],
	},
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized= SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}

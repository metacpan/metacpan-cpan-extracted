#!perl -w
use strict;
use Test::More tests => 1;

use SQL::Type::Guess;

use SQL::Type::Guess;

my @table = (
     [ 'city', 'state' ],
     [ 'Seattle', 'WA' ],
     [ undef, 'WA' ],
);

my $header = shift @table;
my @aoh;
for my $record ( @table ) {
     push @aoh, { map { $header->[$_] => $record->[$_] } 0 ..
$#{$record} };
}

my $g = SQL::Type::Guess->new();

my @warnings;
use Data::Dumper;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $g->guess( @aoh );
};
is_deeply [ grep /\buninitialized\b/, @warnings ], [], "No 'undefined' warnings appear in ->guess()";
use strict;

use Test::More tests => 5;

use_ok( 'Sub::Compose', 'compose', 'chain' );

use Sub::Name qw( subname );

my $a = subname 'a' => sub { return "$_[0] - " . "a:" . caller };
my $b = subname 'b' => sub { return "$_[0] - " . "b:" . caller };
my $c = subname 'c' => sub { return "$_[0] - " . "c:" . caller };

my $d = chain( $a, $b, $c );
isa_ok( $d, 'CODE' );
is( ($d->('START'))[0], 'START - a:Sub::Compose - b:Sub::Compose - c:Sub::Compose' );

my $e = compose( $a, $b, $c );
isa_ok( $e, 'CODE' );
is( ($e->('START'))[0], 'START - a:main - b:main - c:main' );


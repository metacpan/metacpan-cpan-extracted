use strict;
use utf8;
use Test::More;
use Test::Exception;
use Poz qw/z/;

my $nullSchema = z->null;
is($nullSchema->parse(undef), undef, "Null");
throws_ok(sub {
    $nullSchema->parse(1);
}, qr/^Not a null/, "Not a null");

my $arrayWithNullSchema = z->array(z->union(z->number, z->null));
is_deeply($arrayWithNullSchema->parse([undef, 1]), [undef, 1], "Null and Number");
is_deeply($arrayWithNullSchema->parse([1, 2]), [1, 2], "Number and Number");
throws_ok(sub {
    $arrayWithNullSchema->parse([undef, "a"]);
}, qr/^Not a number, Not a null for union value/, "Not a number, Not a null for union value");

done_testing;
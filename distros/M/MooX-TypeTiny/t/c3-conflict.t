use strict;
use warnings;

use Test::More;

my $e;
{
  local $@;
  eval q{
    package C3IssueTest;
    use Moo;
    use MooX::TypeTiny;

    has attr1 => ( is => 'ro' );

    has attr2 => (
      is => 'lazy',
      coerce => sub { 1 },
      default => sub { 1 },
    );

    1;
  } or $e = $@;
}
is $e, undef, "no c3 conflicts for attributes with lazy+coerce";

done_testing;

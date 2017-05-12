use strict;
use warnings;
use Test::More 'no_plan';

my @classes = map { "POE::Filter::Postfix::$_" } qw(Null Base64 Plain);

use_ok($_) for @classes;

for my $class (@classes) {
  my $obj = $class->new;
  my %attr = (foo => 2, baz => "hello", quux => "", blort => "\xff");
  is_deeply(
    $obj->get($obj->put([ \%attr ])),
    [ \%attr ],
    "$class: round trip",
  );
}

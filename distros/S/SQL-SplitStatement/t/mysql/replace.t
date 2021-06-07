use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 2;

for my $verb (qw/INSERT REPLACE/) {
  my $sql = "$verb into mac.cache(keymd5,ts,data) VALUES (?,?,?);";

  my ($stmt, $placeholders) = SQL::SplitStatement->new->split_with_placeholders($sql);

  is_deeply $placeholders, [ 3 ], "$verb statement counts placeholders correctly";
}

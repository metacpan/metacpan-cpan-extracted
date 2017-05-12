#!perl -T

use Test::More tests => 3;

BEGIN {
  use_ok('Test::Chimps::Server::Lister');
}

my $s = Test::Chimps::Server::Lister->new(list_template => 'bogus',
                                          max_reports_per_subcategory => 10);

ok($s, "the server object is defined");
isa_ok($s, 'Test::Chimps::Server::Lister', "and it's of the correct type");

use strict;
use warnings;
use xt::kwalitee::Test;

xt::kwalitee::Test::run(
  ['ISHIGAKI/Acme-CPANAuthors-Japanese-0.131002.tar.gz', 0],
  ['ISHIGAKI/Acme-CPANAuthors-0.23.tar.gz', 1],
);

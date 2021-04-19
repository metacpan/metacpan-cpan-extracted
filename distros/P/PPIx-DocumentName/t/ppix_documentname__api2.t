use strict;
use warnings;
use Test::More;
use PPIx::DocumentName;

subtest 'basic' => sub {

  local $@ = '';
  eval { PPIx::DocumentName->import(-api => 2) };
  like $@, qr/illegal api level: 2/;

};

done_testing;

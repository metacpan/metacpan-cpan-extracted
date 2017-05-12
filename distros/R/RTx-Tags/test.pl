use Test::Simple tests => 1;
eval 'use RT::Search::Googleish_Local';
ok(!$@, $@);

use strict;
use warnings;
use Test::CPANfile;
use Test::More;
use CPAN::Common::Index::MetaDB;

cpanfile_has_all_used_modules(
  recommends => 1,
  suggests => 1,
  index => CPAN::Common::Index::MetaDB->new,
);

done_testing;

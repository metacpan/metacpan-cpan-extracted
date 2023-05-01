use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Sub::Name;
use B::Deparse;

my $source = eval {
    B::Deparse->new->coderef2text(subname foo => sub{ @_ });
};

ok !$@;

like $source, qr/\@\_/;

done_testing;

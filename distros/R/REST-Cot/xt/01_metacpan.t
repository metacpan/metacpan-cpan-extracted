use strict;
use warnings;
use Test::More;

use_ok 'REST::Cot';
my $metacpan = REST::Cot->new('http://api.metacpan.org/');

isa_ok $metacpan, 'REST::Cot::Fragment';
can_ok $metacpan, qw[GET POST PUT PATCH DELETE OPTIONS HEAD];

isa_ok $metacpan->{client}, 'REST::Client';

ok my $r = $metacpan->v0->author->JMMILLS->GET();
isa_ok $r, 'HASH';
ok exists $r->{pauseid};
is $r->{pauseid}, 'JMMILLS';

done_testing;

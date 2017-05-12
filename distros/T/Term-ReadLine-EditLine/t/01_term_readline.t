use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    $ENV{PERL_RL} = 'EditLine';
    require Term::ReadLine;
}

my $t = Term::ReadLine->new('test term::readline::editline');
ok($t, 'made something');
is($t->ReadLine, 'Term::ReadLine::EditLine');

can_ok($t, $_) for qw(ReadLine readline addhistory IN OUT MinLine findConsole Attribs Features new);

$t->addhistory('hoge');

done_testing;


use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Types::Standard -types;
use Net::Curl::Parallel;

my $f = Net::Curl::Parallel->new;

$f->set_response(0, 'a');
$f->set_response(1, 'b');
$f->set_response(2, 'c');

my $r = $f->collect;
is $r, ['a'..'c'], 'collect array (wantarray false)';
is [$f->collect], ['a'..'c'], 'collect list (wantarray true)';

$r = $f->collect(0, 2);
is $r, ['a', 'c'], 'ask for 2 specific indices';
is [$f->collect(0, 2)], ['a', 'c'], '2 specific indices (wantarray true)';

$r = $f->collect(1);
is $r, 'b', 'ask for 1 specific index';
is [$f->collect(1)], ['b'], '1 specific index (wantarray true)';

done_testing;

use strict;
use Test::More tests => 4;

use lib 't/lib';
use TestUtil;

use PHP::Session;

{
    my $session = PHP::Session->new('1234', { save_path => 't', create => 1 });
    $session->set(foo => { hi => 'there' });
    $session->save;
    ok(-e "t/sess_1234", 'session created');
}

my $cont = read_file('t/sess_1234');
is $cont, q(foo|a:1:{s:2:"hi";s:5:"there";}), 'session created: a=1';

{
    my $session = PHP::Session->new('1234', { save_path => 't' });
    my $data = $session->get('foo');
    is ref($data), 'HASH';
    is_deeply $data, { hi => 'there' };
    $session->destroy;
}

use strict;
use Test::More tests => 8;

use lib 't/lib';
use TestUtil;

use PHP::Session;

{
    my $session = PHP::Session->new('1234', { save_path => 't', create => 1 });
    $session->set(foo => '-2');
    $session->set(bar => '-2.1');
    $session->set(baz => '2-1');
    $session->set(dot => '.');
    $session->save;
    ok(-e "t/sess_1234", 'session created');
}

my $cont = read_file('t/sess_1234');
like $cont, qr/foo\|i:-2/;
like $cont, qr/bar\|d:-2\.1/;
like $cont, qr/baz\|s:3:"2-1"/;

{
    my $session = PHP::Session->new('1234', { save_path => 't' });
    is $session->get('foo'), -2;
    is $session->get('bar'), -2.1;
    is $session->get('baz'), '2-1';
    is $session->get('dot'), '.';
    $session->destroy;
}

use strict;
use Test::More tests => 4;

use lib 't/lib';
use TestUtil;

use PHP::Session;

chomp(my $sess = <<'SESSION');
baz|O:3:"foo":2:{s:3:"bar";s:2:"ok";s:3:"yes";s:4:"done";}arr|a:1:{i:3;O:3:"foo":2:{s:3:"bar";s:2:"ok";s:3:"yes";s:4:"done";}}
SESSION
    ;

write_file('t/sess_1234', $sess);

{
    my $session = PHP::Session->new('1234', { save_path => 't' });
    isa_ok $session, 'PHP::Session';

    $session->unregister('foo');
    is $session->get('foo'), undef, 'unregister';

    ok $session->is_registered('baz'), 'is_registered';
    $session->unset;
    is_deeply $session->{_data}, {}, '_data is an empty hash';
}

END { unlink $_ for ('t/sess_1234'); }

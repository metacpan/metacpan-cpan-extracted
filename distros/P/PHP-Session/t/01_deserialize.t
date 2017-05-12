use strict;
use Test::More tests => 24;

use lib 't/lib';
use TestUtil;

use PHP::Session;

chomp(my $sess = <<'SESSION');
baz|O:3:"foo":2:{s:3:"bar";s:2:"ok";s:3:"yes";s:4:"done";}arr|a:1:{i:3;O:3:"foo":2:{s:3:"bar";s:2:"ok";s:3:"yes";s:4:"done";}}!foo|
SESSION
    ;

write_file('t/sess_1234', $sess);

{
    my $session = PHP::Session->new('1234', { save_path => 't' });
    isa_ok $session, 'PHP::Session';

    is $session->id, '1234', 'session id';

    my $baz = $session->get('baz');
    isa_ok $baz, 'PHP::Session::Object';
    is $baz->{_class}, 'foo', 'class';
    is $baz->{bar}, 'ok';
    is $baz->{yes}, 'done';

    my $arr = $session->get('arr');
    is ref($arr), 'HASH', 'arr is hash';
    isa_ok $arr->{3}, 'PHP::Session::Object';
    is $arr->{3}->{_class}, 'foo';
    is $arr->{3}->{bar}, 'ok';
    is $arr->{3}->{yes}, 'done';
    $session->destroy;

    is $session->get('foo'), undef, 'foo is undef';
}

chomp(my $sess2 = <<'SESSION');
count|i:2;c|i:12;!foo|a|a:4:{i:1;s:3:"foo";i:2;O:3:"baz":0:{}i:3;s:3:"bar";i:4;d:-1.2;}d|N;
SESSION
    ;
write_file('t/sess_abcd', $sess2);

{
    my $session = PHP::Session->new('abcd', { save_path => 't' });
    isa_ok $session, 'PHP::Session';

    is $session->id, 'abcd', 'session id';

    is $session->get('count'), 2;
    is $session->get('c'), 12;
    is $session->get('foo'), undef, 'foo is undef';

    my $arr = $session->get('a');
    is ref($arr), 'HASH';
    is $arr->{1}, 'foo';
    isa_ok $arr->{2}, 'PHP::Session::Object';
    is $arr->{2}->{_class}, 'baz';
    is $arr->{3}, 'bar';
    is $arr->{4}, -1.2;
    is $arr->{d}, undef;
    $session->destroy;
}



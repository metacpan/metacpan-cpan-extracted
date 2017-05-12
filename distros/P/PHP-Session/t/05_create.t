use strict;
use Test::More tests => 3;

use lib 't/lib';
use TestUtil;

use PHP::Session;

{
    eval { my $php = PHP::Session->new("abcd", { save_path => 't' }); };
    ok $@, $@;
}

{
    my $php = PHP::Session->new("abcd", { save_path => 't', create => 1 });
    $php->set(foo => "bar");
    $php->save;
    ok( -e "t/sess_abcd", "create");
}

{
    my $php = PHP::Session->new("abcd", { save_path => 't' });
    is $php->get('foo'), 'bar';
}

unlink 't/sess_abcd';


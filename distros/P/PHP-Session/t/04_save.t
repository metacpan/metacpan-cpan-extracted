use strict;
use Test::More tests => 2;

use lib 't/lib';
use TestUtil;

use PHP::Session;

my @sessions;

chomp(my $sess = <<'SESSION');
baz|O:3:"foo":2:{s:3:"bar";s:2:"ok";s:3:"yes";s:4:"done";}arr|a:1:{i:3;O:3:"foo":2:{s:3:"bar";s:2:"ok";s:3:"yes";s:4:"done";}}!foo|
SESSION
    ;

push @sessions, {
    sid => '1234',
    cont => $sess,
};

chomp(my $sess2 = <<'SESSION');
count|i:2;c|i:12;!foo|a|a:4:{i:1;s:3:"foo";i:2;O:3:"baz":0:{}i:3;s:3:"bar";i:4;d:-1.2;}d|N;
SESSION
    ;

push @sessions, {
    sid => 'abcd',
    cont => $sess,
};

for my $session (@sessions) {
    my $filename = "t/sess_" . $session->{sid};
    write_file($filename, $session->{cont});
    my $php = PHP::Session->new($session->{sid}, { save_path => 't' });
    $php->save;
    my $php2 = PHP::Session->new($session->{sid}, { save_path => 't' });
    is_deeply $php, $php2;
    $php->destroy;
}

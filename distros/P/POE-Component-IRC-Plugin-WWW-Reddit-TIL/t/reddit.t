use strict;
use warnings;

use Test::More;
use POE::Component::IRC::Plugin::WWW::Reddit::TIL;

my $class = 'POE::Component::IRC::Plugin::WWW::Reddit::TIL';

can_ok($class,qw(new _get_TIL));

my $reddit = new_ok($class);
my $til    = $reddit->_get_TIL;

like(
    $til,
    qr!^ .+ \s https?:// reddit\.com / [^/]+ /? $!ix,
    'TIL method returns a message and a link'
);

done_testing;

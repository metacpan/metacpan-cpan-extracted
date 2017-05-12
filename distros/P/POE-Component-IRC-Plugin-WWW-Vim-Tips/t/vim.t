use strict;
use warnings;

use Test::More;
use POE::Component::IRC::Plugin::WWW::Vim::Tips;

my $class = 'POE::Component::IRC::Plugin::WWW::Vim::Tips';

can_ok($class,qw(new _get_vim_tip));

my $vim = new_ok($class);

done_testing;

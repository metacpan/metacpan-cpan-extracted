use strict;
use warnings;

use Test::More tests => 2;

use_ok 'Proch::Cmd';
my $data = Proch::Cmd->new(command => '');


isa_ok($data, 'Proch::Cmd');

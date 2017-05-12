package TestAppDB;

use qbit;

use base qw(QBit::Application);

use Test::DB accessor => 'db';

__PACKAGE__->use_config('TestAppDB.cfg');

TRUE;

package TestAppDB;

use qbit;

use base qw(QBit::Application);

use Test::DB accessor       => 'db';
use Test::SecondDB accessor => 'second_db';

__PACKAGE__->config_opts(timelog_class => 'TestTimeLog');

TRUE;

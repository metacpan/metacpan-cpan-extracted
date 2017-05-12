use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth conn user schema1);


my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard_wauth() },
                     #category
                     "301 List follows.\r\n",
                     "cat1:cat1 desc:joe:mark\r",
                     ".\r\n",
                     #submitters
                     "301 List follows.\r\n",
                     "sub1:Sub long name:my contract:2:jimmy:joe, bob\r",
                     ".\r\n",
                     #responsible
                     "301 List follows.\r\n",
                     "bob:Bobby Boy:bobby\@whodunit.gov\r",
                     ".\r\n",
                     #state
                     "301 List follows.\r\n",
                     "closed::really closed",
                     "analyzed:deeply:This was analyzed deeply.\r",
                     ".\r\n",
                     #fieldnames
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #initialinput
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #initialrequired
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #databases
                     "301 List follows.\r\n",
                     "db1:db1 desc:/path/to/db1\r",
                     "db2:db2 desc:/path/to/db2\r",
                     ".\r\n",
                     #category
                     "301 List follows.\r\n",
                     "cat1:cat1 desc:joe:mark\r",
                     ".\r\n",
                     #submitters
                     "301 List follows.\r\n",
                     "sub1:Sub long name:my contract:2:jimmy:joe, bob\r",
                     ".\r\n",
                     #responsible
                     "301 List follows.\r\n",
                     "bob:Bobby Boy:bobby\@whodunit.gov\r",
                     ".\r\n",
                     #state
                     "301 List follows.\r\n",
                     "closed::really closed",
                     "analyzed:deeply:This was analyzed deeply.\r",
                     ".\r\n",
                     #fieldnames
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #initialinput
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #initialrequired
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #databases
                     "301 List follows.\r\n",
                     "db1:db1 desc:/path/to/db1\r",
                     "db2:db2 desc:/path/to/db2\r",
                     ".\r\n",

                     #
                     # Do same thing, but through Net::Gnats
                     #
                     @{ conn() },
                     @{ user() },
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() },
                     #category
                     "301 List follows.\r\n",
                     "cat1:cat1 desc:joe:mark\r",
                     ".\r\n",
                     #submitters
                     "301 List follows.\r\n",
                     "sub1:Sub long name:my contract:2:jimmy:joe, bob\r",
                     ".\r\n",
                     #responsible
                     "301 List follows.\r\n",
                     "bob:Bobby Boy:bobby\@whodunit.gov\r",
                     ".\r\n",
                     #state
                     "301 List follows.\r\n",
                     "closed::really closed",
                     "analyzed:deeply:This was analyzed deeply.\r",
                     ".\r\n",
                     #fieldnames
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #initialinput
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #initialrequired
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #databases
                     "301 List follows.\r\n",
                     "db1:db1 desc:/path/to/db1\r",
                     "db2:db2 desc:/path/to/db2\r",
                     ".\r\n",
                     #category
                     "301 List follows.\r\n",
                     "cat1:cat1 desc:joe:mark\r",
                     ".\r\n",
                     #submitters
                     "301 List follows.\r\n",
                     "sub1:Sub long name:my contract:2:jimmy:joe, bob\r",
                     ".\r\n",
                     #responsible
                     "301 List follows.\r\n",
                     "bob:Bobby Boy:bobby\@whodunit.gov\r",
                     ".\r\n",
                     #state
                     "301 List follows.\r\n",
                     "closed::really closed",
                     "analyzed:deeply:This was analyzed deeply.\r",
                     ".\r\n",
                     #fieldnames
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #initialinput
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #initialrequired
                     "301 List follows.\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     #databases
                     "301 List follows.\r\n",
                     "db1:db1 desc:/path/to/db1\r",
                     "db2:db2 desc:/path/to/db2\r",
                     ".\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c1 = Net::Gnats::Command->list;
my $c2 = Net::Gnats::Command->list( formatted => 1);
my $c3 = Net::Gnats::Command->list( subcommand => 'Bogus' );

my $c1_cat = Net::Gnats::Command->list( subcommand => 'Categories' );
my $c1_sub = Net::Gnats::Command->list( subcommand => 'Submitters' );
my $c1_res = Net::Gnats::Command->list( subcommand => 'Responsible' );
my $c1_sta = Net::Gnats::Command->list( subcommand => 'States' );
my $c1_fld = Net::Gnats::Command->list( subcommand => 'FieldNames' );
my $c1_iif = Net::Gnats::Command->list( subcommand => 'InitialInputFields' );
my $c1_irf = Net::Gnats::Command->list( subcommand => 'InitialRequiredFields' );
my $c1_dbs = Net::Gnats::Command->list( subcommand => 'Databases' );

is $c1->as_string, undef, 'c1 command is undef';
is $c2->as_string, undef, 'c2 command is undef';
is $c3->as_string, 'LIST Bogus', 'c3 command is OK but bad subcommand';

is $g->issue($c1_cat)->is_ok, 1, 'c1 category is OK';
is $g->issue($c1_sub)->is_ok, 1, 'c1 submitters is OK';
is $g->issue($c1_res)->is_ok, 1, 'c1 responsible is OK';
is $g->issue($c1_sta)->is_ok, 1, 'c1 states is OK';
is $g->issue($c1_fld)->is_ok, 1, 'c1 fieldnames is OK';
is $g->issue($c1_iif)->is_ok, 1, 'c1 initialinputfields is OK';
is $g->issue($c1_irf)->is_ok, 1, 'c1 initialrequiredfields is OK';
is $g->issue($c1_dbs)->is_ok, 1, 'c1 databases is OK';


my $cat1 = [
           { name => 'cat1',
             desc => 'cat1 desc',
             contact => 'joe',
             notify => 'mark',
           },];

is_deeply $g->issue($c1_cat)->formatted, $cat1,     'list_categories';

my $sub1 = [
            { name => 'sub1',
              desc => 'Sub long name',
              contract => 'my contract',
              response => '2',
              contact => 'jimmy',
              othernotify => 'joe, bob',
            },
           ];

is_deeply $g->issue($c1_sub)->formatted, $sub1,     'list_submitters';


my $resp1 = [
             { name => 'bob',
               realname => 'Bobby Boy',
               email => 'bobby@whodunit.gov',
             },
            ];

is_deeply  $g->issue($c1_res)->formatted, $resp1, 'list_responsible';

my $s1 = [
          { name => 'closed',
            type => '',
            desc => 'really closed',
          },
          { name => 'analyzed',
            type => 'deeply',
            desc => 'This was analyzed deeply.',
          },
         ];

is_deeply $g->issue($c1_sta)->formatted, $s1, 'list_states';

my $lfn = ['field1', 'field2'];

is_deeply $g->issue($c1_fld)->response->as_list, $lfn, 'list_fieldnames';

my $lii = ['field1', 'field2'];

is_deeply $g->issue($c1_iif)->response->as_list, $lii, 'list_inputfields_initial';

my $lir = ['field1', 'field2'];

is_deeply $g->issue($c1_irf)->response->as_list, $lir, 'list_inputfields_required';

my $dbs = [
           { name => 'db1',
             desc => 'db1 desc',
             path => '/path/to/db1',
           },
           { name => 'db2',
             desc => 'db2 desc',
             path => '/path/to/db2',
           },
          ];

is_deeply $g->issue($c1_dbs)->formatted, $dbs, 'list_databases';



#======================

my $gnats = Net::Gnats->new;
$gnats->gnatsd_connect;
$gnats->login('default', 'madmin', 'madmin');

is_deeply $gnats->list_categories, $cat1, 'list_categories';
is_deeply $gnats->list_submitters, $sub1, 'list_submitters';
is_deeply $gnats->list_responsible, $resp1, 'list_responsible';
is_deeply $gnats->list_states, $s1, 'list_states';
is_deeply $gnats->list_fieldnames, $lfn, 'list_fieldnames';
is_deeply $gnats->list_inputfields_initial, $lii, 'list_inputfields_initial';
is_deeply $gnats->list_inputfields_initial_required, $lir,
  'list_inputfields_initial_required';
is_deeply $gnats->list_databases, $dbs, 'list_databases';

done_testing();

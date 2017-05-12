use warnings;
use strict;
use Test::More;
use Siebel::Srvrmgr::ListParser 0.27;
use Siebel::Srvrmgr::Daemon::ActionFactory 0.27;
use Siebel::Srvrmgr::Daemon::ActionStash 0.27;

my $class  = 'Siebel::Lbconfig::Daemon::Action::ListServers';
my $parser = Siebel::Srvrmgr::ListParser->new(
    { clear_raw => 1, field_delimiter => '|' } );
$ENV{SIEBEL_TZ} = 'America/Sao_Paulo';
my $action = Siebel::Srvrmgr::Daemon::ActionFactory->create(
    $class,
    {
        parser => $parser,
    }
);

isa_ok( $action, $class );
$action->do( read_fixture() );
my $stash   = Siebel::Srvrmgr::Daemon::ActionStash->instance();
my $servers = $stash->shift_stash();
is( ref($servers), 'HASH',
    "content returned from $class instance is a HASH reference" );

SKIP: {
    skip 'invalid content from stash', 1
      unless ( ref($servers) eq 'HASH' );
    is_deeply(
        $servers,
        {
            sieb_serv051 => 23,
            sieb_serv053 => 15,
            sieb_serv056 => 17,
            sieb_serv052 => 13,
            sieb_serv046 => 19,
            sieb_serv047 => 21,
            sieb_serv048 => 7,
            sieb_serv049 => 9,
            sieb_serv045 => 3,
            sieb_serv058 => 5,
            sieb_serv057 => 1,
            sieb_serv050 => 11
        },
        'stash has the expected data structure'
    );
}

done_testing;

sub read_fixture {
    my @data = <DATA>;
    close(DATA);
    return \@data;
}

__DATA__
srvrmgr> list server

SBLSRVR_NAME|SBLSRVR_GROUP_NAME|HOST_NAME   |INSTALL_DIR               |SBLMGR_PID|SV_DISP_STATE|SBLSRVR_STATE|START_TIME         |END_TIME|SBLSRVR_STATUS                   |SV_SRVRID|
------------  ------------------  ------------  --------------------------  ----------  -------------  -------------  -------------------  --------  ---------------------------------  ---------
sieb_serv051|                  |sieb_serv051|/foobar/siebel/81/siebsrvr|30721     |Running      |Running      |2016-09-22 14:18:03|        |8.1.1.11 [23030] LANG_INDEPENDENT|23       |
sieb_serv053|                  |sieb_serv053|/foobar/siebel/81/siebsrvr|1915      |Running      |Running      |2016-09-22 14:18:00|        |8.1.1.11 [23030] LANG_INDEPENDENT|15       |
sieb_serv056|                  |sieb_serv056|/foobar/siebel/81/siebsrvr|27038     |Running      |Running      |2016-09-22 14:17:38|        |8.1.1.11 [23030] LANG_INDEPENDENT|17       |
sieb_serv052|                  |sieb_serv052|/foobar/siebel/81/siebsrvr|23125     |Running      |Running      |2016-09-22 14:17:36|        |8.1.1.11 [23030] LANG_INDEPENDENT|13       |
sieb_serv046|                  |sieb_serv046|/foobar/siebel/81/siebsrvr|25787     |Running      |Running      |2016-09-22 14:18:02|        |8.1.1.11 [23030] LANG_INDEPENDENT|19       |
sieb_serv047|                  |sieb_serv047|/foobar/siebel/81/siebsrvr|3666      |Running      |Running      |2016-09-22 14:17:57|        |8.1.1.11 [23030] LANG_INDEPENDENT|21       |
sieb_serv048|                  |sieb_serv048|/foobar/siebel/81/siebsrvr|3460      |Running      |Running      |2016-09-22 14:18:00|        |8.1.1.11 [23030] LANG_INDEPENDENT|7        |
sieb_serv049|                  |sieb_serv049|/foobar/siebel/81/siebsrvr|6487      |Running      |Running      |2016-09-22 14:17:57|        |8.1.1.11 [23030] LANG_INDEPENDENT|9        |
sieb_serv045|                  |sieb_serv045|/foobar/siebel/81/siebsrvr|10035     |Running      |Running      |2016-09-22 14:17:57|        |8.1.1.11 [23030] LANG_INDEPENDENT|3        |
sieb_serv058|                  |sieb_serv058|/foobar/siebel/81/siebsrvr|13411     |Running      |Running      |2016-09-22 14:17:39|        |8.1.1.11 [23030] LANG_INDEPENDENT|5        |
sieb_serv057|                  |sieb_serv057|/foobar/siebel/81/siebsrvr|1431      |Running      |Running      |2016-09-22 14:17:33|        |8.1.1.11 [23030] LANG_INDEPENDENT|1        |
sieb_serv050|                  |sieb_serv050|/foobar/siebel/81/siebsrvr|1554      |Running      |Running      |2016-09-22 14:17:39|        |8.1.1.11 [23030] LANG_INDEPENDENT|11       |

12 rows returned.


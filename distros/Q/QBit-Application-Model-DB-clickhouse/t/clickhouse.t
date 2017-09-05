#!/usr/bin/perl

use qbit;

use lib::abs qw(../lib ./lib);

use Test::More tests => 33;
use Test::Differences;

use HTTP::Response;

use TestApp;

my $URL = 'http://127.0.0.1:8123/?database=default&user=default&password=';

main();

sub main {
    my $app = TestApp->new();

    $app->pre_run();

    check_create_table($app);

    check_errors($app);

    check_get_all($app);

    check_add_multi($app);

    $app->post_run();
}

sub check_create_table {
    my ($app) = @_;

    eq_or_diff(
        $app->clickhouse->stat->create_sql, q{CREATE TABLE `stat` (
    `f_date` Date,
    `f_string` FixedString(512),
    `f_uint8` UInt8,
    `f_uint32` UInt32,
    `f_enum` Enum8('one' = 1, 'two' = 2)
) ENGINE = MergeTree(`f_date`, (`f_date` , `f_uint8`), 8192);
}, 'Check create_sql'
    );
}

sub check_errors {
    my ($app) = @_;

    my $sql = '1';

    _call_clickhouse(
        {
            set => {
                code    => 504,
                content => "Gateway Timeout",
            },
            check => {
                url     => $URL,
                content => $sql,
            }
        }
    );

    eval {$app->clickhouse->_do($sql)};

    ok($@, 'Exception throw');

    is(
        $@->message, "Gateway Timeout (HTTP504)
1", 'Message is correct'
    );

    _call_clickhouse(
        {
            set => {
                code    => 500,
                content => "Can't connect to 127.0.0.1",
            },
            check => {
                url     => $URL,
                content => $sql,
            }
        }
    );

    eval {$app->clickhouse->_do($sql)};

    ok($@, 'Exception throw');

    is(
        $@->message, "Can't connect to 127.0.0.1 (CH2)
1", 'Message is correct'
    );

    $sql = 'CREATE TABLE `bad`';

    _call_clickhouse(
        {
            set => {
                code => 500,
                content =>
'Code: 62, e.displayText() = DB::Exception: Syntax error: failed at position 19 (end of query): . Expected one of: OpeningRoundBracket, Dot, ON, ENGINE, AS, token, e.what() = DB::Exception'
            },
            check => {
                url     => $URL,
                content => $sql,
            }
        }
    );

    eval {$app->clickhouse->_do($sql)};

    ok($@, 'Exception throw');

    is(
        $@->message,
'Code: 62, e.displayText() = DB::Exception: Syntax error: failed at position 19 (end of query): . Expected one of: OpeningRoundBracket, Dot, ON, ENGINE, AS, token, e.what() = DB::Exception (62)
CREATE TABLE `bad`', 'Message is correct'
    );
}

sub check_get_all {
    my ($app) = @_;

    my $query = $app->clickhouse->query->select(
        table  => $app->clickhouse->stat,
        alias  => 't1',
        fields => {
            f_date    => '',
            undefined => \undef,
            all_sum   => {SUM => ['f_uint8']},
            sum       => ['+' => ['f_uint8', \10, 'f_uint32']],
            #clickhouse functions
            replace => {replaceRegexpAll => ['f_string', \'a', \'b']},
            host    => {hostName         => []},
        },
        #filter ['f_string' => '=' => '3'] throw exception,
        #because sql looks like this: `f_string` = 3
        #but field `f_string` has type 'FixedString'
        filter => [
            'AND',
            [
                ['f_date'   => 'IN' => \['2017-09-02', '2017-09-03']],
                ['f_enum'   => '<>' => \'two'],
                ['f_uint32' => '='  => \3]
            ]
        ]
    );

    $query->group_by(qw(f_date f_string f_uint8 f_uint32));

    $query->order_by('f_date');

    $query->limit(2);

    $query->calc_rows(1);

    _call_clickhouse(
        {
            set => {
                code    => 200,
                content => '{
    "meta":
    [
        {
            "name": "all_sum",
            "type": "UInt64"
        },
        {
            "name": "f_date",
            "type": "Date"
        },
        {
            "name": "host",
            "type": "String"
        },
        {
            "name": "replace",
            "type": "String"
        },
        {
            "name": "sum",
            "type": "UInt64"
        },
        {
            "name": "undefined",
            "type": "Null"
        }
    ],

    "data":
    [
        {
            "all_sum": 54,
            "f_date": "2017-09-02",
            "host": "localhost",
            "replace": "cut",
            "sum": 16,
            "undefined": null
        },
        {
            "all_sum": 68,
            "f_date": "2017-09-03",
            "host": "localhost",
            "replace": "cut",
            "sum": 18,
            "undefined": null
        }
    ],

    "rows": 2,

    "rows_before_limit_at_least": 4,

    "statistics":
    {
        "elapsed": 0.000017079,
        "rows_read": 0,
        "bytes_read": 0
    }
}'
            },
            check => {
                url     => $URL,
                content => q{SELECT
    SUM(`t1`.`f_uint8`) AS `all_sum`,
    `t1`.`f_date` AS `f_date`,
    hostName() AS `host`,
    replaceRegexpAll(`t1`.`f_string`, 'a', 'b') AS `replace`,
    (`t1`.`f_uint8` + 10 + `t1`.`f_uint32`) AS `sum`,
    NULL AS `undefined`
FROM `stat` AS `t1`
WHERE (
    `t1`.`f_date` IN ('2017-09-02', '2017-09-03')
    AND `t1`.`f_enum` <> 'two'
    AND `t1`.`f_uint32` = 3
)
GROUP BY `f_date`, `f_string`, `f_uint8`, `f_uint32`
ORDER BY `f_date`
LIMIT 2 FORMAT JSON}
            }
        }
    );

    is_deeply(
        $query->get_all(),
        [
            {
                'host'      => 'localhost',
                'sum'       => 16,
                'undefined' => undef,
                'replace'   => 'cut',
                'all_sum'   => 54,
                'f_date'    => '2017-09-02'
            },
            {
                'all_sum'   => 68,
                'f_date'    => '2017-09-03',
                'undefined' => undef,
                'replace'   => 'cut',
                'sum'       => 18,
                'host'      => 'localhost'
            }
        ],
        'check get_all'
    );

    is($query->found_rows(), 4, 'check found_rows');
}

sub check_add_multi {
    my ($app) = @_;

    _call_clickhouse(
        {
            set   => {code => 200, content => ''},
            check => {
                url     => $URL,
                content => q{INSERT INTO `stat` (`f_date`, `f_enum`, `f_string`, `f_uint32`, `f_uint8`) VALUES
('2017-09-03 13:42:00', 'one', 'string', 50000, 8),
('2017-09-03 13:50:00', 'two', '12', 60000, 8)}
            }
        }
    );

    $app->clickhouse->stat->add_multi(
        [
            {
                f_date   => '2017-09-03 13:42:00',
                f_string => 'string',
                f_uint8  => 8,
                f_uint32 => 50_000,
                f_enum   => 'one',
            },
            {
                f_date   => '2017-09-03 13:50:00',
                f_string => '12',                    #number as string (field's type: FixedString)
                f_uint8  => '8',                     #number as string (field's type: UInt8)
                f_uint32 => 60_000,
                f_enum   => 'two',
            }
        ]
    );

    _call_clickhouse(
        {
            set   => {code => 200, content => ''},
            check => {
                url     => $URL,
                content => q{INSERT INTO `stat` (`f_date`, `f_string`, `f_uint8`, `f_uint32`, `f_enum`) VALUES
('2017-09-03 13:42:00', 'string', 8, 50000, 'one'),
('2017-09-03 13:50:00', '12', 8, 60000, 'two')}
            }
        }
    );

    $app->clickhouse->stat->add_multi(
        [
            {
                f_date       => '2017-09-03 13:42:00',
                f_string     => 'string',
                f_uint8      => 8,
                f_uint32     => 50_000,
                f_enum       => 'one',
                f_not_exists => 'something',
            },
            {
                f_date       => '2017-09-03 13:50:00',
                f_string     => '12',                    #number as string (field's type: FixedString)
                f_uint8      => '8',                     #number as string (field's type: UInt8)
                f_uint32     => 60_000,
                f_enum       => 'two',
                f_not_exists => 'something',
            }
        ],
        fields => [qw(f_date f_string f_uint8 f_uint32 f_enum)]    #my fields and my order
    );
}

sub _call_clickhouse {
    my ($opts) = @_;

    {
        no strict 'refs';
        no warnings 'redefine';

        *{'LWP::UserAgent::request'} = sub {
            my ($lwp, $req) = @_;

            is($req->method, 'POST', 'Method is correct');

            is($req->uri->as_string, $opts->{'check'}{'url'}, 'Uri is correct') if exists($opts->{'check'}{'url'});

            eq_or_diff($req->content, $opts->{'check'}{'content'}, 'Method is correct')
              if exists($opts->{'check'}{'content'});

            my $res = HTTP::Response->new($opts->{'set'}{'code'});

            $res->content($opts->{'set'}{'content'});

            return $res;
        };
    }
}

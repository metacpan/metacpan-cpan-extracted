package TestApp;

use qbit;

use base qw(QBit::Application);

use TestApp::ClickHouse accessor => 'clickhouse';

__PACKAGE__->config_opts(
    timelog_class => 'TestTimeLog',
    clickhouse    => {
        host     => '127.0.0.1',
        port     => 8123,
        database => 'default',
        user     => 'default',
        password => '',
    }
);

TRUE;

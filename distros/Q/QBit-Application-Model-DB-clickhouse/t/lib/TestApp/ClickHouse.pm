package TestApp::ClickHouse;

use qbit;

use base qw(QBit::Application::Model::DB::clickhouse);

__PACKAGE__->meta(
    tables => {
        stat => {
            fields => [
                {name => 'f_date',   type => 'Date'},
                {name => 'f_string', type => 'FixedString', length => 512},
                {name => 'f_uint8',  type => 'UInt8',},
                {name => 'f_uint32', type => 'UInt32',},
                {name => 'f_enum',   type => 'Enum8', values => ['one', 'two']},
            ],
            engine => {MergeTree => ['f_date', {'' => ['f_date', 'f_uint8']}, \8192]}
        },
    },
);

TRUE;

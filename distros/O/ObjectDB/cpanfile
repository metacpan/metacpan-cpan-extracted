requires 'perl', '5.010';

requires 'Carp'     => 0;
requires 'Storable' => 0;

requires 'DBI';
requires 'SQL::Composer' => '0.19';

recommends 'DBIx::Inspector';

suggests 'DBD::SQLite';
suggests 'DBD::Pg';
suggests 'DBD::mysql';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Fatal';
};

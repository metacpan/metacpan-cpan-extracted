
package OI18nTest::CDBI;
use strict;
use warnings;
use base qw(Class::DBI::mysql);
my $cfg = require("dbi_connect.pl");

my $db       = $ENV{DBI_DBNAME} || $cfg->{db};
my $table    = $ENV{DBI_TABLE}  || $cfg->{table};
my $user     = $ENV{DBI_USER}   || $cfg->{user};
my $password = $ENV{DBI_PASS}   || $cfg->{password};
my $dsn   = "dbi:mysql:$db";

__PACKAGE__->set_db('Main', $dsn, $user, $password);
__PACKAGE__->table($table);
__PACKAGE__->drop_table;
__PACKAGE__->create_table(<<TABLE);
    id          int             not null auto_increment primary key,
    class       varchar(128)    not null,
    instance    varchar(255)    not null default '',
    attr        varchar(64)     not null,
    language    varchar(5)      not null,
    data        blob            not null default '',
    unique(class, instance, attr, language)
TABLE
__PACKAGE__->set_up_table;
END { __PACKAGE__->drop_table }

1;

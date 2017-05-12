package Test::ORM;

use ORM::Db::DBI::SQLite;
#use ORM::Db::DBI::PgSQL;
#use ORM::Db::DBI::MySQL;
use base 'ORM';

Test::ORM->_init
(
    history_class        => 'Test::History',
    prefer_lazy_load     => 0,
    emulate_foreign_keys => 1,
    default_cache_size   => 200,

    db => ORM::Db::DBI::SQLite->new
    (
        database    => 't/Test.db',
        user        => '',
        password    => '',
    ),

#   db => ORM::Db::DBI::MySQL->new
#   (
#       host        => 'localhost',
#       database    => 'orm_test',
#       user        => 'orm_test',
#       password    => 'orm_test',
#   ),

#   db => ORM::Db::DBI::PgSQL->new
#   (
#       host        => 'localhost',
#       database    => 'orm_test',
#       user        => 'postgres',
#       password    => 'postgres',
#       pure_perl_driver => 1,
#   ),
);

sub _guess_table_name
{
    my $my_class = shift;
    my $class = shift;
    my $table;

    $table = substr( $class, index( $class, '::' )+2 );
    $table =~ s/::/__/g;

    return $table;
}

1;

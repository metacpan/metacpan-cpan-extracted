package MyTest::CDBI::Base;

use strict;

use Rose::DB;

use base 'Class::DBI';

our $DB;

sub refresh
{
  no strict;
  no warnings 'redefine';
  *Ima::DBI::_mk_db_closure = sub 
  {
    my ( $class, @connection ) = @_;
    my $dbh;
    return sub 
    {
      unless ( $dbh && $dbh->FETCH('Active') && $dbh->ping )
      {
        my $db = Rose::DB->new;
        $db->connect_option( RootClass => 'DBIx::ContextualFetch' );
        $dbh = $db->retain_dbh;
      }
      return $dbh;
    };
  };


  $DB = Rose::DB->new;
  __PACKAGE__->connection($DB->dsn, $DB->username, $DB->password, scalar $DB->connect_options);
}

1;

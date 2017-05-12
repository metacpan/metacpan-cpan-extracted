package MyTest::CDBI::Sweet::Base;

use strict;

use Rose::DB;

use base 'Class::DBI::Sweet';

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

  my $db = Rose::DB->new;
  __PACKAGE__->connection($db->dsn, $db->username, $db->password, scalar $db->connect_options);
}

1;

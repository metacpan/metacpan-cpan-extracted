package MyDB;
use Mojo::Base -base, -signatures;

use DBI;
use Mojo::Util 'dumper';

has dsn  => 'dbi:SQLite:dbname=my.db';
has _dbh => sub ($self) {
  DBI->connect($self->dsn, '', '', { AutoCommit => 1, RaiseError => 1 });
};

sub new ($package, @args) {
  my $self = $package->SUPER::new(@args);
  $self->_init();
  return $self;
}

sub _init ($self) {
  my $sth = $self->_dbh->prepare(q{
    create table if not exists foo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      text text not null
    )
  });
  $sth->execute();

  $self->_dbh->sqlite_create_function('sleep', 0, sub { sleep 1; });
  warn dumper $self->_dbh;
}

sub insert ($self, $value) {
  my $sth = $self->_dbh->prepare('INSERT INTO foo (text) VALUES (?1)');
  return $sth->execute($value);
}

sub do_slow_stuff ($self) {
  my $sth = $self->_dbh->do('select sleep()');
}

sub flush_all ($self) {
  my $sth = $self->_dbh->prepare('DELETE from foo');
  $sth->execute();
}

1;

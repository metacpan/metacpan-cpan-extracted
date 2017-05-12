package SQL::SqlObject::Pg;

use strict;
use warnings;
use SQL::SqlObject;
use base 'SQL::SqlObject';

our $VERSION = '0.01';

SQL::SqlObject::Config::set 'HOST';
SQL::SqlObject::Config::set 'PORT';
SQL::SqlObject::Config::set 'OPTIONS';
SQL::SqlObject::Config::set 'TTY';
SQL::SqlObject::Config::set DSN         => 'dbi:Pg';
SQL::SqlObject::Config::set NAME_PREFIX => 'dbname=';

SQL::SqlObject::Config::set OTHER_ARGS => (
					   'db_host',
					   'db_port',
					   'db_options',
					   'db_tty'
					  );

SQL::SqlObject::Config::add_arg (
				 'db_host',
				 'host|pg_host|pghost',
				 'PGHOST',
				 'HOST',
				 'db_dsn'
				  );
SQL::SqlObject::Config::add_arg (
				 'db_port',
				 'port|pg_port',
				 'PGPORT',
				 'PORT',
				 'db_dsn'
				);
SQL::SqlObject::Config::add_arg (
				 'db_options',
				 'opts|options|pg_options',
				 'PGOPTIONS',
				 'OPTIONS',
				 'db_dsn'
				);
SQL::SqlObject::Config::add_arg (
				 'db_tty',
				 'tty|pg_tty',
				 'PGTTY',
				 'TTY',
				 'db_dsn'
				);

SQL::SqlObject::Config::add_enviroment_variable 'db_name'     => 'PGDATABASE';
SQL::SqlObject::Config::add_enviroment_variable 'db_user'     => 'PGUSER';
SQL::SqlObject::Config::add_enviroment_variable 'db_password' => 'PGPASSWORD';

SQL::SqlObject::Config::add_alias 'db_name', ('pg_database',
					      'pgdatabase',
					      'dbname');

SQL::SqlObject::Config::add_alias 'db_user', ('pg_user',
					      'pguser',
					      'pg_username',
					      'pgusername');

SQL::SqlObject::Config::add_alias 'db_password', ('pg_pass',
						  'pgpass',
						  'pg_password',
						  'pgpassword');

sub db_host    : lvalue { $#_ and $_[0]->{pg_host} = $_[1]; $_[0]->{pg_host} }
sub db_port    : lvalue { $#_ and $_[0]->{pg_port} = $_[1]; $_[0]->{pg_port} }
sub db_options : lvalue { $#_ and $_[0]->{pg_ops}  = $_[1]; $_[0]->{pg_ops} }
sub db_tty     : lvalue { $#_ and $_[0]->{pg_tty}  = $_[1]; $_[0]->{pg_tty} }

1;
__END__

=head1 NAME

SQL::SqlObject::Pg;

=head1 SYNOPSYS

  use SQL::SqlObject::Pg;
  my $dbh = new Sql::SqlObject::Pg($db_name);

=head1 DESCRIPTION

A subclass of SQL::SqlObject to support PostGreSQL under L<DBI>.

=head1 SEE ALSO

SQL::SqlObject (L<SQL::SqlObjectE>)

=head1 AUTHOR

Rev. Erik C. Elmshauser, D.D. E<lt>erike@pbgnw.comE<gt>

=head1 NOTE

This module may be redistributed under the same terms as perl.

=cut

# accessors for add'l args
sub db_host    : lvalue { $_[0]->{pg_host}    }
sub db_port    : lvalue { $_[0]->{pg_port}    }
sub db_options : lvalue { $_[0]->{pg_options} }
sub db_tty     : lvalue { $_[0]->{pg_tty}     }

# overload the post constructuction method
sub _init { shift->db_dsn = 'dbi:Pg' }

# overload the connect_string rutine
sub connect_string {
  my $self = shift;
  my $name = shift || $self->db_name;
  my $dsn  = $self->db_dsn;
  #return join ';', ("$dsn:dbname=$name", map {
  #  my $meth = "db_$_";
  #  "$_=".$self->$meth;
  #} qw[host port options tty]);
  return $self->SUPER::connect_string($name, $dsn, 'dbname=');
}


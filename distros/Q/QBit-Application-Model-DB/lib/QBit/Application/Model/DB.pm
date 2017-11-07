
=head1 Name

QBit::Application::Model::DB - base class for DB.

=head1 Description

Base class for working with databases.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-DB

=head1 Install

=over

=item *

cpanm QBit::Application::Model::DB

=item *

apt-get install libqbit-application-model-db-perl (http://perlhub.ru/)

=back

=cut

package QBit::Application::Model::DB;
$QBit::Application::Model::DB::VERSION = '0.023';
use qbit;

use base qw(QBit::Application::Model);

use Exception::DB;
use Exception::DB::DuplicateEntry;
use Exception::DB::TimeOut;

use DBI;
use Sys::SigAction;

=head1 Debug

  $QBit::Application::Model::DB::DEBUG = TRUE;

=cut

our $DEBUG = FALSE;

=head1 Abstract methods

=over

=item *

B<query>

=item *

B<get_query_id>

=item *

B<filter>

=item *

B<_get_table_object>

=item *

B<_create_sql_db>

=item *

B<_connect>

=item *

B<_is_connection_error>

=back

=cut

__PACKAGE__->abstract_methods(
    qw(query filter get_query_id _get_table_object _create_sql_db _connect _is_connection_error));

=head1 Accessors

=over

=item *

B<select_timeout> - timeout for select statement

=back

=cut

__PACKAGE__->mk_accessors(qw(select_timeout));

=head1 Package methods

=head2 meta

B<Arguments:>

=over

=item

B<%meta> - meta information about database

=back

B<Example:>

  package Test::DB;

  use qbit;

  use base qw(QBit::Application::Model::DB);

  my $meta = {
      tables => {
          users => {
              fields => [
                  {name => 'id',        type => 'INT',      unsigned => 1, not_null => 1, autoincrement => 1,},
                  {name => 'create_dt', type => 'DATETIME', not_null => 1,},
                  {name => 'login',     type => 'VARCHAR',  length => 255, not_null => 1,},
              ],
              primary_key => [qw(id)],
              indexes     => [{fields => [qw(login)], unique => 1},],
          },

          fio => {
              fields => [
                  {name => 'user_id'},
                  {name => 'name',    type => 'VARCHAR', length => 255,},
                  {name => 'midname', type => 'VARCHAR', length => 255,},
                  {name => 'surname', type => 'VARCHAR', length => 255,},
              ],
              foreign_keys => [[[qw(user_id)] => 'users' => [qw(id)]]]
          },
      },
  };

  __PACKAGE__->meta($meta);

in Appplication.pm

  use Test::DB accessor => 'db';

=cut

sub meta {
    my ($package, %meta) = @_;

    throw gettext("First argument must be package name, QBit::Application::Model::DB descendant")
      if !$package
          || ref($package)
          || !$package->isa('QBit::Application::Model::DB');

    my $pkg_stash = package_stash(ref($package) || $package);
    $pkg_stash->{'__META__'} = \%meta;
}

=head2 get_all_meta

B<Arguments:>

=over

=item

B<$package> - package object or name (optional)

=back

B<Return values:>

=over

=item

B<$meta> - meta information about database

=back

B<Example:>

  my $meta = $app->db->get_all_meta('Test::DB');

=cut

sub get_all_meta {
    my ($self, $package) = @_;

    $package = (ref($self) || $self) unless defined($package);
    my $meta = {};

    foreach my $pkg (eval("\@${package}::ISA")) {
        next unless $pkg->isa(__PACKAGE__);
        $self->_add_meta($meta, $pkg->get_all_meta($pkg));
    }

    $self->_add_meta($meta, package_stash($package)->{'__META__'} || {});

    return $meta;
}

=head2 init

B<No arguments.>

Method called from L</new> before return object.

=cut

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    unless (package_stash(ref($self))->{'__METHODS_CREATED__'}) {
        my $meta = $self->get_all_meta();

        my %tables;
        foreach my $table_name (keys(%{$meta->{'tables'} || {}})) {
            my %table = %{$meta->{'tables'}{$table_name}};

            $table{'class'} = $self->_get_table_class(type => $table{'type'});
            $table{'fields'}       = [$table{'class'}->default_fields(%table),       @{$table{'fields'}       || []}];
            $table{'indexes'}      = [$table{'class'}->default_indexes(%table),      @{$table{'indexes'}      || []}];
            $table{'foreign_keys'} = [$table{'class'}->default_foreign_keys(%table), @{$table{'foreign_keys'} || []}];
            $table{'primary_key'}  = $table{'class'}->default_primary_key(%table)
              unless exists($table{'primary_key'});

            $tables{$table_name} = \%table;
        }

        $self->{'__TABLE_TREE_LEVEL__'}{$_} = $self->_table_tree_level(\%tables, $_, 0) foreach keys(%tables);
        $self->{'__TABLES__'} = {};

        my $class = ref($self);

        foreach my $table_name ($self->_sorted_tables(keys(%tables))) {
            throw gettext('Cannot create table object, "%s" is reserved', $table_name)
              if $self->can($table_name);
            {
                no strict 'refs';
                *{"$class::$table_name"} = sub {
                    my ($self) = @_;

                    $self->{'__TABLES__'}{$table_name} = $tables{$table_name}->{'class'}->new(
                        %{$tables{$table_name}},
                        name => $table_name,
                        db   => $self,
                    ) unless exists($self->{'__TABLES__'}{$table_name});

                    return $self->{'__TABLES__'}{$table_name};
                };
            };
            $self->$table_name if $self->get_option('preload_accessors');
        }

        package_stash(ref($self))->{'__METHODS_CREATED__'} = TRUE;
    }

    $self->{'__SAVEPOINTS__'} = 0;
}

=head2 set_dbh

B<Arguments:>

=over

=item

B<$dbh> - Database handle object (optional)

=back

B<Return values:>

=over

=item

B<$dbh> - Database handle object or undef

=back

B<Example:>

  my $dbh = DBI->connect(...);

  # set
  $app->db->set_dbh($dbh);

  # clear
  $app->db->set_dbh();

=cut

sub set_dbh {
    my ($self, $dbh) = @_;

    if (defined($dbh)) {
        $self->{'__DBH__'}{$$} = $dbh;
    } else {
        delete($self->{'__DBH__'}{$$});
    }

    return $dbh;
}

=head2 dbh

B<No arguments.>

returns a database handle object or undef

B<Example:>

  my $dbh = $app->db->dbh;

=cut

sub dbh {
    my ($self) = @_;

    return $self->{'__DBH__'}{$$};
}

=head2 quote

B<Arguments:>

=over

=item

B<$name> - string

=back

B<Return values:>

=over

=item

B<$quoted_name> - quoted string

=back

B<Example:>

  my $quoted_name = $app->db->quote('users'); # 'users'

=cut

sub quote {
    my ($self, $name) = @_;

    my ($res) = $self->_sub_with_connected_dbh(
        sub {
            my ($self, $name) = @_;
            return $self->dbh->quote($name);
        },
        [$self, $name]
    );

    return $res;
}

=head2 quote_identifier

B<Arguments:>

=over

=item

B<$name> - string

=back

B<Return values:>

=over

=item

B<$quoted_name> - quoted string

=back

B<Example:>

  my $quoted_name = $app->db->quote_identifier('users'); # "users"

=cut

sub quote_identifier {
    my ($self, $name) = @_;

    my ($res) = $self->_sub_with_connected_dbh(
        sub {
            my ($self, $name) = @_;
            return $self->dbh->quote_identifier($name);
        },
        [$self, $name]
    );

    return $res;
}

=head2 begin

B<No arguments.>

start a new transaction or create new savepoint

B<Example:>

  $app->db->begin();

=cut

sub begin {
    my ($self) = @_;

    $self->{'__SAVEPOINTS__'} == 0
      ? $self->_do('BEGIN')
      : $self->_do('SAVEPOINT SP' . $self->{'__SAVEPOINTS__'});

    ++$self->{'__SAVEPOINTS__'};
}

=head2 commit

B<No arguments.>

commits the current transaction or release savepoint

B<Example:>

  $app->db->commit();

=cut

sub commit {
    my ($self) = @_;

    --$self->{'__SAVEPOINTS__'}
      ? $self->_do('RELEASE SAVEPOINT SP' . $self->{'__SAVEPOINTS__'})
      : $self->_do('COMMIT');
}

=head2 rollback

B<No arguments.>

rolls back the current transaction or savepoint

B<Example:>

  $app->db->rollback();

=cut

sub rollback {
    my ($self) = @_;

    my $sql =
      --$self->{'__SAVEPOINTS__'}
      ? $self->_do('ROLLBACK TO SAVEPOINT SP' . $self->{'__SAVEPOINTS__'})
      : $self->_do('ROLLBACK');
}

=head2 transaction

B<Arguments:>

=over

=item

B<$sub> - reference to sub

=back

B<Example:>

  $app->db->transaction(sub {
      # work with db
      ...
  });

=cut

sub transaction {
    my ($self, $sub) = @_;

    $self->begin();
    try {
        $sub->();
    }
    catch {
        my $ex = shift;

        if ($ex->isa('Exception::DB')) {
            $self->{'__SAVEPOINTS__'} = 0;
        } else {
            $self->rollback();
        }

        throw $ex;
    };

    $self->commit();
}

=head2 kill_query

B<Arguments:>

=over

=item

B<$query_id> - number (ID query)

=back

B<Return values:>

=over

=item

B<$res> - Returns the number of rows affected or undef on error.

A return value of -1 means the number of rows is not known, not applicable, or not available.

=back

B<Example:>

  my $res = $app->db->kill_query(35); #SQL: KILL QUERY 35;

=cut

sub kill_query {
    my ($self, $query_id) = @_;

    $self->_do("KILL QUERY $query_id");
}

sub _get_list_tables {
    my ($self, @tables) = @_;

    my $meta = $self->get_all_meta();

    my @result = ();

    if (exists($meta->{'tables'})) {
        my %table_names = map {$_ => TRUE} @tables;

        push(@result, $self->_sorted_tables(grep {!@tables || $table_names{$_}} keys(%{$meta->{'tables'}})));
    }

    return @result;
}

=head2 create_sql

B<Arguments:>

=over

=item

B<@tables> - table names (optional)

=back

B<Return values:>

=over

=item

B<$sql> - sql

=back

B<Example:>

  my $sql = $app->db->create_sql(qw(users));

=cut

sub create_sql {
    my ($self, @tables) = @_;

    $self->_connect();

    my $SQL = '';

    $SQL .= join("\n\n", map {$self->$_->create_sql()} $self->_get_list_tables(@tables));

    return "$SQL\n";
}

=head2 init_db

B<Arguments:>

=over

=item

B<@tables> - table names (optional)

=back

B<Example:>

  $app->db->init_db(qw(users));

=cut

sub init_db {
    my ($self, @tables) = @_;

    $self->_connect();

    $self->_do($self->$_->create_sql()) foreach $self->_get_list_tables(@tables);
}

=head2 finish

B<No arguments.>

Check that transaction closed

B<Example:>

  $app->db->finish();

=cut

sub finish {
    my ($self) = @_;

    if ($self->{'__SAVEPOINTS__'}) {
        $self->{'__SAVEPOINTS__'} = 1;
        $self->rollback();
        throw gettext("Unclosed transaction");
    }
}

sub _do {
    my ($self, $sql, @params) = @_;

    $self->timelog->start($self->_log_sql($sql, \@params));

    my ($res) = $self->_sub_with_connected_dbh(
        sub {
            my ($self, $sql, @params) = @_;

            my $err_code;
            return $self->dbh->do($sql, undef, @params)
              || ($err_code = $self->dbh->err())
              && throw Exception::DB $self->dbh->errstr() . " ($err_code)\n" . $self->_log_sql($sql, \@params),
              errorcode => $err_code;
        },
        \@_
    );

    $self->timelog->finish();

    return $res;
}

sub _get_all {
    my ($self, $sql, @params) = @_;

    $self->timelog->start($self->_log_sql($sql, \@params));

    my ($data) = $self->_sub_with_connected_dbh(
        sub {
            my ($self, $sql, @params) = @_;

            my $TimeOut = Sys::SigAction::set_sig_handler(
                'ALRM',
                sub {
                    my $q_id = $self->get_query_id();

                    #for reconnect
                    $self->set_dbh();

                    $self->kill_query($q_id);

                    throw Exception::DB::TimeOut gettext("Timeout for sql:\n%s", $self->_log_sql($sql, \@params));
                }
            );

            alarm($self->select_timeout // 0);

            my $err_code;
            $self->timelog->start(gettext('DBH prepare'));
            my $sth = $self->dbh->prepare($sql)
              || ($err_code = $self->dbh->err())
              && throw Exception::DB $self->dbh->errstr() . " ($err_code)\n" . $self->_log_sql($sql, \@params),
              errorcode => $err_code;

            $self->timelog->finish();

            $self->timelog->start(gettext('STH execute'));
            $sth->execute(@params)
              || ($err_code = $self->dbh->err())
              && throw Exception::DB $sth->errstr() . " ($err_code)\n" . $self->_log_sql($sql, \@params),
              errorcode => $err_code;
            $self->timelog->finish();

            $self->timelog->start(gettext('STH fetch_all'));
            my $data = $sth->fetchall_arrayref({})
              || ($err_code = $self->dbh->err())
              && throw Exception::DB $sth->errstr() . " ($err_code)\n" . $self->_log_sql($sql, \@params),
              errorcode => $err_code;
            $self->timelog->finish();

            $self->timelog->start(gettext('STH finish'));
            $sth->finish()
              || ($err_code = $self->dbh->err())
              && throw Exception::DB $sth->errstr() . " ($err_code)\n" . $self->_log_sql($sql, \@params),
              errorcode => $err_code;
            $self->timelog->finish();

            alarm(0);

            return $data;
        },
        \@_
    );

    $self->timelog->finish();

    return $data;
}

sub _log_sql {
    my ($self, $sql, $params) = @_;

    $sql =~ s/\?/$self->quote($_)/e foreach @{$params || []};

    l $sql if $DEBUG;

    return $sql;
}

sub _add_meta {
    my ($self, $res, $meta) = @_;

    foreach my $obj_type (keys %{$meta}) {
        foreach my $obj (keys %{$meta->{$obj_type}}) {
            warn gettext('Object "%s" (%s) overrided', $obj, $obj_type)
              if exists($res->{$obj_type}{$obj});
            $res->{$obj_type}{$obj} = $meta->{$obj_type}{$obj};
        }
    }
}

sub _table_tree_level {
    my ($self, $tables, $table_name, $level) = @_;

    return $self->{'__TABLE_TREE_LEVEL__'}{$table_name} + $level
      if exists($self->{'__TABLE_TREE_LEVEL__'}{$table_name});

    my @foreign_tables =
      ((map {$_->[1]} @{$tables->{$table_name}{'foreign_keys'}}), @{$tables->{$table_name}{'inherits'} || []});

    return @foreign_tables
      ? array_max(map {$self->_table_tree_level($tables, $_, $level + 1)} @foreign_tables)
      : $level;
}

sub _sorted_tables {
    my ($self, @table_names) = @_;

    return
      sort {($self->{'__TABLE_TREE_LEVEL__'}{$a} || 0) <=> ($self->{'__TABLE_TREE_LEVEL__'}{$b} || 0) || $a cmp $b}
      @table_names;
}

sub _sub_with_connected_dbh {
    my ($self, $sub, $params, $try) = @_;

    $try ||= 1;
    my @res;

    try {
        $self->_connect() unless $self->{'__SAVEPOINTS__'};
        @res = $sub->(@{$params || []});
    }
    catch {
        my $exception = shift;

        if (
            $try < 3
            && (!defined($self->dbh)
                || $self->_is_connection_error($exception->{'errorcode'} || $self->dbh->err()))
           )
        {
            $self->set_dbh() if defined($self->dbh);

            if ($self->{'__SAVEPOINTS__'}) {
                throw $exception;
            } else {
                @res = $self->_sub_with_connected_dbh($sub, $params, $try + 1);
            }
        } else {
            throw $exception;
        }
    };

    return @res;
}

TRUE;

=head1 Internal packages

=over

=item B<L<QBit::Application::Model::DB::Class>> - base class for DB modules;

=item B<L<QBit::Application::Model::DB::Field>> - base class for DB fields;

=item B<L<QBit::Application::Model::DB::Filter>> - base class for DB filters;

=item B<L<QBit::Application::Model::DB::Query>> - base class for DB queries;

=item B<L<QBit::Application::Model::DB::Table>> - base class for DB tables;

=item B<L<QBit::Application::Model::DB::VirtualTable>> - base class for DB virtual tables;

=back

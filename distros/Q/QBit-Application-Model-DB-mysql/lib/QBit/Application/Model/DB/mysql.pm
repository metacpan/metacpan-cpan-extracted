package QBit::Application::Model::DB::mysql;
$QBit::Application::Model::DB::mysql::VERSION = '0.017';
use qbit;

use base qw(QBit::Application::Model::DB);

use QBit::Application::Model::DB::mysql::Table;
use QBit::Application::Model::DB::mysql::Query;
use QBit::Application::Model::DB::Filter;

sub filter {
    my ($self, $filter, %opts) = @_;

    return QBit::Application::Model::DB::Filter->new($filter, %opts, db => $self);
}

sub query {
    my ($self, %opts) = @_;

    return QBit::Application::Model::DB::mysql::Query->new(db => $self, %opts);
}

sub transaction {
    my ($self, $sub) = @_;

    $self->_connect();
    local $self->{'__DBH__'}{$$}{'mysql_auto_reconnect'} = FALSE;

    $self->SUPER::transaction($sub);
}

sub _do {
    my ($self, $sql, @params) = @_;

    my $res;
    try {
        $res = $self->SUPER::_do($sql, @params);
    }
    catch Exception::DB with {
        my $e = shift;
        $e->{'text'} =~ /^Duplicate entry/
          ? throw Exception::DB::DuplicateEntry $e
          : throw $e;
    };

    return $res;
}

sub kill_query {
    my ($self, $query_id) = @_;

    $self->_do("KILL QUERY $query_id");
}

sub _get_table_class {
    my ($self, %opts) = @_;

    my $table_class;
    if (defined($opts{'type'})) {
        my $try_class = "QBit::Application::Model::DB::mysql::Table::$opts{'type'}";
        $table_class = $try_class if eval("require $try_class");

        throw gettext('Unknown table class "%s"', $opts{'type'}) unless defined($table_class);
    } else {
        $table_class = 'QBit::Application::Model::DB::mysql::Table';
    }

    return $table_class;
}

sub _create_sql_db {
    my ($self) = @_;

    return
        'CREATE DATABASE '
      . $self->{'__DBH__'}{$$}->quote_identifier($self->get_option('database'))
      . "\nDEFAULT CHARACTER SET UTF8;\n" . 'USE '
      . $self->{'__DBH__'}{$$}->quote_identifier($self->get_option('database')) . ";\n\n";
}

sub _connect {
    my ($self) = @_;

    unless (defined($self->{'__DBH__'}{$$})) {
        my $dsn = 'DBI:mysql:'
          . join(
            ';', map {$_ . '=' . $self->get_option($_)}
              grep {defined($self->get_option($_))} qw(database host port)
          );

        $self->{'__DBH__'}{$$} = DBI->connect(
            $dsn,
            $self->get_option('user',     ''),
            $self->get_option('password', ''),
            {
                PrintError           => 0,
                RaiseError           => 0,
                AutoCommit           => 1,
                mysql_auto_reconnect => 1,
                mysql_enable_utf8    => 1,
            },
        ) || throw DBI::errstr();
    }
}

sub _is_connection_error {
    my ($self, $code) = @_;

    return in_array($code || 0, [2006, 2013]);
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::mysql - Class for working with MySQL DB.

=head1 Description

Class for working with MySQL DB. It's not ORM.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-DB-mysql

=head1 Install

=over

=item *

cpanm QBit::Application::Model::DB::mysql

=item *

apt-get install libqbit-application-model-db-mysql-perl (http://perlhub.ru/)

=back

=head1 Package methods

=head2 filter

B<Arguments:>

=over

=item *

B<$filter> - filter (perl variables)

=item *

B<%opts> - additional options

=over

=item *

B<type> - type (AND/OR NOT)

=back

=back

B<Return values:>

=over

=item

B<$filter> - object (QBit::Application::Model::DB::Filter)

=back

B<Example:>

  my $filter = $app->db->filter([id => '=' => \23]);

=head2 query

Create and returns a new query object.

B<Arguments:>

=over

=item *

B<%opts> - options

=over

=item *

comment

=item *

without_check_fields

=item *

without_table_alias

=back

=back

B<Return values:>

=over

=item *

B<$query> - object (QBit::Application::Model::DB::mysql::Query)

=back

B<Example:>

  my $query = $app->db->query(comment => 'example query');

=head2 kill_query

B<Arguments:>

=over

=item *

B<$query_id> - number (ID query)

=back

B<Return values:>

=over

=item *

B<$res> - Returns the number of rows affected or undef on error.

A return value of -1 means the number of rows is not known, not applicable, or not available.

=back

B<Example:>

  my $res = $app->db->kill_query(35); #SQL: KILL QUERY 35;

=head2 transaction

B<Arguments:>

=over

=item *

B<$sub> - reference to sub

=back

B<Example:>

  $app->db->transaction(sub {
      # work with db
      ...
  });

=head1 Internal packages

=over

=item B<L<QBit::Application::Model::DB::mysql::Field>> - class for MySQL fields;

=item B<L<QBit::Application::Model::DB::mysql::Query>> - class for MySQL queries;

=item B<L<QBit::Application::Model::DB::mysql::Table>> - class for MySQL tables;

=back

=cut

package QBit::Application::Model::DB::clickhouse;
$QBit::Application::Model::DB::clickhouse::VERSION = '0.007';
use qbit;

use base qw(QBit::Application::Model::DB);

use QBit::Application::Model::DB::clickhouse::dbi;
use QBit::Application::Model::DB::clickhouse::Table;
use QBit::Application::Model::DB::clickhouse::Query;
use QBit::Application::Model::DB::Filter;

use Exception::DB;
eval {require Exception::DB::DuplicateEntry};

BEGIN {
    no strict 'refs';

    foreach my $method (qw(begin commit rollback transaction)) {
        *{__PACKAGE__ . "::$method"} = sub {throw gettext('Method "%s" not supported', $method)}
    }
}

my $REQUEST;

sub query {
    my ($self, %opts) = @_;

    return QBit::Application::Model::DB::clickhouse::Query->new(db => $self, %opts);
}

sub filter {
    my ($self, $filter, %opts) = @_;

    return QBit::Application::Model::DB::Filter->new($filter, %opts, db => $self);
}

sub _create_sql_db {
    my ($self) = @_;

    return 'CREATE DATABASE ' . $self->dbh->quote_identifier($self->get_option('database'));
}

sub _get_table_class {
    my ($self, %opts) = @_;

    my $table_class;
    if (defined($opts{'type'})) {
        my $try_class = "QBit::Application::Model::DB::clickhouse::Table::$opts{'type'}";
        $table_class = $try_class if eval("require $try_class");

        throw gettext('Unknown table class "%s"', $opts{'type'}) unless defined($table_class);
    } else {
        $table_class = 'QBit::Application::Model::DB::clickhouse::Table';
    }

    return $table_class;
}

sub _connect {
    my ($self, %opts) = @_;

    unless (defined($self->dbh())) {
        foreach (qw(host port database user password)) {
            $opts{$_} //= $self->get_option($_, '');
        }

        $self->set_dbh(
            QBit::Application::Model::DB::clickhouse::dbi->new(
                %opts,
                timeout => $self->get_option('timeout', 300),
                db      => $self
            )
        );
    }
}

sub _is_connection_error {
    my ($self, $code) = @_;

    return !!grep {$code eq $_} qw(CH2);
}

sub quote_identifier {"`$_[1]`"}

sub quote {
    my ($self, $name) = @_;
    #TODO: rewrite(C++)

    return 'NULL' unless defined($name);

    unless (looks_like_number($name)) {
        my $quote = $name;
        $quote =~ s/\\/\\\\/g;
        $quote =~ s/'/\\'/g;

        return "'$quote'";
    }

    return $name;
}

sub _get_all {
    my ($self, $sql, @params) = @_;

    $sql .= ' FORMAT JSON';

    return $self->SUPER::_get_all($sql, @params);
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::clickhouse - Class for working with ClickHouse DB.

=head1 Description

Class for working with ClickHouse DB. It's not ORM.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-DB-clickhouse

=head1 Install

=over

=item *

cpanm QBit::Application::Model::DB::clickhouse

=item *

apt-get install libqbit-application-model-db-clickhouse-perl (http://perlhub.ru/)

=back

B<Example:>

  __PACKAGE__->meta(
      tables => {
          stat => {
              fields => [
                  {name => 'date', type => 'Date',},
                  {name => 'hits', type => 'UInt32',},
              ],
              engine => {MergeTree => ['date', {'' => ['date', 'hits']}, \8192]}
          },
      },
  );

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

  my $filter = $app->clickhouse->filter([id => '=' => \23]);

=head2 query

B<Arguments:>

=over

=item

B<%hash> - options

=over

=item

without_table_alias - boolean(default: false)

=back

=back

B<Return values:>

=over

=item

B<$query> - object (QBit::Application::Model::DB::clickhouse::Query)

=back

B<Example:>

  my $table = $app->clickhouse->stat;

  my $query = $app->clickhouse->query();
  $query->_field_to_sql(undef, 'hits', $table); # `stat`.`hits`

  my $query2 = $app->clickhouse->query(without_table_alias => TRUE);
  $query->_field_to_sql(undef, 'hits', $table); # `hits`

=head1 Internal packages

=over

=item B<L<QBit::Application::Model::DB::clickhouse::Field>> - class for ClickHouse fields;

=item B<L<QBit::Application::Model::DB::clickhouse::Query>> - class for ClickHouse queries;

=item B<L<QBit::Application::Model::DB::clickhouse::Table>> - class for ClickHouse tables;

=item B<L<QBit::Application::Model::DB::clickhouse::dbi>> - class for ClickHouse DBI;

=item B<L<QBit::Application::Model::DB::clickhouse::st>> - class for ClickHouse sth;

=back

=cut

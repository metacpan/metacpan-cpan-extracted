package QBit::Application::Model::DB::clickhouse::dbi;
$QBit::Application::Model::DB::clickhouse::dbi::VERSION = '0.007';
use qbit;

use base qw(QBit::Class);

use LWP::UserAgent;
use HTTP::Request;

use QBit::Application::Model::DB::clickhouse::st;

__PACKAGE__->mk_ro_accessors(qw(db));

__PACKAGE__->mk_accessors(qw(err errstr));

sub init {
    my ($self) = @_;
    
    weaken($self->db);

    $self->{'__REQUEST__'} =
      HTTP::Request->new(
        POST => sprintf('http://%s:%s/?database=%s&user=%s&password=%s', @$self{qw(host port database user password)}));

    $self->{'__LWP__'} = LWP::UserAgent->new(timeout => $self->{'timeout'});
}

sub prepare {
    my ($self, $sql) = @_;

    return QBit::Application::Model::DB::clickhouse::st->new(
        request => $self->{'__REQUEST__'},
        lwp     => $self->{'__LWP__'},
        sql     => $sql,
        dbi     => $self
    );
}

sub do {
    my ($self, $sql, $attr, @params) = @_;

    my $sth = $self->prepare($sql);

    my $res = $sth->execute(@params);

    $self->errstr($sth->errstr()) unless $res;

    return $res;
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::clickhouse::dbi - Class for ClickHouse DBI.

=head1 Description

Implements dbi methods for ClickHouse driver.

=head1 Package methods

=head2 new

B<Arguments:>

=over

=item *

B<%opts> - connection options: host, port, database, user, password, timeout, db(QBit::Application::Model::DB::clickhouse)

=back

B<Return values:>

=over

=item

B<$dbh> - object (QBit::Application::Model::DB::clickhouse::dbi)

=back

B<Example:>

  my $dbh = QBit::Application::Model::DB::clickhouse::dbi->new(
      host     => '127.0.0.1',
      port     => 8123,
      database => 'default',
      user     => 'default',
      password => '',
      timeout  => 300,
      db       => $app->clickhouse
  );

=head2 prepare

B<Arguments:>

=over

=item *

B<$sql> - string (SQL)

=back

B<Return values:>

=over

=item

B<$sth> - object (QBit::Application::Model::DB::clickhouse::st)

=back

B<Example:>

  my $sth = $dbh->prepare('SELECT 1');

=head2 do

B<Arguments:>

=over

=item *

B<$sql> - string (SQL)

=item *

B<$attr> - hash ref (additional attributes)

=item *

B<@params> - array (parameters to binding)

=back

B<Return values:>

=over

=item

B<$boolean> - (true on success; false otherwise)

=back

B<Example:>

  $dbh->do('INSERT INTO `state` (`date`, `hits`) VALUES ("2017-09-03", 35)')
    or die $dbh->err() . ': ' . $dbh->errstr();

=cut

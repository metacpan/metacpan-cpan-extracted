package PDK::DBI::Pg;

use v5.30;
use Moose;
use DBIx::Custom;
use namespace::autoclean;
use Carp qw(croak);

has option => (is => 'ro', isa => 'Maybe[HashRef[Str]]', default => undef,);

with 'PDK::DBI::Role';

has '+dbi' => (isa => 'DBIx::Custom', handles => qr/^(?:select|update|insert|delete|execute|user).*/, );

for my $func (qw(execute delete update insert batchExecute)) {
  around $func => sub {
    my ($orig, $self, @args) = @_;
    my $result;

    eval {
      $result = $self->$orig(@args);
      $self->dbi->dbh->commit;
    };

    if (!!$@) {
      my $error = $@;
      eval { $self->dbi->dbh->rollback };
      croak "提交事务异常: $error" . ($@ ? "\n回滚失败: " . $self->dbi->dbh->errstr : "");
    }

    return $result;
  };
}

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  my %param = @args == 1 && ref $args[0] eq 'HASH' ? %{$args[0]} : @args;

  if (not defined $param{dsn} and defined $param{host} and defined $param{port} and defined $param{dbname}) {
    $param{dsn} = "dbi:Pg:dbname=$param{dbname};host=$param{host};port=$param{port}";
  }

  return $class->$orig(%param);
};

sub clone {
  my $self = shift;
  return __PACKAGE__->new(map { $_ => $self->$_ } qw(dsn user password option));
}

sub batchExecute {
  my ($self, $params, $sql) = @_;
  $self->_rawExecute($params, $sql);
}

sub _rawExecute {
  my ($self, $params, $sql) = @_;
  my $sth   = $self->dbi->dbh->prepare($sql);
  my $count = 0;

  for my $param (@$params) {
    $sth->execute(@$param);
    $self->dbi->dbh->commit if ++$count % 5000 == 0;
  }

  $self->dbi->dbh->commit if $count % 5000 != 0;
}

sub _buildDbi {
  my $self = shift;

  my %param = (
    dsn      => $self->dsn,
    user     => $self->user,
    password => $self->password,
    option   => $self->option // {AutoCommit => 0, RaiseError => 1, PrintError => 0},
  );

  if ($ENV{LANG}) {
    $ENV{NLS_CURRENCY} = $ENV{NLS_DUAL_CURRENCY} = '*';
  }

  my $dbi = DBIx::Custom->connect(%param);
  $dbi->quote('');

  return $dbi;
}

sub disconnect {
  my $self = shift;
  $self->dbi->dbh->disconnect;
}

sub reconnect {
  my $self = shift;
  $self->disconnect;
  $self->{dbi} = $self->_buildDbi;
}

__PACKAGE__->meta->make_immutable;

1;

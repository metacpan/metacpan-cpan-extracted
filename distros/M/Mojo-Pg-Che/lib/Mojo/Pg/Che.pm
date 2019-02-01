package Mojo::Pg::Che;

use Mojo::Base 'Mojo::EventEmitter';#'Mojo::Pg';

=pod

=encoding utf-8

Доброго всем

=head1 Mojo::Pg::Che

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojo::Pg::Che - mix of parent Mojo::Pg and DBI.pm

=head1 DESCRIPTION

See L<Mojo::Pg>

=head1 VERSION

Version 0.854

=cut

our $VERSION = '0.854';


=head1 SYNOPSIS

    use Mojo::Pg::Che;

    my $pg = Mojo::Pg::Che->connect("dbname=test;", "postgres", 'pg-pwd', \%attrs, max_connections=>10);
    # or
    my $pg = Mojo::Pg::Che->new
      ->dsn("DBI:Pg:dbname=test;")
      ->username("postgres")
      ->password('pg--pw')
      ->options(\%attrs)
      ->connect();
    
    # or
    my $pg = Mojo::Pg::Che->new('pg://postgres@/test');
    # or
    my $pg = Mojo::Pg::Che->new()->connect(...);

    # Bloking query
    my $result = $pg->query('select ...', undef, @bind);
    
    # Non-blocking query
    my $result = $pg->query('select ...', {Async => 1, ...}, @bind);
    
    # Cached query
    my $result = $pg->query('select ...', {Cached => 1, ...}, @bind);
    
    # prepare sth
    my $sth = $pg->prepare('select ...');
    
    # cached async sth
    my $sth = $pg->prepare_cached('select ...', {Async => 1,},);
    
    # Non-blocking query for async sth
    $pg->query($sth, undef, @bind, sub {my ($db, $err, $result) = @_; ...});
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
    
    
    # Result non-blocking query for async sth
    my $ref_cb = $pg->query($sth, {Async => 1,}, @bind,);
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
    # Mojo::Pg::Results style
    my res = $$ref_cb->()->hash;
    # same DBI style
    my $res  = $$ref_cb->()->fetchrow_hashref;
    
    # Mojo::Pg style
    my $now = $pg->db->query('select now() as now')->hash->{now};
    $pg->db->query('select pg_sleep(?::int), now() as now', undef, 2, $cb);
    
    # DBI style
    my $now = $pg->selectrow_hashref('select now() as now')->{now};
    my $now = $pg->db->selectrow_hashref('select now() as now')->{now};
    
    my $now = $pg->selectrow_array('select now() as now');

=head2 Transaction syntax

  eval {
    my $tx = $pg->begin;
    $tx->query('insert into foo (name) values (?)', 'bar');
    $tx->do('insert into foo (name) values (?)', 'baz');
    $tx->commit;
  };
  die $@ if $@;
  
  my $db = $pg->db;
  $db->begin;
  $db->do('insert into foo (name) values (?)', 'bazzzz');
  $db->rollback;
  $db->begin;
  $db->query('insert into foo (name) values (?)', 'barrr');
  $db->commit;

=head1 Non-blocking query

  my @results;
  my $cb = sub {
    my ($db, $err, $results) = @_;
    die $err if $err;
    push @results, $results;
  };
  $pg->query('select ?::date as d, pg_sleep(?::int)', undef, ("2016-06-$_", 1), $cb)
    for 17..23;
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  like($_->hash->{d}, qr/2016-06-\d+/, 'correct async query')
    for @results;



=head1 METHODS

All methods from parent module L<Mojo::Pg> are inherits and implements the following new ones.

=head2 connect

DBI-style of new object instance. See L<DBI#connect>

=head2 db

Overriden method of L<Mojo::Pg#db>. Because can first input param - DBI database handler (when prepared statement used).

=head2 prepare

Prepare and return DBI statement handler for query string.

=head2 prepare_cached

Prepare and return DBI cached statement handler for query string.

=head2 query

Like L<Mojo::Pg::Database#query> but input params - L<Mojo::Pg::Che#Params-for-quering-methods>

Blocking query without attr B<Async> or callback.

Non-blocking query with attr B<Async> or callback.

=head2 select

Same method C<query>.

=head2 selectrow_array

DBI style quering. See L<DBI#selectrow_array>. Blocking | non-blocking. Input params - L<Mojo::Pg::Che#Params-for-quering-methods>.

=head2 selectrow_arrayref

DBI style quering. See L<DBI#selectrow_arrayref>. Blocking | non-blocking. Input params - L<Mojo::Pg::Che#Params-for-quering-methods>.

=head2 selectrow_hashref

DBI style quering. See L<DBI#selectrow_hashref>. Blocking | non-blocking. Input params - L<Mojo::Pg::Che#Params-for-quering-methods>.

=head2 selectall_arrayref

DBI style quering. See L<DBI#selectall_arrayref>. Blocking | non-blocking. Input params - L<Mojo::Pg::Che#Params-for-quering-methods>.

=head2 selectall_hashref

DBI style quering. See L<DBI#selectall_hashref>. Blocking | non-blocking. Input params - L<Mojo::Pg::Che#Params-for-quering-methods>.

=head2 selectcol_arrayref

DBI style quering. See L<DBI#selectcol_arrayref>. Blocking | non-blocking. Input params - L<Mojo::Pg::Che#Params-for-quering-methods>.

=head2 do

DBI style quering. See L<DBI#do>. Blocking | non-blocking. Input params - L<Mojo::Pg::Che#Params-for-quering-methods>.

=head2 begin

Start transaction and return new L<Mojo::Pg::Che::Database> object which attr C< {tx} > is a L<Mojo::Pg::Transaction> object. Sinonyms are: C<< ->tx >> and C<< ->begin_work >>.

=head1 Params for quering methods

The methods C<query>, C<select...>, C<do> has next ordered input params:

=over 4

=item * String query | statement handler object

=item * Hashref attrs (optional)

=item * Array of bind values (optional)

=item * Last param - callback/coderef for non-blocking (optional)

=back

=head1 SEE ALSO

L<Mojo::Pg>

L<DBI>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojo-Pg-Che/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Mojo::Pg;
use DBI;
use Carp qw(croak);
use Mojo::Pg::Che::Database;
#~ use Mojo::URL;
#~ use Scalar::Util 'blessed';

has pg => sub { Mojo::Pg->new };#, weak => 1;
has database_class => 'Mojo::Pg::Che::Database';
has dsn             => 'dbi:Pg:';
has max_connections => 5;
has [qw(password username)] => '';
has [qw(parent search_path)];
has options => sub {
  {
    AutoCommit => 1,
    AutoInactiveDestroy => 1,
    PrintError => 0,
    RaiseError => 1,
    ShowErrorStatement => 1,
    pg_enable_utf8 => 1,
  };
};

has debug => $ENV{DEBUG_Mojo_Pg_Che} || 0;
my $PKG = __PACKAGE__;

sub new {
  my $class = shift;
  my $from_string = @_ == 1;
  my $pg = $from_string && Mojo::Pg->new->from_string(shift);

  my $self = $class->SUPER::new(@_);
  $self->pg($pg)
    if $pg;

  if ($from_string) {
    map $self->$_($self->pg->$_),
    qw(dsn username password options search_path);
  } else {
    map $self->pg->$_($self->$_),
    qw(dsn username password options search_path max_connections);#database_class pubsub
  }

  $self->dsn('dbi:Pg:'.$self->dsn)
    unless !$self->dsn || $self->dsn =~ /^dbi:Pg:/;
  
  return $self;
}

#DBI
sub connect {
  my $self = ref $_[0] ? shift : shift->SUPER::new;
  map { my $has = shift; $has && $self->$_($has)} qw(dsn username password);

  if (ref $_[0]) {
    my $attrs =  shift;
    my $options = $self->options;
    @$options{ keys %$attrs } = values %$attrs;
  }
  if (@_) {
    my $attrs = {@_};
    map $self->$_($attrs->{$_}), keys %$attrs;
  }
  
  $self->dsn('dbi:Pg:'.$self->dsn)
    unless !$self->dsn || $self->dsn =~ /^dbi:Pg:/;
  
  #~ $self->pg(Mojo::Pg->new)
    #~ unless $self->pg;
  
  map $self->pg->$_($self->$_),
    qw(dsn username password options search_path max_connections);#database_class  pubsub
  
  #~ say STDERR sprintf("[$PKG->connect] prepare connection data for [%s]", $self->dsn, )
    #~ if $self->debug;
  
  return $self;
}

sub db {
  my ($self, $dbh) = (shift, shift);

  # Fork-safety
  delete @$self{qw(pid queue)} unless ($self->{pid} //= $$) eq $$;
  
  $dbh ||= $self->_dequeue;

  return $self->database_class->new(dbh => $dbh, pg => $self);
}

sub prepare { shift->db->prepare(@_); }
sub prepare_cached { shift->db->prepare_cached(@_); }

# если уже sth и он не в асинхроне - взять его dbh
sub _db {
  my $self = shift;
  my $sth = ref $_[0] ? shift : return $self->db;
  return $self->db
    if !!$sth->{pg_async_status};
  #~ my $db = $sth->{private_mojo_db};
  #~ return $db
    #~ if $db && !$db->dbh->{pg_async_status};

  $self->db($sth->{Database});
}

# если уже sth и он не в асинхроне - взять в запрос его
# или просто у него взять строку запроса для нового dbh
sub _sth {
  my $self = shift;
  my $sth = ref $_[0] ? shift : return @_;
  #~ warn "_sth: $sth->{pg_async_status}, ";
  return ($sth, @_)
    if $sth->{pg_async_status} != 1;
  return ($sth->{Statement}, @_);
}

sub query { my $self = shift; $self->_db(@_)->select($self->_sth(@_)) }
sub select { my $self = shift; $self->_db(@_)->select($self->_sth(@_)) }
sub selectrow_array { my $self = shift; $self->_db(@_)->selectrow_array($self->_sth(@_)) }
sub selectrow_arrayref { my $self = shift; $self->_db(@_)->selectrow_arrayref($self->_sth(@_)) }
sub selectrow_hashref { my $self = shift; $self->_db(@_)->selectrow_hashref($self->_sth(@_)) }
sub selectall_arrayref { my $self = shift; $self->_db(@_)->selectall_arrayref($self->_sth(@_)) }
sub selectall_hashref { my $self = shift; $self->_db(@_)->selectall_hashref($self->_sth(@_)) }
sub selectcol_arrayref { my $self = shift; $self->_db(@_)->selectcol_arrayref($self->_sth(@_)) }
sub do { my $self = shift; $self->_db(@_)->do($self->_sth(@_)) }

#~ sub begin_work {croak 'Use $pg->db->tx | $pg->db->begin';}
sub tx {shift->begin}
sub begin_work {shift->begin}
sub begin {
  my $self = shift;
  my $db = $self->db;
  $db->begin;
  return $db;
}

sub commit  {croak 'Instead use: $tx = $pg->begin; $tx->do(...); $tx->commit;';}
sub rollback {croak 'Instead use: $tx = $pg->begin; $tx->do(...); $tx->rollback;';}

# Patch parent Mojo::Pg::_dequeue
sub _dequeue {
  my $self = shift;
  
  my $queue = $self->{queue} ||= [];
  for my $i (0..$#$queue) {
    
    my $dbh = $queue->[$i];

    next
      if $dbh->{pg_async_status} && $dbh->{pg_async_status} > 0;
    
    splice(@$queue, $i, 1);    #~ delete $queue->[$i]
    
    ($self->debug
      && (say STDERR sprintf("[$PKG->_dequeue] [$dbh] does dequeued, pool count:[%s]", scalar @$queue))
      && 0)
      or return $dbh
      if $dbh->ping;
    
  }
  
  my $dbh = DBI->connect(map { $self->$_ } qw(dsn username password options));
  $self->debug
    && say STDERR sprintf("[$PKG->_dequeue] new DBI connection [$dbh]", );
  

  $self->emit(connection => $dbh);

  return $dbh;
}

sub _enqueue {
  my ($self, $dbh) = @_;
  my $queue = $self->{queue} ||= [];
  #~ warn "queue++ $dbh:", scalar @$queue and
  
  if ($dbh->{Active} && ($dbh->{pg_async_status} && $dbh->{pg_async_status} > 0) || @$queue < $self->max_connections) {
    unshift @$queue, $dbh;
    $self->debug
      && say STDERR sprintf("[$PKG->_enqueue] [$dbh] does enqueued, pool count:[%s], pg_async_status=[%s]", scalar @$queue, $dbh->{pg_async_status});
    return;
  }
  #~ shift @$queue while @$queue > $self->max_connections;
  $self->debug
    && say STDERR sprintf("[$PKG->_enqueue] [$dbh] does not enqueued, pool count:[%s]", scalar @$queue);
}

1;

__END__

has pubsub => sub {
  require Mojo::Pg::PubSub;
  my $pubsub = Mojo::Pg::PubSub->new(pg => shift);
  #~ weaken $pubsub->{pg};#???
#Mojo::Reactor::EV: Timer failed: Can't call method "db" on an undefined value at t/06-pubsub.t line 21.
#EV: error in callback (ignoring): Can't call method "db" on an undefined value at Mojo/Pg/PubSub.pm line 44.
  return $pubsub;
};





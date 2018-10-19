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

Version 0.852

=cut

our $VERSION = '0.852';


=head1 SYNOPSIS

    use Mojo::Pg::Che;

    my $pg = Mojo::Pg::Che->connect("dbname=test;", "postgres", 'pg-pwd', \%attrs);
    # or
    my $pg = Mojo::Pg::Che->new
      ->dsn("DBI:Pg:dbname=test;")
      ->username("postgres")
      ->password('pg--pw')
      ->options(\%attrs);
    
    # or
    my $pg = Mojo::Pg->new('pg://postgres@/test');

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

=head1 Non-blocking query cases

Depends on $attr->{Async} and callback:

1. $attr->{Async} set to 1. None $cb pass. Callback will create inside methods C<< ->query() >> C<< ->select...() >> and will returns ref on that callback. You need start Mojo::IOLoop:

  # async sth
  my $sth = $pg->prepare('select ...', {Async => 1,},);
  # Result non-blocking query for async sth
  my $res_cb = $pg->query($sth, {Async => 1,}, @bind,);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  # Mojo::Pg::Results style
  my res = $$res_cb->()->hash;

2. $attr->{Async} not set. $cb defined. Results pass to $cb. You need start Mojo::IOLoop:

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


3. $attr->{Async} set to 1. $cb defined. Results pass to $cb. You need start Mojo::IOLoop.


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

Copyright 2016 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use DBI;
use Carp qw(croak);
use Mojo::Pg::Che::Database;
use Mojo::URL;
use Scalar::Util 'blessed';

has database_class => 'Mojo::Pg::Che::Database';
has dsn             => 'dbi:Pg:';
has max_connections => 5;
has [qw(password username)] => '';
has [qw(parent)];
has pubsub => sub {
  require Mojo::Pg::PubSub;
  my $pubsub = Mojo::Pg::PubSub->new(pg => shift);
  #~ weaken $pubsub->{pg};#???
#Mojo::Reactor::EV: Timer failed: Can't call method "db" on an undefined value at t/06-pubsub.t line 21.
#EV: error in callback (ignoring): Can't call method "db" on an undefined value at Mojo/Pg/PubSub.pm line 44.
  return $pubsub;
};

has options => sub {
  {AutoCommit => 1, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1, ShowErrorStatement => 1, pg_enable_utf8 => 1,};
};

has debug => $ENV{DEBUG_Mojo_Pg_Che} || 0;
my $PKG = __PACKAGE__;

sub from_string {# copy/paste Mojo::Pg
  my ($self, $str) = @_;
  
  # Parent
  return $self unless $str;
  return $self->parent($str) if blessed $str && $str->isa('Mojo::Pg');

  # Protocol
  return $self unless $str;
  my $url = Mojo::URL->new($str);
  croak qq{Invalid PostgreSQL connection string "$str"}
    unless $url->protocol =~ /^(?:pg|postgres(?:ql)?)$/;

  # Connection information
  my $db = $url->path->parts->[0];
  my $dsn = defined $db ? "dbi:Pg:dbname=$db" : 'dbi:Pg:';
  if (my $host = $url->host) { $dsn .= ";host=$host" }
  if (my $port = $url->port) { $dsn .= ";port=$port" }
  if (defined(my $username = $url->username)) { $self->username($username) }
  if (defined(my $password = $url->password)) { $self->password($password) }

  # Service
  my $hash = $url->query->to_hash;
  if (my $service = delete $hash->{service}) { $dsn .= "service=$service" }

  # Options
  @{$self->options}{keys %$hash} = values %$hash;

  return $self->dsn($dsn);
}

sub new { @_ > 1 ? shift->SUPER::new->from_string(@_) : shift->SUPER::new }# copy/paste Mojo::Pg

sub connect {
  my $self = shift->SUPER::new;
  map $self->$_(shift), qw(dsn username password);
  if (my $attrs = shift) {
    my $options = $self->options;
    @$options{ keys %$attrs } = values %$attrs;
  }
  $self->dsn('DBI:Pg:'.$self->dsn)
    unless $self->dsn =~ /^DBI:Pg:/;
  say STDERR sprintf("[$PKG->connect] prepare connection data for [%s]", $self->dsn, )
    if $self->debug;
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

sub _db_sth {shift->db(ref $_[0] && $_[0]->{Database})}

sub query { shift->_db_sth(@_)->select(@_) }
sub select { shift->_db_sth(@_)->select(@_) }
sub selectrow_array { shift->_db_sth(@_)->selectrow_array(@_) }
sub selectrow_arrayref { shift->_db_sth(@_)->selectrow_arrayref(@_) }
sub selectrow_hashref { shift->_db_sth(@_)->selectrow_hashref(@_) }
sub selectall_arrayref { shift->_db_sth(@_)->selectall_arrayref(@_) }
sub selectall_hashref { shift->_db_sth(@_)->selectall_hashref(@_) }
sub selectcol_arrayref { shift->_db_sth(@_)->selectcol_arrayref(@_) }
sub do { shift->_db_sth(@_)->do(@_) }

#~ sub begin_work {croak 'Use $pg->db->tx | $pg->db->begin';}
sub tx {shift->begin}
sub begin_work {shift->begin}
sub begin {
  my $self = shift;
  my $db = $self->db;
  $db->begin;
  return $db;
}

sub commit {croak 'Use: $tx = $pg->begin; $tx->do(...); $tx->commit;';}
sub rollback {croak 'Use: $tx = $pg->begin; $tx->do(...); $tx->rollback;';}

# Patch parent Mojo::Pg::_dequeue
sub _dequeue {
  my $self = shift;

  #~ while (my $dbh = shift @{$self->{queue} || []}) { return $dbh if $dbh->ping }
  
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
  #~ say STDERR "НОвое [$dbh] соединение";
  

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



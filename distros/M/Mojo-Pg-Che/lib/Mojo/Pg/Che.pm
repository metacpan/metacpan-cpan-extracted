package Mojo::Pg::Che;

use Mojo::Base 'Mojo::EventEmitter';#'Mojo::Pg';
use Mojo::Pg;
use DBI;
use Carp qw(croak);
use Mojo::Pg::Che::Database;
#~ use Mojo::URL;
use Scalar::Util 'blessed';

our $VERSION = '0.8552';

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
  $self->pg($pg->parent || $pg)
    if $pg;
  
  #~ $pg ||= $self->pg->parent || $self->pg;

  map { $self->$_($self->pg->$_); }
    qw(dsn username password search_path)#options
    if $from_string;

  $self->dsn('dbi:Pg:'.$self->dsn)
    unless !$self->dsn || $self->dsn =~ /^dbi:Pg:/;
  
  #~ $self->pg->dsn('dbi:Pg:'.$self->pg->dsn)
    #~ unless !$self->pg->dsn || $self->pg->dsn =~ /^dbi:Pg:/;
  map { $self->pg->$_($self->$_); }
    qw(dsn username password options search_path max_connections);#database_class pubsub 
  
  $self->pg->attr(debug => $self->debug);
  
  return $self;
}

#DBI
sub connect {
  my $self = ref $_[0] ? shift : shift->SUPER::new;
  map { my $has = shift; $has && $self->$_($has)} qw(dsn username password);

  if (ref $_[0]) {
    my $arg =  shift;
    my $options = $self->options;
    @$options{ keys %$arg } = values %$arg;
  }
  if (@_) {
    my $attrs = {@_};
    map $self->$_($attrs->{$_}), keys %$attrs;
  }
  
  $self->dsn('dbi:Pg:'.$self->dsn)
    unless !$self->dsn || $self->dsn =~ /^dbi:Pg:/;
  
  my $pg = $self->pg->parent || $self->pg;
  
  map $pg->$_($self->$_),
    qw(dsn username password options search_path max_connections);#database_class  pubsub
  
  $self->debug
    && say STDERR sprintf("[$PKG->connect] prepare connection data for [%s]", $self->dsn, );
    
  $pg->attr(debug => $self->debug);
  return $self;
}

sub db {
  my ($self, $dbh) = (shift, shift);

  my $pg = $self->pg->parent || $self->pg;
  
  # Fork-safety if $dbh
  undef $dbh
    unless ($pg->{pid} //= $$) eq $$;

  $dbh ||= $pg->_dequeue;

  return $self->database_class->new(dbh => $dbh, pg => $pg, debug=>$self->debug);
}

sub prepare { shift->db->prepare(@_); }
sub prepare_cached { shift->db->prepare_cached(@_); }

# если уже sth и он не в асинхроне - взять его dbh
sub _db {
  my $self = shift;
  my $sth = ref $_[0] ? shift : return $self->db;
  return $self->db
    if !!$sth->{pg_async_status};

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

sub dequeue { my $pg = $_[0]->pg->parent || $_[0]->pg; $pg->_dequeue; }
sub enqueue { my $pg = $_[0]->pg->parent || $_[0]->pg; $pg->_enqueue; }

{ # Patches
  no warnings 'redefine';
# Patch Mojo::Pg::_dequeue
sub Mojo::Pg::_dequeue {
  my $self = shift;
  
  # Fork-safety
  delete @$self{qw(pid queue)} unless ($self->{pid} //= $$) eq $$;
  
  my $queue = $self->{queue} ||= [];
  for my $i (0..$#$queue) {
    
    my $dbh = $queue->[$i];

    next
      if $dbh->{pg_async_status} && $dbh->{pg_async_status} > 0;
    
    splice(@$queue, $i, 1);    #~ delete $queue->[$i]

    next
      unless blessed($dbh) && $dbh->ping; # не понятно почему может $dbh не blessed

    $self->debug
      && say STDERR sprintf("[$PKG->_dequeue] [$dbh][pg_pid %s] does dequeued, pool count:[%s]", $dbh->{pg_pid}, scalar @$queue);
    
    return $dbh;
  }
  
  my $dbh = DBI->connect(map { $self->$_ } qw(dsn username password options));
  $self->debug
    && say STDERR sprintf("[$PKG->_dequeue] new DBI connection [$dbh][pg_pid %s]", $dbh->{pg_pid});
  
  # Search path
  if (my $path = $self->search_path) {
    my $search_path = join ', ', map { $dbh->quote_identifier($_) } @$path;
    $dbh->do("set search_path to $search_path");
  }

  $self->emit(connection => $dbh);

  return $dbh;
}
# Patch Mojo::Pg::_enqueue
sub Mojo::Pg::_enqueue {
  my ($self, $dbh) = @_;
  # Fork-safety
  delete @$self{qw(pid queue)}
    and return
    unless ($self->{pid} //= $$) eq $$;
  
  my $queue = $self->{queue} ||= [];
  
  if ($dbh->{Active} && $dbh->ping && @$queue < $self->max_connections) {#($dbh->{pg_async_status} && $dbh->{pg_async_status} > 0) || 
    unshift @$queue, $dbh;
    # push @$queue, $dbh; # /home/guest/Mojo-Pg-Che/t/09-base-database.t line 108
    $self->debug
      && say STDERR sprintf("[$PKG->_enqueue] [$dbh][pg_pid %s] does enqueued, pool count:[%s], pg_async_status=[%s]", $dbh->{pg_pid}, scalar @$queue, $dbh->{pg_async_status});
    return;
  }
  
  $self->debug
    && say STDERR sprintf("[$PKG->_enqueue] [$dbh][pg_pid %s] does not enqueued, pool count:[%s]", $dbh->{pg_pid}, scalar @$queue);
}

}# end no warnings 'redefine';


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





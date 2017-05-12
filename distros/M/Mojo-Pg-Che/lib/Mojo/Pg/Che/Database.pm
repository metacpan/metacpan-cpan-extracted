package Mojo::Pg::Che::Database;

use Mojo::Base 'Mojo::EventEmitter'; #'Mojo::Pg::Database';
use Carp qw(croak shortmess);
use DBD::Pg ':async';
use Mojo::IOLoop;
use Mojo::Pg::Che::Results;
use Mojo::Pg::Transaction;
use Scalar::Util 'weaken';
#~ use Mojo::JSON 'to_json';

my $handler_err = sub {$_[0] = shortmess $_[0]; 0;};
has handler_err => sub {$handler_err};

has [qw(dbh pg)];

has results_class => 'Mojo::Pg::Che::Results';

my $PKG = __PACKAGE__;

sub disconnect {#  copy/paste Mojo::Pg::Database
  my $self = shift;
  $self->_unwatch;
  $self->dbh->disconnect;
}

sub is_listening { !!keys %{shift->{listen} || {}} }#  copy/paste Mojo::Pg::Database

sub listen {#  copy/paste Mojo::Pg::Database
  my ($self, $name) = @_;

  my $dbh = $self->dbh;
  $dbh->do('listen ' . $dbh->quote_identifier($name))
    unless $self->{listen}{$name}++;
  $self->_watch;

  return $self;
}

sub unlisten {#  copy/paste Mojo::Pg::Database
  my ($self, $name) = @_;

  my $dbh = $self->dbh;
  $dbh->do('unlisten ' . $dbh->quote_identifier($name));
  $name eq '*' ? delete $self->{listen} : delete $self->{listen}{$name};
  $self->_unwatch unless $self->{waiting} || $self->is_listening;

  return $self;
}

sub _notifications {#  copy/paste Mojo::Pg::Database
  my $self = shift;
  my $dbh  = $self->dbh;
  while (my $n = $dbh->pg_notifies) { $self->emit(notification => @$n) }
}

sub notify {#  copy/paste Mojo::Pg::Database
  my ($self, $name, $payload) = @_;

  my $dbh    = $self->dbh;
  my $notify = 'notify ' . $dbh->quote_identifier($name);
  $notify .= ', ' . $dbh->quote($payload) if defined $payload;
  $dbh->do($notify);
  $self->_notifications;

  return $self;
}

sub pid { shift->dbh->{pg_pid} } #  copy/paste Mojo::Pg::Database

sub ping { shift->dbh->ping } #  copy/paste Mojo::Pg::Database

sub query { shift->select(@_) }

sub execute_sth {
  my ($self, $sth,) = map shift, 1..2;
  
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  
  #~ croak 'Previous async query has not finished'
    #~ if $self->dbh->{pg_async_status} == 1;
  
  croak 'Non-blocking query already in progress'
    if $self->{waiting};
  
  local $sth->{HandleError} = $self->handler_err;
  $sth->{pg_async} = $cb ? PG_ASYNC : 0; # $self->dbh->{pg_async_status} == 1 ? PG_OLDQUERY_WAIT : PG_ASYNC # 
  
  #~ $sth->execute(map { _json($_) ? to_json $_->{json} : $_ } @_);
  eval {$sth->execute(@_)}#binds
    or die "Bad statement: ", $@, $sth->{Statement};
  
  # Blocking
  unless ($cb) {
    $self->_notifications;
    return $self->results_class->new(sth => $sth);
  }
  
  # Non-blocking
  $self->{waiting} = {cb => $cb, sth => $sth};
  $self->_watch;
}

sub execute_string {
  my ($self, $query, $attrs,) = map shift, 1..3;
  
  my $dbh = $self->dbh;
  
  my $sth = $self->prepare($query, $attrs, 3);
  
  return $self->execute_sth($sth, @_);
  
}

sub prepare {
  my ($self, $query, $attrs, $flag,)  = @_;
  
  my $dbh = $self->dbh;
  
  return $dbh->prepare_cached($query, $attrs, $flag)
    if delete $attrs->{Cached};
  
  return $dbh->prepare($query, $attrs,);
  
}

sub prepare_cached { shift->dbh->prepare_cached(@_); }

sub tx {shift->begin}
sub begin {
  my $self = shift;
  return $self->{tx}
    if $self->{tx};
  
  my $tx = $self->{tx} = Mojo::Pg::Transaction->new(db => $self);
  weaken $tx->{db};
  return $tx;

}

sub commit {
  my $self = shift;
  my $tx = delete $self->{tx}
    or return;
  $tx->commit;
}

sub rollback {
  my $self = shift;
  my $tx = delete $self->{tx}
    or return;
  #~ warn "TX destroy";
  $tx = undef;# DESTROY
  
}

my @DBH_METHODS = qw(
select
selectrow_array
selectrow_arrayref
selectrow_hashref
selectall_arrayref
selectall_array
selectall_hashref
selectcol_arrayref
do
);

for my $method (@DBH_METHODS) {
  no strict 'refs';
  no warnings 'redefine';
  *{"${PKG}::$method"} = sub { shift->_DBH_METHOD($method, @_) };
  
}

sub _DBH_METHOD {
  my ($self, $method) = (shift, shift);
  my ($sth, $query) = ref $_[0] ? (shift, undef) : (undef, shift);
  
  my @to_fetch = ();
  
  push @to_fetch, shift # $key_field 
    if $method eq 'selectall_hashref' && ! ref $_[0];
  
  my $attrs = shift;
  
  
  $to_fetch[0] = delete $attrs->{KeyField}
      if exists $attrs->{KeyField};
  
  #~ if ($method eq 'selectall_arrayref') {
  for (qw(Slice MaxRows)) {
    push @to_fetch, delete $attrs->{$_}
      if exists $attrs->{$_};
  }
  $to_fetch[0] = delete $attrs->{Columns}
    if exists $attrs->{Columns};
  #~ }
  
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  
  my $async = delete $attrs->{Async} || delete $attrs->{pg_async};

  $sth ||= $self->prepare($query, $attrs, 3,);
  my $result;
  $cb ||= sub {
    my ($db, $err) = map shift, 1..2;
    croak "Error on non-blocking $method: ",$err
      if $err;
    $result = shift;
    
  } if $async;
  
  my @bind = @_;
  
  $result = $self->execute_sth($sth, @bind, $cb ? ($cb) : ());
  
  Mojo::IOLoop->start
    if $async && ! Mojo::IOLoop->is_running;
  
  (my $fetch_method = $method) =~ s/select/fetch/;
  
  return $result->$fetch_method(@to_fetch)
    if ref $result eq $self->results_class && $result->can($fetch_method);
  
  return $result;
  
}

#Patch parent meth for $self->results_class
sub _watch {
  my $self = shift;

  return if $self->{watching} || $self->{watching}++;

  my $dbh = $self->dbh;
  unless ($self->{handle}) {
    open $self->{handle}, '<&', $dbh->{pg_socket} or die "Can't dup: $!";
  }
  Mojo::IOLoop->singleton->reactor->io(
    $self->{handle} => sub {
      #~ die 146;
      my $reactor = shift;

      $self->_unwatch if !eval { $self->_notifications; 1 };
      #~ warn '_Watch', $self->{waiting};
      return unless $self->{waiting} && $dbh->pg_ready;
      my ($sth, $cb) = @{delete $self->{waiting}}{qw(sth cb)};

      # Do not raise exceptions inside the event loop
      my $result = do { local $dbh->{RaiseError} = 0; $dbh->pg_result };
      my $err = defined $result ? undef : $dbh->errstr;

      eval { $self->$cb($err, $self->results_class->new(sth => $sth)); };
      warn "Non-blocking callback result error: ", $@
        and $reactor->{cb_error} = $@
        if $@;
      
      $self->_unwatch unless $self->{waiting} || $self->is_listening;
    }
  )->watch($self->{handle}, 1, 0);
}

sub _unwatch {#  copy/paste Mojo::Pg::Database
  my $self = shift;
  return unless delete $self->{watching};
  Mojo::IOLoop->singleton->reactor->remove($self->{handle});
  $self->emit('close') if $self->is_listening;
}

sub DESTROY {#  copy/paste Mojo::Pg::Database + rollback
  my $self = shift;
  
  $self->rollback;
  
  my $waiting = $self->{waiting};
  $waiting->{cb}($self, 'Premature connection close', undef) if $waiting->{cb};

  return unless (my $pg = $self->pg) && (my $dbh = $self->dbh);
  $pg->_enqueue($dbh);
  
  #~ $self->SUPER::DESTROY;
}

1;
package Mojo::Pg::Che::Database;

#~ use Mojo::Base 'Mojo::EventEmitter';
use Mojo::Base 'Mojo::Pg::Database';
use Carp qw(croak shortmess);
use DBD::Pg ':async';
#~ use Mojo::IOLoop;

use Mojo::Pg::Che::Results;
use Mojo::Pg::Transaction;


my $handler_err = sub {$_[0] = shortmess $_[0]; 0;};
has handler_err => sub {$handler_err};
has results_class => 'Mojo::Pg::Che::Results';
has debug => sub { shift->pg->debug };

my $PKG = __PACKAGE__;

sub query { shift->select(@_) }

sub execute_sth {
  my ($self, $sth,) = map shift, 1..2;
  #~ warn "execute_sth: ", $self->dbh;
  
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  
  #~ croak 'Previous async query has not finished'
    #~ if $self->dbh->{pg_async_status} == 1;
  
  croak 'Non-blocking query already in progress'
    if $self->{waiting};
  
  local $sth->{HandleError} = $self->handler_err;
  
  eval {$sth->execute(@_)}#binds
    or die "Bad statement: ", $@;#, $sth->{Statement};
  
  # Blocking
  unless ($cb) {#
    $self->_notifications;
    return $self->results_class->new(db => $self, sth => $sth);
  }
  
  # Non-blocking
  $self->{waiting} = {cb => $cb, sth => $sth};
  $self->_watch;
}

sub execute_string {
  my ($self, $query, $attrs,) = map shift, 1..3;
  
  my $dbh = $self->dbh;
  
  my $sth = $self->prepare($query, $attrs,);
  
  return $self->execute_sth($sth, @_);
  
}

sub prepare {
  my ($self, $query, $attrs,)  = @_;
  
  my $dbh = $self->dbh;
  
  #~ $attrs->{pg_async} = PG_ASYNC
    #~ if delete $attrs->{Async};

  my $sth = delete $attrs->{Cached}
    ? $dbh->prepare_cached($query, $attrs, 3)
    : $dbh->prepare($query, $attrs);
  
  #~ $sth->{private_mojo_db} = $self;
  return $sth;
}

sub prepare_cached { 
  my $self = shift;
  
  my $sth = $self->dbh->prepare_cached(@_);
  #~ $sth->{private_mojo_db} = $self;
  return $sth;
}

sub tx { shift->begin }
sub begin {
  my $self = shift;
  return $self->{tx}
    if $self->{tx};
  
  my $tx = $self->{tx} = Mojo::Pg::Transaction->new(db => $self);
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
  delete $self->{tx};# DESTROY
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
  
  my $attrs = shift || {};
  
  $to_fetch[0] = delete $attrs->{KeyField}
      if exists $attrs->{KeyField};
  
  for (qw(Slice MaxRows)) {
    push @to_fetch, delete $attrs->{$_}
      if exists $attrs->{$_};
  }
  $to_fetch[0] = delete $attrs->{Columns}
    if exists $attrs->{Columns};
  
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  
  $attrs->{pg_async} = PG_ASYNC
    if $cb;## || delete $attrs->{Async};
  
  $sth->{pg_async} = PG_ASYNC
    if $sth && $attrs->{pg_async};

  $sth ||= $self->prepare($query, $attrs);
  
  #~ $cb ||= $self->_async_cb()
    #~ if $attrs->{pg_async};
  
  my @bind = @_;
  
  my @result = $self->execute_sth($sth, @bind, $cb ? ($cb) : ());# 
  
  (my $fetch_method = $method) =~ s/select/fetch/;
  
  return $result[0]->$fetch_method(@to_fetch)
    if ref $result[0] eq $self->results_class && $result[0]->can($fetch_method);
  
  return wantarray ? @result : shift @result;
  
}


sub DESTROY {#  copy/paste Mojo::Pg::Database + rollback
  my $self = shift;
  
  $self->rollback;
  
  my $waiting = $self->{waiting};
  $waiting->{cb}($self, 'Premature connection close', undef) if $waiting->{cb};
 
  return unless (my $pg = $self->pg) && (my $dbh = $self->dbh);
  $pg->_enqueue($dbh)
    #~ and ($self->debug && say STDERR "DESTROY $dbh")
    unless $dbh->{private_mojo_no_reuse};

}


1;

__END__

sub _async_cb {
  my $self = shift;
  my ($result, $err);
  return sub {
    return wantarray ? ($result, $err) : $result
      unless @_;
    my $db = shift;
    ($err, $result) = @_;
  };
}

sub _watch {
  my $self = shift;

  return if $self->{watching} || $self->{watching}++;

  my $dbh = $self->dbh;
  unless ($self->{handle}) {
    open $self->{handle}, '<&', $dbh->{pg_socket} or die "Can't dup: $!";
  }
  
  my ($sth, $cb);
  
  Mojo::IOLoop->singleton->reactor->io(
    $self->{handle} => sub {
      my $reactor = shift;

      $self->_unwatch if !eval { $self->_notifications; 1 };
      return unless $self->{waiting} && $dbh->pg_ready;
      ($sth, $cb) = @{delete $self->{waiting}}{qw(sth cb)};
      
      # Do not raise exceptions inside the event loop
      my $result = do { local $dbh->{RaiseError} = 0; $dbh->pg_result };
      my $err = defined $result ? undef : $dbh->errstr;

      eval { $self->$cb($err, $self->results_class->new(db => $self, sth => $sth)); };
      $self->_unwatch unless $self->{waiting} || $self->is_listening;
    }
  )->watch($self->{handle}, 1, 0);
  
  return \$cb, \$sth;
}

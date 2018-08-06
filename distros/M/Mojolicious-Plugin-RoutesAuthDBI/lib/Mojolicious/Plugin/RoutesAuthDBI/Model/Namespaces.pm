package Mojolicious::Plugin::RoutesAuthDBI::Model::Namespaces;
#~ use Mojo::Base 'DBIx::Mojo::Model';
use Mojo::Base 'Mojolicious::Plugin::RoutesAuthDBI::Model::Base';

#~ sub new {
  #~ state $self = shift->SUPER::new(@_);
#~ }

sub app_ns {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectall_arrayref($self->sth('namespaces', where=>"where app_ns=1::bit(1)", order=>"order by ts - (coalesce(interval_ts, 0::int)::varchar || ' second')::interval"), { Slice => {namespace=>1} },);
}

sub access {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_array($self->sth('access namespace'), undef, (shift, shift));
}

sub namespace {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('namespace'), undef, (@_));
}

sub new_namespace {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('new namespace'), undef, (@_));
}

sub namespaces {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectall_arrayref($self->sth('namespaces'), { Slice => {} }, );
}


1;

__DATA__
@@ namespaces
select *
from "{%= $schema %}"."{%= $tables->{namespaces} %}"
{%= $where %}
{%= $order %}

@@ access namespace?cached=1
-- доступ ко всем действиям по имени спейса
select count(n.*)
from 
  "{%= $schema %}"."{%= $tables->{namespaces} %}" n
  join "{%= $schema %}"."{%= $tables->{refs} %}" r on n.id=r.id1
  ---join "{%= $schema %}"."{%= $tables->{roles} %}" o on r.id2=o.id
where
  n.namespace=?
  and r.id2=any(?) --- roles ids
  ---and coalesce(o.disable, 0::bit) <> 1::bit
;

@@ namespace
select *
from "{%= $schema %}"."{%= $tables->{namespaces} %}"
where id=? or namespace = ?
;

@@ new namespace
insert into "{%= $schema %}"."{%= $tables->{namespaces} %}" (namespace, descr, app_ns, interval_ts) values (?,?,?,?)
returning *;


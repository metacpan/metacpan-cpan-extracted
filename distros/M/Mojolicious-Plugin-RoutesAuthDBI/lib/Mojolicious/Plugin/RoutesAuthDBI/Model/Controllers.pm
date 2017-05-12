package Mojolicious::Plugin::RoutesAuthDBI::Model::Controllers;
use Mojo::Base 'DBIx::Mojo::Model';

sub new {
  state $self = shift->SUPER::new(@_);
}

sub controller_ns {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('controller', where => "where controller=? and (namespace=? or (?::varchar is null and namespace is null))"), undef, @_);
}

sub controller_id_ns {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('controller', where=>"where (id=? or controller=?) and (namespace_id = ? or namespace = ? or (?::varchar is null and namespace is null))"), undef, (@_));
}

sub new_controller {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('new controller'), undef, (@_));
}

sub controllers {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectall_arrayref($self->sth('controllers'), { Slice => {} }, );
}

sub controllers_ns_id {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectall_arrayref($self->sth('controllers', where=>"where n.id=? or (?::int is null and n.id is null)"), { Slice => {} }, (@_));
}


1;

__DATA__
@@ controller?cached=1
%# Не пустой namespace - четко привязанный контроллер, пустой - обязательно не привязанный контроллер

select * from (
  select c.*, n.namespace, n.id as namespace_id, n.descr as namespace_descr
  from
    "{%= $schema %}"."{%= $tables->{controllers} %}" c
    left join "{%= $schema %}"."{%= $tables->{refs} %}" r on c.id=r.id2
    left join "{%= $schema %}"."{%= $tables->{namespaces} %}" n on n.id=r.id1
  ) s
{%= $where %}

@@ new controller

insert into "{%= $schema %}"."{%= $tables->{controllers} %}" (controller, descr)
values (?,?)
returning *;

@@ controllers
%# Контроллер либо привязан к спейсу или нет

select c.*, n.namespace, n.id as namespace_id, n.descr as namespace_descr
from "{%= $schema %}"."{%= $tables->{controllers} %}" c
left join "{%= $schema %}"."{%= $tables->{refs} %}" r on c.id=r.id2
left join "{%= $schema %}"."{%= $tables->{namespaces} %}" n on n.id=r.id1
{%= $where %};


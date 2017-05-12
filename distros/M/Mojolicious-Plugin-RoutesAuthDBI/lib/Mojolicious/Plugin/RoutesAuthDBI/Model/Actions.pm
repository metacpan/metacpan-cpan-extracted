package Mojolicious::Plugin::RoutesAuthDBI::Model::Actions;
use Mojo::Base 'DBIx::Mojo::Model';

sub new {
  state $self = shift->SUPER::new(@_);
}

sub access {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectrow_array($self->sth('access action'), undef, ( @_ ));
}

sub actions {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectall_arrayref($self->sth('actions'), { Slice => {} }, );
}

sub actions_controller {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectall_arrayref($self->sth('actions', where=>"where controller_id=?"), { Slice => {} }, (shift));
}

sub action_controller {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('actions', where=>"where controller_id=? and (a.id = ? or a.action = ? )"), undef, (@_));
}

sub action_controller_null {# дествие с пустым контроллером
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('actions', where=>"where controller_id is null and (a.id = ? or a.action = ? )"), undef, (@_));
}

sub actions_controller_null {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectall_arrayref($self->sth('actions', where=>"where controller_id is null"), { Slice => {} },);
}

sub new_action {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectrow_hashref($self->sth('new action'), undef, (@_))
}

1;

__DATA__
@@ access action?cached=1
%# доступ к действию в контроллере (действие-каллбак - доступ проверяется по его ID)

select count(r.*)
from
  "{%= $schema %}"."{%= $tables->{refs} %}" rc 
  join "{%= $schema %}"."{%= $tables->{actions} %}" a on a.id=rc.id2
  join "{%= $schema %}"."{%= $tables->{refs} %}" r on a.id=r.id1
  ---join "{%= $schema %}"."{%= $tables->{roles} %}" o on o.id=r.id2
where
  rc.id1=? ---controller id
  and a.action=?
  and r.id2=any(?) --- roles ids
  ---and coalesce(o.disable, 0::bit) <> 1::bit
;

@@ actions
%# Список действий

select * from (
  select a.*, ac.controller_id, ac.controller
  from "{%= $schema %}"."{%= $tables->{actions} %}" a
    left join (
      select a.id, c.id as controller_id, c.controller
      from "{%= $schema %}"."{%= $tables->{actions} %}" a
        join "{%= $schema %}"."{%= $tables->{refs} %}" r on a.id=r.id2
        join "{%= $schema %}"."{%= $tables->{controllers} %}" c on c.id=r.id1
      ) ac on a.id=ac.id-- действия с контроллером
  ) as a
{%= $where %}

@@ new action

insert into "{%= $schema %}"."{%= $tables->{actions} %}" (action, callback, descr)
values (?,?,?)
returning *;


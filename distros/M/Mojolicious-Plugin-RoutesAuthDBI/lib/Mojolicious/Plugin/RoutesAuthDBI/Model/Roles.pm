package Mojolicious::Plugin::RoutesAuthDBI::Model::Roles;
use Mojo::Base 'DBIx::Mojo::Model';

sub new {
  state $self = shift->SUPER::new(@_);
}

sub access {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectrow_array($self->sth('access role'), undef, @_);
}

sub get_role {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('role'), undef, (@_));

}

sub new_role {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('new role'), undef, (@_));

}

sub dsbl_enbl {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('dsbl/enbl role'), undef, (@_));

}

sub profiles {# профили роли
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectall_arrayref($self->sth('role profiles'), { Slice => {} }, (shift));
}

sub roles {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectall_arrayref($self->sth('roles'), { Slice => {} },);
}

1;

__DATA__
@@ role
select *
from "{%= $schema %}"."{%= $tables->{roles} %}"
where id=? or name=?

@@ new role
insert into "{%= $schema %}"."{%= $tables->{roles} %}" (name) values (?)
returning *;

@@ dsbl/enbl role
update "{%= $schema %}"."{%= $tables->{roles} %}"
set disable=?::boolean
where id=? or name=?
returning *;

@@ access role?cached=1
-- Доступ по роли
select count(*)
from "{%= $schema %}"."{%= $tables->{roles} %}"
where (id = ? or name = ?)
  and id = any(?)
  and not coalesce(disable, false)
;

@@ role profiles
-- Пользователи роли
select p.*
from
  "{%= $schema %}"."{%= $tables->{profiles} %}" p
  join "{%= $schema %}"."{%= $tables->{refs} %}" r on p.id=r.id2
where r.id1=?;

@@ roles
select *
from "{%= $schema %}"."{%= $tables->{roles} %}"
{%= $where %}


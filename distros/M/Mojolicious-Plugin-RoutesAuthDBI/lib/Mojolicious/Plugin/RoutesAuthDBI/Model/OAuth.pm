package Mojolicious::Plugin::RoutesAuthDBI::Model::OAuth;
use Mojo::Base 'DBIx::Mojo::Model';

sub new {
  state $self = shift->SUPER::new(@_);
}

sub site {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('update oauth site'), undef, ( @_, ))
      || $self->dbh->selectrow_hashref($self->sth('new oauth site'), undef, (@_,));
}

sub check_profile {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('check profile oauth'), undef, (@_,));
}

sub user {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('update oauth user'), undef, @_)
      || $self->dbh->selectrow_hashref($self->sth('new oauth user'), undef, @_);
}

sub profile {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('profile by oauth user'), undef, (shift))
}

sub detach {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectrow_hashref($self->sth('отсоединить oauth'), undef, (@_));
}

sub oauth_users_by_profile {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectall_hashref($self->sth('profile oauth.users'), 'site_name', undef, (@_));
  
}

1;

__DATA__
@@ update oauth site
update "{%= $schema %}"."{%= $tables->{oauth_sites} %}"
set conf = ?
where name =?
returning *;

@@ new oauth site
insert into "{%= $schema %}"."{%= $tables->{oauth_sites} %}" (conf,name) values (?,?)
returning *;

@@ update oauth user?cached=1
update "{%= $schema %}"."{%= $tables->{oauth_users} %}"
set profile = ?, profile_ts=now()
where site_id =? and user_id=?
returning 1::int as "old", *;

@@ new oauth user
insert into "{%= $schema %}"."{%= $tables->{oauth_users} %}" (profile, site_id, user_id) values (?,?,?)
returning 1::int as "new", *;

@@ profile by oauth user?cached=1
select p.*
from "{%= $schema %}"."{%= $tables->{profiles} %}" p
  join "{%= $schema %}"."{%= $tables->{refs} %}" r on p.id=r.id1

where r.id2=?;


@@ check profile oauth
%# Только один сайт на профиль

select o.*
from "{%= $schema %}"."{%= $tables->{profiles} %}" p
  join "{%= $schema %}"."{%= $tables->{refs} %}" r on p.id=r.id1
  join "{%= $schema %}"."{%= $tables->{oauth_users} %}" o on o.id=r.id2

where p.id=? and o.site_id=?

@@ отсоединить oauth
delete from "{%= $schema %}"."{%= $tables->{oauth_users} %}" d
using "{%= $schema %}"."{%= $tables->{refs} %}" r
where d.site_id = ?
  and r.id1=? -- ид профиля
  and d.id=r.id2

RETURNING d.*, r.id as ref_id;

@@ profile oauth.users
-- список внешних профилей по внутреннему профилю

select u.*, s.name as site_name, s.id as site_id
from "{%= $schema %}"."{%= $tables->{oauth_sites} %}" s
  join "{%= $schema %}"."{%= $tables->{oauth_users} %}" u on s.id = u.site_id
  join "{%= $schema %}"."{%= $tables->{refs} %}" r on u.id=r.id2

where -- s.id=* and 
  r.id1=? -- профиль ид


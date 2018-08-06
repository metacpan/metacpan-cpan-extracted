package Profile;
use Mojo::Base -base;

has [qw(roles auth_cookie)];

#==========
# END Profie pkg
#==========

package Mojolicious::Plugin::RoutesAuthDBI::Model::Profiles;
#~ use Mojo::Base 'DBIx::Mojo::Model';
use Mojo::Base 'Mojolicious::Plugin::RoutesAuthDBI::Model::Base';


#~ has roles => sub {
  #~ my $self=shift;
  #~ $self->dbh->selectall_arrayref($self->sth('profile roles'), { Slice => {} }, ($self->{id}));
  
#~ };

#~ sub new {
  #~ state $self = shift->SUPER::new(@_);
#~ }

sub get_profile {
  my $self = ref($_[0]) ? shift : shift->new;
  my $p = $self->dbh->selectrow_hashref($self->sth('profile'), undef, (shift, shift,));
  #~ bless($p)->SUPER::new# reinit from singleton dict Это работало, но большая портянка объекта модели
  return bless($p, "Profile")->roles($self->roles($p->{id}))#->model($self)
    if $p && $p->{id};
  return undef;
}

sub roles {
  my ($self, $profile_id) = @_;
  $self->dbh->selectall_arrayref($self->sth('profile roles'), { Slice => {} }, ($profile_id));
  
};

sub profiles {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectall_arrayref($self->sth('profiles'), {Slice=>{}},);
}

sub new_profile {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('new profile'), undef, (shift,));
}

1;

__DATA__
@@ profiles
select p.*, l.login, l.pass
from "{%= $schema %}"."{%= $tables->{profiles} %}" p
left join (
  select l.*, r.id1
  from "{%= $schema %}"."{%= $tables->{refs} %}" r 
    join "{%= $schema %}"."{%= $tables->{logins} %}" l on l.id=r.id2
) l on p.id=l.id1

@@ new profile
insert into "{%= $schema %}"."{%= $tables->{profiles} %}" (names) values (?)
returning *;

@@ profile?cached=1
--  Load auth profile
select p.*, l.login, l.pass ---, md5(l.pass) as pass_md5
from "{%= $schema %}"."{%= $tables->{profiles} %}" p
left join (
  select l.*, r.id1
  from "{%= $schema %}"."{%= $tables->{refs} %}" r 
    join "{%= $schema %}"."{%= $tables->{logins} %}" l on l.id=r.id2
) l on p.id=l.id1
where p.id=? or l.login=?

@@ profile roles0000?cached=1
---Роли пользователя(профиля)
select unnest(array_append(("роль/родители"(g.id)).parents_id, g.id))
from
  "{%= $schema %}"."{%= $tables->{roles} %}" g
  join "{%= $schema %}"."{%= $tables->{refs} %}" r on g.id=r.id1
where r.id2=?;

@@ profile roles?cached=1
--- Роли пользователя(профиля)
WITH RECURSIVE rc AS (
   SELECT g.id, p.id as "parent"
   FROM 
    "{%= $schema %}"."{%= $tables->{roles} %}" g
    left join ( --- parent roles
      select p.*, r.id2 as child
      from "{%= $schema %}"."{%= $tables->{roles} %}" p
        join "{%= $schema %}"."{%= $tables->{refs} %}" r on p.id=r.id1
    ) p on g.id= p.child
    
   UNION
   
   SELECT rc.id, p.id as "parent"
   FROM rc
      join "{%= $schema %}"."{%= $tables->{refs} %}" r on r.id2=rc."parent"
      join "{%= $schema %}"."{%= $tables->{roles} %}" p on r.id1= p.id
)
, "pr" as (-- direct profile roles
  select g.*
  from "{%= $schema %}"."{%= $tables->{refs} %}" r
    join "{%= $schema %}"."{%= $tables->{roles} %}" g on r.id1=g.id
  where r.id2=? --- profile id
)

select distinct g.id, g.name
from 
  pr
  join rc on pr.id=rc.id
  join "{%= $schema %}"."{%= $tables->{roles} %}" g on g.id = rc.id or g.id = rc."parent"
;
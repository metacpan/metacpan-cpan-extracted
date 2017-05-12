package Profile;
use Mojo::Base -base;

has [qw(roles auth_cookie)];

#==========
# END Profie pkg
#==========

package Mojolicious::Plugin::RoutesAuthDBI::Model::Profiles;
use Mojo::Base 'DBIx::Mojo::Model';


#~ has roles => sub {
  #~ my $self=shift;
  #~ $self->dbh->selectall_arrayref($self->sth('profile roles'), { Slice => {} }, ($self->{id}));
  
#~ };

sub new {
  state $self = shift->SUPER::new(@_);
}

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

@@ profile roles?cached=1
%# Роли пользователя(профиля)
select g.*
from
  "{%= $schema %}"."{%= $tables->{roles} %}" g
  join "{%= $schema %}"."{%= $tables->{refs} %}" r on g.id=r.id1
where r.id2=?;
--and coalesce(g.disable, 0::bit) <> 1::bit


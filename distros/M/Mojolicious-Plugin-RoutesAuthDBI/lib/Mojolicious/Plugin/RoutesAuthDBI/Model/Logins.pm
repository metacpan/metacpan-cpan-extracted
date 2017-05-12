package Mojolicious::Plugin::RoutesAuthDBI::Model::Logins;
use Mojo::Base 'DBIx::Mojo::Model';

sub new {
  state $self = shift->SUPER::new(@_);
}

sub new_login {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('new login'), undef, (shift, shift));

}

sub login {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('login'), undef, (shift, shift));

}

sub upd_pass {
  my $self = ref($_[0]) ? shift : shift->new;
  my $args = ref($_[0]) ? shift : {@_};
  $self->dbh->selectrow_hashref($self->sth('update pass'), undef, (@$args{qw(new_pass id login old_pass old_pass)}));
}

sub upd_login {
  my $self = ref($_[0]) ? shift : shift->new;
  my $args = ref($_[0]) ? shift : {@_};
  $self->dbh->selectrow_hashref($self->sth('update login'), undef, (@$args{qw(new_login id old_login old_pass old_pass)}));
}

1;

__DATA__
@@ new login
insert into "{%= $schema %}"."{%= $tables->{logins} %}" (login, pass) values (?,?)
returning *;

@@ login
select *
from "{%= $schema %}"."{%= $tables->{logins} %}"
where id=? or login=?;


@@ update pass
update "{%= $schema %}"."{%= $tables->{logins} %}"
set pass = ?
where (id=? or login=?)
  and (?::text is null or pass=?)
returning *;

@@ update login
update "{%= $schema %}"."{%= $tables->{logins} %}"
set login = ?
where (id=? or login=?)
  and (?::text is null or pass=?)
returning *;


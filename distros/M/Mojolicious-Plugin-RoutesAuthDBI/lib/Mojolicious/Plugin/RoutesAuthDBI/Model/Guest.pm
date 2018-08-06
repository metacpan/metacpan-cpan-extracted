package Mojolicious::Plugin::RoutesAuthDBI::Model::Guest;
#~ use Mojo::Base 'DBIx::Mojo::Model';
use Mojo::Base 'Mojolicious::Plugin::RoutesAuthDBI::Model::Base';

#~ sub new {
  #~ state $self = shift->SUPER::new(@_);
#~ }

sub get_guest {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('guest'), undef, (shift));
}

sub store {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('store'), undef, (shift));
}


1;

__DATA__
@@ guest?cached=1
select *
from "{%= $schema %}"."{%= $tables->{guests} %}"
where id=?;

@@ store
insert into "{%= $schema %}"."{%= $tables->{guests} %}" (data) values(?)
returning *;


package Mojolicious::Plugin::RoutesAuthDBI::Model::Refs;
use Mojo::Base 'DBIx::Mojo::Model';

sub new {
  state $self = shift->SUPER::new(@_);
}

sub cnt {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_array($self->sth('cnt refs'), undef, (shift, shift));
}

sub refer {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('ref'), undef, (@_))
    || $self->dbh->selectrow_hashref($self->sth('new ref'), undef, (@_));
  
}

sub del {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectrow_hashref($self->sth('del ref'), undef, (@_));
}

1;

__DATA__
@@ cnt refs?cached=1
%# check if ref between [IDs1] and [IDs2] exists
select count(*)
from "{%= $schema %}"."{%= $tables->{refs} %}"
where id1 = any(?) and id2 = ANY(?);

@@ ref
select *
from "{%= $schema %}"."{%= $tables->{refs} %}"
where id1=? and id2=?;

@@ new ref
insert into "{%= $schema %}"."{%= $tables->{refs} %}" (id1,id2) values (?,?)
returning *;

@@ del ref
%# Delete ref
delete from "{%= $schema %}"."{%= $tables->{refs} %}"
where id=? or (id1=? and id2=?)
returning *;



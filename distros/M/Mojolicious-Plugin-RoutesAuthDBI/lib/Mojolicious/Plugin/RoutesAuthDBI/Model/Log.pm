package Mojolicious::Plugin::RoutesAuthDBI::Model::Log;
#~ use Mojo::Base 'DBIx::Mojo::Model';
use Mojo::Base 'Mojolicious::Plugin::RoutesAuthDBI::Model::Base';


sub log {
  my $self = shift;
  my $data = ref $_[0] ? shift : {@_};
  
  $self->dbh->selectrow_hashref($self->sth('log'), undef, @$data{qw(user_id route_id url status elapsed)});
}

1;

__DATA__
@@ log?cached=1
insert into "{%= $schema %}"."{%= $tables->{logs} %}" (user_id, route_id, url, status, elapsed) values(?,?,?,?,?)
returning *;


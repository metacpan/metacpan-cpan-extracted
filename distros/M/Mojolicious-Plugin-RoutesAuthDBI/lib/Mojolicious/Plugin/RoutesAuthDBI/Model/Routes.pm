package Mojolicious::Plugin::RoutesAuthDBI::Model::Routes;
use Mojo::Base 'DBIx::Mojo::Model';

sub new {
  state $self = shift->SUPER::new(@_);
}

sub routes {
  my $self = ref($_[0]) ? shift : shift->new;
  
  $self->dbh->selectall_arrayref($self->sth('apply routes'), { Slice => {} },);
}

sub routes_ref {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectall_arrayref($self->sth('role routes'), { Slice => {} }, (shift));
}

sub routes_action {# маршруты действия
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectall_arrayref($self->sth('action routes', where=>"where action_id=?"), { Slice => {} }, (shift));
}

sub routes_action_null {# маршруты без действия
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectall_arrayref($self->sth('action routes', where=>"where action_id is null"), { Slice => {} });
}

sub new_route {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->dbh->selectrow_hashref($self->sth('new route'), undef, (@_));
}

1;

__DATA__
@@ role routes
-- Маршруты роли/действия
select t.*
from
  "{%= $schema %}"."{%= $tables->{routes} %}" t
  join "{%= $schema %}"."{%= $tables->{refs} %}" r on t.id=r.id1
where r.id2=?;

@@ apply routes
--- Генерация маршрутов приложения
select r.*, coalesce(ac.controller, c.controller) as controller, coalesce(r.namespace, coalesce(ac.namespace, c.namespace)) as namespace, ac.action, ac.callback, ac.id as action_id, coalesce(ac.controller_id, c.id) as controller_id, case when r.namespace is not null then null else coalesce(ac.namespace_id, c.namespace_id) end as namespace_id
from "{%= $schema %}"."{%= $tables->{routes} %}" r
---  join "{%= $schema %}"."{%= $tables->{refs} %}" rf on r.id=rf.id2
  left join ( -- связь действие-маршрут
    select a.*, c.*, r.id2 as "ref_route_action"
    from 
      "{%= $schema %}"."{%= $tables->{refs} %}" r
      join  "{%= $schema %}"."{%= $tables->{actions} %}" a on r.id1=a.id
      left join (
        select r.id2 as _id, c.controller, c.id as controller_id, n.namespace, n.id as namespace_id
        from 
          "{%= $schema %}"."{%= $tables->{refs} %}" r
          join "{%= $schema %}"."{%= $tables->{controllers} %}" c on r.id1=c.id
          left join "{%= $schema %}"."{%= $tables->{refs} %}" r2 on c.id=r2.id2
          left join "{%= $schema %}"."{%= $tables->{namespaces} %}" n on n.id=r2.id1
      ) c on a.id=c._id
  ) ac on r.id=ac."ref_route_action"
  left join ( -- связь контроллер-маршрут
    select c.*, n.namespace, n.id as namespace_id, r.id2 as "ref_route_controller"
    from
      "{%= $schema %}"."{%= $tables->{refs} %}" r
      join "{%= $schema %}"."{%= $tables->{controllers} %}" c on r.id1=c.id
      left join "{%= $schema %}"."{%= $tables->{refs} %}" r2 on c.id=r2.id2
      left join "{%= $schema %}"."{%= $tables->{namespaces} %}" n on n.id=r2.id1
    
  ) c on r.id=c."ref_route_controller"
--- where not coalesce(r.disable, false)
order by regexp_replace(r.request, '^.* ', '') ---r.ts - (coalesce(r.interval_ts, 0::int)::varchar || ' second')::interval

;

@@ action routes
-- маршрут может быть не привязан к действию
select * from (
select r.*, s.action_id
from "{%= $schema %}"."{%= $tables->{routes} %}" r
  left join (
   select s.id1, a.id as action_id
   from "{%= $schema %}"."{%= $tables->{refs} %}" s
    join "{%= $schema %}"."{%= $tables->{actions} %}" a on a.id=s.id2
  ) s on r.id=s.id1
) s
{%= $where %}; -- action_id is null - free routes; or action(id) routes
;

@@ new route
insert into "{%= $schema %}"."{%= $tables->{routes} %}" (request, host_re, "to", name, descr, auth, disable, interval_ts)
values (?,?,?,?,?,?,?,?)
returning *;


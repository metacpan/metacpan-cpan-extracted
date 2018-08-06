package Mojolicious::Plugin::RoutesAuthDBI::Log;
use Mojo::Base -base;#'Mojolicious::Plugin::Authentication'
use Mojolicious::Plugin::RoutesAuthDBI::Util qw(json_enc json_dec);
use Mojo::Util qw(decode url_unescape);

#~ use constant  PKG => __PACKAGE__;

has [qw(app plugin model)];

has hook => sub {
  my $self = shift;
  $self->app->hook("after_dispatch" => sub {
    $self->log(shift);
  });
  
};

sub new {
  state $self = shift->SUPER::new(@_);
  #~ $self->app->hook("before_dispatch" => sub {
    #~ my $c = shift;
    #~ $c->timing->begin(PKG);
  #~ });
  $self->hook();
}

sub log {
  my ($self, $c) = @_;
  my $conf = $self->plugin->merge_conf;
  my $auth_helper = $conf->{auth}{current_user_fn};
  my $u = $c->$auth_helper || ($self->plugin->guest && $self->plugin->guest->current($c))
    or return;
  my $route = $c->match->endpoint ||  {'non_static_url'=>$c->req->url->to_string};#$c->req->url->path->to_route or return;
  my $route_id = $route->{'Mojolicious::Plugin::RoutesAuthDBI'} && $route->{'Mojolicious::Plugin::RoutesAuthDBI'}{route} && $route->{'Mojolicious::Plugin::RoutesAuthDBI'}{route}{id};
  #~ my $elapsed = $c->timing->elapsed(PKG);
  my $elapsed = $c->timing->elapsed('mojo.timer')
    or return;# не будет для статики
  #~ $c->app->log->debug(sprintf "%s elapsed:%s`s", ($route_id || decode('UTF-8', url_unescape($route->{non_static_url} || '/')), $elapsed)#join(', ', sort keys %$route_db)
  $self->model->log(user_id=>$u->{id}, route_id=>$route_id, url=>$route_id ? undef : decode('UTF-8', url_unescape($route->{non_static_url} || '/')), status=>$c->res->code, elapsed=>$elapsed)
    if $route_id || $route->{non_static_url};# без статики
  
}



1;

=pod

=encoding utf8

Доброго всем


=head1 Mojolicious::Plugin::RoutesAuthDBI::Log

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::RoutesAuthDBI::Log - store log in DBI table.

=head1 SYNOPSIS

    $app->plugin('RoutesAuthDBI', 
        ...
        log => {< hashref options list below >},
        ...
    );

=head1 OPTIONS

=head2 namespace

String, default to 'Mojolicious::Plugin::RoutesAuthDBI'.

=head2 module

String, default to 'Guest' (this module).

=head2 disabled

Boolean, disable logging.

=head2 tables

Hashref, any DB tables names. See L<Mojolicious::Plugin::RoutesAuthDBI::Schema#Default-variables-for-SQL-templates>.

=head2 table

String, DB table B<logs> name. See L<Mojolicious::Plugin::RoutesAuthDBI::Schema#Default-variables-for-SQL-templates>.


=head1 METHODS

=head2 new

Apply logging into DBI table by "after_dispatch" hook


=head1 SEE ALSO

L<Mojolicious::Plugin::RoutesAuthDBI>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche [on] cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/issues>. Pull requests welcome also.

=head1 COPYRIGHT

Copyright 2018+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

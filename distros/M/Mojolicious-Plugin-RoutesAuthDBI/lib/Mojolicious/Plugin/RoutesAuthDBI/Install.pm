package Mojolicious::Plugin::RoutesAuthDBI::Install;
use Mojo::Base 'Mojolicious::Controller';
use DBIx::Mojo::Template;

my $sql = DBIx::Mojo::Template->new(__PACKAGE__);

=pod

=encoding utf8

=head1 Mojolicious::Plugin::RoutesAuthDBI::Install

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::RoutesAuthDBI::Install - is a Mojolicious::Controller for installation instructions.

=head1 DB DESIGN DIAGRAM

See L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/blob/master/Diagram.svg>

=head1 Manual

  $ read -d '' CODE <<PERL; perl -Ilib -e "$CODE" get /man
  use Mojo::Base 'Mojolicious';
  sub startup {
    shift->routes->route('/man')
      ->to('install#manual', namespace=>'Mojolicious::Plugin::RoutesAuthDBI');
  }
  __PACKAGE__->new->start;
  PERL


=head1 View schema (define the postgresql schema name and alternative tables names)

  $ read -d '' CODE <<PERL; perl -Ilib -e "$CODE" get /schema/<name>[?...] # /schema/public?profiles=профили
  use Mojo::Base 'Mojolicious';
  sub startup {
    shift->routes->route('/schema/:schema')
      ->to('Schema#schema', namespace=>'Mojolicious::Plugin::RoutesAuthDBI');
  }
  __PACKAGE__->new->start;
  PERL


=head1 Apply schema (define the postgresql schema name and tables names)

  $ read -d '' CODE <<PERL; perl -Ilib -e "$CODE" get /schema/<name>[?...] 2>/dev/null | psql -d <dbname> # /schema/<name>?roles=groups
  use Mojo::Base 'Mojolicious';
  sub startup {
    shift->routes->route('/schema/:schema')
      ->to('Schema#schema', namespace=>'Mojolicious::Plugin::RoutesAuthDBI');
  }
  __PACKAGE__->new->start;
  PERL


=head1 Sample app

  $ read -d '' CODE <<PERL; perl -Ilib -e "$CODE" get /app 2>/dev/null > test-app.pl
  use Mojo::Base 'Mojolicious';
  sub startup {
    shift->routes->route('/app')
      ->to('install#sampl_app', namespace=>'Mojolicious::Plugin::RoutesAuthDBI');
  }
  __PACKAGE__->new->start;
  PERL

=head1 Define DBI->connect(...) and some plugin options in test-app.pl

=head1 Check list of admin routes:

    $ perl test-app.pl routes

=head1 Start app

    $ perl test-app.pl daemon

=head1 Trust url for admin-user creation:

    $ perl test-app.pl get /<pluginconf->{admin}{prefix}>/<pluginconf->{admin}{trust}>/user/new/<new admin login>/<admin pass> 2>/dev/null

User will be created and assigned to role 'Admin' . Role 'Admin' assigned to namespace 'Mojolicious::Plugin::RoutesAuthDBI' that has access to all admin controller routes!

=head1 Sign in on browser

http://127.0.0.1:3000/sign/in/<new admin login>/<admin pass>

=head1 Administration of system ready!

=cut

sub manual {
  my $c = shift;
  
   $c->render(format=>'txt', text=><<'TXT');
Welcome  Mojolicious::Plugin::RoutesAuthDBI !

1. Apply db schema by command (define the postgresql schema name):
------------

$ perl -e "use Mojo::Base 'Mojolicious'; __PACKAGE__->new()->start(); sub startup {shift->routes->route('/schema/:schema')->to('DB#schema', namespace=>'Mojolicious::Plugin::RoutesAuthDBI');}" get /schema/public 2>/dev/null | psql -d <dbname> # here set public pg schema!


2. Create test-app.pl and then define in them DBI->connect(...) and some plugin options:
------------

$ perl -e "use Mojo::Base 'Mojolicious'; __PACKAGE__->new()->start(); sub startup {shift->routes->route('/')->to('install#sampl_app', namespace=>'Mojolicious::Plugin::RoutesAuthDBI');}" get / 2>/dev/null > test-app.pl

3. View admin routes:
------------

$ perl test-app.pl routes


4. Start app:
------------

$ perl test-app.pl daemon


5. Go to trust url for admin-user creation :
------------

$ perl test-app.pl get /<pluginconf->{admin}{prefix}>/<pluginconf->{admin}{trust}>/admin/new/<new admin login>/<admin pass>

User will be created and assigned to role 'Admin' . Role 'Admin' assigned to namespace 'Mojolicious::Plugin::RoutesAuthDBI' that has access to all admin controller routes!


6. Go to http://127.0.0.1:3000/sign/in/<new admin login>/<admin pass>
------------


Administration of system ready!

TXT
}


sub sampl_app {
  my $c = shift;
  my $code = $sql->{'sample.app'}->render;
  $c->render(format=>'txt', text => <<TXT);
$code
TXT
}


1;

__DATA__
@@ sample.app
use Mojo::Base 'Mojolicious';
use DBI;

has dbh => sub { DBI->connect("DBI:Pg:dbname=<dbname>;", "postgres", undef); };

sub startup {
  my $app = shift;
  # $app->plugin(Config =>{file => 'Config.pm'});
  $app->plugin('RoutesAuthDBI',
    dbh=>$app->dbh,
    auth=>{current_user_fn=>'auth_user'},
    # access=> {},
    admin=>{prefix=>'myadmin', trust=>'fooobaaar',},
  );
}
__PACKAGE__->new->start;


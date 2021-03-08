use 5.008007;
package Mojolicious::Plugin::SQLiteViewerLite;
use Mojo::Base 'Mojolicious::Plugin::SQLiteViewerLite::Base';
use Mojolicious::Plugin::SQLiteViewerLite::Command;
use DBIx::Custom;
use Validator::Custom;
use File::Basename 'dirname';
use Cwd 'abs_path';

our $VERSION = '0.15';

has command => sub {
  my $self = shift;
  my $commond = Mojolicious::Plugin::SQLiteViewerLite::Command->new(dbi => $self->dbi);
};

sub register {
  my ($self, $app, $conf) = @_;
  
  # Database
  my $dbi = $conf->{dbi};
  my $connector = $conf->{connector};
  my $dbh = $conf->{dbh};
  if ($dbi) { $self->dbi($dbi) }
  elsif ($connector) { $self->dbi->connector($connector) }
  else { $self->dbi->dbh($dbh) }
  
  # Add template and public path
  $self->add_template_path($app->renderer, __PACKAGE__);
  $self->add_static_path($app->static, __PACKAGE__);

  # Mojolicious compatibility
  my $any_method_name;
  if ($Mojolicious::VERSION >= '8.67') {
    $any_method_name = 'any'
  }
  else {
    $any_method_name = 'route'
  }
  
  # Routes
  my $r = $conf->{route} // $app->routes;
  my $prefix = $conf->{prefix} // 'sqliteviewerlite';
  $self->prefix($prefix);
  {
    my $r = $r->$any_method_name("/$prefix")->to(
      'sqliteviewerlite#',
      namespace => 'Mojolicious::Plugin::SQLiteViewerLite',
      plugin => $self,
      prefix => $self->prefix,
      main_title => 'SQLite Viewer Lite',
    );
    
    $r->get('/')->to('#default');
    $r->get('/tables')->to(
      '#tables',
      utilities => [
        {path => 'showcreatetables', title => 'Show create tables'},
        {path => 'showselecttables', title => 'Show select tables'},
        {path => 'showprimarykeys', title => 'Show primary keys'},
        {path => 'shownullallowedcolumns', title => 'Show null allowed columns'},
      ]
    );
    $r->get('/table')->to('#table');
    $r->get('/showcreatetables')->to('#showcreatetables');
    $r->get('/showselecttables')->to('#showselecttables');
    $r->get('/showprimarykeys')->to('#showprimarykeys');
    $r->get('/shownullallowedcolumns')->to('#shownullallowedcolumns');
    $r->get('/showdatabaseengines')->to('#showdatabaseengines');
    $r->get('/showcharsets')->to('#showcharsets');
    $r->get('/select')->to('#select');
  }
}

1;

=head1 NAME

Mojolicious::Plugin::SQLiteViewerLite - Mojolicious plugin to display SQLite database information on browser

=head1 CAUTION

B<L<Mojolicious::Plugin::SQLiteViewerLite> is merged into L<Mojolicious::Plugin::DBViewer>>.

B<This module is DEPRECATED and will be removed from CPAN in 2018/4/1>.

But you get it on github.

  https://github.com/yuki-kimoto/Mojolicious-Plugin-SQLiteViewerLite

=head1 SYNOPSYS

  # Mojolicious::Lite
  # (dbh is a database handle already connected to the database)
  plugin 'SQLiteViewerLite', dbh => $dbh;

  # Mojolicious
  $app->plugin('SQLiteViewerLite', dbh => $dbh);

  # Access
  http://localhost:3000/sqliteviewerlite
  
  # Prefix
  plugin 'SQLiteViewerLite', dbh => $dbh, prefix => 'sqliteviewerlite2';
  
  # Route
  my $bridge = $app->route->under(sub {...});
  plugin 'SQLiteViewerLite', dbh => $dbh, route => $bridge;

  # Using connection manager object instead of "dbh"
  plugin 'SQLiteViewerLite', connector => DBIx::Connector->connect(...);

  # Using DBIx::Custom object instead of "dbh"
  plugin 'SQLiteViewerLite', dbi => DBIx::Custom->connect(...);

=head1 DESCRIPTION

L<Mojolicious::Plugin::SQLiteViewerLite> is L<Mojolicious> plugin
to display SQLite database information on browser.

L<Mojolicious::Plugin::SQLiteViewerLite> have the following features.

=over 4

=item *

Display all table names

=item *

Display C<show create table>

=item *

Select * from TABLE

=item *

Display C<primary keys> and C<null allowed columnes> in all tables.

=back

=head1 OPTIONS

=head2 C<connector>

  connector => $connector

Connector object such as L<DBIx::Connector> to connect to database.
You can use this instead of C<dbh> option.

  my $connector = DBIx::Connector->connect(...);

Connector has C<dbh> method to get database handle

=head2 C<dbh>

  dbh => $dbh

dbh is a L<DBI> database handle already connected to the database.

  my $dbh = DBI->connect(...);

=head2 C<dbi>

  dbi => DBIx::Custom->connect(...);

L<DBIx::Custom> object.
you can use this instead of C<dbh> option.

=head2 C<prefix>

  prefix => 'sqliteviewerlite2'

Application base path, default to C<sqliteviewerlite>.

=head2 C<route>

    route => $route

Router, default to C<$app->routes>.

It is useful when C<under> is used.

  my $bridge = $r->under(sub {...});
  plugin 'SQLiteViewerLite', dbh => $dbh, route => $bridge;

=cut

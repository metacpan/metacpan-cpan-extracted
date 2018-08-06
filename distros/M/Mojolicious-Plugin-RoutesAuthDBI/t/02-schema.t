use Mojo::Base 'Mojolicious';
use Test::More;
use Test::Mojo;

my $config = do 't/config.pm';

sub startup {
  my $app = shift;
  #~ $app->plugin('RoutesAuthDBI',
    #~ admin=>{prefix=>$config->{prefix}, trust=>$config->{trust}, role_admin=>$config->{role_admin},},
    #~ guest=>{},
    #~ log=>{},
    #~ template=>$config,
  #~ );
  my $r = $app->routes;
  $r->route('/schema/:schema')
    ->to('Schema#schema', namespace=>'Mojolicious::Plugin::RoutesAuthDBI');
}



my $t = Test::Mojo->new(__PACKAGE__);

$t->get_ok("/schema/$config->{schema}?sequence=$config->{sequence}&".join('&', map("$_=$config->{tables}{$_}", keys %{$config->{tables}})))
  ->status_is(200)
  ->content_like(qr/table\s+(?:IF NOT EXISTS)?\s*"$config->{schema}"\."$config->{tables}{refs}"/i)
  ->content_like(qr/table\s+(?:IF NOT EXISTS)?\s*"$config->{schema}"\."$config->{tables}{profiles}"/i)
  ->content_like(qr/SEQUENCE\s+$config->{sequence}/i)
  ->content_like(qr/table\s+(?:IF NOT EXISTS)?\s*"$config->{schema}"\."$config->{tables}{oauth_users}"/i)
  ->content_like(qr/table\s+(?:IF NOT EXISTS)?\s*"$config->{schema}"\."$config->{tables}{oauth_sites}"/i)
  ->content_like(qr/table\s+(?:IF NOT EXISTS)?\s*"$config->{schema}"\."$config->{tables}{roles}"/i)
  ->content_like(qr/table\s+(?:IF NOT EXISTS)?\s*"$config->{schema}"\."$config->{tables}{routes}"/i)
  ->content_like(qr/table\s+(?:IF NOT EXISTS)?\s*"$config->{schema}"\."$config->{tables}{guests}"/i)
  ->content_like(qr/table\s+(?:IF NOT EXISTS)?\s*"$config->{schema}"\."$config->{tables}{logs}"/i)
  ;

my $create = $t->tx->res->text;


subtest 'need_conn' => sub {
  plan skip_all => 'set env TEST_CONN_PG="DBI:Pg:dbname=<db>/<pg_user>/<passwd>" to enable this test'
    unless $ENV{TEST_CONN_PG};
  my ($dsn, $user, $pw) = split m|[/]|, $ENV{TEST_CONN_PG};
  require DBI;
  my $dbh = DBI->connect($dsn, $user, $pw);
  is $dbh->do($create), '0E0', 'create schema tables';
};


#~ warn $t->tx->res->text;

done_testing();
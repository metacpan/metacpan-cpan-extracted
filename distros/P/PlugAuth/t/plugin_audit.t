use strict;
use warnings;
use 5.010001;
BEGIN { delete $ENV{CLUSTERICIOUS_CONF_DIR} }
use Test2::Plugin::FauxHomeDir;
use Test::More tests => 20;
use Test::Mojo;
use Path::Class::Dir;
use YAML::XS qw( Dump LoadFile );
use Path::Class::File;
use Path::Class::Dir;
use JSON::MaybeXS qw( encode_json );
use File::Glob qw( bsd_glob );

delete $ENV{HARNESS_ACTIVE};
$ENV{LOG_LEVEL} = 'FATAL';

my $etc = Path::Class::Dir
  ->new(bsd_glob('~/etc'));
$etc->mkpath(0,0700);

$etc->file('PlugAuth.conf')->spew(Dump({
  plugins => [
    { 'PlugAuth::Plugin::Audit' => {} },
  ],
}));

my $t = Test::Mojo->new('PlugAuth');

$t->get_ok('/audit')
  ->status_is(200);

ok $t->tx->res->json->{version}, 'tx.res.json.version = ' . $t->tx->res->json->{version};
like $t->tx->res->json->{today}, qr{^\d{4}-\d{2}-\d{2}$}, "today = " . $t->tx->res->json->{today};

sub json($) {
    ( { 'Content-Type' => 'application/json' }, encode_json(shift) );
}

my($year, $month, $day) = do {
  $t->post_ok("/user", json { user => 'primus', password => 'spark' } )
    ->status_is(200);
  
  my $log = eval {
    my $dir = Path::Class::Dir->new(bsd_glob('~/.plugauth_plugin_audit'));
    ($dir) = $dir->children;
    ($dir) = $dir->children;
    ($dir) = $dir->children;
    $dir->file('audit.log');
  };
  diag $@ if $@;
  ok -r $log, "log for a day $log";
  my($entry) = LoadFile($log->stringify);
  
  is $entry->{event}, 'create_user', 'event = create_user';
  like $entry->{time}, qr{^\d+$}, 'time = ' . $entry->{time};
  is $entry->{user}, 'primus', 'user = primus';
  
  ($log->parent->parent->parent->basename,
  $log->parent->parent->basename,
  $log->parent->basename)
};
 
$t->get_ok("/audit/$year/$month/$day")
  ->status_is(200);

is $t->tx->res->json->[0]->{event}, 'create_user', 'event = create_user';
like $t->tx->res->json->[0]->{time_epoch},  qr{^\d+$}, 'time = ' . $t->tx->res->json->[0]->{time_epoch};
is $t->tx->res->json->[0]->{user},  'primus', 'user = primus';
  
$year++;
$t->get_ok("/audit/$year/$month/$day")
  ->status_is(404);

$t->get_ok('/audit/today')
  ->status_is(302)
  ->header_like(Location => qr{/audit/\d\d\d\d/\d\d/\d\d$});

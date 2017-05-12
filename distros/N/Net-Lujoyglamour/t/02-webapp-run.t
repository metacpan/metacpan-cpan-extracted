#!perl 

use Test::More qw( no_plan ); #Random initial string...
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

use Net::Lujoyglamour;
use Net::Lujoyglamour::WebApp;
use Test::WWW::Mechanize::CGIApp;

#First deploy
my $db_name = 'test';
my $dsn = "dbi:SQLite:dbname=$db_name";
my $domain ="qu.ee";
my $schema = Net::Lujoyglamour->connect($dsn);
$schema->deploy({ add_drop_tables => 1});

my $this_dir = $ENV{'PWD'};
my $template_dir;
if ( ($this_dir =~ m{/t$}) || ($this_dir =~ m{/t/$})  ) {
    $template_dir = $this_dir;
} else {
    $template_dir= "$this_dir/t";
}
my $mech = Test::WWW::Mechanize::CGIApp->new;
$mech->app(
	   sub {
	     my $app = new Net::Lujoyglamour::WebApp 
		 PARAMS => { dsn => $dsn,
			     domain => $domain },
		 TMPL_PATH => $template_dir;
	     $app->run();
	   });

$mech->get_ok("?rm=form");
$mech->content_contains('Net::Lujoyglamour', 'Contains Lujoyglamour OK' );
my $long_URL = 'this.is.long';
$mech->get_ok("?rm=geturl&longurl=$long_URL");
my @links = $mech->links;
my $short_link = $links[0]->url;
$mech->content_contains("http://$long_URL", "Long URL shortened to $short_link");
$mech->get_ok("?rm=geturl&longurl=$long_URL");
$mech->content_contains($short_link, "Retrieved same short URL");
my $u='a';
my ($short_link_path) = ($short_link =~ m{/(\w+)$});
while ($u eq $short_link_path) {
    $u++;
}
$mech->get_ok("?rm=geturl&longurl=very.long.url.here.is&shorturl=$u");
$mech->content_contains("http://$domain/$u", "Retrieved very short URL");

$u = 'json';
$mech->get_ok("?rm=geturl&longurl=another.very.long.url.here.is&shorturl=$u&fmt=JSON");
$mech->content_contains("$domain/$u", "JSON OK");

$mech->get_ok("?rm=redirect&url=$u" );

$mech->get_ok("?rm=redirect&url=yaya");
$mech->content_contains( 'Sorry', "Redirect error Ok");
unlink $db_name;


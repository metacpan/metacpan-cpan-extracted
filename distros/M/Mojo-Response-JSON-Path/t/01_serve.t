use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Test::Deep;

use Mojo::Response::JSON::Path;

use Mojo::Util qw/dumper/;

my $called;

get '/' => sub {
    my $c = shift;
    my $json = {
		"entities" =>
		{
		 "Q100148272" =>
		 {
		  "id" => "Q100148272",
		  "sitelinks" =>
		  {
		   "enwiki" =>
		   {
		    "badges" => [],
		    "site" => "enwiki",
		    "title" => "Canyons (song)"
		   }
		  },
		  "type" => "item"
		 }
		},
		"success" => 1
	       };

    $c->render(json => $json);
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200);

my $j = $t->tx->res->json;

my $r =  {
	  "Q100148272" =>
	  {
	   "id" => "Q100148272",
	   "sitelinks" =>
	   {
	    "enwiki" =>
	    {
	     "badges" => [],
	     "site" => "enwiki",
	     "title" => "Canyons (song)"
	    }
	   },
	   "type" => "item"
	  }
	 }
    ;

cmp_ok $j->{success}, '==', 1, 'got response';

$j = $t->tx->res->json('$.entities');

cmp_deeply $j, $r, 'deep comparison';

done_testing;

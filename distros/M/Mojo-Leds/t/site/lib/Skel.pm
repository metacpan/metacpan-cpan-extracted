package Skel;

use Mojo::Base 'Mojo::Leds';
use MongoDB;

sub startup {
	my $s	= shift;
    $s->SUPER::startup(@_);

    my $app = $s->app;
    my $r	= $s->routes;

     my @tables = qw/pages/;
     my $rest = $r->under('/rest')->to(namespace => 'rest', cb => sub {1});
     $s->restify->routes($rest, \@tables, {allows_optional_action => 1});

	$s->plugin('AutoRoutePm' => {
		route 			=> [ $r ],
		exclude 		=> ['rest/']
	});

}

1;

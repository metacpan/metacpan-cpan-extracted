package Skel;

use Mojo::Base 'Mojo::Leds';

sub startup {
	my $s	= shift;
    $s->SUPER::startup(@_);

    my $app = $s->app;
    my $r	= $s->routes;


	$s->plugin('AutoRoutePm' => {
		route 			=> [ $r ],
		exclude 		=> ['rest/']
	});

}

1;

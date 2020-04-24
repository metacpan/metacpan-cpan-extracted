package MyApp;
use Mojo::Base 'Mojolicious';
use Test::Fake::HTTPD;

my $httpd = Test::Fake::HTTPD->new(
    timeout => 10
);

$httpd->run(sub {
    my $request = shift;

    return [ 
	200, 
	['Content-Type' => 'application/json'], 
        ['{"id": ' . int(rand(9999999)) . '}'] 
    ];
});

 
sub startup {
    my $self = shift;

    my $endpoint = $httpd->endpoint;
    $endpoint    =~ s/^http:\/\///;
     
    $self->plugin('ExceptionSentry' => {
	sentry_dsn => 'http://foo:baz@'. $endpoint .'/bar'
    });

    my $main = $self->routes->under('/');
    $main->get(
	sub {
	    shift->render(text => 1);
    	}
    );

    $main->post(
	sub {
	    die 1
	}
    );
}
 
1;

use Plack::Builder;
use Plack::Request;

my $app = sub {
    my $env      = shift;
    my $fire_php = $env->{'plack.fire_php'};

    $fire_php->log('Hello from FirePHP');
    $fire_php->start_group('Levels:');
    $fire_php->info('Log informational message');
    $fire_php->warn('Log warning message');
    $fire_php->error('Log error message');
    $fire_php->end_group;

    $fire_php->start_group('Propably emtpy:');
    $fire_php->dismiss_group;

    return [ 
        200, 
        [ 'Content-Type' => 'text/html' ],
        [ '<body>Hello World</body>' ] 
    ];
};

builder {
    enable 'FirePHP', disabled => 1;
    $app;
};

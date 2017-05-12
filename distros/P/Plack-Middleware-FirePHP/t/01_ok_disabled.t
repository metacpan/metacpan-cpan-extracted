use Plack::Builder;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

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
        [ 'Hello World' ] 
    ];
};

$app = builder {
    enable 'FirePHP', disabled => 1;
    $app;
};

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");

        is $res->code, 200;
        is $res->content, 'Hello World';
        is $res->content_type, 'text/html';
        isnt $res->header('x-wf-1-1-1-1'), '37|[{"Type":"LOG"},"Hello from FirePHP"]|';
        isnt $res->header('x-wf-1-1-1-2'), '47|[{"Type":"GROUP_START","Label":"Levels:"},null]|';
        isnt $res->header('x-wf-1-1-1-3'), '45|[{"Type":"INFO"},"Log informational message"]|';
        isnt $res->header('x-wf-1-1-1-4'), '39|[{"Type":"WARN"},"Log warning message"]|';
        isnt $res->header('x-wf-1-1-1-5'), '38|[{"Type":"ERROR"},"Log error message"]|';
        isnt $res->header('x-wf-1-1-1-6'), '27|[{"Type":"GROUP_END"},null]|';
        isnt $res->header('x-wf-1-index'), 6;
        isnt $res->header('x-wf-1-plugin-1'), 'http://meta.firephp.org/Wildfire/Plugin/FirePHP/Library-FirePHPCore/0.2.0';
        isnt $res->header('x-wf-1-structure-1'), 'http://meta.firephp.org/Wildfire/Structure/FirePHP/FirebugConsole/0.1';
        isnt $res->header('x-wf-protocol-1'), 'http://meta.wildfirehq.org/Protocol/JsonStream/0.2';
    };

done_testing();

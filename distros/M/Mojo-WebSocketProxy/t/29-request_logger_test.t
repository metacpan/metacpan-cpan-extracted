use Test::More;
use Mojo::WebSocketProxy::RequestLogger;

my $logger = Mojo::WebSocketProxy::RequestLogger->new();

subtest 'Test log_message method' => sub {
    $logger->info('This is a info message');
    $logger->warn('This is a warning message');
    $logger->trace('This is a trace message');
    $logger->error('This is an error message');
    $logger->debug('This is debug message');
    $logger->infof('This is a info message %s', ['abc', '221']);
    $logger->warnf('%s This is a warning message ', {with => 'params'});
    $logger->tracef('This is a trace %s message', "with params");
    $logger->errorf('This is an error %s message', "with params");
    $logger->debugf('This is debug message with %s', 'params');
    pass('All log levels tested');
};

subtest 'Test get_context method' => sub {
    my $context = $logger->get_context();
    ok($context->{correlation_id}, 'Correlation ID exists');
};

done_testing();

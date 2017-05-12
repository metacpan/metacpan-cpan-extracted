use Mojo::Redis::Processor;
use Mojolicious::Lite;

my $rp = Mojo::Redis::Processor->new({
    data       => 'Data',
    trigger    => 'R_25',
});

$rp->send();
my $redis_channel = $rp->on_processed(
    sub {
        my ($message, $channel) = @_;
        print "Got a new result [$message]\n";
    });

app->start;

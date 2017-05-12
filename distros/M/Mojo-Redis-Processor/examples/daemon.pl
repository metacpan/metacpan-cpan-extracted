use Mojo::Redis::Processor;
use Parallel::ForkManager;

use constant MAX_WORKERS  => 1;

$pm = new Parallel::ForkManager(MAX_WORKERS);

while (1) {
    my $pid = $pm->start and next;

    my $rp = Mojo::Redis::Processor->new;

    $next = $rp->next();
    if ($next) {
        print "next job started [$next].\n";

        $rp->on_trigger(
            sub {
                my $payload = shift;
                print "processing payload\n";
                return rand(100);
            });
        print "Job done, exiting the child!\n";
    } else {
        print "no job found\n";
        sleep 1;
    }
    $pm->finish;
}

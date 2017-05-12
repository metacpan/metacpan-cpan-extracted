use Qudo::Test;
use Test::Output;

run_tests(1, sub {
    my $driver = shift;
    my $master = test_master(
        driver_class => $driver,
    );

    my $manager = $master->manager;
    $manager->can_do('Worker::Test');
    $manager->register_plugins(
        +{
            name => 'Qudo::Plugin::Logger',
            option => +{
                dispatchers => ['screen'],
                screen => {
                    class     => 'Log::Dispatch::Screen',
                    min_level => 'debug',
                    stderr    => 0,
                },
            },
        }
    );

    $manager->enqueue("Worker::Test", {});
    stdout_is( sub { $manager->work_once } , 'ops!');

    teardown_dbs;
});

package Worker::Test;
use base 'Qudo::Worker';

sub work {
    my ($class, $job) = @_;
    $job->manager->plugin->{logger}->debug('ops!');
}

use Qudo::Test;
use Test::Output;

run_tests(1, sub {
    my $driver = shift;
    my $master = test_master(
        driver_class => $driver,
    );

    my $manager = $master->manager;
    $manager->can_do('Worker::Test');
    $manager->register_hooks(qw/Qudo::Hook::Notify::ReachMaxRetry/);
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
    $manager->work_once;
    $manager->work_once;
    stdout_is( sub { $manager->work_once } , 'Worker::Test already retry max!!');

    teardown_dbs;
});

package Worker::Test;
use base 'Qudo::Worker';

sub max_retries { 2 }
sub work {
    my ($class, $job) = @_;
    die 'ops';
}

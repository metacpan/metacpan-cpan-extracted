use Qudo::Test;
use Test::Output;

run_tests(2, sub {
    my $driver = shift;
    my $master = test_master(
        driver_class => $driver,
    );

    my $manager = $master->manager;
    $manager->can_do('Worker::Test');
    $manager->register_hooks(qw/Qudo::Hook::Notify::Failed/);
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
    stdout_is( sub { $manager->work_once } , 'Worker::Test is failed!!');
    stdout_is( sub { $manager->work_once } , 'Worker::Test is failed!!');

    teardown_dbs;
});

package Worker::Test;
use base 'Qudo::Worker';

sub max_retries { 2 }
sub work {
    my ($class, $job) = @_;
    die 'ops';
}

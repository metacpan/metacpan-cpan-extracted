package Mojolicious::Plugin::Minion::Tasks;
use Mojo::Base 'Mojolicious::Plugin';

use Minion::Task;
use Module::Loader;
use Try::Tiny;

our $VERSION = '0.0.1';

=head2 register

Register the plugin

=cut

sub register {
    my ($self, $app, $config) = @_;

    # Make sure "tasks" namespace is defined
    die __PACKAGE__, ": missing 'namespace' in config.\n"
        if (!$config->{ namespace });

    my $loader  = Module::Loader->new;
    # Find all the modules in the given namespace
    my @modules = $loader->find_modules($config->{ namespace });

    foreach my $module (@modules) {
        # And add the module to the list of tasks
        # e.g.: "MyApp::Tasks::SayHello"
        $app->minion->add_task($module => sub {
            my ($job, $args) = @_;

            $loader->load($module);

            my $task = $module->new({ id => $job->id, app => $app, args => $args });

            # Handle the task
            $self->handle($job, $task);
        });
    }
}

=head2 handle

Handle the given task

=cut

sub handle {
    my ($self, $job, $task) = @_;

    try {
        my $ok = $task->start;

        if ($ok == 1) {
            # Mark as finished
            $job->finish($task->finish);
        } else {
            # Mark as failed
            $job->fail($task->error);
        }
    } catch {
        $job->app->log->warn($_);
        $job->fail($_);
    };

    # Update the tags for the current job
    # See Mojolicious::Plugin::Minion::Overview for more details
    $job->note(tags => $task->tags);
}

1;

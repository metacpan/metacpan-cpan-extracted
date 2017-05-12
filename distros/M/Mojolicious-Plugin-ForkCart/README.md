# ForkCart
Auto launch a process on Mojolicious startup

## Example Usage

    use Mojolicious::Lite;

    plugin Minion => { SQLite => 'sqlite:test.db' };
    plugin ForkCart => { process => ["minion", "minion" ] };

    app->minion->add_task(joy => sub {
        my ($job, @args) = @_;

        my $finish = "Weeee: " . scalar(localtime);
        $job->app->log->info($finish);

        $job->finish($finish);
    });

    get '/', {job_id => 0} => sub {
        my $c = shift;

        # Have fun later
        my $enqued_id = $c->minion->enqueue("joy");
        $c->render(text => "Hello:" . $enqued_id);
    };

    app->start;

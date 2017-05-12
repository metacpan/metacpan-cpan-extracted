#!/opt/perl

use Mojolicious::Lite;

app->log->level("debug");

plugin Minion => { SQLite => 'sqlite:test.db' };
plugin ForkCart => { process => ["minion", "minion", "minion"] };

app->minion->add_task(joy => sub {
    my ($job, @args) = @_;

    my $finish = "Weeee: " . scalar(localtime);
    $job->app->log->info($finish);

    $job->finish($finish);
});

get '/:job_id', {job_id => 0} => sub {
    my $c = shift;

    my $json;
    my $job_id = $c->param("job_id");

    # Show the fun
    eval {
        if ($job_id) {
            my $state = $c->minion->job($job_id)->info->{state};
            my $result = $c->minion->job($job_id)->info->{result};

            $json = { state => $state, result => $result };
        }
    };
    if ($@) {
        $json = { error => 1, message => "Job ID not found" };
    }

    return $c->render(json => $json) if $json;
    
    # Have fun later
    my $enqued_id = $c->minion->enqueue("joy");
    $c->render(text => "Hello:" . $enqued_id);
};

app->start;

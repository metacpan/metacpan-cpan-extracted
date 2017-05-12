use Test::More;
use Cwd 'getcwd';

unless ($_ = $ENV{NET_REDMINE_RAILS_ROOT}) {
    plan skip_all => "Need SD_REDMINE_RAILS_ROOT env var";
    exit;
}

my $REDMINE_RAILS_ROOT = $ENV{NET_REDMINE_RAILS_ROOT};
my $REDMINE_SERVER_PID = undef;

END {
    # system "kill -9 $REDMINE_SERVER_PID" if $REDMINE_SERVER_PID
}

sub net_redmine_test {
    return ("http://localhost:3000/projects/test", "admin", "admin");
}

sub new_net_redmine {
    if ($REDMINE_SERVER_PID) {
        system "kill -9 $REDMINE_SERVER_PID";
        unlink "tmp/pids/server.pid";
        $REDMINE_SERVER_PID = undef;
    }

    {
        my $cwd = getcwd;
        print STDERR "# Starting Redmine Server\n";

        chdir $REDMINE_RAILS_ROOT;
        unlink "tmp/pids/server.pid";
        system q[echo en | rake db:drop db:create db:migrate redmine:load_default_data  >/dev/null];
        system q[script/runner 'p = Project.create(:name => "test", :identifier => "test", :is_public => false); p.enabled_module_names = ["issue_tracking"]; p.trackers = Tracker.all; p.set_parent!(nil); p.save'  >/dev/null];
        system q[script/server -d >/dev/null];
        sleep 10; # It is THAT slow on my machine...

        $REDMINE_SERVER_PID = `cat tmp/pids/server.pid`;
        print STDERR "# Redmine Server started. PID ${REDMINE_SERVER_PID}\n";
        chdir $cwd;
    }

    my ($server, $user, $password) = ("http://localhost:3000/projects/test", "admin", "admin");
    return Net::Redmine->new(url => $server,user => $user, password => $password);
}

use Text::Greeking;

sub new_tickets {
    my ($r, $n) = @_;
    $n ||= 1;

    my $g = Text::Greeking->new;
    $g->paragraphs(1,1);
    $g->sentences(1,1);
    $g->words(8,24);

    my (undef, $filename, $line) = caller;

    return map {
        $r->create(
            ticket => {
                subject => "$filename, line $line " . $g->generate,
                description => $g->generate
            }
        );
    } (1..$n);
}

1;

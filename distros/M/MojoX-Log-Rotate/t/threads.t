use Modern::Perl;
BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
    my $may_crash = scalar grep {/^DEBUGGING|PERL_TRACK_MEMPOOL$/} Config::bincompat_options();
    if($may_crash) {
        #looks like to be the cause of a "panic: free from wrong pool, 55967dc51d80!=559679d30010 during global destruction." message
        print("1..0 # SKIP Perl compiled with DEBUGGING or PERL_TRACK_MEMPOOL\n");
        exit(0);
    }
}

use threads;
use threads::shared;
use Thread::Queue;
use feature 'signatures';
use Test::More;
use Test::Mojo;
use Test::Differences;
use Test::MockTime 0.17 qw( :all );
use File::Slurp qw(slurp);
use MojoX::Log::Rotate;

$|++;
my $LEVEL = $ENV{MOJO_LOG_LEVEL} = 'info';

sub suffix {
    my ($y, $m, $d, $h, $mi, $s) =  (localtime shift)[5, 4, 3, 2, 1, 0];
    sprintf("_%04d%02d%02d_%02d%02d%02d", $y+1900, $m+1, $d, $h, $mi, $s);
}

sub mock_sleep {
    set_fixed_time( time + shift );
}

set_fixed_time('01/01/2022 08:00:00', '%m/%d/%Y %H:%M:%S');
 
unlink 'test.log' if -f 'test.log';
my $start = time;
my $rotations = Thread::Queue->new;

#hack to inject fixed mocked time into the queue thread
my $global_time : shared = time;
my $t0 = time;
my $real_message_handler = \&MojoX::Log::Rotate::on_message_handler;
Mojo::Util::monkey_patch('MojoX::Log::Rotate', 'on_message_handler', sub {
    set_fixed_time($global_time);
    # say "i am ", threads->tid, ", it is $global_time but ", time();
    &$real_message_handler;
});
sub MojoX::Log::Rotate::CLONE {
    # say "i am ", threads->tid, ", fixed time to ", time();
    set_fixed_time($global_time);
}

my $logger = MojoX::Log::Rotate->new(
        threaded => 1,
        frequency => 2, 
        path => 'test.log', 
        on_rotate => sub {
            my ($e, $r) = @_;
            # say "** ROTATION done at ", time();
            $rotations->enqueue($r);
        },
    );
$logger->short(1);

my $t = Test::Mojo->new('TestWebApp');
$t->app->log($logger);
#this rotate event is never triggered because the thread that process messages is created BEFORE this 
# event registration, so the object reference to the logger is forked before and cannot be shared 
# because of GOLB or CODEREF (unless using threads::sharedx maybe...)
$logger->on(rotate => sub { say "# ** ROTATION message never printed **" });

my @threads = map { 
        threads->create(sub {
            for(1..10) {
                $t->get_ok('/test/'.$_.'/'.threads->tid)->status_is(200);
                mock_sleep(1); #is this thread safe?
                sleep(1);
            }
        });
    } 1..5;

for(1..11) {
    $global_time = time;
    sleep(1);
    mock_sleep(1);
}

$_->join for @threads;

$logger->handle->close; #let's unlink file
$logger->stop;

$rotations->end;
my @rotations = map { $_->{how}{rotated_file} } $rotations->dequeue($rotations->pending);

my @expected = ( 
    'test'.suffix($t0 + 3).'.log',
    'test'.suffix($t0 + 6).'.log',
    'test'.suffix($t0 + 9).'.log',
    );
eq_or_diff \@rotations, \@expected, 'rotations';

#another test is to read the content of all files + test.log, sort the lines and assert the content
# make sure it is dispatched
my @got_lines = sort grep { /test called for/ } map { slurp $_ } @expected, 'test.log';
my @expected_lines;
for my $tid (2..6){
    for (1..10){
        push @expected_lines, $logger->_short($LEVEL, "test called for $_ by $tid");
    }
}
@expected_lines = sort @expected_lines;
eq_or_diff \@got_lines, \@expected_lines, 'merged content';

done_testing;

# cleanup temp log files
# say "press ENTER key to continue and delete temps log files"; getc;
unlink $_ for grep { /^test(_\d{8}_\d{6})?\.log$/ } <test*.log>;
exit;

package TestWebApp;
use Mojo::Base 'Mojolicious', -signatures;
 
sub startup {
  my $self = shift;
  $self->log->level('error')->path(undef);
  my $r = $self->routes;
  $r->any('/test/:id/:tid' => sub($c) {
    $c->app->log->$LEVEL('test called for ' . $c->stash('id') . ' by ' . $c->stash('tid'));
    $c->render(text => 'test', status => 200);
  });
}
 
1;

use Test::More tests => 32;
use Test::Mojo;
use File::Copy;

# crude attempt to move any working db file out of the way
# but be warned, running developer tests may whack your local db!
my $db_file = "webui.db";
my $db_file_backup = "$db_file.xxx_temp";

move($db_file, $db_file_backup) if -f $db_file;

# Allow 302 redirect responses
my $t = Test::Mojo->new('Rex::WebUI');
#$t->ua->max_redirects(1);


# Test if the HTML login form exists
$t->get_ok('/dashboard');
$t->status_is(200);
$t->text_is("#content_area h1" => "Rex Web Delopyment Console - Dashboard");

$t->get_ok('/project/0?nolayout=1');
$t->status_is(200);
$t->text_is("#task_info h2" => "Tasks Available");
$t->text_is("#task_info tr:nth-child(1) td:nth-child(2) a" => "get-os");
$t->text_is("#task_info tr:nth-child(2) td:nth-child(2) a" => "long_run");
$t->text_is("#task_info tr:nth-child(3) td:nth-child(2) a" => "long_run2");

$t->get_ok('/project/0/task/view/long_run?nolayout=1');
$t->status_is(200);
$t->text_is("h1" => "Task Details: long_run");
$t->text_is(".info_table tr:nth-child(1) th" => "Description:");
$t->text_is(".info_table tr:nth-child(1) td" => "Long Running Task");
$t->text_is(".info_table tr:nth-child(2) th" => "Server:");
$t->text_is(".info_table tr:nth-child(2) td" => "");

# set a delay in the server call to ensure things happen in the right order here
$Rex::WebUI::Task::TEST_DELAY_AFTER_RUN_TASK = 2;

$t->post_ok('/project/0/task/run/uptime' => form => { task_name => 'uptime' });
$t->status_is(200);
$t->json_is('/status' => 'starting task: uptime');
$t->json_is('/jobid' => 1);

#$t->app->log->level('debug');

# get dashboard again, right away - we should have 1 running task
# this can potentially fail due to timing, probably I should add a debug flag with a small delay
$t->get_ok('/dashboard');
$t->status_is(200);
$t->text_is("#content_area h1" => "Rex Web Delopyment Console - Dashboard");
$t->text_is("#task_info tr:nth-child(2) td:nth-child(1)" => 1, "jobid ok");
$t->text_is("#task_info tr:nth-child(2) td:nth-child(2)" => 'uptime', "name ok");
$t->text_is("#task_info tr:nth-child(2) td:nth-child(3)" => '<local>', "server ok");
$t->text_is("#task_info tr:nth-child(2) td:nth-child(4)" => 'admin', "user ok");
$t->text_like("#task_info tr:nth-child(2) td:nth-child(5)" => qr/Starting|Running/, "status ok");

# There is some problem with threading: Can't create listen socket: Address already in use at /usr/local/share/perl/5.10.1/Mojo/IOLoop.pm line 147.
# But as long as I run a short task and have a small nap here, it seems to work out ok
sleep 3;

eval { $t->websocket_ok('/project/0/task/tail_ws/1'); };
warn "ERROR: $@" if $@;

$t->message_ok;
$t->message_like(qr/^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}] INFO - DONE\n$/);

$t->finish_ok();

#warn "CONTENT: " . $t->tx->res->body;

move($db_file_backup, $db_file) if -f $db_file_backup;



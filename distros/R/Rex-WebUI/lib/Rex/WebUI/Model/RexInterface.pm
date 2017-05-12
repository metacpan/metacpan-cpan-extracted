
package Rex::WebUI::Model::RexInterface;

use strict;

use Rex -base;

use Rex::Batch;
use Rex::Group;

use Data::Dumper;
use Try::Tiny;


sub new { bless {}, shift }

sub get_task
{
	my ($self, $task) = @_;

	my $tasklist = $self->get_tasklist;

	if ($tasklist->is_task("$task")) {

		warn "Loading task: $task";

		$task = {
			%{$tasklist->get_task($task)->get_data},
			name 		=> $task,
		};

		return $task;
	}
	else {

		warn "task '$task' not found";

		return undef;
	}
}

sub get_tasks
{
	my $self = shift;

	my $tasks;

	if ($tasks = $self->{tasks}) {

		$self->log->debug("Tasks already loaded");
	}
	else {

		my $tasklist = $self->get_tasklist;

		$tasks = [ $tasklist->get_tasks ];

		# get the task details for each - possibly more info we want here
		foreach my $task (@$tasks) {

			$task = {
				name 		=> $task,
				desc 		=> $tasklist->get_desc("$task") || $task,
			};
		}
	}

	return $tasks;
}

sub get_tasklist
{
	my $self = shift;

	if (my $tasklist = $self->{tasklist}) {

		return $tasklist;
	}
	else {

		$self->load_rexfile;

		my $tasklist = Rex::TaskList->create();

		return $self->{tasklist} = $tasklist;
	}
}

sub get_servers
{
	my $self = shift;

	my $servers = [];

	my $tasks = $self->get_tasks;

	# build a list of server names from the task list
	foreach my $task (@$tasks) {

		$task = $self->get_task($task->{name});

		my $task_servers = $task->{server};

		next unless $task_servers && scalar @$task_servers > 0;

		foreach my $server (@$task_servers) {
			push @$servers, $server->{name} unless $server->{name} ~~ $servers;
		}
	}

	# expand server list into hashrefs, adding info from db if available
	# TODO: add db interface
	foreach my $server (@$servers) {

		$server = { name => $server};
	}

	return $servers;
}

sub load_rexfile
{
	my ($self, $rexfile) = @_;

  	$rexfile = $self->{rexfile} || "SampleRexfile" unless $rexfile;


	$Rex::TaskList::task_list = {};
	$self->{tasks} = undef;
	delete $self->{tasks};

	$self->{tasklist} = undef;
	delete $self->{tasklist};

	# Is rexfile already loaded?
	if (exists $self->{rexfiles}->{$rexfile}) {

		warn "Rexfile already loaded: $rexfile, use tasklist from cache";
		$Rex::TaskList::task_list = $self->{rexfiles}->{$rexfile};

		$self->{rexfile} = $rexfile;

		return 1;
	}

	# workaround namespace issues - Rex::CLI is handled already for this issue
	if (defined _hacky_do_rexfile($rexfile)) {

		warn "Loaded Rexfile: $rexfile";

		$self->{rexfile} = $rexfile;

		$self->{rexfiles}->{$rexfile} = $Rex::TaskList::task_list;

		return 1;
	}
	else {

		warn "Error loading Rexfile: $rexfile - $@";

		return $self->{rexfile} = undef;
	}
}

sub _hacky_do_rexfile
{
	my $filename = shift;
	my $rexfile = eval { local(@ARGV, $/) = ($filename); <>; };
	eval "package Rex::CLI; use Rex -base; $rexfile";

	if($@) {
		die("Error loading Rexfile: $@");
	}

	return $rexfile;
}

# I'm getting a weird conflict with Rex::Commands::run_task so I'm renaming this to something more obscure
sub do_run_task
{
	my ($self, $task_name, $server_name, $temp_logfile) = @_;

	Rex::Config->set_log_filename($temp_logfile) if $temp_logfile;

	my $result;

	try {
		$result = Rex::Commands::run_task("$task_name", on => $server_name);

		Rex::Logger::info("DONE");

		return $result;
	}
	catch {
		Rex::Logger::info("Task Failed: $_", 'error');
		return undef;
	};
}

sub options
{
	my ($self, $opts) = @_;

	$Rex::Logger::debug = $opts->{debug} if exists $opts->{debug};
	$Rex::Cache::USE    = $opts->{cache} if exists $opts->{cache};
}


1;


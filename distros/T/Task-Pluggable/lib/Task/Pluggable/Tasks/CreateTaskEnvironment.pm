package Task::Pluggable::Tasks::CreateTaskEnvironment;
use base Task::Pluggable::AbstractTask;
__PACKAGE__->task_name('create_task_env');
__PACKAGE__->task_description('create task environment for current directory');
__PACKAGE__->mk_classdata('task_script_name'=>'ptm');


sub execute{
	my $self = shift;	
	$self->create_task_dir();
	$self->create_task_config();
	$self->create_task_script();
}	
sub create_task_dir{
	my $self = shift;
	my $pwd = $ENV{'PWD'};
	opendir my $fh ,$pwd;
	
	READDIR_LOOP:
	while(my $dir = readdir $fh){
		if($dir ne '.' and $dir ne '..'){
			print 'Current directory not empty '."\n";
			print 'Create dirctory yes or no? ';
			while(my $row =<STDIN>){
				chomp($row);
				if($row eq "yes" or $row eq "y"){
					last READDIR_LOOP;
				}
				elsif($row eq "no" or $row eq "n"){
					die "cancel create enviroment";	
				}
				print 'yes or no? ';
			}
		}
	}	
	close $fh;
	print "create task dirctory\n";
	$self->create_dir($pwd."/bin");	
	$self->create_dir($pwd."/config");
	$self->create_dir($pwd."/lib");
	$self->create_dir($pwd."/lib/Tasks");
}

sub get_pwd{
}

sub create_task_script{
	my $self = shift;
	my $perl_path = $ENV{_};
	my $pwd = $ENV{'PWD'};
	my $manager_name = 'Task::Pluggable::CommandLineTaskManager';

	my $script = "#!$perl_path\n";
	$script   .= 'use lib qw(/usr/beat/leport/lib /usr/beat/leport/site-perl '.$pwd."/lib);\n";
	$script   .= <<'__END_SCRIPT__';
use Task::Pluggable;
use YAML qw(LoadFile);
my $task  = new Task::Pluggable();
__END_SCRIPT__
	$script .= '$task->run(new '.$manager_name. '(LoadFile(\''.$pwd.'/config/config.yml'.'\')));';

	my $script_path = $pwd."/bin/".$self->task_script_name();
	print "create task script\n";
	print $script_path ."\n";

	open my $fh,">".$script_path or die $!;
	flock($fh,2) or die $!;
	print $fh $script;
	close $fh;
	chmod 0755 ,$script_path;
}

sub create_task_config{
	my $self = shift;
	my $perl_path = $ENV{_};
	my $pwd = $ENV{'PWD'};

	my $config = "home_dir: $pwd\n";
	$config   .= <<'__END_CONFIG__';
__END_CONFIG__

	my $config_path = $pwd."/config/config.yml";
	print "create task config\n";
	print $config_path ."\n";

	open my $fh,">".$config_path or die $!;
	flock($fh,2) or die $!;
	print $fh $config;
	close $fh;
}


sub create_dir{
	my $self = shift;
	my $path = shift;
	print $path."\n";
	mkdir $path;
}


1;

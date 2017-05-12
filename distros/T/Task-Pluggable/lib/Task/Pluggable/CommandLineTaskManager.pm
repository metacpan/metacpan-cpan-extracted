package Task::Pluggable::CommandLineTaskManager;
use strict;
use warnings;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
use base qw(Task::Pluggable::AbstractTaskManager);

sub load_args{
	my $self = shift;
	$self->task_name(shift @ARGV);
	$self->args(\@ARGV);
}

sub help{
	my $self = shift;
print <<__END_HELP_HEADER__;
Perl Task Manager
usage:
  ptm <task_name> <arg0> <arg1> ..
 
tasklist:

__END_HELP_HEADER__
	foreach my $task_name (sort{ $a cmp $b } keys %{$self->tasks}){
		print '  ';
		print BOLD GREEN sprintf('%-15s',$task_name);
		print '  ';
		print WHITE $self->tasks()->{$task_name}->task_description()."\n";
		if($self->tasks()->{$task_name}->task_args_description()){
			printf('  %-15s  ','');
			print sprintf('%-15s',$self->tasks()->{$task_name}->task_args_description())."\n";
		}
	}

print <<__END_HELP_FOOTER__;

__END_HELP_FOOTER__

}


1;

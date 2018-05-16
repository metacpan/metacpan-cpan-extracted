package TaskPipe::Tool::Command_ShowJobs;

use Moose;
use TaskPipe::JobManager;
use Carp;
use Text::Table::TinyColor 'generate_table';
use Term::ANSIColor;
extends 'TaskPipe::Tool::Command';


has job_manager => (is => 'ro', isa => 'TaskPipe::JobManager', lazy => 1, default  => sub{
    TaskPipe::JobManager->new(
        name => $_[0]->name,
        project => '*global',
        shell => 'foreground'
    );
});



sub execute{
    my $self = shift;

    $self->run_info->scope( 'global' );

    my @cols = qw(id name project pid shell orig_cmd created_dt);

    my $list = $self->job_manager->list_jobs( @cols );

    for my $i (0..$#cols){
        $cols[$i] = colored( $cols[$i], 'bright_blue' );
    }

    my $rows = [ \@cols, @$list ];
    print generate_table(rows => $rows, header_row => 1)."\n";

}


1;

=head1 NAME

TaskPipe::Tool::Command_ShowJobs - show currently running TaskPipe jobs

=head1 PURPOSE

Show a list of the currently executing TaskPipe jobs on the system

=head1 DESCRIPTION

C<show jobs> is useful when you have processes running in the background (i.e. you executed them using the C<--shell=background> parameter.)

To stop a TaskPipe process which is running in the background, you can use C<show jobs> to find the TaskPipe C<job_id> and use this in combination with C<stop job>

    taskpipe show jobs
    taskpipe stop job --job_id=<insert job id>

See the help for C<stop job> for more information.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


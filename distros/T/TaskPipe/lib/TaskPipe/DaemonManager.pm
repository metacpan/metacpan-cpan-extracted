package TaskPipe::DaemonManager;

use Moose;
use Carp;
use Proc::ProcessTable;

has name => (is => 'rw', isa => 'Str');
has orig_cmd => (is => 'rw', isa => 'ArrayRef');
has schema_manager => (is => 'rw', isa => 'TaskPipe::SchemaManager');

sub daemonize{
    my $self = shift;

    $self->clean_table;
    my $check_name = $self->schema_manager->table('daemon')->find({
        name => $self->name
    });

    confess "A daemon with name '".$self->name."' already exists" if $check_name;

    $self->fork_safely and exit;
    POSIX::setsid();
    $self->fork_safely and exit;

    umask 0;
    chdir '/';
    close STDIN;
    close STDOUT;
    close STDERR;

    $self->schema_manager->table('daemon')->create({
        name => $self->name,
        orig_cmd => "@{$self->orig_cmd}",
        pid => $$,
        created_dt => DateTime->now
    });
}



sub fork_safely{
    my $self = shift;

    my $pid = fork;
    confess "Fork failed" unless defined $pid;
    return $pid;
}


sub clean_table{
    my $self = shift;

    my $procs_rs = $self->schema_manager->table('daemon')->search;

    my $t = new Proc::ProcessTable;

    while( my $proc_row = $procs_rs->next ){

        my $active = 0;

        foreach my $p ( @{$t->table} ){   
            if ( $p->pid eq $proc_row->pid ){
                $active = 1;

                my @orig_cmd = split( /\s+/, $proc_row->orig_cmd );
                foreach my $arg ( @orig_cmd ){
                    $active = 0 unless $p->cmndline =~ /$arg/;
                }
            }
        }
        
        if ( ! $active ){
            $proc_row->delete;
        }

    }
}


sub stop_daemon{
    my $self = shift;

    $self->clean_table;
    
    my $proc_row = $self->schema_manager->table('daemon')->find({
        name => $self->name
    });


    confess "Unable to find an active process named '".$self->name."' - perhaps this process is already dead?" unless $proc_row;

    my $n_killed = kill 'KILL', $proc_row->pid;

    confess "Failed to kill process '".$self->name."' (pid=".$proc_row->pid.") for unknown reason" unless $n_killed;
    $proc_row->delete;

}


=head1 NAME

TaskPipe::DaemonManager - manage L<TaskPipe> background processes

=head1 DESCRIPTION

Using this module directly is not recommended. See the general manpages for TaskPipe

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
       

package TaskPipe::Role::RunInfo;

use Moose::Role;

has job_id => (is => 'rw', isa => 'Int');
has run_id => (is => 'rw', isa => 'Int');
has thread_id => (is => 'rw', isa => 'Int',default => 1);
has name => (is => 'rw', isa => 'Maybe[Str]', lazy => 1, default => sub{
    my $self = shift;
    my ($name) = ref($self) =~ /Task_(\w+)$/;
    return $name;
});


sub run_info{
    my $self = shift;

    my $info = '[';
    $info .= "J: ".$self->job_id." " if $self->can('job_id') && $self->job_id;
    $info .= "R: ".$self->run_id." " if $self->can('run_id') && $self->run_id;
    $info .= "P: $$ ";
    $info .= "T: ".$self->thread_id." " if $self->can('thread_id') && $self->thread_id;
    $info.= $self->name." " if $self->can('name') && $self->name;
    $info=~ s/\s+$//;
    $info.='] ';
    return $info;

} 


=head1 NAME

TaskPipe::Role::RunInfo

=head1 DESCRIPTION

A role to provide run information (run_id, thread_id etc.)

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;

package TaskPipe::RunInfo;

use Moose;
use MooseX::ClassAttribute;
use TaskPipe::Role::MooseType_ShellMode;
use TaskPipe::Role::MooseType_ScopeMode;

class_has scope => (is => 'rw', isa => 'ScopeMode', default => 'project');
class_has shell => (is => 'rw', isa => 'ShellMode', default => 'foreground');
class_has cmd => (is => 'rw', isa => 'ArrayRef');
class_has orig_cmd => (is => 'rw', isa => 'ArrayRef');
class_has job_id => (is => 'rw', isa => 'Int');
class_has run_id => (is => 'rw', isa => 'Int');
class_has thread_id => (is => 'rw', isa => 'Int',default => 1);
class_has task_name => (is => 'rw', isa => 'Str');

sub as_string{
    my ($self) = @_;

    my @out;
    foreach my $info_item ( qw(orig_cmd job_id run_id thread_id task_name) ){
        push @out, "$info_item: ".$self->$info_item;
    }
    return +join(' ',@out);
}
    

=head1 NAME

TaskPipe::RunInfo - information about the run (of the current plan)

=head1 DESCRIPTION

provides run information (job_id, thread_id etc.) for the current job/thread

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;

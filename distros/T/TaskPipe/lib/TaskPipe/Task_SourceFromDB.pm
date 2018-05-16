package TaskPipe::Task_SourceFromDB;

use Moose;
use TaskPipe::Iterator;
extends 'TaskPipe::Task';
with 'MooseX::ConfigCascade';


sub action{
    my ($self) = @_;

    my $search = $self->param->{search} || {};
    my $rs = $self->sm->schema->resultset($self->param->{table})->search($search);

    return +TaskPipe::Iterator->new(
        next => sub{ 
            return { +$rs->next->get_columns }; 
        },
        count => sub{ $rs->count },
        reset => sub{ $rs->reset }
    );
}


=head1 NAME

TaskPipe::Task_SourceFromDB - use a database table as the data source

=head1 DESCRIPTION

This task takes reads a database table and outputs the records one by one (via a L<TaskPipe::Iterator>). It is intended to be used as the first task in a plan. Each result that is produced from the iterator will be a hashref of column names against record values. You can specify it in the plan as follows:

    # (tree format):

    task:
        name: SourceFromDB
        table: mysourcetable 

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;    

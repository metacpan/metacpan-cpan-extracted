package TaskPipe::Task_Record_Array;

use Moose;
use Log::Log4perl;
use Data::Dumper;
extends 'TaskPipe::Task_Record';

sub action{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    $self->set_dt;

    my $cols = $self->pinterp->{columns};
    confess "'columns' was not specified" unless $cols; 

    my $add_to_all = $self->pinterp->{add_to_all};
    confess "'add_to_all' was not specified. pinterp: ".Dumper( $self->pinterp ) unless $add_to_all;

    my $record;
    my $rows = $self->pinterp->{array};

    return [{}] unless $rows;
    confess "'array' should have been an arrayref, but was type '".ref($rows)."'" unless ref $rows eq ref [];

    foreach my $row (@$rows){

        my $to_record = { %$add_to_all };


        foreach my $name ( keys %$cols ){
            $to_record->{$name} = $row->{ $cols->{$name} };
        }

        $record = $self->record_row( $to_record );

    }

    if ( $record ){
        my $rec_hash = { $record->get_columns };
        delete $rec_hash->{modified_dt};
        delete $rec_hash->{created_dt};
        return [ $rec_hash ];
    } else {
        return [{}];
    }
}


=head1 NAME

TaskPipe::Task_Record_NameValuePairs - record a result set as a series of name/value pairs

=head1 DESCRIPTION

This task records a list of name value pairs onto a database table. You can use it in your plan by referring to it in the following format:

    task:
        _name: Record_NameValuePairs
        table: whois_kv
        key: 
            table_id: $this{id}
        columns:
            name: param
            value: value
        pairs: $this[1]{*}

In this example (which is shown as part of a C<tree> mode plan, C<key> indicates the foreign key value to go on the table. ie this value will be included on all records in the set passed to the task.

C<columns> tells the task the name of the key/value columns to insert parameter names/parameter values to. This defaults to C<name> and C<value> if not provided.

C<pairs> needs to point to the hashref of key/values you want to go onto the database table. This defaults to the set of inputs to the current task if not provided.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


1;
                        

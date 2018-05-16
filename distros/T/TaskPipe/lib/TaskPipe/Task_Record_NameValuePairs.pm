package TaskPipe::Task_Record_NameValuePairs;

use Moose;
extends 'TaskPipe::Task_Record';

sub action{
    my ($self) = @_;

    $self->set_dt;

    my $name_col = 'name';
    my $val_col = 'value';

    my $cols = $self->pinterp->{columns};
    if ( $cols ){
        $name_col = $cols->{name} if $cols->{name};
        $val_col = $cols->{val} if $cols->{val};
    }
    
    my $record;
    my $kvh = $self->pinterp->{pairs} || $self->input;

    foreach my $k (keys %$kvh){
        next if $self->pinterp->{key}{$k};

        my $to_record = {
            $name_col => $k,
            $val_col => +$kvh->{$k}
        };

        my $key = $self->pinterp->{key};
        if ( $key ){
            foreach my $k (keys %$key){
                $to_record->{ $k } = $key->{ $k };
            }
        }

        $record = $self->record_row( $to_record );

    }

    my $rec_hash = { $record->get_columns };

    return [ $rec_hash ];
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
                        

package TaskPipe::Task_Record;

use Moose;
use DateTime;
use Carp;
use TryCatch;
use Log::Log4perl;
extends 'TaskPipe::Task';

has dt => (is => 'rw', isa => 'DateTime');

sub set_dt{
    my ($self) = @_;
    $self->dt( DateTime->now );
}


sub action{
    my ($self) = @_;
    
    my $logger = Log::Log4perl->get_logger;

    my $table = $self->param->{table};

    confess $self->run_info.": Could not record - no table specified" unless $self->param->{table};

    $self->set_dt;

    my $record = $self->record_row( $self->pinterp->{'values'} );

    return [] unless $record;

    my $rec_hash = { $record->get_columns };

    delete $rec_hash->{modified_dt};
    delete $rec_hash->{created_dt};
#    my $mdt = $rec_hash->{modified_dt};
#    $rec_hash->{modified_dt} = $mdt->ymd.' '.$mdt->hms if $mdt;
#    my $cdt = $rec_hash->{created_dt};
#    $rec_hash->{created_dt} = $cdt->ymd.' '.$cdt->hms if $cdt;

    return [ $rec_hash ];

}


sub record_row{

    my ($self,$row) = @_;

    my $record;
    my $mode = $self->param->{mode};
    my $table = $self->sm->table( $self->param->{table}, 'plan' );

    if ( $mode && $mode eq 'insert' ){

        $record = $table->create({ 
            %$row,
            created_dt => $self->dt,
            modified_dt => $self->dt
        });

    } elsif ( $mode && $mode =~ /(find|new)/ ){

        my $found = $table->find( $row );
        $record = $found if $found and $mode eq 'find';

        if ( ! $found ){

            try {

                $record = $table->create({
                    %$row,
                    created_dt => $self->dt,
                    modified_dt => $self->dt
                });

            } catch ( DBIx::Error::IntegrityConstraintViolation $err ){

                $record = $table->find({
                    %$row
                }) if $mode eq 'find';

            }

        }

    } else {

        $record = $table->update_or_new({ 
            %$row,
        });

        if ( ! $record->in_storage ){

            try {

                $record->insert;
                $record->update({ created_dt => $self->dt });

            } catch ( DBIx::Error::IntegrityConstraintViolation $err ){

                $record = $table->update({ 
                    %$row,
                });

            }

        }

        $record->update({
            modified_dt => $self->dt
        });
    
    }


    return $record;

}


=head1 NAME

TaskPipe::Task_Record - record a record to the database

=head1 DESCRIPTION

TaskPipe::Task_Record extends TaskPipe::Task. It is the standard task which records a record to the database for TaskPipe. You specify can this task in your plan in the following way:

    # (tree format):

    task:
        _name: Record
        mode: insert
        values:
            column1: value1
            column2: value2

            # ...

C<mode> is optional. If C<mode> is omitted, records where the primary key exists will be updated, and will be inserted new otherwise (ie "update or create"). If C<mode> is C<insert> an error will be produced in the duplicate record situation.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut
 

__PACKAGE__->meta->make_immutable;
1;

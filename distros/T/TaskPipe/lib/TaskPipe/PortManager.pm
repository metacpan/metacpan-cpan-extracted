package TaskPipe::PortManager;

use Moose;
use Log::Log4perl;
use Net::EmptyPort;
use Try::Tiny;

has base_port => (is => 'rw', isa => 'Int');
has process_name => (is => 'rw', isa => 'Str');

has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager');
has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new
});


sub get_new_port_number{
    my $self = shift;

    my $err;
    my $port;
    my $base_port = $self->base_port;
    my $port_row;
    my $success = 0;

    while ( ! $success ){

        do {
            $port = Net::EmptyPort::empty_port( $base_port );
            $port_row = $self->gm->table('port')->find_or_new({ 
                port => $port,
            }, {
                key => 'primary'
            });
            $base_port = $port + 1;
        } while( $port_row->in_storage );

        try {

            $port_row->insert;
            $port_row->update({
                job_id => $self->run_info->job_id,
                thread_id => $self->run_info->thread_id,
                process_name => $self->process_name
            });
            $success = 1;

        } catch {

            $base_port = $port + 1;
            $success = 0;

        };    
    
    }

    return $port;
}


sub get_port{
    my ($self) = @_;

    my $port_row = $self->gm->table('port')->find({
        job_id => $self->run_info->job_id,
        process_name => $self->process_name,
        thread_id => $self->run_info->thread_id
    });

    return $port_row->port if $port_row;
    return +$self->get_new_port_number;
}




sub clear_ports{
    my ($self,$job_id) = @_;

    my $ports_rs = $self->gm->table('port')->search({
        job_id => $job_id
    })->delete_all;

}

=head1 NAME

TaskPipe::PortManager - manage ports for TaskPipe

=head1 DESCRIPTION

It is not recommended to use this module directly. See the general manpages for TaskPipe.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;

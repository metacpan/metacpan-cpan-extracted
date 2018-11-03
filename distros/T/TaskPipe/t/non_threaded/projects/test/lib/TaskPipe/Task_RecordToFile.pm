package TaskPipe::Task_RecordToFile;

use Moose;
extends 'TaskPipe::Task';
with 'MooseX::ConfigCascade';


has path_settings => (is => 'ro', isa => 'TaskPipe::PathSettings', default => sub{
    TaskPipe::PathSettings->new(
        scope => 'project'
    );
});
has ext => (is => 'ro', isa => 'Str', default => '.tpdb');


sub action{
    my ($self) = @_;

    my $path = $self->path_settings->path('log',$self->param->{table}.$self->ext);

    my $result = $self->utils->serialize( $self->pinterp->{values} );

    open my $fh, '>>', $path or die "Could not open $path: $!";
    print $fh $result;
    close $fh;
}

__PACKAGE__->meta->make_immutable;
1;

    
        
    

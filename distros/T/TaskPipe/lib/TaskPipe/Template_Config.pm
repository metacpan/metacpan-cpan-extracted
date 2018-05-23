package TaskPipe::Template_Config;

use Moose;
use YAML::XS 'Dump';
use TaskPipe::Tool::Options;
use Hash::Merge;
extends 'TaskPipe::Template';

has options => (is => 'rw', isa => 'TaskPipe::Tool::Options', default => sub{
    TaskPipe::Tool::Options->new;
});

has dir_label => (is => 'ro', isa => 'Str', default => 'conf');
has filename_label => (is => 'ro', isa => 'Str', default => 'conf');

sub deploy{
    my ($self) = @_;

    my @specs = @{$self->option_specs};
    for my $i ( 0..$#specs ){
        $specs[$i] = {module => $specs[$i]} if ref $specs[$i] eq ref '';
        $specs[$i]{section} = 'METHODS' unless $specs[$i]{section};
    }

    $self->options->add_specs( \@specs );
    $self->fine_tune if $self->can('adjustments') && $self->adjustments;

    $self->write_file( +Dump( $self->options->specs_by_module ) );
}


sub fine_tune{
    my ($self) = @_;

    my $merger = Hash::Merge->new('LEFT_PRECEDENT');

    $self->options->specs_by_module( $merger->merge(
        $self->adjustments,
        $self->options->specs_by_module
    ));
}


#    foreach my $module ( keys %{$self->adjustments} ){
#        foreach my $method ( keys %{$self->adjustments->{$module}} ){
#            $self->options->specs_by_module->{ $module }{ $method } = $new_val;

=head1 NAME

TaskPipe::Template_Config

=head1 DESCRIPTION

Inherit from this class to create a config file template (ie for deployment to the global config directory. See e.g. L<TaskPipe::Template_Config_Global> and L<TaskPipe::Template_Config_Project> for examples of how to do this

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;

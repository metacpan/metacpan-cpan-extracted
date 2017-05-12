package Sweet::File::Config;
use latest;
use Moose;

use Carp;
use MooseX::AttributeShortcuts;
use Sweet::HomeDir;
use YAML;
use namespace::autoclean;

extends 'Sweet::File';

sub _build_dir { Sweet::HomeDir->new }

has content => (
    is         => 'lazy',
    isa        => 'HashRef',
);

sub _build_content {
    my $self = shift;

    my $path = $self->path;

    my $content = YAML::LoadFile( $path )
       or croak "Cannot load YAML file $path\n";

    return $content;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Sweet::File::Config

=head1 INHERITANCE

L<Sweet::File>

=cut

=head1 ATTRIBUTES

=head2 content

=cut


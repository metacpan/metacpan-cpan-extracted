package Path::Dispatcher::Rule::Metadata;
use Any::Moose;
extends 'Path::Dispatcher::Rule';

has field => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has matcher => (
    is       => 'ro',
    isa      => 'Path::Dispatcher::Rule',
    required => 1,
);

sub _match {
    my $self = shift;
    my $path = shift;
    my $got = $path->get_metadata($self->field);

    # wow, offensive.. but powerful
    my $metadata_path = $path->clone_path($got);
    return unless $self->matcher->match($metadata_path);

    return {
        leftover => $path->path,
    };
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 NAME

Path::Dispatcher::Rule::Metadata - match path's metadata

=head1 SYNOPSIS

    my $path = Path::Dispatcher::Path->new(
        path => '/REST/Ticket'
        metadata => {
            http_method => 'POST',
        },
    );

    my $rule = Path::Dispatcher::Rule::Metadata->new(
        field   => 'http_method',
        matcher => Path::Dispatcher::Rule::Eq->new(string => 'POST'),
    );

    $rule->run($path);

=head1 DESCRIPTION

Rules of this class match the metadata portion of a path.

=head1 ATTRIBUTES

=head2 field

The metadata field/key name.

=head2 matcher

A L<Path::Dispatcher::Rule> object for matching against the value of the field.

=cut


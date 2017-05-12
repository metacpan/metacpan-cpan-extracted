package Path::Dispatcher::Rule::Empty;
use Any::Moose;
extends 'Path::Dispatcher::Rule';

sub _match {
    my $self = shift;
    my $path = shift;
    return if length $path->path;
    return { leftover => $path->path };
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 NAME

Path::Dispatcher::Rule::Empty - matches only the empty path

=head1 DESCRIPTION

Rules of this class match only the empty path.

=cut


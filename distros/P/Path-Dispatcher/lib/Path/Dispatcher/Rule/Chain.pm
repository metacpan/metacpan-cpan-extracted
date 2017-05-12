package Path::Dispatcher::Rule::Chain;
use Any::Moose;
extends 'Path::Dispatcher::Rule::Always';

override payload => sub {
    my $self    = shift;
    my $payload = super;

    if (!@_) {
        return sub {
            $payload->(@_);
            die "Path::Dispatcher next rule\n"; # FIXME From Path::Dispatcher::Declarative... maybe this should go in a common place?
        };
    }

    return $payload;
};

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;


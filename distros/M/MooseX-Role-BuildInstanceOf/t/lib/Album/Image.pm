package Album::Image; {

    use Moose;

    sub supported_mime_types { qw{image/gif image/jpeg image/png} }

    has height => (
        is => 'ro',
        isa => 'Int',
        required => 1,
        default => 42,
    );

    has width => (
        is => 'ro',
        isa => 'Int',
        required => 1,
        default => 23,
    );

    with "Album::Role::Resource";
}

1;

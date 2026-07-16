package PAGI::Middleware::Session::Store;
$PAGI::Middleware::Session::Store::VERSION = '0.002002';
use strict;
use warnings;

=encoding UTF-8

=head1 NAME

PAGI::Middleware::Session::Store - Base class for async session storage

=head1 SYNOPSIS

    package My::Store;
    use parent 'PAGI::Middleware::Session::Store';
    use Future;

    sub get {
        my ($self, $id) = @_;
        # Return Future resolving to hashref or undef
    }

    sub set {
        my ($self, $id, $data) = @_;
        # Return Future resolving to the transport value
    }

    sub delete {
        my ($self, $id) = @_;
        # Return Future resolving to 1
    }

=head1 DESCRIPTION

PAGI::Middleware::Session::Store defines the async interface for session
storage backends. All methods return L<Future> objects so that storage
operations can be asynchronous (e.g. Redis, database).

Subclasses must implement C<get>, C<set>, and C<delete>.

=head1 METHODS

=head2 new

    my $store = PAGI::Middleware::Session::Store->new(%options);

Create a new store instance.

=cut

sub new {
    my ($class, %options) = @_;

    return bless { %options }, $class;
}

=head2 get

    my $future = $store->get($id);

Retrieve session data for the given ID. Returns a Future that resolves
to a hashref of session data, or undef if no session exists for that ID.
Subclasses must implement this.

=cut

sub get {
    my ($self, $id) = @_;

    die ref($self) . " must implement get()";
}

=head2 set

    my $future = $store->set($id, $data);

Store session data for the given ID. Returns a Future that resolves to
the B<transport value> — the opaque token the session middleware hands to
the State handler to send to the client. For server-side stores this is the
session ID (unchanged from the C<$id> argument); for cookie stores it is the
encoded session blob. Subclasses must implement this.

=cut

sub set {
    my ($self, $id, $data) = @_;

    die ref($self) . " must implement set()";
}

=head2 delete

    my $future = $store->delete($id);

Remove session data for the given ID. Returns a Future that resolves to 1
on success. Subclasses must implement this.

=cut

sub delete {
    my ($self, $id) = @_;

    die ref($self) . " must implement delete()";
}

1;

__END__

=head1 SEE ALSO

L<PAGI::Middleware::Session::Store::Memory> - In-memory session store

L<PAGI::Middleware::Session> - Session management middleware

=cut

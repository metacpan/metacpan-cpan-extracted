package Mojolicious::Sessions::Store::Backend;
$Mojolicious::Sessions::Store::Backend::VERSION = '0.01';
# ABSTRACT: Backend interface for Mojolicious::Sessions::Store

use Mojo::Base -base, -signatures;

sub load ($self, $session_id) {
    die "Method 'load' must be implemented by backend";
}

sub save ($self, $session_id, $data) {
    die "Method 'save' must be implemented by backend";
}

sub delete ($self, $session_id) {
    die "Method 'delete' must be implemented by backend";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Sessions::Store::Backend - Backend interface for Mojolicious::Sessions::Store

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class defines the interface that all backends must implement for
L<Mojolicious::Sessions::Store>.

Backends provide persistent storage for session data. The session data
is a plain hashref (serialized to JSON by the backend).

=head1 NAME

Mojolicious::Sessions::Store::Backend - Backend interface for session storage

=head1 REQUIRED METHODS

=head2 load

    my $data = $backend->load($session_id);

Load session data for the given session ID. Returns a hashref on success,
C<undef> if the session does not exist or has expired.

=head2 save

    $backend->save($session_id, $data);

Save session data for the given session ID. C<$data> is a hashref.
The backend is responsible for serialization (typically JSON).

=head2 delete

    $backend->delete($session_id);

Delete the session data for the given session ID.

=head1 SEE ALSO

L<Mojolicious::Sessions::Store>,
L<Mojolicious::Sessions::Store::Backend::File>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

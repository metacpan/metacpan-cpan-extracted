package Mojolicious::Plugin::ContextAuth::Auth;

# ABSTRACT: Auth class for Mojolicious::Plugin::ContextAuth

use Mojo::Base -base, -signatures;

use Mojolicious::Plugin::ContextAuth::DB;

has session_id => sub { '' };
has 'db';

sub login ($self, $user_id, $password) {
    my $session_id = $self->db->login( $user_id, $password );
    $self->session_id( $session_id );

    return $session_id;
}

sub user_from_session ($self, $session_id) {
    return $self->db->user_from_session( $session_id );
}

sub has_permission ( $self, $session_id, %param ) {
    my $user = $self->db->user_from_session( $session_id );

    my $context_id = $param{context_id};
    if ( $param{context} ) {
        my $context = $self->db->get_by_name('context', $param{context});
        $context_id = $context->context_id;
    }

    my $permission_id = $param{permission_id};
    if ( $param{permission} ) {
        my $permission = $self->db->get_by_name('permission', $param{permission});
        $permission_id = $permission->permission_id;
    }

    return $user->has_permission(
        context_id    => $context_id,
        permission_id => $permission_id,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ContextAuth::Auth - Auth class for Mojolicious::Plugin::ContextAuth

=head1 VERSION

version 0.01

=head1 SYNOPSIS

=head1 METHODS

=head2 login

=head2 user_from_session

=head2 has_permission

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

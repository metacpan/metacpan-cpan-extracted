package MojoX::Session::Simple;
use 5.010001;
use Mojo::Base 'Mojolicious::Sessions';
our $VERSION = "0.06";

sub load {
    my ($self, $c) = @_;
    my $session = $c->req->env->{'psgix.session'};
    $c->stash->{'mojo.session'} = $session;

    ## "expiration" value is inherited
    my $expiration = $session->{expiration} // $self->default_expiration;

    my $remove_session = sub { delete @$session{ keys %$session } };

    $remove_session->() and return
        if !(my $expires = delete $session->{expires}) && $expiration;
    $remove_session->() and return
        if defined $expires && $expires <= time;

    my $stash = $c->stash;
    $remove_session->() and return
        unless $stash->{'mojo.active_session'} = keys %$session;
    $session->{flash} = delete $session->{new_flash} if $session->{new_flash};
}

sub store {
    my ($self, $c) = @_;
    my $env = $c->req->env;

    # Make sure session was active
    my $stash = $c->stash;
    return unless my $session = $stash->{'mojo.session'};
    return unless keys %$session || $stash->{'mojo.active_session'};

    # Don't reset flash for static files
    my $old = delete $session->{flash};
    $session->{new_flash} = $old if $stash->{'mojo.static'};
    delete $session->{new_flash} unless keys %{ $session->{new_flash} };

    # Generate "expires" value from "expiration" if necessary
    my $expiration = $session->{expiration} // $self->default_expiration;
    my $default = delete $session->{expires};
    $session->{expires} = $default || time + $expiration
        if $expiration || $default;

    my $regenerate = delete $session->{regenerate};
    delete $session->{flash} if exists $session->{flash};

    if (defined($session->{expires}) && $session->{expires} <= time) {
        $env->{'psgix.session.options'}{expire} = 1;
    }
    elsif ($regenerate) {
        $env->{'psgix.session.options'}{change_id} = 1;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

MojoX::Session::Simple - Plack::Middleware::Session::Simple adapter for Mojolicious

=head1 SYNOPSIS

    use MojoX::Session::Simple;

    # Replace default session manager
    $mojo_app->sessions(
        MojoX::Session::Simple->new({
            default_expiration => 24 * 60 * 60, # 24 hours
        })
    );

    # In app.psgi, build mojo app to enable Plack::Middleware::Session::Simple.
    use Plack::Builder;

    build {
        enable 'Session::Simple',
            store => Cache::Memcached::Fast->new( ... ),
            cookie_name => 'my-test-app-session';

        $mojo_app->start;
    };

=head1 DESCRIPTION

MojoX::Session::Simple provides compatibility to your L<Mojolicious> app to
transparently use L<Plack::Middleware::Session::Simple> for session management
with no, or little, changes to existing controllers.

=head1 ATTRIBUTES

L<MojoX::Session::Simple> uses the following attributes implemented to L<Mojolicious::Sessions>.

=head2 default_expiration

For details, see L<Mojolicious::Sessions>.

=head1 METHODS

=head2 load

Load session data from C<$env-E<gt>{'psgix.session'}> into C<$c-E<gt>stash-E<gt>{'mojo.session'}>.
Session data will be deleted if the session is expired.

=head2 store

Store session data from C<$c-E<gt>stash-E<gt>{'mojo.session'}> into C<$env-E<gt>{'psgix.session'}>.
You may regenerate session ID by setting the following flag in session data:

=over 4

=item * regenerate

L<MojoX::Session::Simple> sets C<$env-E<gt>{'psgix.option'}{change_id} = 1> when:

    $c->session({ regenerate => 1 });

=back

=head1 LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yowcow@cpan.orgE<gt>

=cut


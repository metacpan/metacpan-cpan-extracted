# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
package Mojolicious::Plugin::PgURLHelper;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::URL;

our $VERSION = '0.03';

sub register {
    my ($self, $app) = @_;

    $app->helper(pg_url => \&_pg_url);
}

sub _pg_url {
    my $c = shift;
    my $s = shift;

    ## Check that we have all what we need
    my $croak = 0;
    if (!defined($s->{host})) {
        $c->app->log->error('Missing host parameter.');
        $croak++;
    }
    if (!defined($s->{database})) {
        $c->app->log->error('Missing database parameter.');
        $croak++;
    }
    if ($s->{user} && index($s->{user}, ':') != -1) {
        $c->app->log->error('You can\'t have a colon in the user name.');
        $croak++;
    }
    return undef if ($croak);

    ## Let's go
    my $addr  = Mojo::URL->new
                    ->scheme('postgresql')
                    ->host($s->{host})
                    ->path('/'.$s->{database});
    $addr->port($s->{port}) if defined $s->{port};
    my $user = (defined $s->{user}) ? $s->{user} : '';
    my $pwd  = (defined $s->{pwd}) ? $s->{pwd} : '';
    $addr->userinfo($user.':'.$pwd) if ($user && $pwd);
    return $addr->to_unsafe_string;
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::PgURLHelper - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('PgURLHelper');

  # Mojolicious::Lite
  plugin 'PgURLHelper';

  # Use the helper
  my $pg_url = $self->pg_url({host => 'localhost', database => 'foo', user => 'bar', pwd => 'baz'});
  my $pg = Mojo::Pg->new($pg_url);
  $self->plugin('Minion', {Pg => $pg_url});

=head1 DESCRIPTION

L<Mojolicious::Plugin::PgURLHelper> is a L<Mojolicious> plugin to easily create PostgreSQL URLs suitable for Mojo::Pg or Minion::Backend::Pg.

=head1 HELPERS

=head2 pg_url

  my $pg_url = $self->pg_url({host => 'localhost', database => 'foo', user => 'bar', pwd => 'baz'});

Arguments:

=over 1

=item host : string, PostgreSQL host, MANDATORY

=item database : string, name of the database, MANDATORY

=item port : integer, PostgreSQL port, optional, no default

=item user : string, username for the connection, can't contain a colon (:), optional, no default

=item pwd : string, password for the connection, optional, no default

=back

Returns a connection string suitable for Mojo::Pg or Minion::Backend::Pg on success.

Returns undef on failure. The reason of the failure is printed in Mojolicious log, severity: error.

Note that if you specify a user, you must specify a password, and vice versa.

=head1 METHODS

L<Mojolicious::Plugin::PgURLHelper> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 BUGS and SUPPORT

The latest source code can be browsed and fetched at:

  https://framagit.org/luc/mojolicious-plugin-pgurlhelper
  git clone https://framagit.org/luc/mojolicious-plugin-pgurlhelper.git

Bugs and feature requests will be tracked at:

  https://framagit.org/luc/mojolicious-plugin-pgurlhelper/issues

=head1 AUTHOR

  Luc DIDRY
  CPAN ID: LDIDRY
  ldidry@cpan.org
  https://fiat-tux.fr/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut

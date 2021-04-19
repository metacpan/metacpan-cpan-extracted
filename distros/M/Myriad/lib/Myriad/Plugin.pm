package Myriad::Plugin;

use Myriad::Class;

our $VERSION = '0.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=head1 NAME

Myriad::Plugin

=head1 DESCRIPTION

The plugin system allows sharing of various features between service implementations.
Examples might include database or API access.

Plugins will be loaded automatically if an as-yet-unknown attribute is used.

For example, a hypothetical C<< async method example : Reverse() { } >> service method
definition would attempt to use the registered C<Reverse> handler, and if none was found
would proceed to load C<< Myriad::Plugin::Reverse >> and try again.

=cut

# Normal access is through this singleton, but we do allow
# separate instances in unit tests. Note that this is the top-level
# Myriad::Plugin instance only, and does not affect the subclass
# instances.
our $REGISTRY = __PACKAGE__->new;

has $plugin;

=head1 METHODS

=cut

=head2 register

Example:

 has $db;
 register SQL => async method ($code, %args) {
  return sub ($srv, @args) {
   my ($sql, @bind) = $srv->$code(@args);
   return $db->query(
    $sql => @bind
   )->row_hashrefs
  }
 };

=cut

async method register ($attr, $code) {
    $log->tracef('Registering plugin %s for %s', $code, $attr);
    die 'already have ' . $attr if exists $plugin->{$attr};
    $plugin->{$attr} = $code;
}

async method apply_to_service ($srv, $method, $attr) {
    $log->tracef('Applying plugin for %s to %s on %s', $attr, $method, $srv);
}

sub import {
    my ($called_on, %args) = @_;
    return undef unless $called_on eq __PACKAGE__;
    my $pkg = caller(0);
    my $meta = Myriad::Class->import(target => $pkg);
    no strict 'refs';
    *{$pkg . '::register'} = sub ($attr, $code) {
        $REGISTRY->register($attr, $code);
    }
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.


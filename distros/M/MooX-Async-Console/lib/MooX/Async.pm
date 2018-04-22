package MooX::Async;

our $VERSION = '0.006';
$VERSION = eval $VERSION;

=head1 NAME

MooX::IOAsync - BovIinate Oout :of: ASsync

=head1 SYNOPSIS

    package Thing;
    use Moo;
    use MooX::Async;

    # Extend an IO::Async module with MooX::Async:
    extends MooXAsync('Notifier');

    # Define a lazy attribute which will hold a callback subref with
    # an (optional) default implementation.
    event on_foo => sub { say "foo" };

=head1 DESCRIPTION

Allows a L<Moo> class to extend a L<IO::Async::Notifier> subclass with
the L<MooX::Async> role and the magic necessary to make
L<IO::Async::Notifier> work as a L<Moo> object.

=head1 BUGS

Certainly.

=cut

use Modern::Perl '2017';
use strictures 2;
use Moo (); # For _install_tracked
use Moo::Role; # For me
use Module::Runtime qw(compose_module_name module_notional_filename);
use namespace::clean;

sub import {
  my $pkg = caller;
  my $has = $pkg->can('has') or return;
  Moo::_install_tracked $pkg, event => sub {
    my $event = shift;
    my $sub = @_ % 2 ? pop : sub { die "$event event unimplemented" };
    $has->($event, @_, is => lazy => builder => sub { $sub });
  };
  Moo::_install_tracked $pkg, MooXAsync => \&MooXAsync;
}

=head1 EXPORTS

L</MooXAsync> and L</event> are exported unconditionally.

=over

=item event($name, [@args], [$subref]) => void

Install a lazy attribute to handle the event C<$name>. This is basically just:

    has $event => (@args, builder => sub { $subref });

=item MooXAsync($notifier) => $async_moo_class

Creates and returns the name of a class which extends C<$notifier>,
which can be an object or the name of a class which subclasses
L<IO::Async::Notifier> with L<Moo> and L<MooX::Async>.

Prepends C<IO::Async::> to C<$notifier> if it doesn't contain
C<::>. If C<$notifier> begins with C<::> then it is removed.

If C<$notifier> is an object then it is re-blessed into the new
package.

=back

=cut

sub MooXAsync {
  my $notifier = shift;
  # Ensure DOES('IO::Async::Notifier') and DOESN'T MooX::Async
  my $class = ref $notifier || $notifier; # Those who bless into '0' deserve what they get
  my $parent = $class =~ /^IO::Async::/ ? $class : compose_module_name('IO::Async', $class);
  my $pkg = $parent . '::' . __PACKAGE__;
  no strict 'refs';
  # This is ugly but I'm lazy.
  if (not scalar keys %{"$pkg\::"}) {
    eval <<"TOP" . <<'BOTTOM' or die; # Keep interpolated part seperate
      package $pkg;
      use Moo;
      extends '$parent';
TOP
      sub configure_unknown {  }
      sub FOREIGNBUILDARGS { shift; @_ }
      around can_event => sub {
        my ($orig, $self, $event) = @_;
        return $self->$event if $self->can("_build_$event");
        $self->$orig($event);
      };
      1;
BOTTOM
    $INC{module_notional_filename($pkg)} = 1;
  }
  bless $notifier, $pkg if ref $notifier; # Any extra mooification?
  return $pkg;
}

use namespace::clean qw(MooXAsync);

1;

=back

=head1 HISTORY

=over

=item MooX::Async 0.004

Have I got it right yet?

=back

=head1 SEE ALSO

L<Moo>

L<IO::Async>

=head1 AUTHOR

Matthew King <chohag@jtan.com>

=cut

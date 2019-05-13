package Starch::Role::Log;
our $VERSION = '0.14';

=encoding utf8

=head1 NAME

Starch::Role::Log - Logging capabilities used internally by Starch.

=cut

use Log::Any;
use Types::Standard -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

=head1 ATTRIBUTES

=head2 log

Returns a L<Log::Any::Proxy> object used for logging to L<Log::Any>.
The category is set to the object's package name, minus any
C<__WITH__.*> bits that Moo::Role adds when composing a class
from roles.

No logging is produced by the stock L<Starch>.  The
L<Starch::Plugin::Trace> plugin adds extensive logging.

More info about logging can be found at
L<Starch/LOGGING>.

=cut

has log => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_log {
    my ($self) = @_;

    return Log::Any->get_logger(
        category => $self->base_class_name(),
    );
}

=head2 base_class_name

Returns the object's class name minus the C<__WITH__.*> suffix put on
by plugins.  This is used to produce more concise logging output.

=cut

sub base_class_name {
    my ($self) = @_;
    my $class = ref( $self );
    $class =~ s{__WITH__.*$}{};
    return $class;
}

=head2 short_class_name

Returns L</base_class_name> with the C<Starch::> prefix
removed.

=cut

sub short_class_name {
    my ($self) = @_;
    my $class = $self->base_class_name();
    $class =~ s{^Starch::}{};
    return $class;
}

1;
__END__

=head1 SUPPORT

See L<Starch/SUPPORT>.

=head1 AUTHORS

See L<Starch/AUTHORS>.

=head1 COPYRIGHT AND LICENSE

See L<Starch/COPYRIGHT AND LICENSE>.

=cut


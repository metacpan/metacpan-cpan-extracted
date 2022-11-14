package Myriad::Util::Defer;

use Myriad::Class type => 'role';

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Util::Defer - provide a deferred wrapper attribute

=head1 DESCRIPTION

This is used to make an async method delay processing until later.

It can be controlled by the C<MYRIAD_RANDOM_DELAY> environment variable,
and defaults to no delay.

=cut

use Attribute::Handlers;
use Class::Method::Modifiers;

use constant RANDOM_DELAY => $ENV{MYRIAD_RANDOM_DELAY} || 0;

use Sub::Util;
sub MODIFY_CODE_ATTRIBUTES ($class, $code, @attrs) {
    my $name = Sub::Util::subname($code);
    my ($method_name) = $name =~ m{::([^:]+)$};
    for my $attr (@attrs) {
        if($attr eq 'Defer') {
            $class->defer_method($method_name, $name);
        } else {
            die 'unknown attribute ' . $attr;
        }
    }
    return;
}

# Helper method that allows us to return a not-quite-immediate
# Future from some inherently non-async code.
sub defer_method ($package, $name, $fqdn) {
    $log->tracef('will defer handler for %s::%s by %f', $package, $name, RANDOM_DELAY);
    my $code = $package->can($name);
    my $replacement = async sub ($self, @args) {
        # effectively $loop->later, but in an await-compatible way:
        # either zero (default behaviour) or if we have a random
        # delay assigned, use that to drive a uniform rand() call
        $log->tracef('call to %s::%s, deferring start', $package, $name);
        await $self->loop->delay_future(
            after => rand(RANDOM_DELAY)
        );

        $log->tracef('deferred call to %s::%s runs now', $package, $name);

        return await $self->$code(
            @args
        );
    };
    {
        no strict 'refs';
        no warnings 'redefine';
        *{join '::', $package, $name} = $replacement if RANDOM_DELAY;
    }
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.


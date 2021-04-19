package Myriad::Util::Defer;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;

no indirect qw(fatal);

=encoding utf8

=head1 NAME

Myriad::Util::Defer - provide a deferred wrapper attribute

=head1 DESCRIPTION

This is used to make an async method delay processing until later.

It can be controlled by the C<MYRIAD_RANDOM_DELAY> environment variable,
and defaults to no delay.

=cut

use Future::AsyncAwait;
use Attribute::Handlers;
use Class::Method::Modifiers;

use Exporter qw(import export_to_level);
use Log::Any qw($log);

our @IMPORT = our @IMPORT_OK = qw(Defer);

use constant RANDOM_DELAY => $ENV{MYRIAD_RANDOM_DELAY} || 0;

# Helper method that allows us to return a not-quite-immediate
# Future from some inherently non-async code.
sub Defer : ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;
    my $name = *{$symbol}{NAME} or die 'need a symbol name';
    $log->tracef('will defer handler for %s::%s', $package, $name);
    around join('::', $package, $name) => async sub {
        my ($code, $self, @args) = @_;

        # effectively $loop->later, but in an await-compatible way:
        # either zero (default behaviour) or if we have a random
        # delay assigned, use that to drive a uniform rand() call
        await $self->loop->delay_future(
            after => rand(RANDOM_DELAY)
        );

        $log->tracef('deferred call to %s::%s', $package, $name);

        return await $self->$code(
            @args
        );
    } if RANDOM_DELAY;
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.


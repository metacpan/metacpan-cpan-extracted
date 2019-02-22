package Starch::Plugin::LogStoreExceptions;
use 5.008001;
use strictures 2;
our $VERSION = '0.11';

=head1 NAME

Starch::Plugin::LogStoreExceptions - Turn Starch store exceptions into log messages.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::LogStoreExceptions'],
        ...,
    );

=head1 DESCRIPTION

This plugin causes any exceptions thrown when C<set>, C<get>, or C<remove> is
called on a store to produce an error log message instead of an exception.

Typically you'll want to use this in production, as the state store being
down is often not enough of a reason to produce 500 errors on every page.

This plugin should be listed last in the plugin list so that it catches
exceptions produced by other plugins.

=cut

use Try::Tiny;

use Moo::Role;
use namespace::clean;

with qw(
    Starch::Plugin::ForStore
);

foreach my $method (qw( set get remove )) {
    around $method => sub{
        my $orig = shift;
        my $self = shift;

        my @args = @_;

        return try {
            return $self->$orig( @args );
        }
        catch {
            $self->log->errorf(
                'Starch store %s errored when %s was called: %s',
                $self->short_store_class_name(), $method, $_,
            );
            return {
                $self->manager->no_store_state_key() => 1,
            } if $method eq 'get';
            return;
        };
    };
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut


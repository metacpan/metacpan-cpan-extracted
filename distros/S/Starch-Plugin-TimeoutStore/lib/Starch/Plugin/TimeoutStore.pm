package Starch::Plugin::TimeoutStore;
use 5.010001;
use strictures 2;
our $VERSION = '0.09';

=head1 NAME

Starch::Plugin::TimeoutStore - Throw an exception if store access surpasses a timeout.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::TimeoutStore'],
        store => {
            class => '::Memory',
            timeout => 0.1, # 1/10th of a second
        },
        ...,
    );

=head1 DESCRIPTION

This plugin causes all calls to C<set>, C<get>, and C<remove> to throw
an exception if they surpass a timeout period.

The timeout is implemented using L<Sys::SigAction>.

Note that some stores implement timeouts themselves and their native
may be better than this naive implementation.

The whole point of detecting timeouts is so that you can still serve
a web page even if the underlying store backend is failing, so
using this plugin with L<Starch::Plugin::LogStoreExceptions> is
probably a good idea.

=cut

use Types::Common::Numeric -types;
use Starch::Util qw( croak );
use Sys::SigAction qw( timeout_call );

use Moo::Role;
use namespace::clean;

with 'Starch::Plugin::ForStore';

=head1 OPTIONAL STORE ARGUMENTS

These arguments are added to classes which consume the
L<Starch::Store> role.

=head2 timeout

How many seconds to timeout.  Fractional seconds may be passed, but
may not be supported on all systems (see L<Sys::SigAction/ABSTRACT>).
Set to C<0> to disable timeout checking.  Defaults to C<0>.

=cut

has timeout => (
    is      => 'ro',
    isa     => PositiveOrZeroNum,
    default => 0,
);

foreach my $method (qw( set get remove )) {
    around $method => sub{
        my $orig = shift;
        my $self = shift;

        my $timeout = $self->timeout();
        return $self->$orig( @_ ) if $timeout == 0;

        my @args = @_;
        my $data;

        if ( timeout_call( $timeout, sub{
            $data = $self->$orig( @args );
        }) ) {
            croak sprintf(
                'The %s method %s exceeded the timeout of %s seconds',
                $self->short_class_name(), $method, $timeout,
            );
        }

        return $data if $method eq 'get';
        return;
    };
}

1;
__END__

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package Stancer::Role::Payment::Auth;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Payment authentication relative role
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(coerce_instance AuthInstance DeviceInstance Maybe);

use Stancer::Auth;
use Stancer::Auth::Status;
use Stancer::Device;
use Stancer::Exceptions::InvalidIpAddress;
use Stancer::Exceptions::InvalidPort;
use Scalar::Util qw(blessed);
use Try::Tiny;

use Moo::Role;

requires qw(_add_modified _attribute_builder);

use namespace::clean;


has auth => (
    is => 'rw',
    isa => Maybe[AuthInstance],
    builder => sub { $_[0]->_attribute_builder('auth') },
    coerce => sub {
        return if not defined $_[0];
        return if "$_[0]" eq q/0/ || "$_[0]" eq q//;
        return $_[0] if blessed($_[0]) and blessed($_[0]) eq 'Stancer::Auth';
        return Stancer::Auth->new() if "$_[0]" eq q/1/;
        return Stancer::Auth->new(status => $_[0]) if $_[0] eq Stancer::Auth::Status::ATTEMPTED;
        return Stancer::Auth->new(status => $_[0]) if $_[0] eq Stancer::Auth::Status::AVAILABLE;
        return Stancer::Auth->new(status => $_[0]) if $_[0] eq Stancer::Auth::Status::DECLINED;
        return Stancer::Auth->new(status => $_[0]) if $_[0] eq Stancer::Auth::Status::EXPIRED;
        return Stancer::Auth->new(status => $_[0]) if $_[0] eq Stancer::Auth::Status::FAILED;
        return Stancer::Auth->new(status => $_[0]) if $_[0] eq Stancer::Auth::Status::REQUESTED;
        return Stancer::Auth->new(status => $_[0]) if $_[0] eq Stancer::Auth::Status::SUCCESS;
        return Stancer::Auth->new(status => $_[0]) if $_[0] eq Stancer::Auth::Status::UNAVAILABLE;
        return Stancer::Auth->new(return_url => $_[0]) if ref(\$_[0]) eq 'SCALAR';
        return Stancer::Auth->new($_[0]);
    },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('auth') },
);


has device => (
    is => 'rw',
    isa => Maybe[DeviceInstance],
    builder => sub { $_[0]->_attribute_builder('device') },
    coerce => coerce_instance('Stancer::Device'),
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('device') },
);

sub _create_device {
    my $this = shift;

    return $this unless defined $this->method;

    if (defined $this->device) {
        $this->device->hydrate_from_env();

        return $this;
    }

    my $device = Stancer::Device->new();

    if (defined $this->auth and defined $this->auth->return_url) {
        $device->hydrate_from_env();
        $this->device($device);
    } else {
        try {
            $device->hydrate_from_env();
            $this->device($device);
        };
    }

    return $this;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Role::Payment::Auth - Payment authentication relative role

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<auth>

Read/Write instance of C<Stancer::Auth>.

May accept a boolean if you use our payment page or a HTTPS url as an alias for `Stancer::Auth::return_url`.

=head2 C<device>

Read/Write instance of C<Stancer::Device>.

Information about device fulfuling the payment.

C<Stancer::Device> needs IP address and port to work, it will automatically used environment
variables as created by Apache or nginx (aka C<SERVER_ADDR> and C<SERVER_PORT>).

If variables are not available or if you are using a proxy, you must give IP and port at object instanciation.

    $payment->device(ip => $ip, port => $port);

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Role::Payment::Auth;

You must import C<Log::Any::Adapter> before our libraries, to initialize the logger instance before use.

You can choose your log level on import directly:
    use Log::Any::Adapter (File => '/var/log/payment.log', log_level => 'info');

Read the L<Log::Any> documentation to know what other options you have.

=cut

=head1 SECURITY

=over

=item *

Never, never, NEVER register a card or a bank account number in your database.

=item *

Always uses HTTPS in card/SEPA in communication.

=item *

Our API will never give you a complete card/SEPA number, only the last four digits.
If you need to keep track, use these last four digit.

=back

=cut

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://gitlab.com/wearestancer/library/lib-perl/-/issues> or by email to
L<bug-stancer@rt.cpan.org|mailto:bug-stancer@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Joel Da Silva <jdasilva@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2024 by Stancer / Iliad78.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

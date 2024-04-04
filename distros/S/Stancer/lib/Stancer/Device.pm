package Stancer::Device;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Device representation
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(:network Maybe Str);

use Moo;

extends 'Stancer::Core::Object';

use namespace::clean;

has '+_integer' => (
    default => sub{ [qw(port)] },
);


has city => (
    is => 'rw',
    isa => Maybe[Str],
    builder => sub { $_[0]->_attribute_builder('country') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('city') },
);


has country => (
    is => 'rw',
    isa => Maybe[Str],
    builder => sub { $_[0]->_attribute_builder('country') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('country') },
);


has http_accept => (
    is => 'rw',
    isa => Maybe[Str],
    trigger => sub { $_[0]->_add_modified('http_accept') },
);


has ip => (
    is => 'rw',
    isa => Maybe[IpAddress],
    coerce => sub {
        return if not defined $_[0];
        return if $_[0] eq '1';
        return if $_[0] eq q//;
        return $_[0];
    },
    trigger => sub { $_[0]->_add_modified('ip') },
);


has languages => (
    is => 'rw',
    isa => Maybe[Str],
    trigger => sub { $_[0]->_add_modified('languages') },
);


has port => (
    is => 'rw',
    isa => Maybe[Port],
    coerce => sub {
        return if not defined $_[0];
        return if $_[0] eq q//;
        return $_[0];
    },
    trigger => sub { $_[0]->_add_modified('port') },
);


has user_agent => (
    is => 'rw',
    isa => Maybe[Str],
    trigger => sub { $_[0]->_add_modified('user_agent') },
);


sub hydrate_from_env {
    my $this = shift;

    $this->http_accept($ENV{HTTP_ACCEPT}) if defined $ENV{HTTP_ACCEPT} and not defined $this->http_accept;
    $this->ip($ENV{SERVER_ADDR}) if defined $ENV{SERVER_ADDR} and not defined $this->ip;
    $this->languages($ENV{HTTP_ACCEPT_LANGUAGE}) if defined $ENV{HTTP_ACCEPT_LANGUAGE} and not defined $this->languages;
    $this->port($ENV{SERVER_PORT}) if defined $ENV{SERVER_PORT} and not defined $this->port;
    $this->user_agent($ENV{HTTP_USER_AGENT}) if defined $ENV{HTTP_USER_AGENT} and not defined $this->user_agent;

    Stancer::Exceptions::InvalidIpAddress->throw() if not defined $this->ip;
    Stancer::Exceptions::InvalidPort->throw() if not defined $this->port;

    return $this;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Device - Device representation

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<city>

Read/Write string.

Customer's city.

=head2 C<country>

Read/Write string.

Customer's country.

=head2 C<http_accept>

Read/Write string.

Customer's browser acceptance.

=head2 C<ip>

Read/write IP address.

Customer's IP address.

May be an IPv4 (aka 212.27.48.10) or an IPv6 (2a01:e0c:1::1).

=head2 C<languages>

Read/Write string.

Customer's browser accepted languages.

=head2 C<port>

Read/Write integer.

Customer's port.

=head2 C<user_agent>

Read/Write string.

Customer's browser user agent.

=head1 METHODS

=head2 C<< Stancer::Device->new() : I<self> >>

=head2 C<< Stancer::Device->new(I<%args>) : I<self> >>

=head2 C<< Stancer::Device->new(I<\%args>) : I<self> >>

You may not need to create yourself a device instance, it will automatically be created for you.

    # Get an empty new device
    my $new = Stancer::Device->new();

This object needs a valid IP address (IPv4 or IPv6) ans a valid port, it will automatically used environment
variables as created by Apache or nginx (aka C<SERVER_ADDR> and C<SERVER_PORT>).

If variables are not available or if you are using a proxy, you must give IP and port at object instanciation.

    my $device = Stancer::Device->new(ip => $ip, port => $port);

=head2 C<< Stancer::Device->hydrate_from_env() : I<self> >>

Hydrate frpm environment.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Device;

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

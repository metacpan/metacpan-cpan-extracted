package Stancer::Customer;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Customer representation
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(Email ExternalId Maybe Mobile);

use Stancer::Exceptions::BadMethodCall;

use Moo;

extends 'Stancer::Core::Object';
with 'Stancer::Role::Name';

use namespace::clean;

has '+endpoint' => (
    default => 'customers',
);


has email => (
    is => 'rw',
    isa => Maybe[Email],
    builder => sub { $_[0]->_attribute_builder('email') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('email') },
);


has external_id => (
    is => 'rw',
    isa => Maybe[ExternalId],
    builder => sub { $_[0]->_attribute_builder('external_id') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('external_id') },
);


has mobile => (
    is => 'rw',
    isa => Maybe[Mobile],
    builder => sub { $_[0]->_attribute_builder('mobile') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('mobile') },
);


around send => sub {
    my ($orig, $this, $values) = @_;

    if (!$this->has_id && !$this->has_email && !$this->has_mobile) {
        my $message = 'You must provide an email or a phone number to create a customer.';

        Stancer::Exceptions::BadMethodCall->throw(message => $message);
    }

    return $this->$orig($values);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Customer - Customer representation

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<email>

Read/Write 5 to 64 characters.

Customer email

=head2 C<external_id>

Read/Write 36 characters maximum string.

External for the API, you can store your customer's identifier here.

=head2 C<mobile>

Read/Write 8 to 16 characters.

Customer mobile phone number

=head2 C<name>

Read/Write 4 to 64 characters.

Customer name

=head1 METHODS

=head2 C<< Stancer::Customer->new() : I<self> >>

=head2 C<< Stancer::Customer->new(I<$token>) : I<self> >>

=head2 C<< Stancer::Customer->new(I<%args>) : I<self> >>

=head2 C<< Stancer::Customer->new(I<\%args>) : I<self> >>

This method accept an optional string, it will be used as an entity ID for API calls.

    # Get an empty new customer
    my $new = Stancer::Customer->new();

    # Get an existing customer
    my $exist = Stancer::Customer->new($token);

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Customer;

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

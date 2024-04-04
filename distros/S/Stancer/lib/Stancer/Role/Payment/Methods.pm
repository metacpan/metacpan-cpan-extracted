package Stancer::Role::Payment::Methods;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Payment's methods relative role
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(coerce_instance ArrayRef CardInstance Enum Maybe SepaInstance Str);
use List::MoreUtils qw(any);

use Moo::Role;

requires qw(_add_modified _attribute_builder _set_method);

use namespace::clean;


has card => (
    is => 'rw',
    isa => Maybe[CardInstance],
    builder => sub { $_[0]->_attribute_builder('card') },
    coerce => coerce_instance('Stancer::Card'),
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('card')->_set_method('card') },
);


has method => (
    is => 'rwp',
    isa => Maybe[Str],
    builder => sub { $_[0]->_attribute_builder('method') },
    lazy => 1,
    predicate => 1,
);


has methods_allowed => (
    is => 'rw',
    isa => Maybe[ArrayRef[Enum['card', 'sepa']]],
    builder => sub { $_[0]->_attribute_builder('methods_allowed') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('methods_allowed') },
);

around methods_allowed => sub {
    my ($orig, $class, $args) = @_;

    return $class->$orig unless defined $args;

    $args = [$args] if ref $args eq q//;

    if (
            (not $class->_process_hydratation)
        && defined $class->currency
        && $class->currency ne 'eur'
        && any { $_ eq 'sepa' } @{$args}
    ) {
        my $message = sprintf 'You can not ask for "%s" with "%s" currency.', (
            'sepa',
            uc $class->currency,
        );

        Stancer::Exceptions::InvalidMethod->throw(message => $message);
    }

    return $class->$orig($args);
};


has sepa => (
    is => 'rw',
    isa => Maybe[SepaInstance],
    builder => sub { $_[0]->_attribute_builder('sepa') },
    coerce => coerce_instance('Stancer::Sepa'),
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('sepa')->_set_method('sepa') },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Role::Payment::Methods - Payment's methods relative role

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<card>

Read/Write instance of C<Stancer::Card>.

Target card for the payment.

=head2 C<method>

Read-only string, should be "card" or "sepa".

Payment method used.

=head2 C<methods_allowed>

Read/Write arrayref of string.

List of methods allowed to be used on payment page.

You can pass a C<string> or an C<arrayref> of C<string>, we will always return an C<arrayref> of C<string>.

=head2 C<sepa>

Read/Write instance of C<Stancer::Sepa>.

Target sepa account for the payment.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Role::Payment::Methods;

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

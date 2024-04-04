package Stancer::Card;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Card representation
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(coerce_boolean Bool CardNumber CardVerificationCode Char Maybe Month Str Year);

use Stancer::Exceptions::InvalidExpirationMonth;
use Stancer::Exceptions::InvalidExpirationYear;
use List::MoreUtils qw(any);

use Moo;

extends 'Stancer::Core::Object';
with 'Stancer::Role::Country', 'Stancer::Role::Name';

use namespace::clean;

has '+_boolean' => (
    default => sub{ [qw(tokenize)] },
);

has '+endpoint' => (
    default => 'cards',
);

has '+_integer' => (
    default => sub{ [qw(exp_month exp_year)] },
);

has '+_json_ignore' => (
    default => sub{ [qw(endpoint created populated brand country last4)] },
);


has brand => (
    is => 'rwp',
    isa => Maybe[Str],
    builder => sub { $_[0]->_attribute_builder('brand') },
    lazy => 1,
    predicate => 1,
);


my %names = (
    amex => 'American Express',
    dankort => 'Dankort',
    discover => 'Discover',
    jcb => 'JCB',
    maestro => 'Maestro',
    mastercard => 'MasterCard',
    visa => 'VISA',
);

sub brandname {
    my $this = shift;
    my $brand = $this->brand;

    return undef if not defined $brand;
    return $names{$brand} if any { $_ eq $brand } keys %names;
    return $brand;
}


has cvc => (
    is => 'rw',
    isa => Maybe[CardVerificationCode],
    builder => sub { $_[0]->_attribute_builder('cvc') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('cvc') },
);


sub expiration {
    my $this = shift;
    my $year = $this->exp_year;
    my $month = $this->exp_month;
    my $message = 'You must set an expiration %s before asking for a date.';

    Stancer::Exceptions::InvalidExpirationMonth->throw(message => sprintf $message, 'month') if not defined $month;
    Stancer::Exceptions::InvalidExpirationYear->throw(message => sprintf $message, 'year') if not defined $year;

    return DateTime->last_day_of_month(year => $year, month => $month);
}


has exp_month => (
    is => 'rw',
    isa => Maybe[Month],
    builder => sub { $_[0]->_attribute_builder('exp_month') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('exp_month') },
);


has exp_year => (
    is => 'rw',
    isa => Maybe[Year],
    builder => sub { $_[0]->_attribute_builder('exp_year') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('exp_year') },
);


has funding => (
    is => 'rwp',
    isa => Maybe[Str],
    builder => sub { $_[0]->_attribute_builder('funding') },
    lazy => 1,
    predicate => 1,
);


has last4 => (
    is => 'rwp',
    isa => Maybe[Char[4]],
    builder => sub { $_[0]->_attribute_builder('last4') },
    lazy => 1,
    predicate => 1,
);


has nature => (
    is => 'rwp',
    isa => Maybe[Str],
    builder => sub { $_[0]->_attribute_builder('nature') },
    lazy => 1,
    predicate => 1,
);


has network => (
    is => 'rwp',
    isa => Maybe[Str],
    builder => sub { $_[0]->_attribute_builder('network') },
    lazy => 1,
    predicate => 1,
);


has number => (
    is => 'rw',
    isa => Maybe[CardNumber],
    predicate => 1,
    trigger => sub {
        my $this = shift;
        my $number = shift;
        my $last4 = substr $number, -4;

        $this->_add_modified('number');
        $this->_set_last4($last4);
    },
);


has tokenize => (
    is => 'rw',
    isa => Maybe[Bool],
    builder => sub { $_[0]->_attribute_builder('tokenize') },
    coerce => coerce_boolean(),
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('tokenize') },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Card - Card representation

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<brand>

Read-only string.

Card brand name

=head2 C<brandname>

Read-only string.

Card real brand name.

Whereas C<brand> returns brand as a simple normalized string like "amex",
C<brandname> will return a complete and real brand name, like "American Express".

=head2 C<country>

Read-only string.

Card country

=head2 C<cvc>

Read/Write 3 characters string.

Card verification code

=head2 C<expiration>

Read-only C<DateTime>.

Expiration date as a C<DateTime> object.

=head2 C<exp_month>

Read/Write integer.

Expiration month

=head2 C<exp_year>

Read/Write integer.

Expiration year

=head2 C<funding>

Read-only string or undefined.

Type of funding

Should be one of "credit", "debit", "prepaid", "universal", "charge", "deferred".
May be undefined when the type could not be determined.

=head2 C<last4>

Read-only 4 characters string.

Last four card number

=head2 C<name>

Read/Write 4 to 64 characters string.

Card holder's name

=head2 C<nature>

Read-only string or undefined.

Nature of the card

Should be "personnal" or "corporate".
May be undefined when the nature could not be determined.

=head2 C<network>

Read-only string or undefined.

Nature of the card

Should be "mastercard", "national" or "visa".
May be undefined when the network could not be determined.

=head2 C<number>

Read/Write 16 to 19 characters string.

Card number

=head2 C<tokenize>

Read/Write boolean.

Save card for later use

=head1 METHODS

=head2 C<< Stancer::Card->new() : I<self> >>

=head2 C<< Stancer::Card->new(I<$token>) : I<self> >>

=head2 C<< Stancer::Card->new(I<%args>) : I<self> >>

=head2 C<< Stancer::Card->new(I<\%args>) : I<self> >>

This method accept an optional string, it will be used as an entity ID for API calls.

    # Get an empty new card
    my $new = Stancer::Card->new();

    # Get an existing card
    my $exist = Stancer::Card->new($token);

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Card;

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

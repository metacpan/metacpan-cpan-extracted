package Net::Stripe::Card;
$Net::Stripe::Card::VERSION = '0.33';
use Moose;
use Moose::Util::TypeConstraints qw(union);
use Kavorka;
use Net::Stripe::Token;

# ABSTRACT: represent a Card object from Stripe

# Input fields
has 'number'          => (is => 'ro', isa => 'Maybe[Str]');
has 'cvc'             => (is => 'ro', isa => 'Maybe[Int]');
has 'name'            => (is => 'ro', isa => 'Maybe[Str]');
has 'address_line1'   => (is => 'ro', isa => 'Maybe[Str]');
has 'address_line2'   => (is => 'ro', isa => 'Maybe[Str]');
has 'address_zip'     => (is => 'ro', isa => 'Maybe[Str]');
has 'address_state'   => (is => 'ro', isa => 'Maybe[Str]');
has 'address_country' => (is => 'ro', isa => 'Maybe[Str]');

# Both input and output
has 'exp_month'       => (is => 'ro', isa => 'Maybe[Int]', required => 1);
has 'exp_year'        => (is => 'ro', isa => 'Maybe[Int]', required => 1);

# Output fields
has 'id'                   => (is => 'ro', isa => 'Maybe[Str]');
has 'address_line_1_check' => (is => 'ro', isa => 'Maybe[Str]');
has 'address_zip_check'    => (is => 'ro', isa => 'Maybe[Str]');
has 'country'              => (is => 'ro', isa => 'Maybe[Str]');
has 'cvc_check'            => (is => 'ro', isa => 'Maybe[Str]');
has 'fingerprint'          => (is => 'ro', isa => 'Maybe[Str]');
has 'last4'                => (is => 'ro', isa => 'Maybe[Str]');
has 'brand'                => (is => 'ro', isa => 'Maybe[Str]');  # formerly 'type'

method form_fields {
    return (
        map { ("card[$_]" => $self->$_) }
            grep { defined $self->$_ }
                qw/number cvc name address_line1 address_line2 address_zip
                   address_state address_country exp_month exp_year/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Card - represent a Card object from Stripe

=head1 VERSION

version 0.33

=head1 ATTRIBUTES

=head2 address_country

Reader: address_country

Type: Maybe[Str]

=head2 address_line1

Reader: address_line1

Type: Maybe[Str]

=head2 address_line2

Reader: address_line2

Type: Maybe[Str]

=head2 address_line_1_check

Reader: address_line_1_check

Type: Maybe[Str]

=head2 address_state

Reader: address_state

Type: Maybe[Str]

=head2 address_zip

Reader: address_zip

Type: Maybe[Str]

=head2 address_zip_check

Reader: address_zip_check

Type: Maybe[Str]

=head2 brand

Reader: brand

Type: Maybe[Str]

=head2 country

Reader: country

Type: Maybe[Str]

=head2 cvc

Reader: cvc

Type: Maybe[Int]

=head2 cvc_check

Reader: cvc_check

Type: Maybe[Str]

=head2 exp_month

Reader: exp_month

Type: Maybe[Int]

This attribute is required.

=head2 exp_year

Reader: exp_year

Type: Maybe[Int]

This attribute is required.

=head2 fingerprint

Reader: fingerprint

Type: Maybe[Str]

=head2 id

Reader: id

Type: Maybe[Str]

=head2 last4

Reader: last4

Type: Maybe[Str]

=head2 name

Reader: name

Type: Maybe[Str]

=head2 number

Reader: number

Type: Maybe[Str]

=head1 AUTHORS

=over 4

=item *

Luke Closs

=item *

Rusty Conover

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Prime Radiant, Inc., (c) copyright 2014 Lucky Dinosaur LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

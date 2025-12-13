package Net::Stripe::Coupon;
$Net::Stripe::Coupon::VERSION = '0.43';
use Moose;
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent a Coupon object from Stripe

has 'id'                 => (is => 'rw', isa => 'Maybe[Str]');
has 'percent_off'        => (is => 'rw', isa => 'Maybe[Int]', required => 1);
has 'duration'           => (is => 'rw', isa => 'Maybe[Str]', required => 1);
has 'duration_in_months' => (is => 'rw', isa => 'Maybe[Int]');
has 'max_redemptions'    => (is => 'rw', isa => 'Maybe[Int]');
has 'redeem_by'          => (is => 'rw', isa => 'Maybe[Int]');
has 'metadata'           => (is => 'ro', isa => 'Maybe[HashRef]');

method form_fields {
    return $self->form_fields_for(
        qw/id percent_off duration duration_in_months max_redemptions redeem_by
            metadata/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Coupon - represent a Coupon object from Stripe

=head1 VERSION

version 0.43

=head1 ATTRIBUTES

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 duration

Reader: duration

Writer: duration

Type: Maybe[Str]

This attribute is required.

=head2 duration_in_months

Reader: duration_in_months

Writer: duration_in_months

Type: Maybe[Int]

=head2 id

Reader: id

Writer: id

Type: Maybe[Str]

=head2 max_redemptions

Reader: max_redemptions

Writer: max_redemptions

Type: Maybe[Int]

=head2 metadata

Reader: metadata

Type: Maybe[HashRef]

=head2 percent_off

Reader: percent_off

Writer: percent_off

Type: Maybe[Int]

This attribute is required.

=head2 redeem_by

Reader: redeem_by

Writer: redeem_by

Type: Maybe[Int]

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

package Net::Stripe::Discount;
$Net::Stripe::Discount::VERSION = '0.39';
use Moose;
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent a Discount object from Stripe

has 'coupon' => (is => 'rw', isa => 'Maybe[Net::Stripe::Coupon]');
has 'start' => (is => 'rw', isa => 'Maybe[Int]');

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Discount - represent a Discount object from Stripe

=head1 VERSION

version 0.39

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

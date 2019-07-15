package Net::Stripe::LineItem;
$Net::Stripe::LineItem::VERSION = '0.37';
use Moose;

# ABSTRACT: represent an Line Item object from Stripe

has 'id'                => (is => 'ro', isa => 'Maybe[Str]');
has 'livemode'          => (is => 'ro', isa => 'Maybe[Bool]');
has 'amount'            => (is => 'ro', isa => 'Maybe[Int]');
has 'currency'          => (is => 'ro', isa => 'Maybe[Str]');
has 'period'            => (is => 'ro', isa => 'Maybe[HashRef]');
has 'proration'         => (is => 'ro', isa => 'Maybe[Bool]');
has 'type'              => (is => 'ro', isa => 'Maybe[Str]');
has 'description'       => (is => 'ro', isa => 'Maybe[Str]');
has 'metadata'          => (is => 'ro', isa => 'Maybe[HashRef]');
has 'plan'              => (is => 'ro', isa => 'Maybe[Net::Stripe::Plan]');
has 'quantity'          => (is => 'ro', isa => 'Maybe[Int]');

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::LineItem - represent an Line Item object from Stripe

=head1 VERSION

version 0.37

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

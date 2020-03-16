package Net::Stripe::Token;
$Net::Stripe::Token::VERSION = '0.42';
use Moose;
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent a Token object from Stripe

# Args for creating a Token
has 'card'        => (is => 'ro', isa => 'Maybe[Net::Stripe::Card]', required => 1);
has 'amount'      => (is => 'ro', isa => 'Maybe[Int]');
has 'currency'    => (is => 'ro', isa => 'Maybe[Str]');

# Args returned by the API
has 'id'          => (is => 'ro', isa => 'Maybe[Str]');
has 'created'     => (is => 'ro', isa => 'Maybe[Int]');
has 'used'        => (is => 'ro', isa => 'Maybe[Bool|Object]');
has 'livemode'    => (is => 'ro', isa => 'Maybe[Bool|Object]');
has 'type'        => (is => 'ro', isa => 'Maybe[Str]');
has 'client_ip'   => (is => 'ro', isa => 'Maybe[Str]');

method form_fields {
    return $self->form_fields_for(
        qw/amount currency card/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Token - represent a Token object from Stripe

=head1 VERSION

version 0.42

=head1 ATTRIBUTES

=head2 amount

Reader: amount

Type: Maybe[Int]

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 card

Reader: card

Type: Maybe[Net::Stripe::Card]

This attribute is required.

=head2 client_ip

Reader: client_ip

Type: Maybe[Str]

=head2 created

Reader: created

Type: Maybe[Int]

=head2 currency

Reader: currency

Type: Maybe[Str]

=head2 id

Reader: id

Type: Maybe[Str]

=head2 livemode

Reader: livemode

Type: Maybe[Bool|Object]

=head2 type

Reader: type

Type: Maybe[Str]

=head2 used

Reader: used

Type: Maybe[Bool|Object]

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

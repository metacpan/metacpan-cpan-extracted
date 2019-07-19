package Net::Stripe::Card;
$Net::Stripe::Card::VERSION = '0.39';
use Moose;
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
has 'address_city'    => (is => 'ro', isa => 'Maybe[Str]');
has 'address_state'   => (is => 'ro', isa => 'Maybe[Str]');
has 'address_country' => (is => 'ro', isa => 'Maybe[Str]');
has 'metadata'        => (is => 'rw', isa => 'Maybe[HashRef]');

# Both input and output
has 'exp_month'       => (is => 'ro', isa => 'Maybe[Int]', required => 1);
has 'exp_year'        => (is => 'ro', isa => 'Maybe[Int]', required => 1);

# Output fields
has 'id'                   => (is => 'ro', isa => 'Maybe[Str]');
has 'address_line1_check'  => (is => 'ro', isa => 'Maybe[Str]');
has 'address_zip_check'    => (is => 'ro', isa => 'Maybe[Str]');
has 'country'              => (is => 'ro', isa => 'Maybe[Str]');
has 'cvc_check'            => (is => 'ro', isa => 'Maybe[Str]');
has 'fingerprint'          => (is => 'ro', isa => 'Maybe[Str]');
has 'last4'                => (is => 'ro', isa => 'Maybe[Str]');
has 'brand'                => (is => 'ro', isa => 'Maybe[Str]');  # formerly 'type'

method form_fields_for_card_metadata {
    my $metadata = $self->metadata();
    my @metadata = ();
    while( my($k,$v) = each(%$metadata) ) {
      push @metadata, 'card[metadata]['.$k.']';
      push @metadata, $v;
    }
    return @metadata;
}

method form_fields {
    return (
        $self->form_fields_for_card_metadata(),
        map { ("card[$_]" => $self->$_) }
            grep { defined $self->$_ }
                qw/number cvc name address_line1 address_line2 address_zip
                   address_city address_state address_country exp_month exp_year/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Card - represent a Card object from Stripe

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

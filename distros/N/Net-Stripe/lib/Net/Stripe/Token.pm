package Net::Stripe::Token;
$Net::Stripe::Token::VERSION = '0.39';
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

method form_fields {
    return (
        (defined $self->card ? $self->card->form_fields : () ),
        map { $_ => $self->$_ }
            grep { defined $self->$_ }
                qw/amount currency/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Token - represent a Token object from Stripe

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

package Net::Stripe::List;
$Net::Stripe::List::VERSION = '0.39';
use Moose;
use Kavorka;

# ABSTRACT: represent a list of objects from Stripe

has 'count'    => (is => 'ro', isa => 'Maybe[Int]'); # no longer included by default, see note below
has 'url'      => (is => 'ro', isa => 'Str', required => 1);
has 'has_more' => (is => 'ro', isa => 'Bool|Object', required => 1);
has 'data'     => (traits => ['Array'],
                   is => 'ro',
                   isa => 'ArrayRef',
                   required => 1,
                   handles => {
                       elements => 'elements',
                       map => 'map',
                       grep => 'grep',
                       first => 'first',
                       get => 'get',
                       join => 'join',
                       is_empty => 'is_empty',
                       sort => 'sort',
                   });

method last {
    return $self->get(scalar($self->elements)-1);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::List - represent a list of objects from Stripe

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

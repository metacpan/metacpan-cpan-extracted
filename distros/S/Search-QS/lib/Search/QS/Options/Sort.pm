package Search::QS::Options::Sort;
$Search::QS::Options::Sort::VERSION = '0.01';
use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

# ABSTRACT: A sort element


enum 'direction_types', [qw( asc desc )];

has name => ( is => 'rw', isa => 'Str');
has direction => ( is => 'rw', isa => 'direction_types', default => 'asc');

sub to_qs() {
    my $s   = shift;

    return 'sort[' . $s->name . ']=' . $s->direction;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::QS::Options::Sort - A sort element

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This object incapsulate a single sort item.

=head1 METHODS

=head2 name()

The field to sort

=head2 direction()

The type of sort (asc|desc)

=head2 to_qs()

Return a query string of the internal rappresentation of the object

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

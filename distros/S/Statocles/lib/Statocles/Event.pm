package Statocles::Event;
our $VERSION = '0.098';
# ABSTRACT: Events objects for Statocles

#pod =head1 EVENTS
#pod
#pod =head2 Statocles::Event::Pages
#pod
#pod An event with L<page objects|Statocles::Page>.
#pod
#pod =cut

package Statocles::Event::Pages;

use Statocles::Base 'Class';
extends 'Beam::Event';

#pod =attr pages
#pod
#pod An array of L<Statocles::Page> objects
#pod
#pod =cut

has pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']],
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Event - Events objects for Statocles

=head1 VERSION

version 0.098

=head1 ATTRIBUTES

=head2 pages

An array of L<Statocles::Page> objects

=head1 EVENTS

=head2 Statocles::Event::Pages

An event with L<page objects|Statocles::Page>.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

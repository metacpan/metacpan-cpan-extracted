package Statocles::Link::Tree;
our $VERSION = '0.085';
# ABSTRACT: A link object with child links, making a tree

#pod =head1 SYNOPSIS
#pod
#pod     my $link = Statocles::Link::Tree->new(
#pod         href => '/',
#pod         text => 'Home',
#pod         children => [
#pod             {
#pod                 href => '/blog',
#pod                 text => 'Blog',
#pod             },
#pod             {
#pod                 href => '/projects',
#pod                 text => 'Projects',
#pod             },
#pod         ],
#pod     );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class represents a link which is allowed to have child links.
#pod This allows making trees of links for multi-level menus.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Statocles::Link>
#pod
#pod =cut

use Statocles::Base 'Class';
extends 'Statocles::Link';

#pod =attr children
#pod
#pod     $link->children([
#pod         # Object
#pod         Statocles::Link::Tree->new(
#pod             href => '/blog',
#pod             text => 'Blog',
#pod         ),
#pod
#pod         # Hashref of attributes
#pod         {
#pod             href => '/about',
#pod             text => 'About',
#pod         },
#pod
#pod         # URL only
#pod         'http://example.com',
#pod     ]);
#pod
#pod The children of this link. Should be an arrayref of
#pod C<Statocles::Link::Tree> objects, hashrefs of attributes for
#pod C<Statocles::Link::Tree> objects, or URLs which will be used as the
#pod C<href> attribute for a C<Statocles::Link::Tree> object.
#pod
#pod =cut

has children => (
    is => 'rw',
    isa => LinkTreeArray,
    coerce => LinkTreeArray->coercion,
    default => sub { [] },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Link::Tree - A link object with child links, making a tree

=head1 VERSION

version 0.085

=head1 SYNOPSIS

    my $link = Statocles::Link::Tree->new(
        href => '/',
        text => 'Home',
        children => [
            {
                href => '/blog',
                text => 'Blog',
            },
            {
                href => '/projects',
                text => 'Projects',
            },
        ],
    );

=head1 DESCRIPTION

This class represents a link which is allowed to have child links.
This allows making trees of links for multi-level menus.

=head1 ATTRIBUTES

=head2 children

    $link->children([
        # Object
        Statocles::Link::Tree->new(
            href => '/blog',
            text => 'Blog',
        ),

        # Hashref of attributes
        {
            href => '/about',
            text => 'About',
        },

        # URL only
        'http://example.com',
    ]);

The children of this link. Should be an arrayref of
C<Statocles::Link::Tree> objects, hashrefs of attributes for
C<Statocles::Link::Tree> objects, or URLs which will be used as the
C<href> attribute for a C<Statocles::Link::Tree> object.

=head1 SEE ALSO

L<Statocles::Link>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

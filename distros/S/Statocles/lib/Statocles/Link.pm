package Statocles::Link;
our $VERSION = '0.089';
# ABSTRACT: A link object to build <a> and <link> tags

use Statocles::Base 'Class';
use Scalar::Util qw( blessed );

#pod =attr href
#pod
#pod The URL location being linked to. Sets the C<href> attribute.
#pod
#pod =cut

has href => (
    is => 'rw',
    isa => Str,
    required => 1,
    coerce => sub {
        my ( $href ) = @_;
        if ( blessed $href && $href->isa( 'Mojo::Path' ) ) {
            return $href->to_abs_string;
        }
        return $href;
    },
);

#pod =attr text
#pod
#pod The text inside the link tag. Only useful for <a> links.
#pod
#pod =cut

has text => (
    is => 'ro',
    isa => Maybe[Str],
    lazy => 1,
    default => sub {
        # For ease of transition, let's default to title, which we used for the
        # text prior to this class.
        return $_[0]->title;
    },
);

#pod =attr title
#pod
#pod The title of the link. Sets the C<title> attribute.
#pod
#pod =cut

has title => (
    is => 'ro',
    isa => Str,
);

#pod =attr rel
#pod
#pod The relationship of the link. Sets the C<rel> attribute.
#pod
#pod =cut

has rel => (
    is => 'ro',
    isa => Str,
);

#pod =attr type
#pod
#pod The MIME type of the resource being linked to. Sets the C<type> attribute for C<link>
#pod tags.
#pod
#pod =cut

has type => (
    is => 'ro',
    isa => Str,
);

#pod =method new_from_element
#pod
#pod     my $link = Statocles::Link->new_from_element( $dom_elem );
#pod
#pod Construct a new Statocles::Link out of a Mojo::DOM element (either an <a> or a <link>).
#pod
#pod =cut

sub new_from_element {
    my ( $class, $elem ) = @_;
    return $class->new(
        ( map {; $_ => $elem->attr( $_ ) } grep { $elem->attr( $_ ) } qw( href title rel ) ),
        ( map {; $_ => $elem->$_ } qw( text ) ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Link - A link object to build <a> and <link> tags

=head1 VERSION

version 0.089

=head1 SYNOPSIS

    my $link = Statocles::Link->new( text => 'Foo', href => 'http://example.com' );
    say $link->href;
    say $link->text;

    say sprintf '<a href="%s">%s</a>', $link->href, $link->text;

=head1 DESCRIPTION

This object encapsulates a link (either an C<a> or C<link> tag in HTML). These objects
are friendly for templates and can provide some sanity checks.

=head1 ATTRIBUTES

=head2 href

The URL location being linked to. Sets the C<href> attribute.

=head2 text

The text inside the link tag. Only useful for <a> links.

=head2 title

The title of the link. Sets the C<title> attribute.

=head2 rel

The relationship of the link. Sets the C<rel> attribute.

=head2 type

The MIME type of the resource being linked to. Sets the C<type> attribute for C<link>
tags.

=head1 METHODS

=head2 new_from_element

    my $link = Statocles::Link->new_from_element( $dom_elem );

Construct a new Statocles::Link out of a Mojo::DOM element (either an <a> or a <link>).

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

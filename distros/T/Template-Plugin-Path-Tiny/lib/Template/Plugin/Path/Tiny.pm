package Template::Plugin::Path::Tiny;

# ABSTRACT: use Path::Tiny objects from within templates

use Moo;
extends qw/ Template::Plugin /;

use Path::Tiny;
use Types::Standard -types;

use namespace::autoclean;

our $VERSION = 'v0.1.0';

has context => (
    is       => 'ro',
    isa      => Object,
    weak_ref => 1,
);

sub BUILD {
    my ($self) = @_;

    $self->context->define_vmethod( scalar => as_path => \&path );

    $self->context->define_vmethod(
        list => as_path => sub { path( @{ $_[0] } ) } );

}

sub BUILDARGS {
    my ( $class, $context ) = @_;

    return { context => $context };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::Path::Tiny - use Path::Tiny objects from within templates

=head1 VERSION

version v0.1.0

=head1 SYNOPSIS

  [% USE Path::Tiny %]

  The file [% x.basename %] is in [% x.parent %].

=head1 DESCRIPTION

This plugin allows you to turn scalars and lists into L<Path::Tiny>
objects.

=head1 CAVEATS

Besides some simple filename manipulation, this plugin allows you to
perform file operations from within templates. While that may be
useful, it's probably a I<bad idea>.  Consider performing file
operations outside of the template and only using this for
manipulating path names instead.

=head1 SEE ALSO

L<Template>

L<Path::Tiny>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Template-Plugin-Path-Tiny>
and may be cloned from L<git://github.com/robrwo/Template-Plugin-Path-Tiny.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Template-Plugin-Path-Tiny/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

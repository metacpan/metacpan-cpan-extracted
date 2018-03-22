package Statocles::Page::Plain;
our $VERSION = '0.088';
# ABSTRACT: A plain page (with templates)

use Statocles::Base 'Class';
with 'Statocles::Page';

#pod =attr content
#pod
#pod The content of the page, already rendered to HTML.
#pod
#pod =cut

has _content => (
    is => 'ro',
    isa => Str,
    required => 1,
    init_arg => 'content',
);

#pod =method content
#pod
#pod     my $html = $page->content;
#pod
#pod Get the content for this page.
#pod
#pod =cut

sub content {
    return $_[0]->_content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Page::Plain - A plain page (with templates)

=head1 VERSION

version 0.088

=head1 SYNOPSIS

    my $page = Statocles::Page::Plain->new(
        path => '/path/to/page.html',
        content => '...',
    );

    my $js = Statocles::Page::Plain->new(
        path => '/js/app.js',
        content => '...',
    );

=head1 DESCRIPTION

This L<Statocles::Page> contains any content you want to put in it, while still
allowing for templates and layout. This is useful when you generate HTML (or
anything else) outside of Statocles.

=head1 ATTRIBUTES

=head2 content

The content of the page, already rendered to HTML.

=head1 METHODS

=head2 content

    my $html = $page->content;

Get the content for this page.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

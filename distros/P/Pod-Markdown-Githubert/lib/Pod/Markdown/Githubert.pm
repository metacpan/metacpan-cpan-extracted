package Pod::Markdown::Githubert;
use strict;
use warnings;

use Pod::Markdown ();
our @ISA = 'Pod::Markdown';

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(
        markdown_fragment_format => sub {
            my ($self, $str) = @_;
            $str =~ tr/A-Za-z0-9_\- //cd;
            $str =~ tr/A-Z /a-z-/;
            $str
        },
        @_
    );
    $self->accept_targets('highlighter', 'github-markdown');
    $self->{+__PACKAGE__} = {
        hl_language => '',
    };
    $self
}

sub format_perldoc_url {
    my $self = shift;
    my ($name, $section) = @_;
    my $prev_url_prefix;
    if (defined $name && $name =~ /\Aperl[a-z0-9]*\z/) {
        $prev_url_prefix = $self->perldoc_url_prefix;
        $self->perldoc_url_prefix('https://perldoc.perl.org/');
    }
    my $url = $self->SUPER::format_perldoc_url($name, $section);
    $self->perldoc_url_prefix($prev_url_prefix) if defined $prev_url_prefix;
    $url
}

sub start_for {
    my $self = shift;
    my ($attr) = @_;
    if ($attr->{target} eq 'highlighter') {
        $self->_new_stack;
        $self->_stack_state->{for_highlighter} = 1;
        return;
    }
    $self->SUPER::start_for(@_)
}

sub end_for {
    my $self = shift;
    my ($attr) = @_;
    if ($self->_stack_state->{for_highlighter}) {
        my $text = $self->_pop_stack_text;
        my %settings =
            map /\A([^=]*)=(.*)\z/s
                ? ($1 => $2)
                : (language => $_),
            split ' ', $text;
        $self->{+__PACKAGE__}{hl_language} = $settings{language} // '';
        return;
    }
    $self->SUPER::end_for(@_)
}

sub _indent_verbatim {
    my $self = shift;
    my ($paragraph) = @_;
    my $min_indent = 'inf';
    while ($paragraph =~ /^( +)/mg) {
        my $n = length $1;
        $min_indent = $n if $n < $min_indent;
    }
    my $rep =
        $min_indent < 'inf'
            ? "{$min_indent}"
            : '+';
    $paragraph =~ s/^ $rep//mg;
    my $fence = '```';
    while ($paragraph =~ /^ *\Q$fence\E *$/m) {
        $fence .= '`';
    }
    my $hl_language = $self->{+__PACKAGE__}{hl_language};
    if ($hl_language !~ /\A[^`\s]\S*\z/) {
        $hl_language = '';
    }
    "$fence$hl_language\n$paragraph\n$fence"
}

sub end_item_number {
    my $self = shift;
    if ($self->_last_string =~ /\S/) {
        return $self->SUPER::end_item_number(@_);
    }
    $self->_end_item($self->_private->{item_number} . '. <!-- -->');
}

1
__END__

=encoding utf8

=head1 NAME

Pod::Markdown::Githubert - convert POD to Github-flavored Markdown

=head1 SYNOPSIS

=for highlighter language=perl

    use Pod::Markdown::Githubert ();

    my $parser = Pod::Markdown::Githubert->new;
    $parser->output_string(\my $markdown);
    $parser->parse_string_document($pod_string);

    # see Pod::Markdown docs for the full API

=head1 DESCRIPTION

Pod::Markdown::Githubert is a module for converting documents in POD format
(see L<perlpod>) to Github-flavored Markdown. It is a subclass of
L<Pod::Markdown> (which see for API documentation) that adds the following
Github-specific enhancements and fixes:

=over

=item *

Internal links (of the form C<LE<lt>/fooE<gt>>) are converted to something that
hopefully matches how Github generates HTML ids for Markdown headings. In
short, internal links to a section of the current page should just work when
rendered on Github.

=item *

Github-specific Markdown code can be embedded literally using a
C<=for github-markdown> paragraph or
C<=begin github-markdown ... =end github-markdown> section.

In other words, if you want to render e.g. a badge, but only on Github, not all
Markdown renderers, put it in a C<=for github-markdown> paragraph.

=item *

External links to module documentation normally point to
L<https://metacpan.org/>. But that doesn't work for some of the manual pages
included with Perl because they are only generated when perl is built (such as
L<perlapi>), so this module redirects all C<perlXYZ> links to
L<https://perldoc.perl.org/>, which has the full set.

=item *

Verbatim paragraphs are translated to fenced code blocks (surrounded by
C<```>) with normalized indentation (meaning it doesn't matter whether the
paragraph is indented by 1 space, 4 spaces, or 23 spaces in the POD source; it
will generated the same Markdown).

=item *

Code blocks containing C<```> are rendered correctly, as are code blocks in
nested structures (such as list items) even when a numbered list item starts
with a code block.

=item *

Syntax highlighting can be enabled by tagging each code block with its
language. As this module translates a POD document, it keeps a global "current
language" setting, which is applied to every verbatim paragraph. Initially the
"current language" is empty, which just produces ordinary C<```> code blocks.

A C<=for highlighter language=FOO> paragraph sets the "current language" to
I<FOO>. (More specifically, you can put multiple I<KEY=VALUE> options in a
C<=for highlighter> paragraph, but this module only looks at the C<language>
option.) If you only want to set the "current language" to I<FOO>, you can also
write C<=for highlighter FOO> (that is, C<language> is the default option).

The "current language" is applied to all following verbatim paragraphs and
produces C<```FOO> tagged code blocks:

=for highlighter language=pod

    =for highlighter language=perl

        my $dog = "spot";

    ... other stuff ...

        my $car = "cdr";

    =for highlighter language=html

        <p>Hello!</p>

produces the following Markdown code:

=for highlighter language=markdown

    ```perl
    my $dog = "spot";
    ```

    ... other stuff ...

    ```perl
    my $car = "cdr";
    ```

    ```html
    <p>Hello!</p>
    ```

=back

=begin :README

=head1 INSTALLATION

To download and install this module, use your favorite CPAN client, e.g.
L<C<cpan>|cpan>:

=for highlighter language=sh

    cpan Pod::Markdown::Githubert

Or L<C<cpanm>|cpanm>:

    cpanm Pod::Markdown::Githubert

To do it manually, run the following commands (after downloading and unpacking
the tarball):

    perl Makefile.PL
    make
    make test
    make install

=end :README

=head1 SEE ALSO

L<Pod::Markdown>, L<perlpod>

=head1 AUTHOR

Lukas Mai, C<< <lmai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2023 Lukas Mai.

This module is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See L<https://dev.perl.org/licenses/> for more information.

=cut

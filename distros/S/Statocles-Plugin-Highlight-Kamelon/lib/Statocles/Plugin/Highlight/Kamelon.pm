package Statocles::Plugin::Highlight::Kamelon;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = 1.000;

use Statocles::Base 'Class';
with 'Statocles::Plugin';

BEGIN {
    eval { require Syntax::Kamelon }
        or die 'Error loading Statocles::Plugin::Highlight::Kamelon. '
        . 'Install Syntax::Kamelon to use this plugin';
}

has style => (
    is      => 'ro',
    isa     => Str,
    default => 'default',
);

my %available_attributes
    = map { $_ => '' } Syntax::Kamelon->AvailableAttributes;

my %format_table = (
    %available_attributes,
    Alert          => '<span class="hljs-strong">',
    Annotation     => '<span class="hljs-meta">',
    Attribute      => '<span class="hljs-meta">',
    BaseN          => '<span class="hljs-number">',
    BuiltIn        => '<span class="hljs-built_in">',
    Char           => '<span class="hljs-string">',
    Comment        => '<span class="hljs-comment">',
    CommentVar     => '<span class="hljs-comment">',
    Constant       => '<span class="hljs-variable">',
    ControlFlow    => '<span class="hljs-keyword">',
    DataType       => '<span class="hljs-type">',
    DecVal         => '<span class="hljs-number">',
    Documentation  => '<span class="hljs-comment">',
    Error          => '<span class="hljs-emphasis">',
    Extension      => '<span class="hljs-keyword">',
    Float          => '<span class="hljs-number">',
    Function       => '<span class="hljs-function">',
    Import         => '<span class="hljs-title">',
    Information    => '',
    Keyword        => '<span class="hljs-keyword">',
    Normal         => '',
    Operator       => '<span class="hljs-operator">',
    Others         => '<span class="hljs-keyword">',
    Preprocessor   => '<span class="hljs-variable">',
    RegionMarker   => '<span class="hljs-section">',
    SpecialChar    => '<span class="hljs-string">',
    SpecialString  => '<span class="hljs-string">',
    String         => '<span class="hljs-string">',
    Variable       => '<span class="hljs-variable">',
    VerbatimString => '<span class="hljs-string">',
    Warning        => '<span class="hljs-emphasis">',
);

my $textfilter = '[%~ text FILTER html ~%]';

my $hl = Syntax::Kamelon->new(
    formatter => [
        'Base',
        textfilter   => \$textfilter,
        format_table => \%format_table,
        tagend       => '</span>',
    ],
);

my %syntax_for = map { lc $_ => $_ } $hl->AvailableSyntaxes;

sub highlight {
    my ($self, $args, @helper_args) = @_;

    my $text = pop @helper_args;
    my $type = pop @helper_args;
    my %opt  = @helper_args;

    my $style = $opt{-style} || $self->style;

    # Find the requested syntax.
    my $syntax = $syntax_for{lc $type}
        or die qq{Don't know how to highlight "$type"};

    # Add the style sheet to the page.
    my $page = $args->{page} || $args->{self};
    if ($page) {
        my $path      = '/plugin/highlight/' . $style . '.css';
        my $style_url = $page->site->theme->url($path);
        if (!grep { $_->href eq $style_url } $page->links('stylesheet')) {
            $page->links(stylesheet => $style_url);
        }
    }

    # Handle Mojolicious begin/end.
    if (ref $text eq 'CODE') {
        $text = $text->();
    }

    # Remove leading and trailing empty lines.
    $text =~ s/\A\v+//;
    $text =~ s/\v+\z//;

    # Outdent text that is indented with four spaces or a tab like a Markdown
    # code block.
    if ($text !~ m/^(?![ ]{4}|$)/m) {
        $text =~ s/^[ ]{4}//mg;
    }
    elsif ($text !~ m/^(?!\t|$)/m) {
        $text =~ s/^\t//mg;
    }

    # Highlight the text.
    $hl->Syntax($syntax);
    $hl->Parse($text);

    my $output = '<pre><code class="hljs">' . $hl->Format . '</code></pre>';

    return $output;
}

sub register {
    my ($self, $site) = @_;

    $site->theme->helper(highlight => sub { $self->highlight(@_) });

    return $self;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Statocles::Plugin::Highlight::Kamelon - Highlight code

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  # Configuration in site.yml
  site:
    class: Statocles::Site
    plugins:
      highlight:
        $class: Statocles::Plugin::Highlight::Kamelon
        $args:
          style: default

  # Usage in Markdown files
  %= highlight Perl => begin
  print "hello, world\n"
  %end

  %= highlight Perl => include -raw => 'hello.pl'

=head1 DESCRIPTION

A plugin for the static website generator Statocles that adds an alternative
syntax highlighter.  Source code and configuration examples in Markdown files
are highlighted with Syntax::Kamelon.

=head1 ATTRIBUTES

=head2 style

The plugin uses Cascading Style Sheets that are provided by
L<Statocles::Plugin::Highlight>.

=over

=item * default

=item * solarized-dark

=item * solarized-light

=back

Download additional style sheets from the L<Highlight.js
project|https://github.com/highlightjs/highlight.js/tree/main/src/styles> and
put the files into your theme's F<plugin/highlight> directory.

=head1 SUBROUTINES/METHODS

=head2 highlight

  %= highlight Bash => begin
  echo "hello, world"
  %end

  %= highlight 'Intel x86 (NASM)' => include -raw => 'hello.nasm'

  %= highlight -style => 'solarized-dark', Kotlin => begin
  println("hello, world")
  %end

Highlights code with the specified syntax.  Enclose code in begin...end blocks
or include code from files.  See L</BUGS AND LIMITATIONS> for caveats.  Use a
different style sheet by passing a C<-style> option.

Run the following command to output the languages and file formats that are
supported by L<Syntax::Kamelon>:

  perl -MSyntax::Kamelon -E \
  'say for sort { fc $a cmp fc $b } Syntax::Kamelon->new->AvailableSyntaxes'

=head2 register

  $plugin->register($site);

Registers the "highlight" helper function.  Automatically called by Statocles
if the plugin is added to the F<site.yml>.

=head1 DIAGNOSTICS

=over

=item B<< Don't know how to highlight "SYNTAX" >>

The specified syntax is unknown.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Register the plugin in your F<site.yml>.

  site:
    class: Statocles::Site
    plugins:
      highlight:
        $class: Statocles::Plugin::Highlight::Kamelon
        $args:
          style: default

=head1 DEPENDENCIES

Requires Perl 5.16 and the modules L<Statocles> and L<Syntax::Kamelon> from
CPAN.

=head1 INCOMPATIBILITIES

This plugin provides a "highlight" helper function and thus conflicts with
L<Statocles::Plugin::Highlight>.  A Statocles site cannot register both
plugins.

=head1 BUGS AND LIMITATIONS

Do not highlight code from untrusted sources in begin...end blocks.  Statocles
interprets L<Mojo::Template> tags in such blocks.  Escape tags in the source
code with C<%>.  For example, replace C<<%> with C<<%%>.

Always include files with C<-raw>, which disables the template tags.

See L<Syntax::Kamelon> for the syntax highlighter's limitations.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

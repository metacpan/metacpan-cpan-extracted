package Org::Element::Setting;

use 5.010001;
use locale;

use Moo;
extends 'Org::Element';
with 'Org::ElementRole';
with 'Org::ElementRole::Block';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-05'; # DATE
our $DIST = 'Org-Parser'; # DIST
our $VERSION = '0.560'; # VERSION

our @known_settings = qw(
ARCHIVE
ASCII
ATTR_ASCII
ATTR_BEAMER
ATTR_HTML
ATTR_LATEX
ATTR_ODT
AUTHOR
BABEL
BEAMER
BEAMER_COLOR_THEME
BEAMER_FONT_THEME
BEAMER_INNER_THEME
BEAMER_OUTER_THEME
BEAMER_THEME
BEGIN
BEGIN_ASCII
BEGIN_BEAMER
BEGIN_CENTER
BEGIN_COMMENT
BEGIN_EXAMPLE
BEGIN_HTML
BEGIN_LATEX
BEGIN_QUOTE
BEGIN_SRC
BEGIN_SRC
BEGIN_VERSE
BIND
CALL
CAPTION
CATEGORY
COLUMNS
CONSTANTS
DATE
DESCRIPTION
DRAWERS
EMAIL
EXPORT_EXCLUDE_TAGS
EXPORT_INCLUDE_TAGS
FILETAGS
HEADER
HEADERS
HTML
HTML_HEAD
HTML_HEAD_EXTRA
HTML_INCLUDE_STYLE
INCLUDE
INDEX
INFOJS_OPT
KEYWORDS
LABEL
LANGUAGE
LAST_MOBILE_CHANGE
LATEX
LATEX_CLASS
LATEX_CLASS_OPTIONS
LATEX_HEADER
LATEX_HEADER_EXTRA
LINK
LINK_HOME
LINK_UP
MACRO
NAME
ODT_STYLES_FILE
OPTIONS
ORGLST
ORGTBL
PLOT
POSTID
PRIORITIES
PROPERTY
RESULTS
SEQ_TODO
SETUPFILE
SRCNAME
STARTUP
STYLE
TAGS
TBLFM
TEXT
TITLE
TOC
TODO
TYP_TODO
XSLT
                    );

has name => (is => 'rw');
has raw_arg => (is => 'ro');
has args => (is => 'rw');
has indent => (is => 'rw');

# static method
sub indentable_settings {
    state $data = [qw/TBLFM/];
    $data;
}

sub BUILD {
    require Org::Document;
    my ($self, $build_args) = @_;
    my $doc = $self->document;
    my $pass = $build_args->{pass} // 1;

    my $name    = uc $self->name;
    $self->name($name);

    my $args = $self->args;
    if ($name eq 'DRAWERS') {
        if ($pass == 1) {
            for my $arg (@$args) {
                push @{ $doc->drawer_names }, $arg
                    unless grep { $_ eq $arg } @{ $doc->drawer_names };
            }
        }
    } elsif ($name eq 'FILETAGS') {
        if ($pass == 1) {
            no warnings 'once';
            $args->[0] =~ /^$Org::Document::tags_re$/ or
                $self->die("Invalid argument for FILETAGS: $args->[0]");
            for my $tag (split /:/, $args->[0]) {
                next unless length $tag;
                push @{ $doc->tags }, $tag
                    unless grep { $_ eq $tag } @{ $doc->tags };
            }
        }
    } elsif ($name eq 'PRIORITIES') {
        if ($pass == 1) {
            for (@$args) {
                push @{ $doc->priorities }, $_;
            }
        }
    } elsif ($name eq 'PROPERTY') {
        if ($pass == 1) {
            @$args >= 2 or $self->die("Not enough argument for PROPERTY, minimum 2");
            my $name = shift @$args;
            $doc->properties->{$name} = @$args > 1 ? [@$args] : $args->[0];
        }
    } elsif ($name =~ /^(SEQ_TODO|TODO|TYP_TODO)$/) {
        if ($pass == 1) {
            my $done;
            for (my $i=0; $i<@$args; $i++) {
                my $arg = $args->[$i];
                if ($arg eq '|') { $done++; next }
                $done++ if !$done && @$args > 1 && $i == @$args-1;
                my $ary = $done ? $doc->done_states : $doc->todo_states;
                push @$ary, $arg unless grep { $_ eq $arg } @$ary;
            }
        }
    } else {
        unless ($self->document->ignore_unknown_settings) {
            $self->die("Unknown setting $name") unless grep { $_ eq $name } @known_settings;
        }
    }
}

sub as_string {
    my ($self) = @_;
    join("",
         $self->indent // "",
         "#+".uc($self->name), ":",
         $self->args && @{$self->args} ?
             " ".Org::Document::__format_args($self->args) : "",
         "\n"
     );
}

1;
# ABSTRACT: Represent Org in-buffer settings

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::Setting - Represent Org in-buffer settings

=head1 VERSION

This document describes version 0.560 of Org::Element::Setting (from Perl distribution Org-Parser), released on 2023-08-05.

=head1 DESCRIPTION

Derived from L<Org::Element>.

=for Pod::Coverage as_string BUILD

=head1 ATTRIBUTES

=head2 name => STR

Setting name.

=head2 raw_arg => ARRAY

String, read-only (can only be set during instantiation). Setting's raw
arguments.

=head2 args => ARRAY

Setting's arguments.

=head2 indent => STR

Indentation (whitespaces before C<#+>), or empty string if none.

=head1 METHODS

=head2 Org::Element::Setting->indentable_settings -> ARRAY

Return an arrayref containing the setting names that can be indented. In Org,
some settings can be indented and some can't. Setting names are all in
uppercase.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-Parser>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-Parser>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-Parser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

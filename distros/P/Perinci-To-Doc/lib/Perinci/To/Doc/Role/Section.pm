package Perinci::To::Doc::Role::Section;

use 5.010;
use Log::ger;
use Moo::Role;

has doc_sections => (is=>'rw');
has doc_lines => (is => 'rw'); # store final result, array
has doc_indent_level => (is => 'rw');
has doc_indent_str => (is => 'rw', default => sub{"  "}); # indent characters

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-14'; # DATE
our $DIST = 'Perinci-To-Doc'; # DIST
our $VERSION = '0.879'; # VERSION

sub add_doc_section_before {
    my ($self, $name, $before) = @_;
    my $ss = $self->doc_sections;
    return unless $ss;
    my $i = 0;
    my $added;
    while ($i < @$ss && defined($before)) {
        if ($ss->[$i] eq $before) {
            my $pos = $i;
            splice @$ss, $pos, 0, $name;
            $added++;
            last;
        }
        $i++;
    }
    unshift @$ss, $name unless $added;
}

sub add_doc_section_after {
    my ($self, $name, $after) = @_;
    my $ss = $self->doc_sections;
    return unless $ss;
    my $i = 0;
    my $added;
    while ($i < @$ss && defined($after)) {
        if ($ss->[$i] eq $after) {
            my $pos = $i+1;
            splice @$ss, $pos, 0, $name;
            $added++;
            last;
        }
        $i++;
    }
    push @$ss, $name unless $added;
}

sub delete_doc_section {
    my ($self, $name) = @_;
    my $ss = $self->doc_sections;
    return unless $ss;
    my $i = 0;
    while ($i < @$ss) {
        if ($ss->[$i] eq $name) {
            splice @$ss, $i, 1;
        } else {
            $i++;
        }
    }
}

sub inc_doc_indent {
    my ($self, $n) = @_;
    $n //= 1;
    $self->{doc_indent_level} += $n;
}

sub dec_doc_indent {
    my ($self, $n) = @_;
    $n //= 1;
    $self->{doc_indent_level} -= $n;
    die "BUG: Negative doc indent level" unless $self->{doc_indent_level} >=0;
}

sub gen_doc {
    my ($self, %opts) = @_;
    log_trace("-> gen_doc(opts=%s)", \%opts);

    $self->doc_lines([]);
    $self->doc_indent_level(0);

    $self->before_gen_doc(%opts) if $self->can("before_gen_doc");

    for my $s (@{ $self->doc_sections // [] }) {
        my $meth = "gen_doc_section_$s";
        log_trace("=> $meth(%s)", \%opts);
        $self->$meth(%opts);
    }

    $self->after_gen_doc(%opts) if $self->can("after_gen_doc");

    log_trace("<- gen_doc()");
    join("", @{ $self->doc_lines });
}

1;
# ABSTRACT: Role for class that generates documentation with sections

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::To::Doc::Role::Section - Role for class that generates documentation with sections

=head1 VERSION

This document describes version 0.879 of Perinci::To::Doc::Role::Section (from Perl distribution Perinci-To-Doc), released on 2022-05-14.

=head1 DESCRIPTION

This is a role for classes that produce documentation with sections. This role
provides a workflow for parsing and generating sections, regulating indentation,
and a C<gen_doc()> method.

To generate documentation, first you provide a list of section names in
C<doc_sections>. Then you run C<gen_doc()>, which will call
C<gen_doc_section_SECTION()> method for each section consecutively, which is
supposed to append lines of text to C<doc_lines>. Finally all the added lines is
concatenated together and returned by C<gen_doc()>.

=head1 ATTRIBUTES

=head2 doc_sections => ARRAY

Should be set to the names of available sections.

=head2 doc_lines => ARRAY

=head2 doc_indent_level => INT

=head2 doc_indent_str => STR (default '  ' (two spaces))

Character(s) used for indent.

=head1 METHODS

=head2 add_doc_section_before($name, $anchor)

=head2 add_doc_section_after($name, $anchor)

=head2 delete_doc_section($name)

=head2 inc_doc_indent([N])

=head2 dec_doc_indent([N])

=head2 gen_doc() => STR

Generate documentation.

The method will first initialize C<doc_lines> to an empty array C<[]> and
C<doc_indent_level> to 0.

It will then call C<before_gen_doc> if the hook method exists, to allow class to
do stuffs prior to document generation. L<Perinci::To::Text> uses this, for
example, to retrieve metadata from Riap server.

Then, as described in L</"DESCRIPTION">, for each section listed in
C<doc_sections> it will call C<gen_doc_section_SECTION>.

After that, it will call C<after_gen_doc> if the hook method exists, to allow
class to do stuffs after document generation.

Lastly, it returns concatenated C<doc_lines>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-To-Doc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-To-Doc>.

=head1 SEE ALSO

This role is used, among others, by: C<Perinci::To::*> modules.

L<Perinci::To::Doc::Role::Section::AddTextLines> which provides C<add_doc_lines>
to add text with optional text wrapping.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-To-Doc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package Org::Element::Text;

use 5.010;
use locale;
use Moo;
extends 'Org::Element';
with 'Org::ElementRole';
with 'Org::ElementRole::Inline';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-06'; # DATE
our $DIST = 'Org-Parser'; # DIST
our $VERSION = '0.561'; # VERSION

has text => (is => 'rw');
has style => (is => 'rw');

our %mu2style = (''=>'', '*'=>'B', '_'=>'U', '/'=>'I',
                 '+'=>'S', '='=>'C', '~'=>'V');
our %style2mu = reverse(%mu2style);

sub as_string {
    my ($self) = @_;
    my $muchar = $style2mu{$self->style // ''} // '';

    join("",
         $muchar,
         $self->text // '', $self->children_as_string,
         $muchar);
}

sub as_text {
    my $self = shift;
    my $muchar = $style2mu{$self->style // ''} // '';

    join("",
         $muchar,
         $self->text // '', $self->children_as_text,
         $muchar);
}

1;
# ABSTRACT: Represent text

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::Text - Represent text

=head1 VERSION

This document describes version 0.561 of Org::Element::Text (from Perl distribution Org-Parser), released on 2023-11-06.

=head1 DESCRIPTION

Derived from L<Org::Element>.

Org::Element::Text is an object that represents a piece of text. It has C<text>
and C<style> attributes. Simple text like C<Jakarta> or C<*Jakarta!*> will be
represented, respectively, as C<(text=Jakarta, style='')> and C<text=Jakarta!,
style=B> (for bold).

This object can also hold other inline (non-block) elements, e.g. links, radio
targets, timestamps, time ranges. They are all put in the C<children> attribute.

=for Pod::Coverage as_string

=head1 ATTRIBUTES

=head2 text => str

Plain text for this object I<only>. Note that if you want to get a plain text
representation for the whole text (including child elements), you'd want the
C<as_text> method.

=head2 style => str

''=normal, I=italic, B=bold, U=underline, S=strikethrough, V=verbatim,
C=code

=head1 METHODS

=head2 as_text => str

From L<Org::ElementRole::Inline>.

=head2 as_string => str

From L<Org::Element>.

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

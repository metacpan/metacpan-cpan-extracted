package Org::Element::FixedWidthSection;

use 5.010;
use locale;
use Moo;
extends 'Org::Element';
with 'Org::Element::Role';
with 'Org::Element::BlockRole';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-27'; # DATE
our $DIST = 'Org-Parser'; # DIST
our $VERSION = '0.557'; # VERSION

sub text {
    my ($self) = @_;
    my $res = $self->_str;
    $res =~ s/^[ \t]*: ?//mg;
    $res;
}

1;
# ABSTRACT: Represent Org fixed-width section

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::FixedWidthSection - Represent Org fixed-width section

=head1 VERSION

This document describes version 0.557 of Org::Element::FixedWidthSection (from Perl distribution Org-Parser), released on 2022-03-27.

=head1 SYNOPSIS

 use Org::Element::FixedWidthSection;
 my $el = Org::Element::FixedWidthSection->new(_str => ": line1\n: line2\n");

=head1 DESCRIPTION

Fixed width section is a block of text where each line is prefixed by colon +
space (or just a colon + space or a colon). Example:

 Here is an example:
   : some example from a text file.
   :   second line.
   :
   : fourth line, after the empty above.

which is functionally equivalent to:

 Here is an example:
   #+BEGIN_EXAMPLE
   some example from a text file.
     another example.

   fourth line, after the empty above.
   #+END_EXAMPLE

Derived from L<Org::Element>.

=head1 ATTRIBUTES

=head1 METHODS

=head2 $el->text => STR

The text (without colon prefix).

=for Pod::Coverage as_string BUILD

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-Parser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

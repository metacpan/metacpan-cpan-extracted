package Org::Element::List;

use 5.010;
use locale;
use Moo;
extends 'Org::Element';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-08'; # DATE
our $DIST = 'Org-Parser'; # DIST
our $VERSION = '0.556'; # VERSION

has indent => (is => 'rw');
has type => (is => 'rw');
has bullet_style => (is => 'rw');

sub items {
    my $self = shift;
    my @items;
    for (@{ $self->children }) {
        push @items, $_ if $_->isa('Org::Element::ListItem');
    }
    \@items;
}

1;
# ABSTRACT: Represent Org list

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::List - Represent Org list

=head1 VERSION

This document describes version 0.556 of Org::Element::List (from Perl distribution Org-Parser), released on 2022-02-08.

=head1 DESCRIPTION

Must have L<Org::Element::ListItem> (or another ::List) as children.

Derived from L<Org::Element>.

=begin Pod::Coverage




=end Pod::Coverage

=head1 ATTRIBUTES

=head2 indent

Indent (e.g. " " x 2).

=head2 type

'U' for unordered list (-, +, * for bullets), 'D' for description list, 'O' for
ordered list (1., 2., 3., and so on).

=head2 bullet_style

E.g. '-', '*', '+'. For ordered list, currently just use '<N>.'

=head1 METHODS

=head2 $list->items() => ARRAY OF OBJECTS

Return the items, which are an arrayref of L<Org::Element::ListItem> objects.

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

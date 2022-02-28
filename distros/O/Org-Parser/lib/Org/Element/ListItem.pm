package Org::Element::ListItem;

use 5.010;
use locale;
use Moo;
extends 'Org::Element';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-08'; # DATE
our $DIST = 'Org-Parser'; # DIST
our $VERSION = '0.556'; # VERSION

has bullet => (is => 'rw');
has check_state => (is => 'rw');
has desc_term => (is => 'rw');

sub header_as_string {
    my ($self) = @_;
    join("",
         $self->parent->indent,
         $self->bullet, " ",
         defined($self->check_state) ? "[".$self->check_state."]" : "",
         defined($self->desc_term) ? $self->desc_term->as_string . " ::" : "",
     );
}

sub as_string {
    my ($self) = @_;
    $self->header_as_string . $self->children_as_string;
}

1;
# ABSTRACT: Represent Org list item

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::ListItem - Represent Org list item

=head1 VERSION

This document describes version 0.556 of Org::Element::ListItem (from Perl distribution Org-Parser), released on 2022-02-08.

=head1 DESCRIPTION

Must have L<Org::Element::List> as parent.

Derived from L<Org::Element>.

=head1 ATTRIBUTES

=head2 bullet

=head2 check_state

undef, " ", "X" or "-".

=head2 desc_term

Description term (for description list).

=head1 METHODS

=for Pod::Coverage header_as_string as_string

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

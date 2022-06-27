package Org::Element::TableRow;

use 5.010;
use locale;
use Moo;
extends 'Org::Element';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-23'; # DATE
our $DIST = 'Org-Parser'; # DIST
our $VERSION = '0.558'; # VERSION

sub as_string {
    my ($self) = @_;
    return $self->_str if defined $self->_str;

    join("",
         "|",
         join("|", map {$_->as_string} @{$self->children}),
         "\n");
}

sub as_array {
    my ($self) = @_;

    [map {$_->as_string} @{$self->children}];
}

sub cells {
    my ($self) = @_;
    return [] unless $self->children;

    my $cells = [];
    for my $el (@{$self->children}) {
        push @$cells, $el if $el->isa('Org::Element::TableCell');
    }
    $cells;
}

1;
# ABSTRACT: Represent Org table row

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::TableRow - Represent Org table row

=head1 VERSION

This document describes version 0.558 of Org::Element::TableRow (from Perl distribution Org-Parser), released on 2022-06-23.

=head1 DESCRIPTION

Derived from L<Org::Element>. Must have L<Org::Element::TableCell>
instances as its children.

=for Pod::Coverage as_string

=head1 ATTRIBUTES

=head1 METHODS

=head2 $table->cells() => ELEMENTS

Return the cells of the row.

=head2 $table->as_array() => ARRAY

Return an arrayref containing the cells of the row, each cells already
stringified with as_string().

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

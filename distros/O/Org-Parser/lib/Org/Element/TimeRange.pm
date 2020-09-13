package Org::Element::TimeRange;

our $DATE = '2020-09-11'; # DATE
our $VERSION = '0.552'; # VERSION

use 5.010;
use locale;
use Moo;
extends 'Org::Element';
with 'Org::Element::Role';
with 'Org::Element::InlineRole';

has ts1 => (is => 'rw');
has ts2 => (is => 'rw');

sub as_string {
    my ($self) = @_;
    return $self->_str if $self->_str;
    join("",
         $self->ts1->as_string,
         "--",
         $self->ts2->as_string
     );
}

sub as_text {
    goto \&as_string;
}

1;
# ABSTRACT: Represent Org time range (TS1--TS2)

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::TimeRange - Represent Org time range (TS1--TS2)

=head1 VERSION

This document describes version 0.552 of Org::Element::TimeRange (from Perl distribution Org-Parser), released on 2020-09-11.

=head1 DESCRIPTION

Derived from L<Org::Element>.

=head1 ATTRIBUTES

=head2 ts1 => TIMESTAMP ELEMENT

Starting timestamp.

=head2 ts2 => TIMESTAMP ELEMENT

Ending timestamp.

=head1 METHODS

=head2 as_string => str

From L<Org::Element>.

=head2 as_text => str

From L<Org::Element::InlineRole>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-Parser>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-Parser>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-Parser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

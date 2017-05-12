package Org::Element::Footnote;

our $DATE = '2016-12-24'; # DATE
our $VERSION = '0.53'; # VERSION

use 5.010;
use locale;
use Log::Any::IfLOG '$log';
use Moo;
extends 'Org::Element';
with 'Org::Element::Role';
with 'Org::Element::InlineRole';

has name => (is => 'rw');
has is_ref => (is => 'rw');
has def => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;
    $log->tracef("name = %s", $self->name);
}

sub as_string {
    my ($self) = @_;

    join("",
         "[fn:", ($self->name // ""),
         defined($self->def) ? ":".$self->def->as_string : "",
         "]");
}

sub as_text {
    goto \&as_string;
}

1;
# ABSTRACT: Represent Org footnote reference and/or definition

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::Footnote - Represent Org footnote reference and/or definition

=head1 VERSION

This document describes version 0.53 of Org::Element::Footnote (from Perl distribution Org-Parser), released on 2016-12-24.

=head1 DESCRIPTION

Derived from L<Org::Element>.

=for Pod::Coverage ^(BUILD)$

=head1 ATTRIBUTES

=head2 name => STR|undef

Can be undef, for anonymous footnote (but in case of undef, is_ref must be
true and def must also be set).

=head2 is_ref => BOOL

Set to true to make this a footnote reference.

=head2 def => TEXT ELEMENT

Set to make this a footnote definition.

=head1 METHODS

=head2 as_string => str

From L<Org::Element>.

=head2 as_text => str

From L<Org::Element::InlineRole>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-Parser>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Org-Parser>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-Parser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

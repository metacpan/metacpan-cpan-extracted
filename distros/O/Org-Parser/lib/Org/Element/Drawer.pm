package Org::Element::Drawer;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-27'; # DATE
our $DIST = 'Org-Parser'; # DIST
our $VERSION = '0.555'; # VERSION

use 5.010;
use locale;
use Moo;
use experimental 'smartmatch';
extends 'Org::Element';
with 'Org::Element::Role';
with 'Org::Element::BlockRole';

has name => (is => 'rw');
has properties => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;
    my $doc = $self->document;
    my $pass = $args->{pass} // 1;

    if ($pass == 2) {
        die "Unknown drawer name: ".$self->name
            unless $self->name ~~ @{$doc->drawer_names};
    }
}

sub _parse_properties {
    my ($self, $raw_content) = @_;
    $self->properties({}) unless $self->properties;
    while ($raw_content =~ /^[ \t]*:(\w+):[ \t]+
                            ($Org::Document::args_re)[ \t]*(?:\R|\z)/mxg) {
        $self->properties->{$1} = $2;
    }
}

sub as_string {
    my ($self) = @_;
    join("",
         ":", $self->name, ":\n",
         $self->children_as_string,
         ":END:");
}

1;
# ABSTRACT: Represent Org drawer

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::Drawer - Represent Org drawer

=head1 VERSION

This document describes version 0.555 of Org::Element::Drawer (from Perl distribution Org-Parser), released on 2021-06-27.

=head1 DESCRIPTION

Derived from L<Org::Element>.

Example of a drawer in an Org document:

 * A heading
 :SOMEDRAWER:
 some text
 more text ...
 :END:

A special drawer named C<PROPERTIES> is used to store a list of properties:

 * A heading
 :PROPERTIES:
 :Title:   the title
 :Publisher:   the publisher
 :END:

=for Pod::Coverage BUILD as_string

=head1 ATTRIBUTES

=head2 name => STR

Drawer name.

=head2 properties => HASH

Collected properties in the drawer. In the example properties drawer above,
C<properties()> will result in:

 {
   Title => "the title",
   Publisher => "the publisher",
 }

=head1 METHODS

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

This software is copyright (c) 2021, 2020, 2019, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

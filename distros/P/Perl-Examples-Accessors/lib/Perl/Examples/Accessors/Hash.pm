package Perl::Examples::Accessors::Hash;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Perl-Examples-Accessors'; # DIST
our $VERSION = '0.133'; # VERSION

sub new {
    my ($class, %attrs) = @_;
    bless \%attrs, $class;
}

sub attr1_unoptimized {
    my $self = shift;
    $self->{attr1} = $_[0] if @_;
    $self->{attr1};
}

sub attr1 {
    if (@_ > 1) {
        $_[0]{attr1} = $_[1];
    } else {
        $_[0]{attr1};
    }
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::Accessors::Hash

=head1 VERSION

This document describes version 0.133 of Perl::Examples::Accessors::Hash (from Perl distribution Perl-Examples-Accessors), released on 2024-05-06.

=head1 DESCRIPTION

This is an example of a class which does not use any kind of object system or
accessor generator. It is hash-based.

=for Pod::Coverage ^(attr1_unoptimized)$

=head1 ATTRIBUTES

=head2 attr1

=head1 METHODS

=head2 new(%attrs) => obj

Constructor. Accept a hash to set attributes. No error checking is performed.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-Examples-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-Examples-Accessors>.

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

This software is copyright (c) 2024, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Examples-Accessors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

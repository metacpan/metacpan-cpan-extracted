package Sah::Schema::natnum;

our $DATE = '2018-04-03'; # DATE
our $VERSION = '0.071'; # VERSION

our $schema = ['posint', {
    summary => 'Same as posint',
    description => <<'_',

Natural numbers are those used for counting and ordering. Some definitions, like
ISO 80000-2 begin the natural numbers with 0. But in this definition, natural
numbers start with 1. For integers that start at 0, see `nonnegint`.

_
}, {}];

1;
# ABSTRACT: Same as posint

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::natnum - Same as posint

=head1 VERSION

This document describes version 0.071 of Sah::Schema::natnum (from Perl distribution Sah-Schemas-Int), released on 2018-04-03.

=head1 DESCRIPTION

Natural numbers are those used for counting and ordering. Some definitions, like
ISO 80000-2 begin the natural numbers with 0. But in this definition, natural
numbers start with 1. For integers that start at 0, see C<nonnegint>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Int>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Sah-Schema-Int>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Int>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

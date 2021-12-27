package Sah::Schemas::Examples;

our $DATE = '2021-07-30'; # DATE
our $VERSION = '0.009'; # VERSION

1;
# ABSTRACT: Various example Sah schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Examples - Various example Sah schemas

=head1 VERSION

This document describes version 0.009 of Sah::Schemas::Examples (from Perl distribution Sah-Schemas-Examples), released on 2021-07-30.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<array_of_int|Sah::Schema::array_of_int>

Array of integers.

=item * L<array_of_posint|Sah::Schema::array_of_posint>

Array of positive integers.

=item * L<example::foo|Sah::Schema::example::foo>

A sample schema.

This is just a simple schema based on C<str> with no additional restriction
clauses.


=item * L<example::has_merge|Sah::Schema::example::has_merge>

Even integer.

This schema is based on "posint", which is ["int", {min=>1}], and adds another
clause div_by=>2. However, this schema also deletes the min=>1 clause using
merge key: merge.delete.min=>undef. Thus, the resolved result becomes ["int",
{div_by=>2}] which is basically "even integer". Without the merge key, this
schema would become "positive even integer."


=item * L<example::recurse1|Sah::Schema::example::recurse1>

Recursive schema.

This schema will cause the resolver L<Data::Sah::Resolve> to bail because it
recurses to itself.


=item * L<example::recurse2a|Sah::Schema::example::recurse2a>

Recursive schema.

=item * L<example::recurse2b|Sah::Schema::example::recurse2b>

Recursive schema.

This schema will cause the resolver L<Data::Sah::Resolve> to bail because it
eventually recurses to itself.


=item * L<hash_of_int|Sah::Schema::hash_of_int>

Hash of integers.

=item * L<hash_of_posint|Sah::Schema::hash_of_posint>

Hash of positive integers.

=item * L<ints|Sah::Schema::ints>

Array of integers.

=item * L<posints|Sah::Schema::posints>

Array of positive integers.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

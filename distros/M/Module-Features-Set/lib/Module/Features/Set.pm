package Module::Features::Set;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-29'; # DATE
our $DIST = 'Module-Features-Set'; # DIST
our $VERSION = '0.003'; # VERSION

our %FEATURES_DEF = (
    v => 1,
    summary => 'Features of modules that handle set data structure',
    features => {
        can_insert_value                         => {summary => 'Provide a way for user to insert a value to a set', tags=>['category:basic']},
        can_delete_value                         => {summary => 'Provide a way for user to delete a value from a set', tags=>['category:basic']},
        can_search_value                         => {summary => 'Provide a way for user to search a value in a set', tags=>['category:basic']},
        can_count_values                         => {summary => 'Provide a way for user to get the number of values in a set', tags=>['category:basic']},

        can_union_sets                           => {summary => 'Provide a way for user to perform union operation of two or more sets', tags=>['category:interset-operation']},
        can_intersect_sets                       => {summary => 'Provide a way for user to perform intersection operation of two or more sets', tags=>['category:interset-operation']},
        can_difference_sets                      => {summary => 'Provide a way for user to perform difference operation of two or more sets (values in first set not in the rest)', tags=>['category:interset-operation']},
        can_symmetric_difference_sets            => {summary => 'Provide a way for user to perform symmetric difference operation of two or more sets (values that are only in exactly one set)', tags=>['category:interset-operation']},

        can_compare_sets                         => {summary => 'Provide a way for user to check the equality of two sets', tags=>['category:sets']},

        speed                                    => {summary => 'Subjective speed rating, relative to other set modules', schema=>['str', in=>[qw/slow medium fast/]], tags=>['category:speed']},

        memory_overhead                          => {summary => 'Subjective memory overhead rating, relative to other set modules', schema=>['str', in=>[qw/low medium high/]], tags=>['category:memory_overhead']},

        features                                 => {summary => 'Subjective feature richness/completeness rating, relative to other set modules', schema=>['str', in=>[qw/few medium many/]], tags=>['category:features']},
    },
);

1;
# ABSTRACT: Features of modules that handle set data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Features::Set - Features of modules that handle set data structure

=head1 VERSION

This document describes version 0.003 of Module::Features::Set (from Perl distribution Module-Features-Set), released on 2021-11-29.

=head1 DESCRIPTION

=head1 DEFINED FEATURES

Features defined by this module:

=over

=item * can_compare_sets

Optional. Type: bool. Provide a way for user to check the equality of two sets. 

=item * can_count_values

Optional. Type: bool. Provide a way for user to get the number of values in a set. 

=item * can_delete_value

Optional. Type: bool. Provide a way for user to delete a value from a set. 

=item * can_difference_sets

Optional. Type: bool. Provide a way for user to perform difference operation of two or more sets (values in first set not in the rest). 

=item * can_insert_value

Optional. Type: bool. Provide a way for user to insert a value to a set. 

=item * can_intersect_sets

Optional. Type: bool. Provide a way for user to perform intersection operation of two or more sets. 

=item * can_search_value

Optional. Type: bool. Provide a way for user to search a value in a set. 

=item * can_symmetric_difference_sets

Optional. Type: bool. Provide a way for user to perform symmetric difference operation of two or more sets (values that are only in exactly one set). 

=item * can_union_sets

Optional. Type: bool. Provide a way for user to perform union operation of two or more sets. 

=item * features

Optional. Type: str. Subjective feature richness/completeness rating, relative to other set modules. 

=item * memory_overhead

Optional. Type: str. Subjective memory overhead rating, relative to other set modules. 

=item * speed

Optional. Type: str. Subjective speed rating, relative to other set modules. 

=back

For more details on module features, see L<Module::Features>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Features-Set>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Features-Set>.

=head1 SEE ALSO

L<Module::Features>

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Features-Set>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

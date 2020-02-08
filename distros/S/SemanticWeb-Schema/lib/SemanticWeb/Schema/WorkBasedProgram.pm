use utf8;

package SemanticWeb::Schema::WorkBasedProgram;

# ABSTRACT: A program with both an educational and employment component

use Moo;

extends qw/ SemanticWeb::Schema::EducationalOccupationalProgram /;


use MooX::JSON_LD 'WorkBasedProgram';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.1';


has occupational_category => (
    is        => 'rw',
    predicate => '_has_occupational_category',
    json_ld   => 'occupationalCategory',
);



has training_salary => (
    is        => 'rw',
    predicate => '_has_training_salary',
    json_ld   => 'trainingSalary',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::WorkBasedProgram - A program with both an educational and employment component

=head1 VERSION

version v6.0.1

=head1 DESCRIPTION

A program with both an educational and employment component. Typically
based at a workplace and structured around work-based learning, with the
aim of instilling competencies related to an occupation. WorkBasedProgram
is used to distinguish programs such as apprenticeships from school,
college or other classroom based educational programs.

=head1 ATTRIBUTES

=head2 C<occupational_category>

C<occupationalCategory>

=for html <p>A category describing the job, preferably using a term from a taxonomy
such as <a href="http://www.onetcenter.org/taxonomy.html">BLS
O*NET-SOC</a>, <a
href="https://www.ilo.org/public/english/bureau/stat/isco/isco08/">ISCO-08<
/a> or similar, with the property repeated for each applicable value.
Ideally the taxonomy should be identified, and both the textual label and
formal code for the category should be provided.<br/><br/> Note: for
historical reasons, any textual label and formal code provided as a literal
may be assumed to be from O*NET-SOC.<p>

A occupational_category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CategoryCode']>

=item C<Str>

=back

=head2 C<_has_occupational_category>

A predicate for the L</occupational_category> attribute.

=head2 C<training_salary>

C<trainingSalary>

The estimated salary earned while in the program.

A training_salary should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmountDistribution']>

=back

=head2 C<_has_training_salary>

A predicate for the L</training_salary> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::EducationalOccupationalProgram>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

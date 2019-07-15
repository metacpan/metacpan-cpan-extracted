use utf8;

package SemanticWeb::Schema::MedicalTest;

# ABSTRACT: Any medical test

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalTest';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has affected_by => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'affectedBy',
);



has normal_range => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'normalRange',
);



has sign_detected => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'signDetected',
);



has used_to_diagnose => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'usedToDiagnose',
);



has uses_device => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'usesDevice',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalTest - Any medical test

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Any medical test, typically performed for diagnostic purposes.

=head1 ATTRIBUTES

=head2 C<affected_by>

C<affectedBy>

Drugs that affect the test's results.

A affected_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Drug']>

=back

=head2 C<normal_range>

C<normalRange>

Range of acceptable values for a typical patient, when applicable.

A normal_range should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEnumeration']>

=item C<Str>

=back

=head2 C<sign_detected>

C<signDetected>

A sign detected by the test.

A sign_detected should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalSign']>

=back

=head2 C<used_to_diagnose>

C<usedToDiagnose>

A condition the test is used to diagnose.

A used_to_diagnose should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalCondition']>

=back

=head2 C<uses_device>

C<usesDevice>

Device used to perform the test.

A uses_device should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalDevice']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEntity>

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

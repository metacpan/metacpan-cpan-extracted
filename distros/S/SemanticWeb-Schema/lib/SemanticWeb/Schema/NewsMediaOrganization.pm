use utf8;

package SemanticWeb::Schema::NewsMediaOrganization;

# ABSTRACT: A News/Media organization such as a newspaper or TV station.

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'NewsMediaOrganization';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has actionable_feedback_policy => (
    is        => 'rw',
    predicate => '_has_actionable_feedback_policy',
    json_ld   => 'actionableFeedbackPolicy',
);



has corrections_policy => (
    is        => 'rw',
    predicate => '_has_corrections_policy',
    json_ld   => 'correctionsPolicy',
);



has diversity_policy => (
    is        => 'rw',
    predicate => '_has_diversity_policy',
    json_ld   => 'diversityPolicy',
);



has diversity_staffing_report => (
    is        => 'rw',
    predicate => '_has_diversity_staffing_report',
    json_ld   => 'diversityStaffingReport',
);



has ethics_policy => (
    is        => 'rw',
    predicate => '_has_ethics_policy',
    json_ld   => 'ethicsPolicy',
);



has masthead => (
    is        => 'rw',
    predicate => '_has_masthead',
    json_ld   => 'masthead',
);



has mission_coverage_priorities_policy => (
    is        => 'rw',
    predicate => '_has_mission_coverage_priorities_policy',
    json_ld   => 'missionCoveragePrioritiesPolicy',
);



has no_bylines_policy => (
    is        => 'rw',
    predicate => '_has_no_bylines_policy',
    json_ld   => 'noBylinesPolicy',
);



has ownership_funding_info => (
    is        => 'rw',
    predicate => '_has_ownership_funding_info',
    json_ld   => 'ownershipFundingInfo',
);



has unnamed_sources_policy => (
    is        => 'rw',
    predicate => '_has_unnamed_sources_policy',
    json_ld   => 'unnamedSourcesPolicy',
);



has verification_fact_checking_policy => (
    is        => 'rw',
    predicate => '_has_verification_fact_checking_policy',
    json_ld   => 'verificationFactCheckingPolicy',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::NewsMediaOrganization - A News/Media organization such as a newspaper or TV station.

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

A News/Media organization such as a newspaper or TV station.

=head1 ATTRIBUTES

=head2 C<actionable_feedback_policy>

C<actionableFeedbackPolicy>

=for html <p>For a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a> or
other news-related <a class="localLink"
href="http://schema.org/Organization">Organization</a>, a statement about
public engagement activities (for news media, the newsroomâs), including
involving the public - digitally or otherwise -- in coverage decisions,
reporting and activities after publication.<p>

A actionable_feedback_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_actionable_feedback_policy>

A predicate for the L</actionable_feedback_policy> attribute.

=head2 C<corrections_policy>

C<correctionsPolicy>

=for html <p>For an <a class="localLink"
href="http://schema.org/Organization">Organization</a> (e.g. <a
class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>),
a statement describing (in news media, the newsroomâs) disclosure and
correction policy for errors.<p>

A corrections_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_corrections_policy>

A predicate for the L</corrections_policy> attribute.

=head2 C<diversity_policy>

C<diversityPolicy>

=for html <p>Statement on diversity policy by an <a class="localLink"
href="http://schema.org/Organization">Organization</a> e.g. a <a
class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>.
For a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>, a
statement describing the newsroomâs diversity policy on both staffing and
sources, typically providing staffing data.<p>

A diversity_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_diversity_policy>

A predicate for the L</diversity_policy> attribute.

=head2 C<diversity_staffing_report>

C<diversityStaffingReport>

=for html <p>For an <a class="localLink"
href="http://schema.org/Organization">Organization</a> (often but not
necessarily a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>),
a report on staffing diversity issues. In a news context this might be for
example ASNE or RTDNA (US) reports, or self-reported.<p>

A diversity_staffing_report should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Article']>

=item C<Str>

=back

=head2 C<_has_diversity_staffing_report>

A predicate for the L</diversity_staffing_report> attribute.

=head2 C<ethics_policy>

C<ethicsPolicy>

=for html <p>Statement about ethics policy, e.g. of a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>
regarding journalistic and publishing practices, or of a <a
class="localLink" href="http://schema.org/Restaurant">Restaurant</a>, a
page describing food source policies. In the case of a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>,
an ethicsPolicy is typically a statement describing the personal,
organizational, and corporate standards of behavior expected by the
organization.<p>

A ethics_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_ethics_policy>

A predicate for the L</ethics_policy> attribute.

=head2 C<masthead>

=for html <p>For a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>, a
link to the masthead page or a page listing top editorial management.<p>

A masthead should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_masthead>

A predicate for the L</masthead> attribute.

=head2 C<mission_coverage_priorities_policy>

C<missionCoveragePrioritiesPolicy>

=for html <p>For a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>, a
statement on coverage priorities, including any public agenda or stance on
issues.<p>

A mission_coverage_priorities_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_mission_coverage_priorities_policy>

A predicate for the L</mission_coverage_priorities_policy> attribute.

=head2 C<no_bylines_policy>

C<noBylinesPolicy>

=for html <p>For a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a> or
other news-related <a class="localLink"
href="http://schema.org/Organization">Organization</a>, a statement
explaining when authors of articles are not named in bylines.<p>

A no_bylines_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_no_bylines_policy>

A predicate for the L</no_bylines_policy> attribute.

=head2 C<ownership_funding_info>

C<ownershipFundingInfo>

=for html <p>For an <a class="localLink"
href="http://schema.org/Organization">Organization</a> (often but not
necessarily a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>),
a description of organizational ownership structure; funding and grants. In
a news/media setting, this is with particular reference to editorial
independence. Note that the <a class="localLink"
href="http://schema.org/funder">funder</a> is also available and can be
used to make basic funder information machine-readable.<p>

A ownership_funding_info should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AboutPage']>

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_ownership_funding_info>

A predicate for the L</ownership_funding_info> attribute.

=head2 C<unnamed_sources_policy>

C<unnamedSourcesPolicy>

=for html <p>For an <a class="localLink"
href="http://schema.org/Organization">Organization</a> (typically a <a
class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>),
a statement about policy on use of unnamed sources and the decision process
required.<p>

A unnamed_sources_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_unnamed_sources_policy>

A predicate for the L</unnamed_sources_policy> attribute.

=head2 C<verification_fact_checking_policy>

C<verificationFactCheckingPolicy>

=for html <p>Disclosure about verification and fact-checking processes for a <a
class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a> or
other fact-checking <a class="localLink"
href="http://schema.org/Organization">Organization</a>.<p>

A verification_fact_checking_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_verification_fact_checking_policy>

A predicate for the L</verification_fact_checking_policy> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

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

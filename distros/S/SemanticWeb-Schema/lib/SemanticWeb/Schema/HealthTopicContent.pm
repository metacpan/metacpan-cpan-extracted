use utf8;

package SemanticWeb::Schema::HealthTopicContent;

# ABSTRACT:  HealthTopicContent is WebContent that is about some aspect of a health topic

use Moo;

extends qw/ SemanticWeb::Schema::WebContent /;


use MooX::JSON_LD 'HealthTopicContent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has has_health_aspect => (
    is        => 'rw',
    predicate => '_has_has_health_aspect',
    json_ld   => 'hasHealthAspect',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HealthTopicContent - HealthTopicContent is WebContent that is about some aspect of a health topic

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

=for html <p><a class="localLink"
href="http://schema.org/HealthTopicContent">HealthTopicContent</a> is <a
class="localLink" href="http://schema.org/WebContent">WebContent</a> that
is about some aspect of a health topic, e.g. a condition, its symptoms or
treatments. Such content may be comprised of several parts or sections and
use different types of media. Multiple instances of <a class="localLink"
href="http://schema.org/WebContent">WebContent</a> (and hence <a
class="localLink"
href="http://schema.org/HealthTopicContent">HealthTopicContent</a>) can be
related using <a class="localLink"
href="http://schema.org/hasPart">hasPart</a> / <a class="localLink"
href="http://schema.org/isPartOf">isPartOf</a> where there is some kind of
content hierarchy, and their content described with <a class="localLink"
href="http://schema.org/about">about</a> and <a class="localLink"
href="http://schema.org/mentions">mentions</a> e.g. building upon the
existing <a class="localLink"
href="http://schema.org/MedicalCondition">MedicalCondition</a>
vocabulary.<p>

=head1 ATTRIBUTES

=head2 C<has_health_aspect>

C<hasHealthAspect>

=for html <p>Indicates the aspect or aspects specifically addressed in some <a
class="localLink"
href="http://schema.org/HealthTopicContent">HealthTopicContent</a>. For
example, that the content is an overview, or that it talks about treatment,
self-care, treatments or their side-effects.<p>

A has_health_aspect should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::HealthAspectEnumeration']>

=back

=head2 C<_has_has_health_aspect>

A predicate for the L</has_health_aspect> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::WebContent>

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

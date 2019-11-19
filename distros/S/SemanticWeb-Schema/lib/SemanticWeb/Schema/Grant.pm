use utf8;

package SemanticWeb::Schema::Grant;

# ABSTRACT: A grant

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Grant';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has funded_item => (
    is        => 'rw',
    predicate => '_has_funded_item',
    json_ld   => 'fundedItem',
);



has sponsor => (
    is        => 'rw',
    predicate => '_has_sponsor',
    json_ld   => 'sponsor',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Grant - A grant

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

=for html <p>A grant, typically financial or otherwise quantifiable, of resources.
Typically a <a class="localLink" href="http://schema.org/funder">funder</a>
sponsors some <a class="localLink"
href="http://schema.org/MonetaryAmount">MonetaryAmount</a> to an <a
class="localLink" href="http://schema.org/Organization">Organization</a> or
<a class="localLink" href="http://schema.org/Person">Person</a>, sometimes
not necessarily via a dedicated or long-lived <a class="localLink"
href="http://schema.org/Project">Project</a>, resulting in one or more
outputs, or <a class="localLink"
href="http://schema.org/fundedItem">fundedItem</a>s. For financial
sponsorship, indicate the <a class="localLink"
href="http://schema.org/funder">funder</a> of a <a class="localLink"
href="http://schema.org/MonetaryGrant">MonetaryGrant</a>. For non-financial
support, indicate <a class="localLink"
href="http://schema.org/sponsor">sponsor</a> of <a class="localLink"
href="http://schema.org/Grant">Grant</a>s of resources (e.g. office
space).<br/><br/> Grants support activities directed towards some agreed
collective goals, often but not always organized as <a class="localLink"
href="http://schema.org/Project">Project</a>s. Long-lived projects are
sometimes sponsored by a variety of grants over time, but it is also common
for a project to be associated with a single grant.<br/><br/> The amount of
a <a class="localLink" href="http://schema.org/Grant">Grant</a> is
represented using <a class="localLink"
href="http://schema.org/amount">amount</a> as a <a class="localLink"
href="http://schema.org/MonetaryAmount">MonetaryAmount</a>.<p>

=head1 ATTRIBUTES

=head2 C<funded_item>

C<fundedItem>

=for html <p>Indicates an item funded or sponsored through a <a class="localLink"
href="http://schema.org/Grant">Grant</a>.<p>

A funded_item should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<_has_funded_item>

A predicate for the L</funded_item> attribute.

=head2 C<sponsor>

A person or organization that supports a thing through a pledge, promise,
or financial contribution. e.g. a sponsor of a Medical Study or a corporate
sponsor of an event.

A sponsor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_sponsor>

A predicate for the L</sponsor> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

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

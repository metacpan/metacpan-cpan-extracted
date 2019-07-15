use utf8;

package SemanticWeb::Schema::InteractionCounter;

# ABSTRACT: A summary of how users have interacted with this CreativeWork

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'InteractionCounter';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has interaction_service => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'interactionService',
);



has interaction_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'interactionType',
);



has user_interaction_count => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'userInteractionCount',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::InteractionCounter - A summary of how users have interacted with this CreativeWork

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A summary of how users have interacted with this CreativeWork. In most
cases, authors will use a subtype to specify the specific type of
interaction.

=head1 ATTRIBUTES

=head2 C<interaction_service>

C<interactionService>

The WebSite or SoftwareApplication where the interactions took place.

A interaction_service should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SoftwareApplication']>

=item C<InstanceOf['SemanticWeb::Schema::WebSite']>

=back

=head2 C<interaction_type>

C<interactionType>

=for html The Action representing the type of interaction. For up votes, +1s, etc.
use <a class="localLink"
href="http://schema.org/LikeAction">LikeAction</a>. For down votes use <a
class="localLink" href="http://schema.org/DislikeAction">DislikeAction</a>.
Otherwise, use the most specific Action.

A interaction_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Action']>

=back

=head2 C<user_interaction_count>

C<userInteractionCount>

The number of interactions for the CreativeWork using the WebSite or
SoftwareApplication.

A user_interaction_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::StructuredValue>

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

use utf8;

package SemanticWeb::Schema::AlignmentObject;

# ABSTRACT: An intangible item that describes an alignment between a learning resource and a node in an educational framework.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'AlignmentObject';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has alignment_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'alignmentType',
);



has educational_framework => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'educationalFramework',
);



has target_description => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'targetDescription',
);



has target_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'targetName',
);



has target_url => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'targetUrl',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AlignmentObject - An intangible item that describes an alignment between a learning resource and a node in an educational framework.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

An intangible item that describes an alignment between a learning resource
and a node in an educational framework.

=head1 ATTRIBUTES

=head2 C<alignment_type>

C<alignmentType>

A category of alignment between the learning resource and the framework
node. Recommended values include: 'assesses', 'teaches', 'requires',
'textComplexity', 'readingLevel', 'educationalSubject', and
'educationalLevel'.

A alignment_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<educational_framework>

C<educationalFramework>

The framework to which the resource being described is aligned.

A educational_framework should be one of the following types:

=over

=item C<Str>

=back

=head2 C<target_description>

C<targetDescription>

The description of a node in an established educational framework.

A target_description should be one of the following types:

=over

=item C<Str>

=back

=head2 C<target_name>

C<targetName>

The name of a node in an established educational framework.

A target_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<target_url>

C<targetUrl>

The URL of a node in an established educational framework.

A target_url should be one of the following types:

=over

=item C<Str>

=back

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

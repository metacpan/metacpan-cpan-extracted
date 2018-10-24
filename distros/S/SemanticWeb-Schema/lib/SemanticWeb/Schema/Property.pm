use utf8;

package SemanticWeb::Schema::Property;

# ABSTRACT: A property

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Property';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has domain_includes => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'domainIncludes',
);



has inverse_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inverseOf',
);



has range_includes => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'rangeIncludes',
);



has superseded_by => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'supersededBy',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Property - A property

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A property, used to indicate attributes and relationships of some Thing;
equivalent to rdf:Property.

=head1 ATTRIBUTES

=head2 C<domain_includes>

C<domainIncludes>

Relates a property to a class that is (one of) the type(s) the property is
expected to be used on.

A domain_includes should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Class']>

=back

=head2 C<inverse_of>

C<inverseOf>

Relates a property to a property that is its inverse. Inverse properties
relate the same pairs of items to each other, but in reversed direction.
For example, the 'alumni' and 'alumniOf' properties are inverseOf each
other. Some properties don't have explicit inverses; in these situations
RDFa and JSON-LD syntax for reverse properties can be used.

A inverse_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Property']>

=back

=head2 C<range_includes>

C<rangeIncludes>

Relates a property to a class that constitutes (one of) the expected
type(s) for values of the property.

A range_includes should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Class']>

=back

=head2 C<superseded_by>

C<supersededBy>

Relates a term (i.e. a property, class or enumeration) to one that
supersedes it.

A superseded_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Enumeration']>

=item C<InstanceOf['SemanticWeb::Schema::Class']>

=item C<InstanceOf['SemanticWeb::Schema::Property']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

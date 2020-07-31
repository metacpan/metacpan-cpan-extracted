use utf8;

package SemanticWeb::Schema::StupidType;

# ABSTRACT: A StupidType for testing.

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'StupidType';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has stupid_property => (
    is        => 'rw',
    predicate => '_has_stupid_property',
    json_ld   => 'stupidProperty',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::StupidType - A StupidType for testing.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A StupidType for testing.

=head1 ATTRIBUTES

=head2 C<stupid_property>

C<stupidProperty>

This is a StupidProperty! - for testing only

A stupid_property should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_stupid_property>

A predicate for the L</stupid_property> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Thing>

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

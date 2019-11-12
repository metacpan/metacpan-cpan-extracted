use utf8;

package SemanticWeb::Schema::CategoryCodeSet;

# ABSTRACT: A set of Category Code values.

use Moo;

extends qw/ SemanticWeb::Schema::DefinedTermSet /;


use MooX::JSON_LD 'CategoryCodeSet';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.0';


has has_category_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasCategoryCode',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CategoryCodeSet - A set of Category Code values.

=head1 VERSION

version v5.0.0

=head1 DESCRIPTION

A set of Category Code values.

=head1 ATTRIBUTES

=head2 C<has_category_code>

C<hasCategoryCode>

A Category code contained in this code set.

A has_category_code should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CategoryCode']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::DefinedTermSet>

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

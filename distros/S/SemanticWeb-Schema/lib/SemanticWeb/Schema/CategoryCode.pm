use utf8;

package SemanticWeb::Schema::CategoryCode;

# ABSTRACT: A Category Code.

use Moo;

extends qw/ SemanticWeb::Schema::DefinedTerm /;


use MooX::JSON_LD 'CategoryCode';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has code_value => (
    is        => 'rw',
    predicate => '_has_code_value',
    json_ld   => 'codeValue',
);



has in_code_set => (
    is        => 'rw',
    predicate => '_has_in_code_set',
    json_ld   => 'inCodeSet',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CategoryCode - A Category Code.

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

A Category Code.

=head1 ATTRIBUTES

=head2 C<code_value>

C<codeValue>

A short textual code that uniquely identifies the value.

A code_value should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_code_value>

A predicate for the L</code_value> attribute.

=head2 C<in_code_set>

C<inCodeSet>

=for html <p>A <a class="localLink"
href="http://schema.org/CategoryCodeSet">CategoryCodeSet</a> that contains
this category code.<p>

A in_code_set should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CategoryCodeSet']>

=item C<Str>

=back

=head2 C<_has_in_code_set>

A predicate for the L</in_code_set> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::DefinedTerm>

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

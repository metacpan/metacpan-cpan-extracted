use utf8;

package SemanticWeb::Schema::ReplaceAction;

# ABSTRACT: The act of editing a recipient by replacing an old object with a new object.

use Moo;

extends qw/ SemanticWeb::Schema::UpdateAction /;


use MooX::JSON_LD 'ReplaceAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has replacee => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'replacee',
);



has replacer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'replacer',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ReplaceAction - The act of editing a recipient by replacing an old object with a new object.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

The act of editing a recipient by replacing an old object with a new
object.

=head1 ATTRIBUTES

=head2 C<replacee>

A sub property of object. The object that is being replaced.

A replacee should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<replacer>

A sub property of object. The object that replaces.

A replacer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::UpdateAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

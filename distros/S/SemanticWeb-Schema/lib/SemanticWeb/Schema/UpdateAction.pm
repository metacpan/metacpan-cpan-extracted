use utf8;

package SemanticWeb::Schema::UpdateAction;

# ABSTRACT: The act of managing by changing/editing the state of the object.

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'UpdateAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has collection => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'collection',
);



has target_collection => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'targetCollection',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::UpdateAction - The act of managing by changing/editing the state of the object.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The act of managing by changing/editing the state of the object.

=head1 ATTRIBUTES

=head2 C<collection>

A sub property of object. The collection target of the action.

A collection should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<target_collection>

C<targetCollection>

A sub property of object. The collection target of the action.

A target_collection should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Action>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

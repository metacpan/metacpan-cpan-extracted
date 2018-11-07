use utf8;

package SemanticWeb::Schema::AuthorizeAction;

# ABSTRACT: The act of granting permission to an object.

use Moo;

extends qw/ SemanticWeb::Schema::AllocateAction /;


use MooX::JSON_LD 'AuthorizeAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has recipient => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recipient',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AuthorizeAction - The act of granting permission to an object.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The act of granting permission to an object.

=head1 ATTRIBUTES

=head2 C<recipient>

A sub property of participant. The participant who is at the receiving end
of the action.

A recipient should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::AllocateAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

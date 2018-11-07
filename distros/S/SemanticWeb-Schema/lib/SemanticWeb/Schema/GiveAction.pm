use utf8;

package SemanticWeb::Schema::GiveAction;

# ABSTRACT: The act of transferring ownership of an object to a destination

use Moo;

extends qw/ SemanticWeb::Schema::TransferAction /;


use MooX::JSON_LD 'GiveAction';
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

SemanticWeb::Schema::GiveAction - The act of transferring ownership of an object to a destination

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

=for html The act of transferring ownership of an object to a destination. Reciprocal
of TakeAction.<br/><br/> Related actions:<br/><br/> <ul> <li><a
class="localLink" href="http://schema.org/TakeAction">TakeAction</a>:
Reciprocal of GiveAction.</li> <li><a class="localLink"
href="http://schema.org/SendAction">SendAction</a>: Unlike SendAction,
GiveAction implies that ownership is being transferred (e.g. I may send my
laptop to you, but that doesn't mean I'm giving it to you).</li> </ul> 

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

L<SemanticWeb::Schema::TransferAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

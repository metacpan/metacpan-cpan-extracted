use utf8;

package SemanticWeb::Schema::LendAction;

# ABSTRACT: The act of providing an object under an agreement that it will be returned at a later date

use Moo;

extends qw/ SemanticWeb::Schema::TransferAction /;


use MooX::JSON_LD 'LendAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has borrower => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'borrower',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LendAction - The act of providing an object under an agreement that it will be returned at a later date

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

=for html The act of providing an object under an agreement that it will be returned
at a later date. Reciprocal of BorrowAction.<br/><br/> Related
actions:<br/><br/> <ul> <li><a class="localLink"
href="http://schema.org/BorrowAction">BorrowAction</a>: Reciprocal of
LendAction.</li> </ul> 

=head1 ATTRIBUTES

=head2 C<borrower>

A sub property of participant. The person that borrows the object being
lent.

A borrower should be one of the following types:

=over

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

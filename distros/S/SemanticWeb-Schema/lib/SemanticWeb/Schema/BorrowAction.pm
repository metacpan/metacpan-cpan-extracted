use utf8;

package SemanticWeb::Schema::BorrowAction;

# ABSTRACT: The act of obtaining an object under an agreement to return it at a later date

use Moo;

extends qw/ SemanticWeb::Schema::TransferAction /;


use MooX::JSON_LD 'BorrowAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has lender => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'lender',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BorrowAction - The act of obtaining an object under an agreement to return it at a later date

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

=for html The act of obtaining an object under an agreement to return it at a later
date. Reciprocal of LendAction.<br/><br/> Related actions:<br/><br/> <ul>
<li><a class="localLink"
href="http://schema.org/LendAction">LendAction</a>: Reciprocal of
BorrowAction.</li> </ul> 

=head1 ATTRIBUTES

=head2 C<lender>

A sub property of participant. The person that lends the object being
borrowed.

A lender should be one of the following types:

=over

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

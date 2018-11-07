use utf8;

package SemanticWeb::Schema::WinAction;

# ABSTRACT: The act of achieving victory in a competitive activity.

use Moo;

extends qw/ SemanticWeb::Schema::AchieveAction /;


use MooX::JSON_LD 'WinAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has loser => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'loser',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::WinAction - The act of achieving victory in a competitive activity.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The act of achieving victory in a competitive activity.

=head1 ATTRIBUTES

=head2 C<loser>

A sub property of participant. The loser of the action.

A loser should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::AchieveAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

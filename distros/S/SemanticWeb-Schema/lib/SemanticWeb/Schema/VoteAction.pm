use utf8;

package SemanticWeb::Schema::VoteAction;

# ABSTRACT: The act of expressing a preference from a fixed/finite/structured set of choices/options.

use Moo;

extends qw/ SemanticWeb::Schema::ChooseAction /;


use MooX::JSON_LD 'VoteAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has candidate => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'candidate',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::VoteAction - The act of expressing a preference from a fixed/finite/structured set of choices/options.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

The act of expressing a preference from a fixed/finite/structured set of
choices/options.

=head1 ATTRIBUTES

=head2 C<candidate>

A sub property of object. The candidate subject of this action.

A candidate should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::ChooseAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

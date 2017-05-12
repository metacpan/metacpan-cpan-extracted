use strict; use warnings;
package Perl::Tags::Naive::Moose;

use parent 'Perl::Tags::Naive';

our $VERSION = '0.32';

=head2 C<get_parsers>

The following parsers are defined by this module.

=over 4

=cut

sub get_parsers
{
	my $self = shift;
	return (
		$self->SUPER::get_parsers(),
		$self->can('extends_line'),
		$self->can('with_line'),
		$self->can('has_line'),
		$self->can('around_line'),
		$self->can('before_line'),
		$self->can('after_line'),
		$self->can('override_line'),
		$self->can('augment_line'),
		$self->can('class_line'),
		$self->can('method_line'),
		$self->can('role_line'),
	);
}

=item C<extends_line>

Parse the declaration of a 'extends' Moose keyword, returning a L<Perl::Tags::Tag::Extends> if found.

=cut

sub extends_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/extends\s+["']?((?:\w+|::)+)\b/) {
	return Perl::Tags::Tag::Recurse->new(
	    name    => $1,
	    line    => 'dummy',
	);
    }
    return;
}

=item C<with_line>

Parse the declaration of a 'with' Moose keyword, returning a L<Perl::Tags::Tag::With> tag if found.

=cut

sub with_line {
    my ( $self, $line, $statement, $file ) = @_;
    if ( $statement =~ m/\bwith\s+(?:qw.)?\W*([a-zA-Z0-9_: ]+)/ ) {
        my @roles = split /\s+/, $1;
        my @returns;
        foreach my $role (@roles) {
            push @returns, Perl::Tags::Tag::Recurse->new(
		name    => $role,
		line    => 'dummy',
            );
        }
        return @returns;
    }
    return;
}

=item C<has_line>

Parse the declaration of a 'has' Moose keyword, returning a L<Perl::Tags::Tag::Has> if found.

=cut

sub has_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/\bhas\s+["']?(\w+)\b/) {
        return (
            Perl::Tags::Tag::Has->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<around_line>

Parse the declaration of a 'around' Moose keyword, returning a L<Perl::Tags::Tag::Around> tag if found.

=cut

sub around_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/around\s+["'](\w+)\b/) {
        return (
            Perl::Tags::Tag::Around->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<before_line>

Parse the declaration of a 'before' Moose keyword, returning a L<Perl::Tags::Tag::Before> tag if found.

=cut

sub before_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/before\s+["'](\w+)\b/) {
        return (
            Perl::Tags::Tag::Before->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<after_line>

Parse the declaration of a 'after' Moose keyword, returning a L<Perl::Tags::Tag::After> tag if found.

=cut

sub after_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/after\s+["'](\w+)\b/) {
        return (
            Perl::Tags::Tag::After->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<override_line>

Parse the declaration of a 'override' Moose keyword, returning a L<Perl::Tags::Tag::Override> tag if found.

=cut

sub override_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/override\s+["'](\w+)\b/) {
        return (
            Perl::Tags::Tag::Override->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<augment_line>

Parse the declaration of a 'augment' Moose keyword, returning a L<Perl::Tags::Tag::Augment> tag if found.

=cut

sub augment_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/augment\s+["']?(\w+)\b/) {
        return (
            Perl::Tags::Tag::Augment->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<class_line>

Parse the declaration of a 'class' Moose keyword, returning a L<Perl::Tags::Tag::Class> tag if found.

=cut

sub class_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/class\s+(\w+)\b/) {
        return (
            Perl::Tags::Tag::Class->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<method_line>

Parse the declaration of a 'method' Moose keyword, returning a L<Perl::Tags::Tag::Method> tag if found.

=cut

sub method_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/method\s+(\w+)\b/) {
        return (
            Perl::Tags::Tag::Method->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<role_line>

Parse the declaration of a 'role' Moose keyword, returning a L<Perl::Tags::Tag::Role> tag if found.

=cut

sub role_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/role\s+(\w+)\b/) {
        return (
            Perl::Tags::Tag::Role->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=head1 C<Perl::Tags::Tag::Method>

=head2 C<type>: Method

=cut

package Perl::Tags::Tag::Method;
our @ISA = qw/Perl::Tags::Tag::Sub/;

sub type { 'Method' }


=head1 C<Perl::Tags::Tag::Has>

=head2 C<type>: Has

=cut

package Perl::Tags::Tag::Has;
our @ISA = qw/Perl::Tags::Tag::Method/;

sub type { 'Has' }

=head1 C<Perl::Tags::Tag::Around>

=head2 C<type>: Around

=cut

package Perl::Tags::Tag::Around;
our @ISA = qw/Perl::Tags::Tag::Method/;

sub type { 'Around' }

=head1 C<Perl::Tags::Tag::Before>

=head2 C<type>: Before

=cut

package Perl::Tags::Tag::Before;
our @ISA = qw/Perl::Tags::Tag::Method/;

sub type { 'Before' }

=head1 C<Perl::Tags::Tag::After>

=head2 C<type>: After

=cut

package Perl::Tags::Tag::After;
our @ISA = qw/Perl::Tags::Tag::Method/;

sub type { 'After' }

=head1 C<Perl::Tags::Tag::Override>

=head2 C<type>: Override

=cut

package Perl::Tags::Tag::Override;
our @ISA = qw/Perl::Tags::Tag::Method/;

sub type { 'Override' }

=head1 C<Perl::Tags::Tag::Augment>

=head2 C<type>: Augment

=cut

package Perl::Tags::Tag::Augment;
our @ISA = qw/Perl::Tags::Tag::Method/;

sub type { 'Augment' }

=head1 C<Perl::Tags::Tag::Class>

=head2 C<type>: Class

=cut

package Perl::Tags::Tag::Class;
our @ISA = qw/Perl::Tags::Tag::Package/;

sub type { 'Class' }

=head1 C<Perl::Tags::Tag::Role>

=head2 C<type>: Role

=cut

package Perl::Tags::Tag::Role;
our @ISA = qw/Perl::Tags::Tag::Package/;

sub type { 'Role' }

1;

=head1 AUTHOR and LICENSE

    dr bean - drbean at sign cpan a dot org

This is licensed under the same terms as Perl itself.  (Or as Vim if you +prefer).

=cut

# vim: set ts=8 sts=4 sw=4 noet:

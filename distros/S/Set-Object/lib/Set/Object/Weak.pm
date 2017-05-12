
=head1 NAME

Set::Object::Weak - Sets without the referant reference increment

=head1 SYNOPSIS

 use Set::Object::Weak qw(weak_set);

 my $set = Set::Object::Weak->new( 0, "", {}, [], $object );
 # or
 my $set = weak_set( 0, "", {}, [], $object );

 print $set->size;  # 2 - the scalars aren't objects

=head1 DESCRIPTION

Sets, but weak.  See L<Set::Object/weaken>.

Note that the C<set> in C<Set::Object::Weak> returns weak sets.  This
is intentional, so that you can make all the sets in scope weak just
by changing C<use Set::Object> to C<use Set::Object::Weak>.

=cut

package Set::Object::Weak;
use strict;
use base qw(Set::Object);  # boo hiss no moose::role yet I hear you say

use base qw(Exporter);     # my users would hate me otherwise
use vars qw(@ISA @EXPORT_OK);
use Set::Object qw(blessed);

our @EXPORT_OK = qw(weak_set set);

=head1 CONSTRUCTORS

=over

=item new

This class method is exactly the same as C<Set::Object-E<gt>new>,
except that it returns a weak set.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->weaken;
    $self->insert(@_);
    $self;
}

=item weak_set( ... )

This optionally exported B<function> is a shortcut for saying
C<Set::Object::Weak-E<gt>new(...)>.

=cut


sub weak_set {
    __PACKAGE__->new(@_);
}

=item set( ... )

This method is exported so that if you see:

 use Set::Object qw(set);

You can turn it into using weak sets lexically with:

 use Set::Object::Weak qw(set);

Set::Object 1.19 had a bug in this method that meant that it would not
add the passed members into it.

=cut

sub set {
    my $class = __PACKAGE__;
    if (blessed $_[0] and $_[0]->isa("Set::Object")) {
    	$class = (shift)->strong_pkg;
    }
    $class->new(@_);
}

1;

__END__

=back

=head1 SEE ALSO

L<Set::Object>

=head1 CREDITS

Perl magic by Sam Vilain, <samv@cpan.org>

Idea from nothingmuch.

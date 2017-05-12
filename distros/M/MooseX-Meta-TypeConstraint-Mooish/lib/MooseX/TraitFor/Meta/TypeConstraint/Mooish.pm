#
# This file is part of MooseX-Meta-TypeConstraint-Mooish
#
# This software is Copyright (c) 2015 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::TraitFor::Meta::TypeConstraint::Mooish;
our $AUTHORITY = 'cpan:RSRCHBOY';
$MooseX::TraitFor::Meta::TypeConstraint::Mooish::VERSION = '0.001';
# ABSTRACT: Handle Moo-style constraints

use Moose::Role;
use namespace::autoclean 0.24;
use Try::Tiny;


has original_constraint => (
    is        => 'ro',
    isa       => 'CodeRef',
    writer    => '_set_original_constraint',
    predicate => 'has_original_constraint',
);


has mooish => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);


before compile_type_constraint => sub {
    my $self = shift @_;

    ### only wrap our given constraint iff we're supposed to be mooish...
    return unless $self->mooish;

    ### wrap our type constraint, and set it...
    my $wrapped_constraint = $self->_wrap_constraint($self->constraint);
    $self->_set_original_constraint($self->constraint);
    $self->_set_constraint($wrapped_constraint);

    return;
};

sub _wrap_constraint {
    my ($self, $constraint) = @_;

    # call the original constraint.  if it does not die, return true; if it
    # does die, return false.  We might do something with the fail message
    # down the road, but not right now.

    return sub {
        my @args = @_;
        my $fail_msg = try {
            local $_ = $args[0];
            $constraint->(@args);
            return;
        }
        catch {
            return $_;
        };

        return !$fail_msg;
    };
}


around create_child_type => sub {
    my ($orig, $self) = (shift, shift);

    return $self->$orig(mooish => 0, @_);
};

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl mooish

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

MooseX::TraitFor::Meta::TypeConstraint::Mooish - Handle Moo-style constraints

=head1 VERSION

This document describes version 0.001 of MooseX::TraitFor::Meta::TypeConstraint::Mooish - released March 12, 2015 as part of MooseX-Meta-TypeConstraint-Mooish.

=head1 SYNOPSIS

This trait implements the functionality described in
L<MooseX::Meta::TypeConstraint::Mooish>, and you, dear reader, are encouraged
to read about it over there.  Here we simply document the nuts and bolts.

=head1 DESCRIPTION

    # determining where this goes is left as an exercise for the reader
    with 'MooseX::TraitFor::Meta::TypeConstraint::Mooish';

=head1 ATTRIBUTES

=head2 original_constraint

The original constraint CodeRef is stashed away here.

=head2 mooish

If true, the constraint should be considered written in the style of L<Moo> constraints; that is, if an exception is thrown the
constraint is considered to have failed; otherwise it passes.  Return values are ignored.

Default is true.

=head1 METHODS

=head2 original_constraint()

Reader for the L</original_constraint> attribute; returns the original
constraint as passed to new().

=head2 has_original_constraint()

Predicate for the L</original_constraint> attribute.

=head2 mooish()

Reader for the L</mooish> attribute.

=head2 compile_type_constraint

If L</mooish> is true, we wrap the L</original_constraint> in a sub that translates L<Moo> behaviors
(die on fail; otherwise success) to L<Moose::Meta::TypeConstraint> expectations (false on fail; true on success).

We stash the original constraint in L</original_constraint> (surprise!),
and set the L<constraint attribute|Moose::Meta::TypeConstraint/constraint> to
the wrapped constraint.

=head2 create_child_type

Subtypes created here are not mooish, unless an explicit C<mooish => 1> is
passed.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::Meta::TypeConstraint::Mooish|MooseX::Meta::TypeConstraint::Mooish>

=item *

L<MooseX::Meta::TypeConstraint::Mooish|MooseX::Meta::TypeConstraint::Mooish>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/moosex-meta-typeconstraint-mooish>
and may be cloned from L<git://https://github.com/RsrchBoy/moosex-meta-typeconstraint-mooish.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/moosex-meta-typeconstraint-mooish/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-meta-typeconstraint-mooish&title=RsrchBoy's%20CPAN%20MooseX-Meta-TypeConstraint-Mooish&tags=%22RsrchBoy's%20MooseX-Meta-TypeConstraint-Mooish%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-meta-typeconstraint-mooish&title=RsrchBoy's%20CPAN%20MooseX-Meta-TypeConstraint-Mooish&tags=%22RsrchBoy's%20MooseX-Meta-TypeConstraint-Mooish%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

#
# This file is part of MooseX-Meta-TypeConstraint-Mooish
#
# This software is Copyright (c) 2015 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::Meta::TypeConstraint::Mooish;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: e3cfe12
$MooseX::Meta::TypeConstraint::Mooish::VERSION = '0.001';

# ABSTRACT: Translate Moo-style constraints to Moose-style

use Moose;
use namespace::autoclean 0.24;

extends 'Moose::Meta::TypeConstraint';
with 'MooseX::TraitFor::Meta::TypeConstraint::Mooish';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

MooseX::Meta::TypeConstraint::Mooish - Translate Moo-style constraints to Moose-style

=head1 VERSION

This document describes version 0.001 of MooseX::Meta::TypeConstraint::Mooish - released March 12, 2015 as part of MooseX-Meta-TypeConstraint-Mooish.

=head1 SYNOPSIS

    # easiest is via AttributeShortcuts
    use MooseX::AttributeShortcuts 0.028;

    has foo => (
        is  => 'rw',
        isa => sub { die unless $_[0] == 5 },
    );

    # or, the hard way
    use MooseX::Meta::TypeConstraint::Mooish;

    has foo => (
        is  => 'rw',
        isa => MooseX::Meta::TypeConstraint::Mooish->new(
            constraint => sub { die unless $_[0] == 5 },
        ),
    );

=head1 DESCRIPTION

L<Moose type constraints|Moose::Meta::TypeConstraint> are expected to return
true if the value passes the constraint, and false otherwise; L<Moo>
"constraints", on the other hand, die if validation fails.

This metaclass allows for Moo-style constraints; it will wrap them and
translate their Moo into a dialect Moose understands.

Note that this is largely to enable functionality in
L<MooseX::AttributeShortcuts>; the easiest way use this metaclass is by using
that package.  Also, as it's not inconceivable that this functionality may be
desired in other constraint metaclasses, the bulk of this metaclass'
functionality is implemented as
L<a trait|MooseX::TraitFor::Meta::TypeConstraint::Mooish>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::AttributeShortcuts|MooseX::AttributeShortcuts>

=item *

L<MooseX::TraitFor::Meta::TypeConstraint::Mooish|MooseX::TraitFor::Meta::TypeConstraint::Mooish>

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

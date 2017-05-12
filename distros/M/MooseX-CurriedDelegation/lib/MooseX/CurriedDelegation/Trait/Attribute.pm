#
# This file is part of MooseX-CurriedDelegation
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::CurriedDelegation::Trait::Attribute;
our $AUTHORITY = 'cpan:RSRCHBOY';
$MooseX::CurriedDelegation::Trait::Attribute::VERSION = '0.003';
# ABSTRACT: The great new MooseX::CurriedDelegation!

use Moose::Role;
use namespace::autoclean;
use MooseX::Util 'with_traits';

use aliased 'MooseX::CurriedDelegation::Trait::Method::Delegation' => 'OurMethodTrait';



sub method_curried_delegation_metaclass {
    my $self = shift @_;

    return with_traits($self->delegation_metaclass => OurMethodTrait);
}

around _make_delegation_method => sub {
    my ($orig, $self) = (shift, shift);
    my ($handle_name, $delegation_hash) = @_;

    ### $delegation_hash
    return $self->$orig(@_)
        unless 'HASH' eq ref $delegation_hash;

    confess "We should never have more than one key when setting up delegation: $handle_name"
        if keys %$delegation_hash > 1;

    my ($method_to_call) = keys %$delegation_hash;
    my @curry_args       = @{ $delegation_hash->{$method_to_call} };
    my $curry_coderef    = shift @curry_args;

    ### $method_to_call
    ### @curry_args

    return $self->method_curried_delegation_metaclass->new(
        name               => $handle_name,
        package_name       => $self->associated_class->name,
        attribute          => $self,
        delegate_to_method => $method_to_call,
        curry_coderef      => $curry_coderef,
        curried_arguments  => \@curry_args,
    );
};

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

MooseX::CurriedDelegation::Trait::Attribute - The great new MooseX::CurriedDelegation!

=head1 VERSION

This document describes version 0.003 of MooseX::CurriedDelegation::Trait::Attribute - released November 09, 2016 as part of MooseX-CurriedDelegation.

=head1 DESCRIPTION

This is just a trait applied to the delegation method metaclass (generally
L<Moose::Meta::Method::Delegation>).  No user-serviceable parts here.

=head1 METHODS

=head2 method_curried_delegation_metaclass

Returns a class composed of the applied class' delegation metaclass and our
delegation method trait.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::CurriedDelegation|MooseX::CurriedDelegation>

=item *

L<MooseX::CurriedDelegation>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/moosex-currieddelegation/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-currieddelegation&title=RsrchBoy's%20CPAN%20MooseX-CurriedDelegation&tags=%22RsrchBoy's%20MooseX-CurriedDelegation%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-currieddelegation&title=RsrchBoy's%20CPAN%20MooseX-CurriedDelegation&tags=%22RsrchBoy's%20MooseX-CurriedDelegation%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

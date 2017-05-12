#
# This file is part of MooseX-Util
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::Util::Meta::Class;
our $AUTHORITY = 'cpan:RSRCHBOY';
$MooseX::Util::Meta::Class::VERSION = '0.006';
# ABSTRACT: A helper metaclass

use Moose;
use namespace::autoclean;

extends 'Moose::Meta::Class';
with 'MooseX::TraitFor::Meta::Class::BetterAnonClassNames';

# NOTE: making this package immutable breaks our metaclass compatibility!
#__PACKAGE__->meta->make_immutable;
!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl BetterAnonClassNames

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

MooseX::Util::Meta::Class - A helper metaclass

=head1 VERSION

This document describes version 0.006 of MooseX::Util::Meta::Class - released June 26, 2015 as part of MooseX-Util.

=head1 SYNOPSIS

    # create a new type of Zombie catcher equipped with machete and car
    my $meta = MooseX::Util::Meta::Class->create_anon_class(
        'Zombie::Catcher' => qw{
            Zombie::Catcher::Tools::Machete
            Zombie::Catcher::Tools::TracyChapmansFastCar
         },
     );

    # created anon classname is: Zombie::Catcher::__ANON__::SERIAL::42

=head1 DESCRIPTION

This is a trivial extension of L<Moose::Meta::Class> that consumes the
L<BetterAnonClassNames|MooseX::TraitFor::Meta::Class::BetterAnonClassNames>
trait.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::Util|MooseX::Util>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/moosex-util/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-util&title=RsrchBoy's%20CPAN%20MooseX-Util&tags=%22RsrchBoy's%20MooseX-Util%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-util&title=RsrchBoy's%20CPAN%20MooseX-Util&tags=%22RsrchBoy's%20MooseX-Util%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

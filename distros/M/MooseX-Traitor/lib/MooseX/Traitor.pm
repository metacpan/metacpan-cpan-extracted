#
# This file is part of MooseX-Traitor
#
# This software is Copyright (c) 2015 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::Traitor;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: cea3b2c
$MooseX::Traitor::VERSION = '0.006';

# ABSTRACT: An alternate way to compose your classes with traits

use Moose::Role;
use namespace::autoclean;
use MooseX::Util ();


sub with_traits {
    my ($thing, @traits) = @_;

    my $class = blessed $thing || $thing;

    return MooseX::Util::with_traits($class => @traits);
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl composable CLOS behaviour behaviours

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

MooseX::Traitor - An alternate way to compose your classes with traits

=head1 VERSION

This document describes version 0.006 of MooseX::Traitor - released June 25, 2015 as part of MooseX-Traitor.

=head1 SYNOPSIS

    # in your class definition...
    package MyClass;
    use Moose;
    use namespace::autoclean;

    with 'MooseX::Traitor';

    # somewhere else in Gotham...
    my $thinger = MyClass->with_traits('Thinger::Trait1')->new(...);

=head1 DESCRIPTION

One of the most powerful things about L<Moose> is that with roles and easy
"anonymous" class creation we are blessed with a fantastic new way of
creating classes, often on the fly, out of other classes and those composable
bits of behaviour, roles.

Even better, this application of discrete chunks of behaviours enables people
simply using a class to extend and tweak its behaviour in new ways -- possibly
ways never contemplated by the authors of the classes being altered.

=head1 METHODS

=head2 with_traits(<trait1>, ...)

This method builds an anonymous class from the consuming class and any traits
specified.

You may use the full trait specification syntax, e.g.:

    MyClass->with_traits('My::Trait' => { -excludes => ... })

Calling this routine with no traits specified will simply return the name of
the class.  This is not considered an error.

Note that we handle being called directly against a package (e.g.
C<< MyClass->with_traits(...) >>) and against an instance (e.g.
C<< $self->with_traits(...) >>) identically; in each instance the class
referenced is subclassed.

=head1 ROLES OR TRAITS?

There are many different definitions of what a role is vs a trait, ranging
from "hey man, it's all cool" to "CLOS calls them all traits SO TRAITS IS THE
ONE TRUE NAME", it seems that most people tend to think of them this way:

Roles are traits that a class knowingly consumes (e.g. via with()).

Traits are roles that are applied without the class' consent (e.g. anonymous
subclass composition or C<< $trait_meta->apply('ClassThinger') >>).

Or maybe that's just what this author is imposing on everyone else.  Either
way, that's what we'll be using here if the definition ever becomes important.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/moosex-traitor/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-traitor&title=RsrchBoy's%20CPAN%20MooseX-Traitor&tags=%22RsrchBoy's%20MooseX-Traitor%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-traitor&title=RsrchBoy's%20CPAN%20MooseX-Traitor&tags=%22RsrchBoy's%20MooseX-Traitor%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

#
# This file is part of MooseX-Util
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::Util;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.005-4-gcb0aacd
$MooseX::Util::VERSION = '0.006';

# ABSTRACT: Moose::Util extensions

use strict;
use warnings;

use parent 'Moose::Util';

use Sub::Exporter::Progressive -setup => {
    exports => [
        qw{
            add_method_modifier
            apply_all_roles
            does_role
            english_list
            ensure_all_roles
            find_meta
            get_all_attribute_values
            get_all_init_args
            is_role
            meta_attribute_alias
            meta_class_alias
            resolve_metaclass_alias
            resolve_metatrait_alias
            search_class_by_role
            throw_exception
            with_traits
        },

        # and our own...
        qw{
            is_private
        },
    ],
    groups => { default => [ ':all' ] },
};

use Carp 'confess';
use MooseX::Util::Meta::Class;


# TODO allow with_traits() to be curried with different class metaclasses?

sub with_traits {
    my ($class, @roles) = @_;
    return $class unless @roles;
    return MooseX::Util::Meta::Class->create_anon_class(
        superclasses => [$class],
        roles        => \@roles,
        cache        => 1,
    )->name;
}


sub is_private($) {
    my ($name) = @_;

    confess 'is_private() must be called with a name to test!'
        unless $name;

    return 1 if $name =~ /^_/;
    return;
}

sub find_meta { goto \&Moose::Util::find_meta }

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

MooseX::Util - Moose::Util extensions

=head1 VERSION

This document describes version 0.006 of MooseX::Util - released June 26, 2015 as part of MooseX-Util.

=head1 SYNOPSIS

    use MooseX::Util qw{ ensure_all_roles with_traits };

    # profit!

=head1 DESCRIPTION

This is a utility module that handles all of the same functions that
L<Moose::Util> handles.  In fact, most of the functions exported by this
package are simply re-exports from L<Moose::Util>, so you're recommended to
read the documentation of that module for a comprehensive view.

However.

We've re-implemented a number of the functions our parent provides, for a
variety of reasons.  Those functions are documented here.

=head1 FUNCTIONS

=head2 with_traits(<classname> => (<trait1>, ... ))

Given a class and one or more traits, we construct an anonymous class that is
a subclass of the given class and consumes the traits given.  This is exactly
the same as L<Moose::Util/with_traits>, except that we use
L<MooseX::Util::Meta::Class/create_anon_class> to construct the anonymous
class, rather than L<Moose::Meta::Class/create_anon_class> directly.

Essentially, this means that when we do:

    my $anon_class_name = with_traits('Zombie::Catcher', 'SomeTrait');

For $anon_class_name we get:

    Zombie::Catcher::__ANON__::SERIAL::1

Rather than:

    Moose::Meta::Class::__ANON__::SERIAL::1

This is nice because we have an idea of where the first anonymous class came
from, whereas the second one could could be from anywhere.

=head2 is_private

    # true if "private"
    ... if is_private('_some_name');

Ofttimes we need to determine if a name is considered "private" or not.  By convention,
method, attribute, and other names are considered private if their first character is
an underscore.

While trivial to test for, this allows us to centralize the tests in one place.

=for Pod::Coverage find_meta

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Moose::Util>

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

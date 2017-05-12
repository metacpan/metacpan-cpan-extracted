#
# This file is part of Reindeer
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Reindeer::Types;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Reindeer::Types::VERSION = '0.018';
# ABSTRACT: Reindeer combined type library

use strict;
use warnings;

use base 'MooseX::Types::Combine';

use Reindeer::Util;

# no provision for filtering
__PACKAGE__->provide_types_from(Reindeer::Util::type_libraries());

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Reindeer::Types - Reindeer combined type library

=head1 VERSION

This document describes version 0.018 of Reindeer::Types - released March 28, 2015 as part of Reindeer.

=head1 SYNOPSIS

    package Foo;
    use Moose;
    use Reindeer::Types ':all';

=head1 DESCRIPTION

This is a combined type library, allowing for the quick and easy import of all
the type libraries L<Reindeer> provides by default.  Its primary goal is to
make the types easily available even when using Reindeer isn't an option.

It is not necessary (or prudent) to directly use this in a Reindeer class (or
role).

=head1 TYPES

=head2 C<LoadableClass>

A normal class / package.

=head2 C<LoadableRole>

Like C<LoadableClass>, except the loaded package must be a L<Moose::Role>.

=head2 C<SimpleStr>

A C<Str> with no new-line characters.

=head2 C<NonEmptySimpleStr>

A C<Str> with no new-line characters and length > 0

=head2 C<LowerCaseSimpleStr>

A C<Str> with no new-line characters, length > 0 and no uppercase characters
A coercion exists via C<lc> from C<NonEmptySimpleStr>

=head2 C<UpperCaseSimpleStr>

A C<Str> with no new-line characters, length > 0 and no lowercase characters
A coercion exists via C<uc> from C<NonEmptySimpleStr>

=head2 C<Password>

=head2 C<StrongPassword>

=head2 C<NonEmptyStr>

A C<Str> with length > 0

=head2 C<LowerCaseStr>

A C<Str> with length > 0 and no uppercase characters.
A coercion exists via C<lc> from C<NonEmptyStr>

=head2 C<UpperCaseStr>

A C<Str> with length > 0 and no lowercase characters.
A coercion exists via C<uc> from C<NonEmptyStr>

=head2 C<NumericCode>

A C<Str> with no new-line characters that consists of only Numeric characters.
Examples include, Social Security Numbers, Personal Identification Numbers, Postal Codes, HTTP Status
Codes, etc. Supports attempting to coerce from a string that has punctuation
in it ( e.g credit card number 4111-1111-1111-1111 ).

=head2 C<PositiveNum>

=head2 C<PositiveOrZeroNum>

=head2 C<PositiveInt>

=head2 C<PositiveOrZeroInt>

=head2 C<NegativeNum>

=head2 C<NegativeOrZeroNum>

=head2 C<NegativeInt>

=head2 C<NegativeOrZeroInt>

=head2 C<SingleDigit>

=head2 IxHash

Base type: TiedHash

This type coerces from ArrayRef.  As of 0.004 we no longer coerce from
HashRef, as that lead to 1) annoyingly easy to miss errors involving expecting
C<$thing->attribute( { a => 1, b => 2, ... } )> to result in proper ordering;
and 2) the Hash native trait appearing to work normally but instead silently
destroying the preserved order (during certain write operations).

(See also L<MooseX::Types::Tied::Hash::IxHash>.)

=head2 Dir

    has 'dir' => (
        is       => 'ro',
        isa      => Dir,
        required => 1,
        coerce   => 1,
    );

(See also L<MooseX::Types::Path::Class>.)

=head2 File

    has 'file' => (
        is       => 'ro',
        isa      => File,
        required => 1,
        coerce   => 1,
    );

(See also L<MooseX::Types::Path::Class>.)

=head2 MooseX::Types::Moose

We provide all Moose native types by including L<MooseX::Types::Moose>; see
that package for more information.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reindeer|Reindeer>

=item *

L<L<Reindeer> has the full list of type libraries we incorporate.|L<Reindeer> has the full list of type libraries we incorporate.>

=item *

L<L<MooseX::Types::Combine>.|L<MooseX::Types::Combine>.>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/reindeer>
and may be cloned from L<git://https://github.com/RsrchBoy/reindeer.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/reindeer/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Freindeer&title=RsrchBoy's%20CPAN%20Reindeer&tags=%22RsrchBoy's%20Reindeer%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Freindeer&title=RsrchBoy's%20CPAN%20Reindeer&tags=%22RsrchBoy's%20Reindeer%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

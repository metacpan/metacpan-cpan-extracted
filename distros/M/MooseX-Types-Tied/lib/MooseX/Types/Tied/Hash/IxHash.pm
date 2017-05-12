#
# This file is part of MooseX-Types-Tied
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::Types::Tied::Hash::IxHash;
{
  $MooseX::Types::Tied::Hash::IxHash::VERSION = '0.003';
}

# ABSTRACT: Moose type library for Tie::IxHash tied hashes

use strict;
use warnings;

use MooseX::Types -declare => [ qw{ IxHash } ];
#use namespace::clean;

use Scalar::Util qw{ blessed };
use Tie::IxHash;
use MooseX::Types::Moose ':all';
use MooseX::Types::Tied  ':all';

subtype IxHash,
    as TiedHash,
    where { blessed(tied %$_) eq 'Tie::IxHash' },
    message { 'Referenced hash is not tied to an Tie::IxHash: ' . ref tied $_ },
    ;

coerce IxHash,
    from ArrayRef,
    via { tie my %x, 'Tie::IxHash', @{$_}; \%x },
    ;

1;



=pod

=encoding utf-8

=head1 NAME

MooseX::Types::Tied::Hash::IxHash - Moose type library for Tie::IxHash tied hashes

=head1 VERSION

This document describes version 0.003 of MooseX::Types::Tied::Hash::IxHash - released April 21, 2012 as part of MooseX-Types-Tied.

=head1 SYNOPSIS

    use Moose;
    use MooseX::Types::Tied::Hash::IxHash ':all';

    has tied_array => (is => 'ro', isa => IxHash);

    # etc...

=head1 DESCRIPTION

This is a collection of L<Moose> types and coercion settings for L<Tie::IxHash>
tied hashes.

The package behaves as you'd expect a L<MooseX::Types> library to act: either
specify the types you want imported explicitly or use the ':all' catchall.

=for stopwords TiedArray TiedHash TiedHandle IxHash

=head1 TYPES

=head2 IxHash

Base type: TiedHash

This type coerces from ArrayRef.  As of 0.004 we no longer coerce from
HashRef, as that lead to 1) annoyingly easy to miss errors involving expecting
C<$thing->attribute( { a => 1, b => 2, ... } )> to result in proper ordering;
and 2) the Hash native trait appearing to work normally but instead silently
destroying the preserved order (during certain write operations).

=head1 WARNING!

This type is not compatible with the write operations allowed by the Hash
Moose native attribute trait.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::Types::Tied|MooseX::Types::Tied>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/moosex-types-tied>
and may be cloned from L<git://github.com/RsrchBoy/moosex-types-tied.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/moosex-types-tied/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__


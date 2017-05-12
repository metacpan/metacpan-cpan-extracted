#
# This file is part of MooseX-Types-Tied
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::Types::Tied;
{
  $MooseX::Types::Tied::VERSION = '0.003';
}

# ABSTRACT: Basic tied Moose types library

use strict;
use warnings;

use MooseX::Types -declare => [ qw{ Tied TiedHash TiedArray TiedHandle } ];
use MooseX::Types::Moose ':all';

#use namespace::clean;

subtype Tied,
    as Ref,
    where { defined tied $$_ },
    message { 'Referenced scalar is not tied!' },
    ;

subtype TiedArray,
    as ArrayRef,
    where { defined tied @$_ },
    message { 'Array is not tied!' },
    ;

subtype TiedHash,
    as HashRef,
    where { defined tied %$_ },
    message { 'Hash is not tied!' },
    ;

subtype TiedHandle,
    as FileHandle,
    where { defined tied $$_ },
    message { 'Handle is not tied!' },
    ;

1;



=pod

=encoding utf-8

=head1 NAME

MooseX::Types::Tied - Basic tied Moose types library

=head1 VERSION

This document describes version 0.003 of MooseX::Types::Tied - released April 21, 2012 as part of MooseX-Types-Tied.

=head1 SYNOPSIS

    use Moose;
    use MooseX::Types::Tied ':all';

    has tied_array => (is => 'ro', isa => TiedArray);

    # etc...

=head1 DESCRIPTION

This is a collection of basic L<Moose> types for tied references.  The package
behaves as you'd expect a L<MooseX::Types> library to act: either specify the
types you want imported explicitly or use the ':all' catchall.

=for stopwords TiedArray TiedHash TiedHandle

=head1 TYPES

=head2 Tied

Base type: Ref (to Scalar)

=head2 TiedArray

Base type: ArrayRef

=head2 TiedHash

Base type: HashRef

=head2 TiedHandle

Base type: FileHandle

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


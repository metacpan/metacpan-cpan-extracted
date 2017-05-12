# String::FixedLen.pm
#
# Copyright (c) 2007 David Landgren
# All rights reserved

=head1 NAME

String::FixedLen - Create strings that will never exceed a specific length

=head1 VERSION

This document describes version 0.02 of String::FixedLen, released
2007-08-03.

=head1 SYNOPSIS

  use String::FixedLen;

  tie my $str, 'String::FixedLen', 4;

  $str = 'a';
  $str .= 'cheater;        # "ache"
  $str = "hello, world\n"; # "hell"
  $str = 9999 + 12;        # "1001"

  # and so on

=head1 DESCRIPTION

C<String::FixedLen> is used to create strings that can never exceed a fixed length.
Whenever an assignment would cause the string to exceed the limit, it is clamped
to the maximum length and the remaining characters are discarded.

=head1 DIAGNOSTICS

None.

=head1 NOTES

The source scalar that is being assigned to a String::FixedLen
scalar may be huge:

   my $big = 'b' x 1_000_000;
   $fixed = $big;

but at no point will the FixedLen string ever exceed its upper limit.

=head1 BUGS

Please report all bugs at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-FixedLen|rt.cpan.org>

Make sure you include the output from the following two commands:

  perl -MString::FixedLen -le 'print $String::FixedLen::VERSION'
  perl -V

=head1 ACKNOWLEDGEMENTS

The idea for this module came up during a discussion on the French
perl mailing list (perl@mongueurs.net).

=head1 AUTHOR

David Landgren, copyright (C) 2007. All rights reserved.

http://www.landgren.net/perl/

If you (find a) use this module, I'd love to hear about it. If you
want to be informed of updates, send me a note. You know my first
name, you know my domain. Can you guess my e-mail address?

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package String::FixedLen;

use strict;

use vars '$VERSION';
$VERSION = '0.02';

sub TIESCALAR {
    my $class = shift;
    my $len   = shift;
    return bless { s => undef, len => $len}, $class;
}

sub STORE {
    my $self = shift;
    $self->{s} = length $_[0] > $self->{len}
        ? substr($_[0], 0, $self->{len})
        : $_[0]
    ;
}

sub FETCH {
    $_[0]->{s};
}

1;

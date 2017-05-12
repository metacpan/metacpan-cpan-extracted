# Copyright (c) 2011 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package Regexp::Common::Chess;

use warnings;
use strict;
use Regexp::Common qw/pattern no_defaults/;

use vars qw/$VERSION/;
$VERSION = '0.1';

my $check     = '[+#]';
my $rank      = '[1-8]';
my $file      = '[a-h]';
my $piece     = '[KNBQR]';

my $promotion = "x?${file}[18]=(?!K)$piece";
my $pawnmove  = "(?:$file?x)?$file(?![18])$rank";
my $stdmove   = "$piece$file?$rank?x?$file$rank";
my $castling  = "O-O(?:-O)?";

pattern name => ['Chess' => 'SAN'],
        create => "(?-i:(?:$promotion|$castling|$pawnmove|$stdmove)$check?)"
        ;

=head1 NAME

Regexp::Common::Chess - regexp for algebraic notation in chess

=head1 SYNOPSIS

 use Regexp::Common qw/Chess/;

 my $move = 'Rxh7+';
 if($move =~ /^$RE{Chess}{SAN}$/) {
         say "Yay! A valid chess move!";
 } else {
         say "Sad to say, that doesn't look valid...";
 }

=head1 DESCRIPTION

This module defines a regular expression for use when parsing
standard algebaric notation (SAN) as specified in the Portable
Game Notation (PGN) standard (export format). It is not a
complete PGN regexp. It is limited to only match one specific
move at a time.

=head1 SEE ALSO

The PGN format, including its SAN specification, is documented
in the "Portable Game Notation Specification and Implementation 
Guide", available here:

=over

=item * L<http://www.chessclub.com/help/PGN-spec>

=back

The L<Regexp::Common> manual documents the use of the
Regexp::Common framework and interface, used by
Regexp::Common::Chess.

=head1 AVAILABILITY

The latest released code of this module is available from CPAN.

The latest development, useful for contributing and for those
living on the edge etc. is available from Github:

=over

=item * L<https://github.com/olof/Regexp-Common-Chess>

=back

=head1 COPYRIGHT

 Copyright (c) 2011 - Olof Johansson <olof@cpan.org>
 All rights reserved.

 This program is free software; you can redistribute it 
 and/or modify it under the same terms as Perl itself.

=cut

1;

#
# $Id: Consts.pm 2236 2015-02-15 17:03:25Z gomor $
#
package Net::SinFP::Consts;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
   matchType => [qw(
      NS_MATCH_TYPE_P1P2P3
      NS_MATCH_TYPE_P1P2
      NS_MATCH_TYPE_P2
   )],
   matchMask => [qw(
      NS_MATCH_MASK_HEURISTIC0
      NS_MATCH_MASK_HEURISTIC1
      NS_MATCH_MASK_HEURISTIC2
   )],
);

our @EXPORT_OK = (
   @{$EXPORT_TAGS{matchType}},
   @{$EXPORT_TAGS{matchMask}},
);

use constant NS_MATCH_TYPE_P1P2P3 => 'P1P2P3';
use constant NS_MATCH_TYPE_P1P2   => 'P1P2';
use constant NS_MATCH_TYPE_P2     => 'P2';

use constant NS_MATCH_MASK_HEURISTIC0 => 'HEURISTIC0';
use constant NS_MATCH_MASK_HEURISTIC1 => 'HEURISTIC1';
use constant NS_MATCH_MASK_HEURISTIC2 => 'HEURISTIC2';

1;

__END__

=head1 NAME

Net::SinFP::Consts - all constants are defined here

=head1 DESCRIPTION

Go to http://www.gomor.org/sinfp to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

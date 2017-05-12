## Domain Registry Interface, EPP Message class for .SE
## Contributed by Ulrich Wisser from NIC SE
##
## Copyright (c) 2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::SE::Message;

use strict;
use warnings;
use base 'Net::DRI::Protocol::EPP::Message';
our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SE::Message - .SE EPP Message for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2009 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

#
# This is an exact copy of Net::DRI::Protocol::EPP::Message::_get_content
# Only getChildrenByTagNameNS has been replaced with getElementsByTagNameNS
# to enable parsing of <???:infData/> inside <iis:notifyXXX/> elements.
#
sub _get_content {
    my ( $self, $node, $nstag, $nodename ) = @_;
    return unless ( defined($node) && defined($nstag) && $nstag && defined($nodename) && $nodename );
    my $ns = $self->ns($nstag);
    $ns = $nstag unless defined($ns) && $ns;
    my @tmp = $node->getElementsByTagNameNS( $ns, $nodename );
    return unless @tmp;
    return $tmp[0];
}

####################################################################################################
1;
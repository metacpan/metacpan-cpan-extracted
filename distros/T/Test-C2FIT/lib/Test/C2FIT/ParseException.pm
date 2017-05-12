# $Id: ParseException.pm,v 1.6 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Written by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::ParseException;
use base 'Test::C2FIT::Exception';

sub getErrorOffset {
    my $self = shift;
    return $self->value();
}

# Keep Perl happy.
1;

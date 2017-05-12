# $Id: Exception.pm,v 1.6 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Written by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::Exception;

use Error qw( :try );
use base 'Error::Simple';

sub getMessage {
    my $self    = shift;
    my $message = $self->stringify();
    chomp $message;
    return $message;
}

# Keep Perl happy.
1;

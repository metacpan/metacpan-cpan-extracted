# $Id: GenericAdapter.pm,v 1.6 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::GenericAdapter;

use strict;
use vars qw(@ISA);
@ISA = qw(Test::C2FIT::TypeAdapter);

sub parse {
    my $self = shift;
    my ($s) = @_;

    return $s;
}

1;

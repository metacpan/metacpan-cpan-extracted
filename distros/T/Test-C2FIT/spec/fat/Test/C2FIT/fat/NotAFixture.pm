# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::fat::NotAFixture;
use strict;

sub new {
    my $pkg = shift;
    $pkg = ref($pkg) if ref($pkg);
    return bless {}, $pkg;
}

1;

__END__

package fat;

public class NotAFixture {
}

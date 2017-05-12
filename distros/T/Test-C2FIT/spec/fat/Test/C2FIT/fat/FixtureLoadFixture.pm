# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::fat::FixtureLoadFixture;
use base 'Test::C2FIT::ColumnFixture';

use strict;

use Error qw( :try );

#use Test::C2FIT::Parse;
use Test::C2FIT::Fixture;

sub LoadResult {
    my $self = shift;
    $self->loadFixture();
    return "loaded";    # we'll get an exception if it didn't load
}

sub loadFixture {
    my $self    = shift;
    my $fixture = new Test::C2FIT::Fixture();
    $fixture->loadFixture( $self->{'FixtureName'} );
}

sub ErrorMessage {
    my $self = shift;
    my $message;
    try {
        $self->loadFixture();
        $message = "(none)";
      }
      otherwise {
        my $e = shift;
        $message = $e->getMessage();
      };
    return $message;
}

1;

__END__

package fat;

import fit.*;

public class FixtureLoadFixture extends ColumnFixture {
	public String FixtureName;
	
	public String LoadResult() throws Exception {
        loadFixture();
		return "loaded";    // we'll get an exception if it didn't load
	}

    private void loadFixture()
        throws InstantiationException, IllegalAccessException, ClassNotFoundException {
        Fixture fixture = new Fixture();
        fixture.loadFixture(FixtureName);
    }
	
	public String ErrorMessage() {
		try {
			loadFixture();
			return "(none)";
		}
		catch (Exception e) {
			return e.getMessage();
		}
	}
}





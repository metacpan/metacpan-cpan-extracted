# Dialog.pm
#
# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>

package Test::C2FIT::eg::music::Dialog;

use base qw(Test::C2FIT::Fixture);
use strict;

sub new {
    my $pkg = shift;

    return bless {
        message => $_[0],
        caller  => $_[1],
        @_
    }, $pkg;
}

sub message {
    my $self = shift;

    return $self->{'message'};
}

sub ok {
    my $self = shift;
    if ( $self->{'message'} eq "load jamed" ) {
        Test::C2FIT::eg::music::MusicPlayer::stop();
    }
    $Test::C2FIT::ActionFixture::actor = $self->{'caller'};
}

1;

=for Java
// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Read license.txt in this directory.

package eg.music;

import fit.*;

public class Dialog extends Fixture {
    String message;
    Fixture caller;

    Dialog (String message, Fixture caller) {
        this.message = message;
        this.caller = caller;
    }

    public String message() {
        return message;
    }

    public void ok () {
        if (message.equals("load jamed"))   {MusicPlayer.stop();}
        ActionFixture.actor = caller;
    }

}
=cut


# Realtime.pm
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::eg::music::Realtime;

use base 'Test::C2FIT::TimedActionFixture';
use strict;
use Test::C2FIT::eg::music::Simulator;
use Test::C2FIT::Fixture;

sub new {
    my $pkg = shift;

    return bless {
        system => $Test::C2FIT::eg::music::Simulator::system,
        @_
    }, $pkg;
}

sub time {
    my $self = shift;

    # return Simulator::time();
    return $Test::C2FIT::eg::music::Simulator::time;
}

sub do_pause {
    my $self = shift;

    my $seconds = $self->{'cells'}->more()->text();
    $self->{'system'}->delay($seconds);
}

sub do_await {
    my $self = shift;

    $self->_system( "wait", $self->{'cells'}->more() );
}

sub do_fail {
    my $self = shift;

    $self->_system( "fail", $self->{'cells'}->more() );
}

sub do_enter {
    my $self = shift;

    $self->{'system'}->delay(0.8);
    $self->SUPER::do_enter();
}

sub do_press {
    my $self = shift;

    $self->{'system'}->delay(1.2);
    $self->SUPER::do_press();
}

sub _system {
    my $self = shift;
    my ( $prefix, $cell ) = @_;

    my $method = Test::C2FIT::Fixture::camel( $prefix . " " . $cell->text() );
    eval { $self->{'system'}->$method(); };
    if ($@) {
        $self->exception( $cell, $@ );
    }
}

1;

__END__

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

package eg.music;

import fit.*;
import java.util.Date;

public class Realtime extends TimedActionFixture {

    Simulator system = Simulator.system;

    public Date time () {
        return new Date(Simulator.time);
    }

    public void pause () {
        double seconds = Double.parseDouble(cells.more.text());
        system.delay(seconds);
    }

    public void await () throws Exception {
        system("wait", cells.more);
    }

    public void fail () throws Exception {
        system("fail", cells.more);
    }

    public void enter() throws Exception {
        system.delay(0.8);
        super.enter();
    }

    public void press() throws Exception {
        system.delay(1.2);
        super.press();
    }

    private void system(String prefix, Parse cell) throws Exception {
        String method = camel(prefix+" "+cell.text());
        Class[] empty = {};
        try {
            system.getClass().getMethod(method,empty).invoke(system,empty);
        } catch (Exception e) {
            exception (cell, e);
        }
    }
}

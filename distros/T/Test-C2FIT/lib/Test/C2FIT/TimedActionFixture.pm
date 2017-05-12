# $Id: TimedActionFixture.pm,v 1.8 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::TimedActionFixture;

use base 'Test::C2FIT::ActionFixture';
use strict;
use Test::C2FIT::Parse;

sub doTable {
    my $self = shift;
    my ($table) = shift;

    $self->SUPER::doTable($table);
    $table->parts()->parts()->last()->more( $self->td("time") );
    $table->parts()->parts()->last()->more( $self->td("split") );
}

sub formatTime($) {
    my ($value) = @_;
    my @t = localtime($value);
    my $r = sprintf( "%2d:%02d:%02d", $t[2], $t[1], $t[0] );

    #    warn "SSS: $r\n";
    return $r;
}

sub doCells {
    my $self    = shift;
    my ($cells) = @_;
    my $start   = $self->time();
    $self->SUPER::doCells($cells);
    my $split = $self->time() - $start;
    $cells->last()->more( $self->td( formatTime($start) ) );
    $cells->last()->more( $self->td($split) );    #TBD format?
}

sub time {
    my $self = shift;
    return CORE::time();
}

sub td {
    my $self = shift;
    my ($body) = @_;
    return Test::C2FIT::Parse->from( "td", $self->info($body), undef, undef );
}

1;

__END__

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

package fit;

import java.util.Date;
import java.text.*;

public class TimedActionFixture extends ActionFixture {

    public DateFormat format = new SimpleDateFormat("hh:mm:ss");

    // Traversal ////////////////////////////////

    public void doTable(Parse table) {
        super.doTable(table);
        table.parts.parts.last().more = td("time");
        table.parts.parts.last().more = td("split");
    }

    public void doCells(Parse cells) {
        Date start  = time();
        super.doCells(cells);
        long split = time().getTime() - start.getTime();
        cells.last().more = td(format.format(start));
        cells.last().more = td(split<1000 ? "" : Double.toString((split)/1000.0));
    }

    // Utility //////////////////////////////////

    public Date time() {
        return new Date();
    }

    public Parse td (String body) {
        return new Parse("td", gray(body), null, null);
    }

}


# Display.pm
#
# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>

package Test::C2FIT::eg::music::Display;

use base qw(Test::C2FIT::RowFixture);
use strict;

sub getTargetClass {
    my $self = shift;

    return "Music";
}

sub query {
    my $self = shift;

    return Test::C2FIT::eg::music::MusicLibrary::displayContents();
}

sub parse {
    my $self = shift;
    my ( $string, $type ) = @_;

    if ( $type eq "date" ) {    #TBD we can't do this yet
                                # return Music.dateFormat.parse($string);
    }
    return $self->SUPER::parse( $string, $type );
}

1;

__END__

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

package eg.music;

import java.text.DateFormat;
import java.util.Date;

public class Display extends fit.RowFixture {

    public Class getTargetClass() {
        return Music.class;
    }

    public Object[] query() {
        return MusicLibrary.displayContents();
    }

    public Object parse (String s, Class type) throws Exception {
        if (type.equals(Date.class))    {return Music.dateFormat.parse(s);}
        return super.parse (s, type);
    }

}


# Music.pm
#
# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>

package Test::C2FIT::eg::music::Music;

use strict;

use vars qw($status);
$status = "ready";

sub new {
    my $pkg = shift;

    return bless {
        title       => undef,
        artist      => undef,
        album       => undef,
        genre       => undef,
        size        => undef,
        seconds     => undef,
        trackNumber => undef,
        trackCount  => undef,
        year        => undef,
        date        => undef,
        selected    => 0,
        @_
    }, $pkg;
}

sub title {
    my $self = shift;

    return $self->{'title'};
}

sub artist {
    my $self = shift;

    return $self->{'artist'};
}

sub album {
    my $self = shift;

    return $self->{'album'};
}

sub track {
    my $self = shift;

    return $self->{'trackNumber'} . " of " . $self->{'trackCount'};
}

sub seconds {
    my $self = shift;

    return $self->{'seconds'};
}

sub time {
    my $self = shift;

    return int( $self->{'seconds'} / 0.6 + 0.5 ) / 100;
}

sub year {
    my $self = shift;

    return $self->{'year'};
}

sub toString {
    my $self = shift;

    return $self->{'title'} ? $self->{'title'} : "Music";
}

# Factor method

sub parse {
    my ($string) = @_;

    my $m = new Test::C2FIT::eg::music::Music();
    my @parts = ( split( "\t", $string ) )[ 0 .. 9 ];
    $m->{'title'}       = $parts[0];
    $m->{'artist'}      = $parts[1];
    $m->{'album'}       = $parts[2];
    $m->{'genre'}       = $parts[3];
    $m->{'size'}        = $parts[4];
    $m->{'seconds'}     = $parts[5];
    $m->{'trackNumber'} = $parts[6];
    $m->{'trackCount'}  = $parts[7];
    $m->{'year'}        = $parts[8];
    $m->{'date'}        = $parts[9];

    return $m;
}

1;

__END__

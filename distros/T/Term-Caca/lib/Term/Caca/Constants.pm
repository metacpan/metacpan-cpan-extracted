package Term::Caca::Constants;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: libcaca constants from caca.h
$Term::Caca::Constants::VERSION = '3.1.0';
use strict;
use warnings;

use base 'Exporter';

our ( @EXPORT_OK, %EXPORT_TAGS );

use constant {

  ## enum caca_color

  BLACK              => 0,
  BLUE               => 1,
  GREEN              => 2,
  CYAN               => 3,
  RED                => 4,
  MAGENTA            => 5,
  BROWN              => 6,
  LIGHTGRAY          => 7,
  DARKGRAY           => 8,
  LIGHTBLUE          => 9,
  LIGHTGREEN         => 10,
  LIGHTCYAN          => 11,
  LIGHTRED           => 12,
  LIGHTMAGENTA       => 13,
  YELLOW             => 14,
  WHITE              => 15,

  ## enum caca_feature

  BACKGROUND               => 0x10,
  BACKGROUND_BLACK         => 0x11,
  BACKGROUND_SOLID         => 0x12,

  BACKGROUND_MIN           => 0x11,
  BACKGROUND_MAX           => 0x12,

  ANTIALIASING             => 0x20,
  ANTIALIASING_NONE        => 0x21,
  ANTIALIASING_PREFILTER   => 0x22,

  ANTIALIASING_MIN         => 0x21,
  ANTIALIASING_MAX         => 0x22,

  DITHERING                => 0x30,
  DITHERING_NONE           => 0x31,
  DITHERING_ORDERED2       => 0x32,
  DITHERING_ORDERED4       => 0x33,
  DITHERING_ORDERED8       => 0x34,
  DITHERING_RANDOM         => 0x35,

  DITHERING_MIN            => 0x31,
  DITHERING_MAX            => 0x35,

  FEATURE_UNKNOWN          => 0xffff,

  ## enum caca_event

    NO_EVENT =>          0x0000,
    KEY_PRESS =>     0x0001,
    KEY_RELEASE =>   0x0002,
    MOUSE_PRESS =>   0x0004,
    MOUSE_RELEASE => 0x0008,
    MOUSE_MOTION =>  0x0010,
    RESIZE =>        0x0020,
    QUIT =>          0x0040,
    ANY_EVENT =>     0xffff,

  ## enum caca_key
  KEY_UNKNOWN              => 0,

  # /* The following keys have ASCII equivalents */
  KEY_BACKSPACE            => 8,
  KEY_TAB                  => 9,
  KEY_RETURN               => 13,
  KEY_PAUSE                => 19,
  KEY_ESCAPE               => 27,
  KEY_DELETE               => 127,

  # /* The following keys do not have ASCII equivalents but have been
  #  * chosen to match the SDL equivalents */
  KEY_UP                   => 273,
  KEY_DOWN                 => 274,
  KEY_LEFT                 => 275,
  KEY_RIGHT                => 276,
  KEY_INSERT               => 277,
  KEY_HOME                 => 278,
  KEY_END                  => 279,
  KEY_PAGEUP               => 280,
  KEY_PAGEDOWN             => 281,
  KEY_F1                   => 282,
  KEY_F2                   => 283,
  KEY_F3                   => 284,
  KEY_F4                   => 285,
  KEY_F5                   => 286,
  KEY_F6                   => 287,
  KEY_F7                   => 288,
  KEY_F8                   => 289,
  KEY_F9                   => 290,
  KEY_F10                  => 291,
  KEY_F11                  => 292,
  KEY_F12                  => 293,
  KEY_F13                  => 294,
  KEY_F14                  => 295,
  KEY_F15                  => 296,

};

%EXPORT_TAGS = (
  colors => [ qw(
    BLACK
    BLUE
    GREEN
    CYAN
    RED
    MAGENTA
    BROWN
    LIGHTGRAY
    DARKGRAY
    LIGHTBLUE
    LIGHTGREEN
    LIGHTCYAN
    LIGHTRED
    LIGHTMAGENTA
    YELLOW
    WHITE
  ) ],

  features => [ qw(
    BACKGROUND
    BACKGROUND_BLACK
    BACKGROUND_SOLID

    BACKGROUND_MIN
    BACKGROUND_MAX

    ANTIALIASING
    ANTIALIASING_NONE
    ANTIALIASING_PREFILTER

    ANTIALIASING_MIN
    ANTIALIASING_MAX

    DITHERING
    DITHERING_NONE
    DITHERING_ORDERED2
    DITHERING_ORDERED4
    DITHERING_ORDERED8
    DITHERING_RANDOM

    DITHERING_MIN
    DITHERING_MAX

    FEATURE_UNKNOWN
  ) ],

  events => [ qw(
    NO_EVENT
    KEY_PRESS
    KEY_RELEASE
    MOUSE_PRESS
    MOUSE_RELEASE
    MOUSE_MOTION
    RESIZE
    QUIT
    ANY_EVENT
  ) ],

  'keys' => [ qw(
    KEY_UNKNOWN

    KEY_BACKSPACE
    KEY_TAB
    KEY_RETURN
    KEY_PAUSE
    KEY_ESCAPE
    KEY_DELETE

    KEY_UP
    KEY_DOWN
    KEY_LEFT
    KEY_RIGHT
    KEY_INSERT
    KEY_HOME
    KEY_END
    KEY_PAGEUP
    KEY_PAGEDOWN
    KEY_F1
    KEY_F2
    KEY_F3
    KEY_F4
    KEY_F5
    KEY_F6
    KEY_F7
    KEY_F8
    KEY_F9
    KEY_F10
    KEY_F11
    KEY_F12
    KEY_F13
    KEY_F14
    KEY_F15
  ) ],

  all => [ ],
);


# add all the other ":class" tags to the ":all" class,
# deleting duplicates
{
  my %seen;

  for (keys %EXPORT_TAGS) {
    Exporter::export_ok_tags($_);

    push @{$EXPORT_TAGS{all}},
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::Constants - libcaca constants from caca.h

=head1 VERSION

version 3.1.0

=head1 SYNOPSIS

Import all constants into current package/namespace:

  use Term::Caca::Constants ':all';

Only import the constants pertaining to events and keys:

  use Term::Caca qw(:events :keys);

=head1 EXPORT TAGS 

=head2 :colors

  BLACK       BLUE        GREEN       CYAN          RED                 
  MAGENTA     BROWN       LIGHTGRAY   DARKGRAY      LIGHTBLUE           
  LIGHTGREEN  LIGHTCYAN   LIGHTRED    LIGHTMAGENTA  YELLOW              
  WHITE       DEFAULT     TRANSPARENT         

=head2 :events

  NO_EVENT    ANY_EVENT
  KEY_PRESS   KEY_RELEASE
  MOUSE_PRESS MOUSE_RELEASE   MOUSE_MOTION
  RESIZE      QUIT

=head2 :keys

  KEY_UNKNOWN

  KEY_DELETE  KEY_TAB   KEY_PAUSE  KEY_RETURN  KEY_BACKSPACE  KEY_ESCAPE
  KEY_UP      KEY_DOWN  KEY_LEFT   KEY_RIGHT
  KEY_INSERT  KEY_HOME  KEY_END    KEY_PAGEUP  KEY_PAGEDOWN

  KEY_F1  KEY_F2   KEY_F3   KEY_F4   KEY_F5   KEY_F6   KEY_F7   KEY_F8
  KEY_F9  KEY_F10  KEY_F11  KEY_F12  KEY_F13  KEY_F14  KEY_F15

=head2 :features

  FEATURE_UNKNOWN

  BACKGROUND
  BACKGROUND_BLACK
  BACKGROUND_SOLID
  BACKGROUND_MIN
  BACKGROUND_MAX

  ANTIALIASING
  ANTIALIASING_NONE
  ANTIALIASING_PREFILTER
  ANTIALIASING_MIN
  ANTIALIASING_MAX

  DITHERING
  DITHERING_NONE
  DITHERING_ORDERED2
  DITHERING_ORDERED4
  DITHERING_ORDERED8
  DITHERING_RANDOM
  DITHERING_MIN
  DITHERING_MAX

=head1 AUTHORS

=over 4

=item *

John Beppu <beppu@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019, 2018, 2013, 2011 by John Beppu.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

package Mplayer::NowPlaying::Genres;
use strict;

BEGIN {
  use Exporter;
  use vars qw(@ISA @EXPORT $VERSION);
  $VERSION = '0.010';
  @ISA    = 'Exporter';
  @EXPORT = qw(get_genre);
}

use Carp qw(croak);

sub get_genre {
  my $genre = shift;
  if( ($genre < 0) or ($genre > 255) ) {
    croak("An integer between 0 and 255, inclusive, is required\n");
  }

  # Stolen from the mplayer source
  my %genres = (
    0   => "Blues",
    1   => "Classic Rock",
    10  => "New Age",
    100 => "Humour",
    101 => "Speech",
    102 => "Chanson",
    103 => "Opera",
    104 => "Chamber Music",
    105 => "Sonata",
    106 => "Symphony",
    107 => "Booty Bass",
    108 => "Primus",
    109 => "Porn Groove",
    11  => "Oldies",
    110 => "Satire",
    111 => "Slow Jam",
    112 => "Club",
    113 => "Tango",
    114 => "Samba",
    115 => "Folklore",
    116 => "Ballad",
    117 => "Power Ballad",
    118 => "Rhytmic Soul",
    119 => "Freestyle",
    12  => "Other",
    120 => "Duet",
    121 => "Punk Rock",
    122 => "Drum Solo",
    123 => "Acapella",
    124 => "Euro-House",
    125 => "Dance Hall",
    126 => "Goa",
    127 => "Drum & Bass",
    128 => "Club-House",
    129 => "Hardcore",
    13  => "Pop",
    130 => "Terror",
    131 => "Indie",
    132 => "BritPop",
    133 => "Negerpunk",
    134 => "Polsk Punk",
    135 => "Beat",
    136 => "Christian Gangsta Rap",
    137 => "Heavy Metal",
    138 => "Black Metal",
    139 => "Crossover",
    14  => "R&B",
    140 => "Contemporary Christian",
    141 => "Christian Rock",
    142 => "Merengue",
    143 => "Salsa",
    144 => "Thrash Metal",
    145 => "Anime",
    146 => "Jpop",
    147 => "Synthpop",
    15  => "Rap",
    16  => "Reggae",
    17  => "Rock",
    18  => "Techno",
    19  => "Industrial",
    2   => "Country",
    20  => "Alternative",
    21  => "Ska",
    22  => "Death Metal",
    23  => "Pranks",
    24  => "Soundtrack",
    25  => "Eurotechno",
    255 => "Unknown",
    26  => "Ambient",
    27  => "Trip-Hop",
    28  => "Vocal",
    29  => "Jazz+Funk",
    3   => "Dance",
    30  => "Fusion",
    31  => "Trance",
    32  => "Classical",
    33  => "Instrumental",
    34  => "Acid",
    35  => "House",
    36  => "Game",
    37  => "Sound Clip",
    38  => "Gospel",
    39  => "Noise",
    4   => "Disco",
    40  => "Alternative Rock",
    41  => "Bass",
    42  => "Soul",
    43  => "Punk",
    44  => "Space",
    45  => "Meditative",
    46  => "Instrumental Pop",
    47  => "Instrumental Rock",
    48  => "Ethnic",
    49  => "Gothic",
    5   => "Funk",
    50  => "Darkwave",
    51  => "Techno-Industrial",
    52  => "Electronic",
    53  => "Pop-Folk",
    54  => "Eurodance",
    55  => "Dream",
    56  => "Southern Rock",
    57  => "Comedy",
    58  => "Cult",
    59  => "Gangsta",
    6   => "Grunge",
    60  => "Top 40",
    61  => "Christian Rap",
    62  => "Pop/Funk",
    63  => "Jungle",
    64  => "Native American",
    65  => "Cabaret",
    66  => "New Wave",
    67  => "Psychadelic",
    68  => "Rave",
    69  => "Show Tunes",
    7   => "Hip-Hop",
    70  => "Trailer",
    71  => "Lo-Fi",
    72  => "Tribal",
    73  => "Acid Punk",
    74  => "Acid Jazz",
    75  => "Polka",
    76  => "Retro",
    77  => "Musical",
    78  => "Rock & Roll",
    79  => "Hard Rock",
    8   => "Jazz",
    80  => "Folk",
    81  => "Folk/Rock",
    82  => "National Folk",
    83  => "Swing",
    84  => "Fast-Fusion",
    85  => "Bebop",
    86  => "Latin",
    87  => "Revival",
    88  => "Celtic",
    89  => "Bluegrass",
    9   => "Metal",
    90  => "Avantgarde",
    91  => "Gothic Rock",
    92  => "Progressive Rock",
    93  => "Psychedelic Rock",
    94  => "Symphonic Rock",
    95  => "Slow Rock",
    96  => "Big Band",
    97  => "Chorus",
    98  => "Easy Listening",
    99  => "Acoustic"
  );

  return $genres{$genre};
}



1;


__END__

=pod

=head1 NAME

Mplayer::NowPlaying::Genres - Get at Mplayer genres by index

=head1 SYNOPSIS

    use Mplayer::NowPlaying::Genres;

    my $genre = get_genre(42); # Soul

=head1 DESCRIPTION

B<Mplayer::NowPlaying::Genres> provides L<Mplayer::NowPlaying> with a simple
interface for retrieving genre names by index.

=head1 EXPORTS

=head2 get_genre()

Parameters: $integer

Returns:    $genre

  my $genre = get_genre(128);

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

=cut

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2010, 2011 the B<Mplayer::NowPlaying::Genres>s L</AUTHOR> and
L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Mplayer::NowPlaying>

=cut

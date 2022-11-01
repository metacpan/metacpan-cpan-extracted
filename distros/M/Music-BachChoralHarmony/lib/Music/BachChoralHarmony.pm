package Music::BachChoralHarmony;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Parse the UCI Bach choral harmony data set

our $VERSION = '0.0411';

use Moo;
use strictures 2;

use Text::CSV ();
use File::ShareDir qw/ dist_dir /;
use List::Util qw/ any /;

use namespace::clean;


has data_file => (
    is      => 'ro',
    default => sub { dist_dir('Music-BachChoralHarmony') . '/jsbach_chorals_harmony.data' },
);


has key_title => (
    is      => 'ro',
    default => sub { dist_dir('Music-BachChoralHarmony') . '/jsbach_BWV_keys_titles.txt' },
);


has data => (
    is       => 'rw',
    init_arg => undef,
    default  => sub { {} },
);


sub parse {
    my ($self) = @_;

    # Collect the key signatures and titles
    my %data;

    open my $fh, '<', $self->key_title
        or die "Can't read ", $self->key_title, ": $!";

    while ( my $line = readline($fh) ) {
        chomp $line;
        next if $line =~ /^\s*$/ || $line =~ /^#/;
        my @parts = split /\s+/, $line, 4;
        $data{ $parts[0] } = {
            bwv   => $parts[1],
            key   => $parts[2],
            title => $parts[3],
        };
    }

    close $fh;

    # Collect the events
    my $csv = Text::CSV->new( { binary => 1 } )
        or die "Can't use CSV: ", Text::CSV->error_diag;

    open $fh, '<', $self->data_file
        or die "Can't read ", $self->data_file, ": $!";

    my $progression;

    # 000106b_ 2 YES  NO  NO  NO YES  NO  NO YES  NO  NO  NO  NO E 5  C_M
    while ( my $row = $csv->getline($fh) ) {

        ( my $id = $row->[0] ) =~ s/\s*//g;

        my $notes = '';

        for my $note ( 2 .. 13 ) {
            $notes .= $row->[$note] eq 'YES' ? 1 : 0;
        }

        ( my $bass   = $row->[14] ) =~ s/\s*//g;
        ( my $accent = $row->[15] ) =~ s/\s*//g;
        ( my $chord  = $row->[16] ) =~ s/\s*//g;

        $progression->{$id}{key}   ||= $data{$id}{key};
        $progression->{$id}{bwv}   ||= $data{$id}{bwv};
        $progression->{$id}{title} ||= $data{$id}{title};

        my $struct = {
            notes  => $notes,
            bass   => $bass,
            accent => $accent,
            chord  => $chord,
        };

        push @{ $progression->{$id}{events} }, $struct;
    }

    $csv->eof or die $csv->error_diag;
    close $fh;

    $self->data($progression);

    return $self->data;
}


sub search {
    my ( $self, %args ) = @_;

    my %results = ();

    if ( $args{id} ) {
        my @ids = split /\s+/, $args{id};

        for my $id ( @ids ) {
            $results{$id} = $self->data->{$id};
        }
    }

    if ( $args{key} ) {
        my @iter = keys %results ? keys %results : keys %{ $self->data };

        my @keys = split /\s+/, $args{key};

        for my $id ( @iter ) {
            if ( $results{$id} ) {
                delete $results{$id}
                    unless any { $_ eq $results{$id}{key} } @keys;
            }
            else {
                $results{$id} = $self->data->{$id}
                    if any { $_ eq $self->data->{$id}{key} } @keys;
            }
        }
    }

    if ( $args{bass} ) {
        %results = $self->_search_param( bass => $args{bass}, \%results );
    }

    if ( $args{chord} ) {
        %results = $self->_search_param( chord => $args{chord}, \%results );
    }

    if ( $args{notes} ) {
        my @iter = keys %results ? keys %results : keys %{ $self->data };

        my $and = $args{notes} =~ /&/ ? 1 : 0;
        my $re  = $and ? qr/\s*&\s*/ : qr/\s+/;

        my @notes = split $re, $args{notes};

        my %index = (
            'C'  => 0,
            'C#' => 1,
            'Db' => 1,
            'D'  => 2,
            'D#' => 3,
            'Eb' => 3,
            'E'  => 4,
            'F'  => 5,
            'F#' => 6,
            'Gb' => 6,
            'G'  => 7,
            'G#' => 8,
            'Ab' => 8,
            'A'  => 9,
            'A#' => 10,
            'Bb' => 10,
            'B'  => 11,
        );

        ID: for my $id ( @iter ) {
            my %and_notes = ();

            my $match = 0;

            for my $event ( @{ $self->data->{$id}{events} } ) {
                my @bitstring = split //, $event->{notes};

                my $i = 0;

                for my $bit ( @bitstring ) {
                    if ( $bit ) {
                        for my $note ( sort @notes ) {
                            if ( defined $index{$note} && $i == $index{$note} ) {
                                if ( $and ) {
                                    $and_notes{$note}++;
                                }
                                else {
                                    $match++;
                                }
                            }
                        }
                    }

                    $i++;
                }
            }

            if ( $and ) {
                if ( keys %and_notes ) {
                    my %notes;
                    @notes{@notes} = undef;

                    my $i = 0;

                    for my $n ( keys %and_notes ) {
                        $i++
                            if exists $notes{$n};
                    }

                    if ( $i == scalar keys %notes ) {
                        $results{$id} = $self->data->{$id};
                    }
                    else {
                        delete $results{$id}
                            if $results{$id};
                    }
                }
            }
            else {
                if ( $results{$id} && $match <= 0 ) {
                    delete $results{$id};
                }
                elsif ( $match > 0 ) {
                    $results{$id} = $self->data->{$id};
                }
            }
        }
    }

    return \%results;
}


sub bits2notes {
    my ( $self, $string, $accidental ) = @_;

    $accidental ||= 'b';

    my @notes = ();

    no warnings 'qw';
    my @positions = qw( C C#|Db D D#|Eb E F F#|Gb G G#|Ab A A#|Bb B );

    my @bits = split //, $string;

    my $i = 0;

    for my $bit ( @bits ) {
        if ( $bit ) {
            my @note = split /\|/, $positions[$i];
            my $note = '';

            if ( @note > 1 ) {
                $note = $accidental eq '#' ? $note[0] : $note[1];
            }
            else {
                $note = $note[0];
            }

            push @notes, $note;
        }

        $i++;
    }

    return \@notes;
}

sub _search_param {
    my ( $self, $name, $param, $seen ) = @_;

    my @iter = keys %$seen ? keys %$seen : keys %{ $self->data };

    my %results = ();

    my $and = $param =~ /&/ ? 1 : 0;
    my $re  = $and ? qr/\s*&\s*/ : qr/\s+/;

    my %notes = ();
    @notes{ split $re, $param } = undef;

    ID: for my $id ( @iter ) {
        my %and_notes = ();

        my $match = 0;

        for my $event ( @{ $self->data->{$id}{events} } ) {
            for my $note ( keys %notes ) {
                if ( $note eq $event->{$name} ) {
                    if ( $and ) {
                        $and_notes{$note}++;
                    }
                    else {
                        $match++;
                    }
                }
            }
        }

        if ( $and ) {
            if ( keys %and_notes ) {
                my $i = 0;

                for my $n ( keys %and_notes ) {
                    $i++
                        if exists $notes{$n};
                }

                if ( $i == scalar keys %notes ) {
                    $results{$id} = $self->data->{$id};
                }
                else {
                    delete $results{$id}
                        if $results{$id};
                }
            }
        }
        else {
            if ( $results{$id} && $match <= 0 ) {
                delete $results{$id};
            }
            elsif ( $match > 0 ) {
                $results{$id} = $self->data->{$id};
            }
        }
    }

    return %results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::BachChoralHarmony - Parse the UCI Bach choral harmony data set

=head1 VERSION

version 0.0411

=head1 SYNOPSIS

  use Music::BachChoralHarmony;

  my $bach = Music::BachChoralHarmony->new;
  my $songs = $bach->parse;

  # show all the song ids:
  print Dumper [ sort keys %$songs ];
  print Dumper [ sort keys %{ $bach->data } ]; # Same

  # show all the song titles:
  print Dumper [ map { $songs->{$_}{title} } sort keys %$songs ];

  $songs = $bach->search( id => '000106b_' );
  $songs = $bach->search( id => '000106b_ 000206b_' );
  $songs = $bach->search( key => 'C_M' );         # In C major
  $songs = $bach->search( key => 'C_M C_m' );     # In C major or C minor
  $songs = $bach->search( bass => 'C' );          # With a C note in the bass
  $songs = $bach->search( bass => 'C D' );        # With C or D in the bass
  $songs = $bach->search( bass => 'C & D' );      # With C and D in the bass
  $songs = $bach->search( chord => 'C_M' );       # With a C major chord
  $songs = $bach->search( chord => 'C_M D_m' );   # With a C major or a D minor chord
  $songs = $bach->search( chord => 'C_M & D_m' ); # With C major and D minor chords
  $songs = $bach->search( notes => 'C E G' );     # With the notes C or E or G
  $songs = $bach->search( notes => 'C & E & G' ); # With C and E and G
  # Args can be combined too:
  $songs = $bach->search( key => 'C_M C_m', chord => 'X_m & F_M' );

  # Possibly handy:
  my $notes = $bach->bits2notes('100000000000');     # [ C ]
  $notes = $bach->bits2notes('010000000000');        # [ Db ]
  $notes = $bach->bits2notes('000000000010');        # [ Bb ]
  $notes = $bach->bits2notes( '000000000010', '#' ); # [ A# ]
  $notes = $bach->bits2notes('110000000010');        # [ C Db Bb ]

=head1 DESCRIPTION

C<Music::BachChoralHarmony> parses the UCI Bach choral harmony data set of 60
chorales and does a few things:

* It turns the UCI CSV data into a perl data structure.

* It combines the Bach BWV number, song title and key with the data.

* It converts the UCI YES/NO note specification into a bit string and
named note list.

* It allows searching by ids, keys, notes, and chords.

The BWV and titles were collected from an Internet Archive and
filled-in from L<https://bach-chorales.com/>.  The keys were computed
with a L<music21|https://web.mit.edu/music21/> program, and if missing
filled-in again from L<https://bach-chorales.com/>.  Check out the
links in the L</SEE ALSO> section for more information.

The main purpose of this module is to produce the results of the
F<eg/*> programs.  So check 'em out!

=head1 ATTRIBUTES

=head2 data_file

  $file = $bach->data_file;

The local file where the Bach choral harmony data set resides.

Default: F<dist_dir()/jsbach_chorals_harmony.data>

=head2 key_title

  $file = $bach->key_title;

The local file where the key signatures and titles for each song are listed by
BWV number.

Default: F<dist_dir()/jsbach_BWV_keys_titles.txt>

=head2 data

  $songs = $bach->data;

The data resulting from the L</parse> method.

=head1 METHODS

=head2 new

  $bach = Music::BachChoralHarmony->new;

Create a new C<Music::BachChoralHarmony> object.

=head2 parse

  $songs = $bach->parse;

Parse the B<data_file> and B<key_title> files into the B<data> hash
reference of each song keyed by the song id.  Each song includes a BWV
identifier, title, key and list of events.  The event list is made of
hash references with a B<notes> bit-string, B<bass> note, the
B<accent> value and the resonating B<chord>.

=head2 search

  $songs = $bach->search( $k => $v ); # As in the SYNOPSIS above

Search the parsed result B<data> by song B<id>s, B<key>s, B<bass>
notes, B<chord>s, or individual B<notes> and return a hash reference
of the format:

  { $song_id => $song_data, ... }

The B<id>, and B<key> can be searched by single or multiple values
returning all songs that match.  Note names must be separated with a
space character.

The B<bass>, B<chord>, and B<notes> can be searched either as C<or>
(separating note names with a space character), or as inclusive C<and>
(separating note names with an C<&> character).

=head2 bits2notes

  $notes = $bach->bits2notes($string);
  $notes = $bach->bits2notes( $string, $accidental );

Convert a bit-string of 12 binary positions to a note list array
reference.

The B<accidental> can be given as C<#> sharp or C<b> flat in the case
of enharmonic notes.  Default: C<b>

The dataset B<notes> bit-string is defined by position as follows:

  0  => C
  1  => C# or Db
  2  => D
  3  => D# or Eb
  4  => E
  5  => F
  6  => F# or Gb
  7  => G
  8  => G# or Ab
  9  => A
  10 => A# or Bb
  11 => B

=head1 SEE ALSO

The F<eg/*> and F<t/01-methods.t> files in this distribution.

L<File::ShareDir>

L<List::Util>

L<Moo>

L<Text::CSV>

L<https://archive.ics.uci.edu/ml/datasets/Bach+Choral+Harmony>
is the dataset itself.

L<https://web.archive.org/web/20140515065053/http://www.jsbchorales.net/bwv.shtml>
was the original site.

L<http://www.bach-chorales.com/BachChorales.htm>
is a more modern site.

L<https://github.com/ology/Bach-Chorales/>
is a web app that displays chord transitions with this module.

L<https://github.com/ology/Bach-Chorales/blob/master/bin/key.py>
is a program written to extract the key signature.

L<https://github.com/ology/Bach-Chorales/blob/master/chorales.zip>
are the collected MIDI files and PDF transcriptions.

L<https://en.wikipedia.org/wiki/Chorale_cantata_(Bach)>
describes the context.

=head1 THANK YOU

Dan Book (L<DBOOK|https://metacpan.org/author/DBOOK>)
for the ShareDir clues.

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

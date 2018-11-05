package Music::BachChoralHarmony;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Parse the UCI Bach choral harmony data set

our $VERSION = '0.0104';

use Moo;
use strictures 2;
use namespace::clean;

use Text::CSV;
use File::ShareDir 'dist_dir';


has data_file => (
    is      => 'ro',
    default => sub { dist_dir('Music-BachChoralHarmony') . '/' .  'jsbach_chorals_harmony.data' },
);


has key_title => (
    is      => 'ro',
    default => sub { dist_dir('Music-BachChoralHarmony') . '/' . 'jsbach_BWV_keys_titles.txt' },
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
        or die "Can't use CSV: ", Text::CSV->error_diag();

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

    $csv->eof or die $csv->error_diag();
    close $fh;

    return $progression;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::BachChoralHarmony - Parse the UCI Bach choral harmony data set

=head1 VERSION

version 0.0104

=head1 SYNOPSIS

  use Music::BachChoralHarmony;

  my $bach = Music::BachChoralHarmony->new;
  my $songs = $bach->parse;

  # show all the song ids:
  print Dumper [ keys %$songs ];

  # show all the song titles:
  print Dumper [ map { $songs->{$_}{title} } keys %$songs ];

=head1 DESCRIPTION

C<Music::BachChoralHarmony> parses the UCI Bach choral harmony data set of 60
chorales.

This module does a few simple things:

1. It turns the UCI CSV data into a perl data structure.

2. It converts the UCI YES/NO note specification into a bit string.

3. It combines the Bach BWV number, song title and key with the data.

The BWV and titles were collected from an old Internet Archive of
C<jsbchorales.net> and filled-in from C<bach-chorales.com>.  The keys were
computed with a C<music21> python program and again filled-in from
C<bach-chorales.com>.  Check out the links in the L</SEE ALSO> section.

See the distribution C<eg/> programs for usage examples.

=head1 ATTRIBUTES

=head2 data_file

The local file where the Bach choral harmony data set resides.

Default: C<dist_dir()>/jsbach_chorals_harmony.data

=head2 key_title

The local file where the key signatures and titles for each song are listed by
BWV number.

Default: C<dist_dir()>/jsbach_BWV_keys_titles.txt

=head1 METHODS

=head2 new()

  $bach = Music::BachChoralHarmony->new();

Create a new C<Music::BachChoralHarmony> object.

=head2 parse()

  $songs = $bach->parse();

Parse the B<data_file> and B<key_title> files into a hash reference of each song
keyed by the song id.  Each song includes a BWV identifier, title, key and list
of events.  The event list is made of hash references with keys for the notes
bit string, bass note, the accent value and the resonating chord.

=head1 SEE ALSO

L<Moo>

L<Text::CSV>

L<File::ShareDir>

L<https://archive.ics.uci.edu/ml/datasets/Bach+Choral+Harmony>

L<https://web.archive.org/web/20140515065053/http://www.jsbchorales.net/bwv.shtml>

L<http://www.bach-chorales.com/BachChorales.htm>

L<http://web.mit.edu/music21/>

L<https://github.com/ology/Bach-Chorales/blob/master/bin/key.py>

=head1 THANK YOU

Dan Book (DBOOK) for the ShareDir clues.

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#
# This file is part of Movies-Organizer
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Movies::Organizer;

# ABSTRACT: Organize your movies using imdb

use strict;
use warnings;

our $VERSION = '1.3';    # VERSION

use Moo;
use MooX::Options;
use File::Path 2.08 'make_path';
use Carp;
use Data::Dumper;
use File::Glob ':globally';
use File::Spec;
use File::Copy;
use Term::ReadLine;
use Term::ReadLine::Perl;
use WWW::REST;
use JSON::XS;
use 5.010;
use utf8;

option 'from' => (
    doc => 'Source directory to organize',
    is  => 'ro',
    isa => sub {
        my ($dest) = @_;
        croak "Source directory is missing !" unless -d $dest;
    },
    required => 1,
    format   => 's',
);

option 'to' => (
    doc => 'Destination of the organized movies',
    is  => 'ro',
    isa => sub {
        my ($dest) = @_;
        if ( !-d $dest ) {
            make_path( $dest, { error => \my $err } );
            if (@$err) {
                for my $diag (@$err) {
                    my ( $file, $message ) = %$diag;
                    croak "Error : $message\n";
                }
            }
        }
    },
    required => 1,
    format   => 's',
);

option 'min_size' => (
    is      => 'ro',
    default => sub { 100 * 1024**2 },
    doc     => 'minimum size of file to handle it has movies',
    format  => 'i',
);

option 'with_aka' => (
    is      => 'ro',
    default => sub {0},
    doc     => 'show alsa known as for movies title',
);

has '_filter_words' => (
    is      => 'ro',
    default => sub {
        [   qw/
                french
                english
                x264
                720p
                1080p
                bluray
                avi
                mkv
                divx
                bdrip
                xvid
                brrip
                ac3
                multi
                truefrench
                dts
                hdma
                hdtv
                hdrip
                m2ts
                s\d+
                e\d+
                s\d+e\d+
                /
        ];
    },
);

has '_rs' => (
    is      => 'ro',
    default => sub {
        my ($self) = @_;
        my $rs = WWW::REST->new('http://imdbapi.org/');
        $rs->_ua->agent('Mozilla/5.0');
        $rs->dispatch(
            sub {
                my $self = shift;
                croak $self->status_line if $self->is_error;
                my $ct = decode_json( $self->content );
                return ref $ct eq 'ARRAY' ? $ct->[0] : $ct;
            }
        );
        return $rs;
    }
);

sub find_movies {
    my ($self) = @_;

    my @dir_to_scan = ( $self->from );
    my @movies;
    while ( my $dir = shift @dir_to_scan ) {
        $dir =~ s/ /\\ /g;
        while ( my $cur = glob "$dir/*" ) {
            push( @dir_to_scan, $cur ) and next if -d $cur;
            push @movies, $cur if -s $cur >= $self->min_size;
        }
    }
    return @movies;
}

sub filter_title {
    my ( $self, $file ) = @_;
    my ( undef, undef, $movie ) = File::Spec->splitpath($file);
    my @words_ok;
SKIP_WORD: for my $word ( split( /\W+/x, $movie ) ) {
        for my $filter ( @{ $self->_filter_words } ) {
            next SKIP_WORD if $word =~ m/^$filter$/ix;
        }
        push @words_ok, $word;
    }
    return join( ' ', @words_ok );
}

sub move_movie {
    my ( $self, %options ) = @_;
    my ( $term, $file, $imdb, $title, $season, $episode )
        = @options{qw/term file imdb title season episode/};
    my ( undef, undef, $movie ) = File::Spec->splitpath($file);
    my ( $season_part, $episode_part );
    my $is_series = $imdb->{type} eq 'TVS';

    if ($is_series) {
        $season_part  = sprintf( "S%02d", $season );
        $episode_part = sprintf( "E%02d", $episode );
    }

    #extract ext
    my ($ext) = $movie =~ m/\.([^\.]+)$/x;
    $ext = "avi" unless defined $ext;

    #fix title space
    $title =~ s/\W+/ /gx;
    $title =~ s/^\s+|\s+$//gx;
    $title =~ s/\s+(\w)/.\u$1/gx;    #replace space by dot

    #create destination
    my $dest = File::Spec->catfile( $self->to,
        ucfirst( $imdb->{type} eq 'TVS' ? 'Tv series' : 'Movie' ) );
    if ($is_series) {
        $dest = File::Spec->catfile( $dest, $title, $season_part );
    }
    make_path( $dest, { error => \my $err } );
    if (@$err) {
        for my $diag (@$err) {
            my ( undef, $message ) = %$diag;
            croak "Error : $message\n";
        }
    }

    #build final filename
    if ($is_series) {
        $ext = join( '.', $season_part . $episode_part, $ext );
    }
    else {
        $ext = join( '.', "(" . $imdb->{year} . ")", $ext );
    }
    my $fdest = File::Spec->catfile( $dest, join( '.', $title, $ext ) );

    say "Moving  : ";
    say "   From : ", $file;
    say "   To   : ", $fdest;

    exit unless $term->readline( 'Continue (Y/n) ? > ', 'y' ) eq 'y';

    move( $file, $fdest );
    croak "Error occur !" if -e $file || !-e $fdest;

    $file =~ s/\.[^\.]+$/.srt/x;
    $fdest =~ s/\.[^\.]+$/.srt/x;

    if ( -e $file ) {

        say "Moving  : ";
        say "   From : ", $file;
        say "   To   : ", $fdest;

        exit unless $term->readline( 'Continue (Y/n) ? > ', 'y' ) eq 'y';

        move( $file, $fdest );
        croak "Error occur !" if -e $file || !-e $fdest;

    }
    return;
}

## no critic qw(Subroutines::ProhibitExcessComplexity)
sub run {
    my $self = shift;

    my $term = Term::ReadLine->new;
    my ( $imdb, $movie_title, $season, $episode );
    for my $movie ( $self->find_movies() ) {
        say "";
        say "Organize : $movie";
        my $another_episode;
        if (   defined $imdb
            && $imdb->{type} eq 'TVS'
            && $term->readline(
                "is it another episode of " . $movie_title . " ? (Y/n) > ",
                "y" ) eq "y"
            )
        {
            $another_episode = 1;
            say "";
        }
        else {
            $imdb = undef;
        }
        if ( !$another_episode ) {
            while ( !defined $imdb ) {
                my $imdb_search = $term->readline( "IMDB Search > ",
                    $self->filter_title($movie) );
                my $imdb_search_key = $imdb_search =~ /^tt\d+/x ? 'id' : 'q';

                my $imdb_search_year
                    = $term->readline("Movie/Series Year > ");

                my @imdb_search_params = (
                    $imdb_search_key => $imdb_search,
                    limit            => 1,
                    plot             => qw/full/,
                    episode          => 0
                );
                push @imdb_search_params,
                    year => $imdb_search_year,
                    yg   => 1
                    if $imdb_search_year ne '';

                $imdb = $self->_rs->get(@imdb_search_params);

                $imdb = undef if $imdb->{error};
                if ($imdb) {
                    say "Movie    : ", $imdb->{title} // "";
                    say "Aka      : ", join(
                        ', ',
                        map { utf8::encode($_); $_ } ## no critic (ProhibitComplexMappings)
                            @{ $imdb->{also_known_as} // [] }
                    ) if $self->with_aka;
                    say "Kind     : ",
                        ( $imdb->{type} // "" ) eq 'TVS'
                        ? 'Tv Serie'
                        : 'Movie';
                    say "Year     : ", $imdb->{year} // "";
                    say "Plot     : ", $imdb->{plot} // "";
                    say "Directory: ",
                        join( ', ', @{ $imdb->{directors} // [] } );
                    say "Cast     : ",
                        join( ', ', @{ $imdb->{actors} // [] } );
                    say "Genre    : ",
                        join( ', ', @{ $imdb->{genres} // [] } );
                    say "Duration : ",
                        join( ', ', @{ $imdb->{runtime} // [] } );
                    say "Language : ",
                        join( ', ', @{ $imdb->{language} // [] } );
                    say "";
                    my $correct
                        = $term->readline( "Is it correct ? (Y/n) > ", "y" );
                    $imdb = undef unless $correct eq 'y';
                }
            }
            $movie_title = $imdb->{title};
            my @movie_titles = ($movie_title);
            push @movie_titles, @{ $imdb->{also_known_as} // [] }
                if $self->with_aka;
            if ( @movie_titles > 1 ) {
                my $choice;
                say "Select best title : ";
                for ( my $i = 1; $i <= @movie_titles; $i++ ) {
                    say sprintf( "    %d) %s", $i, $movie_titles[ $i - 1 ] );
                }
                while ( !defined $choice ) {
                    $choice = $term->readline( " > ", 1 );
                    $choice = undef
                        if $choice =~ /\D/x
                        || $choice < 1
                        || $choice > @movie_titles;
                }
                $movie_title = $movie_titles[ $choice - 1 ];
                say "";
            }
        }
        if ( $imdb->{type} eq 'TVS' ) {
            my $ok = 0;
            while ( !$ok || !defined $season || !defined $episode ) {
                $ok++;
                $season  = $term->readline( "Season ? > ",  $season );
                $episode = $term->readline( "Episode ? > ", $episode );
                if (   $season =~ /\D/x
                    || $episode =~ /\D/x
                    || $season eq ''
                    || $episode eq '' )
                {
                    say "Please, use only numeric values !";
                    say "";
                    $ok = 0;
                    next;
                }
                if (!(  $term->readline(
                            "is it season "
                                . $season
                                . " episode "
                                . $episode
                                . " ? (Y/n) > ",
                            "y"
                        ) eq "y"
                    )
                    )
                {
                    $ok = 0;
                }
            }
        }

        $self->move_movie(
            term    => $term,
            file    => $movie,
            imdb    => $imdb,
            title   => $movie_title,
            season  => $season,
            episode => $episode
        );
        $episode++ if defined $episode;
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Movies::Organizer - Organize your movies using imdb

=head1 VERSION

version 1.3

=head1 SYNOPSIS

    movies_organizer -h
    movies_organizer --from /movies/to/rename --to /movies_well_named

=head1 METHODS

=head2 find_movies

pass thought 'from' directory, and get all movies files. It will take file bigger than 'min_size'

=head2 filter_title

Extract words from the file name, filter any common bad one, and return filtered title.

=head2 move_movie

move the movie to the destination with the right name, that wil ease your classment with XMDB tools type.

=head2 run

Run the tools, and rename properly your movies.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/MoviesOrganizer/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

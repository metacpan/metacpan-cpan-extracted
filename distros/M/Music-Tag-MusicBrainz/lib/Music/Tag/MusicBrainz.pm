package Music::Tag::MusicBrainz;
use strict; use warnings; use utf8;
our $VERSION = '0.4101';

# Copyright © 2006,2010 Edward Allen III. Some rights reserved.
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.

use WebService::MusicBrainz::Artist;
use WebService::MusicBrainz::Release;
use WebService::MusicBrainz::Track;
use Cache::FileCache;
use utf8;
use base qw(Music::Tag::Generic);

sub default_options {
    {   prefered_country         => "US",
        min_artist_score         => 1,
        min_album_score          => 17,
        min_track_score          => 3,
        ignore_mbid              => 0,
        trust_time               => 0,
        trust_track              => 0,
        trust_title              => 0,
        skip_seen                => 0,
        ignore_multidisc_warning => 1,
        mb_host                  => "www.musicbrainz.org",
    };
}

sub required_values {
    return qw( artist);
}

sub set_values {
    return
        qw( album releasedate totaltracks title tracknum title track releasedate);
}

sub get_tag {
    my $self = shift;
    if (   ( $self->options->{skip_seen} )
        && ( length( $self->info->get_data('mb_trackid') ) == 36 ) ) {
        $self->status( "Skipping previously looked up track with mb_trackid "
                . $self->info->get_data('mb_trackid') );
    }
    else {
        $self->artist_info() && $self->album_info() && $self->track_info();
    }
    return $self;
}

sub artist_info {
    my $self = shift;
    $self->status( "Looking up artist from " . $self->options->{mb_host} );
    unless ( exists $self->{mb_a} ) {
        $self->{mb_a} = WebService::MusicBrainz::Artist->new(
            HOST  => $self->options->{mb_host},
            CACHE => $self->mb_cache
        );
    }
    my $params   = {};
    my $maxscore = 0;
    my $artist   = undef;
    if (   ( $self->info->has_data('mb_artistid') )
        && ( not $self->options->{ignore_mbid} ) ) {
        $params->{MBID} = $self->info->get_data('mb_artistid');
        $artist = $self->{mb_a}->search($params);
        unless ( ref($artist) eq "WebService::MusicBrainz::Response::Artist" )
        {
            $artist = $artist->artist();
        }
        $maxscore = 8;
    }
    elsif ( ( $self->info->has_data('artist') ) ) {
        $params->{NAME} = $self->info->get_data('artist');
        my $response = $self->{mb_a}->search($params);
        return unless $response;
        return unless $response->artist_list();
        foreach ( @{ $response->artist_list->artists() } ) {
            my $s = 0;
            if (   ( $self->info->has_data('artist') )
                && ( $_->{name} )
                && ( $self->info->get_data('artist') eq $_->{name} ) ) {
                $s += 16;
            }
            elsif (( $self->info->has_data('artist') )
                && ( $_->{sortname} )
                && ( $self->info->get_data('artist') eq $_->{sortname} ) ) {
                $s += 8;
            }
            elsif (( $self->info->has_data('mb_artistid') )
                && ( $_->{id} )
                && ( $self->info->get_data('mb_artistid') eq $_->{id} ) ) {
                $s += 4;
            }
            elsif (
                   ( $self->info->has_data('artist') )
                && ( $_->{name} )
                && ($self->simple_compare(
                        $self->info->get_data('artist'),
                        $_->{name}, .90
                    )
                )
                ) {
                $s += 2;
            }
            if ( $s > $maxscore ) {
                $artist   = $_;
                $maxscore = $s;
            }
        }
        if ( $maxscore > $self->options->{min_artist_score} ) {
            $self->status( "Artist ", $artist->name, " won election with ",
                $maxscore, "pts" );
        }
        elsif ($maxscore) {
            $self->status( "Artist ", $artist->name, " won election with ",
                $maxscore, "pts, but that is not good enough" );
            return;
        }
        else {
            $self->status("No Artist found");
            return;
        }
    }
    return unless ( defined $artist );
    my %amap = (
        name            => 'artist',
        id              => 'mb_artistid',
        sort_name       => 'sortname',
        type            => 'artist_type',
        life_span_begin => 'artist_start',
        life_span_end   => 'artist_end',

    );

    while ( my ( $k, $v ) = each %amap ) {
        if ( $artist->$k ) {
            unless (( $self->info->has_data($v) )
                and ( ( $self->info->get_data($v) ) eq ( $artist->$k ) ) ) {
                $self->info->set_data( $v => $artist->$k );
                $self->tagchange("ARTIST");
            }
        }
    }
    return $self->info;
}

sub album_info {
    my $self = shift;
    $self->status( "Looking up album from " . $self->options->{mb_host} );
    unless ( exists $self->{mb_r} ) {
        $self->{mb_r} = WebService::MusicBrainz::Release->new(
            HOST  => $self->options->{mb_host},
            CACHE => $self->mb_cache
        );
    }
    my $params = { LIMIT => 200 };
    my $release = undef;
    if (   ( $self->info->has_data('mb_albumid') )
        && ( not $self->info->options->{ignore_mbid} )
        && ( length( $self->info->get_data('mb_albumid') ) > 30 )

        ) {
        $params->{MBID} = $self->info->get_data('mb_albumid');
        my $response = $self->{mb_r}->search($params);
        $release = $response->release();

        #print Dumper($release);
    }
    else {
        if (   ( $self->info->has_data('mb_artistid') )
            && ( $self->info->get_data('mb_artistid') ) ) {
            $params->{artistid} = $self->info->get_data('mb_artistid');
        }
        elsif ( ( $self->info->has_data('artist') )
            && ( $self->info->get_data('artist') ) ) {
                $params->{artist} = $self->info->get_data('artist');
        }
        else {
                $self->status("Artist required for album lookup...");
                return ();
        }

        my $response = $self->{mb_r}->search($params);
        return unless $response;

        #     albumid          256 pts
        #     title             64 pts
        #	    asin              32 pts
        #     simple_title      32 pts
        #	    discid            32 pts
        #	    track_count       16 pts
        #     release_date       8 pts
        #     track name match   4 pts
        #     strack name match  2 pts
        #     track time match   1 pts

        my $releases = $response->release_list();
        return unless $releases;

        my $maxscore = 0;
        foreach ( @{ $releases->releases } ) {
                my $s     = 0;
                my $title = $_->{title};
                my $disc  = 1;
                if ( $title =~ /^(.+) \(disc (\d)(\: ([^)]*))?\)/i ) {
                    $title = $1;
                    $disc  = $2;
                }
                if (    ( $self->info->has_data('mb_albumid') )
                    and ( $self->info->get_data('mb_albumid') eq $_->id )
                    and ( not $self->options->{ignore_mbid} ) ) {
                    $s += 256;
                }
                if ( $title eq $self->info->album ) {
                    $s += 64;
                }
                if (   ( $_->{asin} )
                    && ( $self->info->asin )
                    && ( length( $_->{asin} ) > 8 )
                    && ( $_->{asin} eq $self->info->get_data('asin') ) ) {
                    $s += 32;
                }
                if ($self->simple_compare(
                        $title, $self->info->get_data('album'), .80
                    )
                    ) {
                    $s += 32;
                }
                if (( $self->info->has_data('totaltracks') )
                    and ( ( $self->info->get_data('totaltracks') )
                        == ( $_->track_list->{count} ) )
                    ) {
                    $s += 16;
                }
                if (    ( $self->info->has_data('disc') )
                    and ( defined $disc )
                    and ( ( $self->info->get_data('disc') ) == ($disc) ) ) {
                    $s += 8;
                }
                if ( $s > $maxscore ) {
                    $release  = $_;
                    $maxscore = $s;
                }
        }
        if ( $maxscore > $self->options->{min_album_score} ) {
                $self->status( "Awarding highest score of "
                        . $maxscore . " to "
                        . $release->title );
        }
        elsif ($release) {
                $self->status( "Highest score of "
                        . $maxscore . " to "
                        . $release->title
                        . " is too low" );
                return;
        }
        else {
                $self->status("No good match found for album, sorry\n");
                return;
        }
    }
    if ( $release->type ) {
            unless (
                ( $self->info->has_data('album_type') )
                and ( ( $self->info->get_data('album_type') ) eq
                    ( $release->{type} ) )
                ) {
                $self->info->set_data( 'album_type', $release->{type} );
                $self->tagchange("ALBUM_TYPE");
            }
    }
    if ( $release->id ) {
            unless (
                ( $self->info->has_data('mb_albumid') )
                and ( ( $self->info->get_data('mb_albumid') ) eq
                    ( $release->{id} ) )
                ) {
                $self->info->set_data( 'mb_albumid', $release->id() );
                $self->tagchange("MB_ALBUMID");
            }
    }
    if ( $release->title ) {

# Parse out additional disc information.  I still don't know how to deal with multi-volume sets
# in MusicBrainz.  Style says to use (disc X) or (disc X: Disc Title) or even (box X, disc X).
# for now, I will support in album_title /\(disc (\d):?[^)]*\)/.
            unless ( ( $self->info->has_data('album') )
                && ( $self->info->get_data('album') eq $release->title ) ) {
                if ($release->title() =~ /^(.+) \(disc (\d)(\: ([^)]*))?\)/i )
                {
                    my ( $alb, $disc, $disctitle ) = ( $1, $2, $4 );
                    unless ( $self->info->get_data('album') eq $alb ) {
                        $self->info->set_data( 'album', $1 );
                        $self->tagchange("ALBUM");
                    }
                    unless ( $self->info->get_data('disc') eq $disc ) {
                        $self->info->set_data( 'disc', $2 );
                        $self->tagchange("DISC");
                    }
                    if ($3) {
                        $self->status("Debug disctitle: $disctitle");
                        unless (
                            $self->info->get_data('disctitle') eq $disctitle )
                        {
                            $self->info->set_data( 'disctitle', $disctitle );
                            $self->tagchange("DISCTITLE");
                        }
                    }
                }
                else {
                    $self->info->set_data( 'album', $release->title() );
                    $self->tagchange("ALBUM");
                }
            }
    }
    if ( $release->track_list ) {
            unless (
                ( $self->info->has_data('totaltracks') )
                and ( ( $self->info->get_data('totaltracks') )
                    == ( $release->track_list->{count} ) )
                ) {
                $self->info->get_data( 'totaltracks',
                    $release->track_list->{count} );
                $self->tagchange("TOTALTRACKS");
            }
    }

    if ( exists $release->{asin} ) {
            unless (( $self->info->has_data('asin') )
                and ( $self->info->get_data('asin') eq $release->{asin} ) ) {
                $self->info->set_data( 'asin', $release->{asin} );
                $self->tagchange("ASIN");
            }
    }
    return $self->info;
}

sub track_info {
        my $self = shift;
        if ((   (      $self->info->has_data('totaldiscs')
                    && $self->info->get_data('totaldiscs') > 1
                )
                or (   $self->info->has_data('disc')
                    && $self->info->get_data('disc') > 1 )
            )
            && ( not $self->options->{ignore_multidisc_warning} )
            ) {
            $self->status(
                "Warning! Multi-Disc item. MusicBrainz is not reliable for this. Will not change track name or number."
            );
        }
        $self->status( "Looking up track from " . $self->options->{mb_host} );
        unless ( exists $self->{mb_r} ) {
            $self->{mb_r} = WebService::MusicBrainz::Release->new(
                HOST  => $self->options->{mb_host},
                CACHE => $self->mb_cache
            );
        }
        return unless ( $self->info->has_data('mb_albumid') );
        my $params = {
            MBID => $self->info->get_data('mb_albumid'),
            INC  => "tracks discs release-events",
        };
        my $response = $self->{mb_r}->search($params);
        unless ( $response->release->track_list ) {
            return;
        }
        my $tracks   = $response->release->track_list->tracks();
        my $release  = $response->release;
        my $tracknum = 0;
        my $maxscore = 0;
        my $track    = undef;
        my $trackn   = 0;

        #   track ID (unless ignore_ids)  128 pts
        #   tracknum match                  4 pts
        #    trust track set               64 pts
        #   title match                     8 pts
        #    trust title set               64 pts
        #   close title match               4 pts
        #    trust title set               16 pts
        #   time match                      2 pts
        #    trust time set                64 pts
        #   close time match                1 pts
        #    trust time set                16 pts

        foreach my $t ( @{$tracks} ) {
            my $s = 0;
            if (   ( $self->info->has_data('mb_trackid') )
                && ( $self->info->get_data('mb_trackid') eq $t->{id} )
                && ( not $self->info->{ignore_mbid} ) ) {
                $s += 128;
            }
            if (   ( $self->info->has_data('track') )
                && ( $self->info->get_data('track') - 1 == $tracknum ) ) {
                if ( $self->options->{trust_track} ) {
                    $s += 64;
                }
                else {
                    $s += 4;
                }
            }
            if (   ( $self->info->has_data('title') )
                && ( $self->info->get_data('title') eq $t->{title} ) ) {
                if ( $self->options->{trust_title} ) {
                    $s += 64;
                }
                else {
                    $s += 8;
                }
            }
            elsif (
                ( $self->info->has_data('title') )
                && ($self->simple_compare(
                        $self->info->get_data('title'),
                        $t->{title}, .80
                    )
                )
                ) {
                if ( $self->options->{trust_title} ) {
                    $s += 16;
                }
                else {
                    $s += 4;
                }
            }
            if (   ( $self->info->has_data('duration') )
                && ( exists $t->{duration} )
                && ( defined $t->{duration} ) ) {
                my $diff =
                    abs( $self->info->get_data('duration') - $t->{duration} );
                if ( $diff < 3000 ) {
                    if ( $self->options->{trust_time} ) {
                        $s += 16;
                    }
                    else {
                        $s += 1;
                    }
                }
                elsif ( $diff < 100 ) {
                    $s += 2;
                    if ( $self->options->{trust_time} ) {
                        $s += 64;
                    }
                    else {
                        $s += 1;
                    }
                }
            }
            if ( $s > $maxscore ) {
                $maxscore = $s;
                $track    = $t;
                $trackn   = $tracknum + 1;
            }
            $tracknum++;
        }
        if (   ($maxscore)
            && ( $maxscore > $self->options->{min_track_score} ) ) {
            $self->status( "Awarding highest score of "
                    . $maxscore . " to "
                    . $track->title );
        }
        elsif ($maxscore) {
            $self->status( "Highest score was "
                    . $maxscore . " for "
                    . $track->title
                    . ", but that is not good enough, skipping track info." );
            return;
        }
        else {
            $self->status("No match for track, skipping track info.");
            return;
        }
        unless (
            (   (      $self->info->has_data('totaldiscs')
                    && $self->info->get_data('totaldiscs') > 1
                )
                or (   $self->info->has_data('disc')
                    && $self->info->get_data('disc') > 1 )
            )
            && ( not $self->options->{ignore_multidisc_warning} )
            ) {
            if ( $track->title ) {
                unless (
                    ( $self->info->has_data('title') )
                    and ( ( $self->info->get_data('title') ) eq
                        ( $track->title ) )
                    ) {
                    $self->info->set_data( 'title', $track->title );
                    $self->tagchange("TITLE");
                }
            }
            unless (( $self->info->has_data('track') )
                and ( $self->info->get_data('track') == $trackn ) ) {
                $self->info->set_data( 'track', $trackn );
                $self->tagchange("TRACK");
            }
            if ( $track->id ) {
                unless (
                    ( $self->info->has_data('mb_trackid') )
                    and ( ( $self->info->get_data('mb_trackid') ) eq
                        ( $track->id ) )
                    ) {
                    $self->info->set_data( 'mb_trackid', $track->id );
                    $self->tagchange("MB_TRACKID");
                }
            }
        }
        my $releases = [];
        if ( $release->release_event_list ) {
            $releases = $release->release_event_list->events;
        }
        my $countrycode = undef;
        my $releasedate = undef;
        if ( scalar @{$releases} ) {
            $maxscore = 0;
            foreach ( @{$releases} ) {
                my $score = 0;
                if (   ( $_->date )
                    && ( $self->info->has_data('releasedate') )
                    && ( $_->date eq $self->info->get_data('releasedate') ) )
                {
                    $score += 4;
                }
                elsif ( $_->country eq $self->options->{prefered_country} ) {
                    $score += 2;
                }
                elsif ( not defined $countrycode ) {
                    $score += 1;
                }
                if ( $score > $maxscore ) {
                    $countrycode = $_->country();
                    $releasedate = $_->date();
                    $maxscore    = $score;
                }
            }
        }
        if (($countrycode)
            && (not( ( $self->info->has_data('countrycode') )
                    && ($self->info->get_data('countrycode') eq $countrycode )
                )
            )
            ) {
            $self->info->set_data( 'countrycode', $countrycode );
            $self->tagchange("countrycode");
        }
        if (($releasedate)
            && (not( ( $self->info->has_data('releasedate') )
                    && ($self->info->get_data('releasedate') eq $releasedate )
                )
            )
            ) {
            $self->info->set_data( 'releasedate', $releasedate );
            $self->tagchange("releasedate");
        }
}

sub mb_cache {
        my $self = shift;
        my $new  = shift;
        if ($new) {
            $self->{mb_cache} = $new;
        }
        unless ( ( exists $self->{mb_cache} ) && ( $self->{mb_cache} ) ) {
            if ( $self->options->{mb_cache} ) {
                $self->{mb_cache} = $self->options->{mb_cache};
            }
            else {
                $self->{mb_cache} = Cache::FileCache->new(
                    {   namespace          => "mb_cache",
                        default_expires_in => 60000,
                    }
                );
            }
        }
        return $self->{mb_cache};
}

1;
__END__

=pod

=head1 NAME

Music::Tag::MusicBrainz - Plugin module for Music::Tag to get information from MusicBrainz database.

=head1 SYNOPSIS

	use Music::Tag

	my $info = Music::Tag->new($filename);
   
	my $plugin = $info->add_plugin("MusicBrainz");
	$plugin->get_tag;

	print "Music Tag Track ID ", $info->mb_trackid();

=head1 DESCRIPTION

This plugin gathers additional information about a track from L<www.musicbrianz.org>, and updates the Music::Tag object.

Music::Tag::MusicBrainz objects must be created by Music::Tag.

=head1 REQUIRED DATA VALUES

=over 4

=item artist

=back

=head1 USED DATA VALUES

=over 4

=item album

This is used to filter results. 

=item releasedate

This is used to filter results. 

=item totaltracks

This is used to filter results. 

=item title

title is used only if track is not true, or if trust_title option is set.

=item tracknum

tracknum is used only if title is not true, or if trust_track option is set.

=back

=head1 SET DATA VALUES

=over 4

=item album

=item title

title is set only if trust_track is true.

=item track

track is set only if track is not true or trust_title is true.

=item releasedate

=back

=head1 METHODS

=over 4

=item B<get_tag()>

Updates current Music::Tag object with information from MusicBrainz database.

Same as $mbplugin->artist_info() && $mbplugin->album_info() && $mbplugin->track_info();

=item B<artist_info()>

Update the Music::Tag object with information about the artist from MusicBrainz.

=item B<album_info()>

Update the Music::Tag object with information about the album from MusicBrainz.

=item B<track_info()>

Update the Music::Tag object with information about the track from MusicBrainz.

=item B<mb_cache()>

Returns and optionally sets a reference to the Cache::FileCache object used to cache requests.

=item B<default_options()>

Returns hash of default options for plugin

=item B<required_values()>

A list of required values required for get_tag() to work.

=item B<set_values()>

A list of values that can be set by this module.

=back

=head1 OPTIONS

=over 4

=item prefered_country

If multiple release countries are available, prefer this one. Default is 'US'.

=item min_artist_score

Minimum artist score for a match.  Default is 1.

=item min_album_score

Minimum album score for a mach.  Default is 17.  Raise if you get too many false positives.

=item min_track_score.

Minimum track score.  Default is 3.

=item ignore_mbid

If set, will ignore any MusicBrainz ID values found.

=item trust_time

If set, will give high priority to track duration in matching

=item trust_track

If set, will give high priority to track number in matching

=item trust_title

If set, will give high priority to title in matching.

=item skip_seen

If set, will not perform a MusicBrainz lookup if an mb_trackid is set.

=item ignore_multidisc_warning

If set, will enable use of MusicBrainz standards to get disc numbers.

=item mb_host

Set to host for musicbrainz.  Default is www.musicbrainz.org.

=back

=head1 BUGS

Sometimes will grab incorrect info. This is due to the lack of album level view when repairing tags.

Please use github for bug tracking: L<http://github.com/riemann42/Music-Tag-MusicBrainz/issues|http://github.com/riemann42/Music-Tag-MusicBrainz/issues>.

=head1 SEE ALSO

L<WebService::MusicBrainz>, L<Music::Tag>, L<www.musicbrianz.org>

=head1 SOURCE

Source is available at github: L<http://github.com/riemann42/Music-Tag-MusicBrainz|http://github.com/riemann42/Music-Tag-MusicBrainz>.

=head1 AUTHOR 

Edward Allen III <ealleniii _at_ cpan _dot_ org>

=head1 COPYRIGHT

Copyright © 2007,2008 Edward Allen III. Some rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either:

a) the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

b) the "Artistic License" which comes with Perl.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
Kit, in the file named "Artistic".  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301, USA or visit their web page on the Internet at
http://www.gnu.org/copyleft/gpl.html.




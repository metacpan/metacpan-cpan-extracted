package Music::Tag::MP3;
use strict; use warnings; use utf8;
our $VERSION = '0.4101';

# Copyright © 2007,2010 Edward Allen III. Some rights reserved.
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.

use MP3::Tag;
use MP3::Info;
use base qw(Music::Tag::Generic);

sub default_options {
    { apic_cover => 1, };
}

sub _decode_uni {
    my $in = shift;
    my $c = unpack( "U", substr( $in, 0, 1 ) );
    if ( ($c) && ( $c == 255 ) ) {
        $in = decode( "UTF-16LE", $in );

        #$in =~ s/^[^A-Za-z0-9]*//;
        #$in =~ s/ \/ //g;
    }
    return $in;
}

sub mp3 {
    my $self = shift;
    unless ( ( exists $self->{'_mp3'} ) && ( ref $self->{'_mp3'} ) ) {
        if ( $self->info->get_data('filename') ) {
            $self->{'_mp3'} = MP3::Tag->new( $self->info->get_data('filename') );
        }
        else {
            return undef;
        }
    }
    return $self->{'_mp3'};
}

sub _auto_methods_map {
    return {
        bitrate => {
            method     => 'bitrate_kbps',
            decode_uni => 0,
            inspect    => 0,
            readonly   => 1
        },
        duration => {
            method     => 'total_millisecs_int',
            decode_uni => 0,
            inspect    => 0,
            readonly   => 1
        },
        frequency => {
            method     => 'frequency_Hz',
            decode_uni => 0,
            inspect    => 0,
            readonly   => 1
        },
        stereo => {
            method     => 'is_stereo',
            decode_uni => 0,
            inspect    => 0,
            readonly   => 1
        },
        bytes => {
            method     => 'size_bytes',
            decode_uni => 0,
            inspect    => 0,
            readonly   => 1
        },
        frames => {
            method     => 'frames',
            decode_uni => 0,
            inspect    => 0,
            readonly   => 1
        },
        'framesize' => {
            method     => 'frame_len',
            decode_uni => 0,
            inspect    => 0,
            readonly   => 1
        },
        vbr => {
            method     => 'is_vbr',
            decode_uni => 0,
            inspect    => 0,
            readonly   => 1
        },
        title    => { method => 'title',   decode_uni => 1, inspect => 1 },
        artist   => { method => 'artist',  decode_uni => 1, inspect => 1 },
        album    => { method => 'album',   decode_uni => 1, inspect => 1 },
        comment  => { method => 'comment', decode_uni => 1, inspect => 1 },
        year     => { method => 'year',    decode_uni => 1, inspect => 1 },
        genre    => { method => 'genre',   decode_uni => 1, inspect => 1 },
        tracknum => { method => 'track',   decode_uni => 0, inspect => 0 },
        composer => {
            method     => 'composer',
            decode_uni => 0,
            inspect    => 0,
            readonly   => 1
        },
        performer => {
            method     => 'performer',
            decode_uni => 1,
            inspect    => 0,
            readonly   => 1
        },
    };
}

sub _id3v2_frame_map {
    return {
        discnum  => [ { frame => 'TPOS', description => '' } ],
        label    => [ { frame => 'TPUB', description => '' } ],
        sortname => [
            { frame => 'XSOP', description => '' },
            { frame => 'TPE1', description => '' }
        ],
        mb_trackid => [
            { frame => 'TXXX', description => 'MusicBrainz Track Id' },
            { frame => 'UFID', field       => '_Data', description => '' }
        ],
        asin     => [ { frame => 'TXXX', description => 'ASIN' } ],
        sortname => [ { frame => 'TXXX', description => 'Sortname' } ],
        albumartist_sortname => [
            {   frame       => 'TXXX',
                description => 'MusicBrainz Album Artist Sortname'
            },
            { frame => 'TXXX', description => 'ALBUMARTISTSORT' }
        ],
        albumartist => [
            { frame => 'TXXX', description => 'MusicBrainz Album Artist' }
        ],
        countrycode => [
            {   frame       => 'TXXX',
                description => 'MusicBrainz Album Release Country'
            }
        ],
        mb_artistid =>
            [ { frame => 'TXXX', description => 'MusicBrainz Artist Id' } ],
        mb_albumid =>
            [ { frame => 'TXXX', description => 'MusicBrainz Album Id' } ],
        album_type => [
            { frame => 'TXXX', description => 'MusicBrainz Album Status' }
        ],
        artist_type =>
            [ { frame => 'TXXX', description => 'MusicBrainz Artist Type' } ],
        mip_puid => [ { frame => 'TXXX', description => 'MusicIP PUID' } ],
        artist_start =>
            [ { frame => 'TXXX', description => 'Artist Begins' } ],
        artist_end => [ { frame => 'TXXX', description => 'Artist Ends' } ],
        ean        => [ { frame => 'TXXX', description => 'EAN/UPC' } ],
        mip_puid => [ { frame => 'TXXX', description => 'MusicMagic Data' } ],
        mip_fingerprint =>
            [ { frame => 'TXXX', description => 'MusicMagic Fingerprint' } ],
    };
}

sub set_values {
    my $self = shift;
    return (
        keys %{ $self->_auto_methods_map },
        keys %{ $self->_id3v2_frame_map },
        'picture', 'lyrics', 'encoder', 'label'
    );
}

sub saved_values {
    my $self = shift;
    return (
        keys %{ $self->_auto_methods_map },
        keys %{ $self->_id3v2_frame_map },
        'picture', 'lyrics', 'encoder', 'label'
    );
}

sub get_tag {
    my $self = shift;
    return unless ( $self->mp3 );
    $self->mp3->config( id3v2_mergepadding => 0 );
    $self->mp3->config( autoinfo => "ID3v2", "ID3v1" );
    return unless $self->mp3;

    $self->info->datamethods('filetype');
    $self->info->datamethods('mip_fingerprint');
    $self->info->set_data('filetype','mp3');

    $self->mp3->get_tags;

    my $mt_to_mp3 = $self->_auto_methods_map();

    while ( my ( $mt, $mp3 ) = each %{$mt_to_mp3} ) {
        my $method  = $mp3->{method};
        $self->info->set_data($mt, $self->mp3->$method );
    }
    my $frame_map = $self->_id3v2_frame_map();
    if ( exists $self->mp3->{ID3v2} ) {
        while ( my ( $mt, $mp3d ) = each %{$frame_map} ) {
            foreach my $mp3 ( @{$mp3d} ) {
                my $t =
                    $self->mp3->{ID3v2}
                    ->frame_select( $mp3->{frame}, $mp3->{description},
                    [''] );
                if ( ( ref $t ) && ( exists $mp3->{field} ) ) {
                    $self->info->set_data($mt,$t->{ $mp3->{field} } );
                    last;
                }
                elsif ($t) {
                    $self->info->set_data($mt,$t);
                    last;
                }
            }
        }

        my $day = $self->mp3->{ID3v2}->get_frame('TDAT') || "";
        if ( ( $day =~ /(\d\d)(\d\d)/ ) && ( $self->mp3->year ) ) {
            my $releasedate = $self->mp3->year . "-" . $1 . "-" . $2;
            my $time = $self->mp3->{ID3v2}->get_frame('TIME') || "";
            if ( $time =~ /(\d\d)(\d\d)/ ) {
                $releasedate .= " " . $1 . ":" . $2;
            }
            print STDERR "Reading releasedate of $releasedate\n";
            $self->info->set_data('releasetime',$releasedate);
        }

        my $lyrics = $self->mp3->{ID3v2}->get_frame('USLT');
        if ( ref $lyrics ) {
            $self->info->set_data('lyrics', $lyrics->{Text} );
        }
        if ( $self->mp3->{ID3v2}->get_frame('TENC') ) {
            $self->info->set_data('encoded_by', $self->mp3->{ID3v2}->get_frame('TENC') );
        }

        if ( ref $self->mp3->{ID3v2}->get_frame('USER') ) {
            if ( $self->mp3->{ID3v2}->get_frame('USER')->{Language} eq "Cop" )
            {
                $self->status("Emusic mistagged file found");
                $self->info->set_data('encoded_by','emusic');
            }
        }

        if (( not $self->options->{ignore_apic} )
            && ( $self->mp3->{ID3v2}
                ->frame_select( 'APIC', '', 'Cover (front)' ) )
            && ( not $self->info->has_data('picture') )
            ) {
            $self->info->picture(
                $self->mp3->{ID3v2}->get_frame( 'APIC', '', 'Cover (front)' )
            );
        }

        if ( $self->info->get_data('comment') =~ /^Amazon.com/i ) {
            $self->info->set_data('encoded_by','Amazon.com');
        }
        if ( $self->info->get_data('comment') =~ /^cdbaby.com/i ) {
            $self->info->set_data('encoded_by','cdbaby.com');
        }

    }

    $self->{mp3info} = MP3::Info::get_mp3info( $self->info->get_data('filename') );
    if ( $self->{mp3info}->{LAME} ) {
        $self->info->set_data('pregap', $self->{mp3info}->{LAME}->{start_delay} );
        $self->info->set_data('postgap', $self->{mp3info}->{LAME}->{end_padding} );
        if ( $self->{mp3info}->{LAME}->{encoder_version} ) {
            $self->info->set_data('encoder',
                $self->{mp3info}->{LAME}->{encoder_version} );
        }
    }

    if ( $self->mp3->mpeg_version() ) {
        $self->info->set_data('codec', "MPEG Version "
                . $self->mp3->mpeg_version()
                . " Layer "
                . $self->mp3->mpeg_layer() );
    }

    return $self;
}

sub calculate_gapless {
    my $self = shift;
    my $file = shift;
    my $gap  = {};
    require MP3::Info;
    require Math::Int64;
    $MP3::Info::get_framelengths = 1;
    my $info = MP3::Info::get_mp3info($file);
    if ( ($info) && ( $info->{LAME}->{end_padding} ) ) {
        $gap->{gaplesstrackflag} = 1;
        $gap->{pregap}           = $info->{LAME}->{start_delay};
        $gap->{postgap}          = $info->{LAME}->{end_padding};
        $gap->{samplecount} =
              $info->{FRAME_SIZE} * scalar( $info->{FRAME_LENGTHS} )
            - $gap->{pregap}
            - $gap->{postgap};
        my $finaleight = 0;
        for ( my $n = 1; $n <= 8; $n++ ) {
            $finaleight += $info->{FRAME_LENGTHS}->[ -1 * $n ];
        }
        $gap->{gaplessdata} =
              Math::Int64::uint64( $info->{SIZE} )
            - Math::Int64::uint64($finaleight);
    }
    return $gap;
}

sub strip_tag {
    my $self = shift;
    $self->status("Stripping current tags");
    if ( exists $self->mp3->{ID3v2} ) {
        $self->mp3->{ID3v2}->remove_tag;
        $self->mp3->{ID3v2}->write_tag;
    }
    if ( exists $self->mp3->{ID3v1} ) {
        $self->mp3->{ID3v1}->remove_tag;
    }
    return $self;
}

sub set_tag {
    my $self     = shift;
    my $filename = $self->info->get_data('filename');
    $self->status("Updating MP3");

    my $mt_to_mp3 = $self->_auto_methods_map();
    while ( my ( $mt, $mp3 ) = each %{$mt_to_mp3} ) {
        my $method = $mp3->{method} . '_set';
        next if ( ( exists $mp3->{readonly} ) && ( $mp3->{readonly} ) );
        $self->mp3->$method( $self->info->get_data($mt), 1 );
    }

    my $id3v1;
    my $id3v2;
    if ( $self->mp3->{ID3v2} ) {
        $id3v2 = $self->mp3->{ID3v2};
    }
    else {
        $id3v2 = $self->mp3->new_tag("ID3v2");
    }
    if ( $self->mp3->{ID3v1} ) {
        $id3v1 = $self->mp3->{ID3v1};
    }
    else {
        $id3v1 = $self->mp3->new_tag("ID3v1");
    }

    $self->status("Writing ID3v2 Tag");

    my $frame_map = $self->_id3v2_frame_map();

    while ( my ( $mt, $mp3d ) = each %{$frame_map} ) {
        my $mp3 = $mp3d->[0];
        next if ( ( exists $mp3->{readonly} ) && ( $mp3->{readonly} ) );
        if ( $self->info->has_data($mt) ) {
            my $val = $self->info->get_data($mt);
            if (   ( not ref $val )
                && ( exists $mp3->{field} )
                && ( $mp3->{field} ) ) {
                $val = { $mp3->{field} => $self->info->get_data($mt) };
            }
            #else {
                $id3v2->frame_select( $mp3->{frame}, $mp3->{description},
                    [''], $val );
            #}
        }
    }

    if ( $self->info->has_data('lyrics') ) {
        $id3v2->remove_frame('USLT');
        $id3v2->add_frame( 'USLT', 0, "ENG", "Lyrics", $self->info->get_data('lyrics') );
    }
    if ( $self->info->has_data('encoded_by') ) {
        $id3v2->remove_frame('TENC');
        $id3v2->add_frame( 'TENC', 0, $self->info->get_data('encoded_by') );
    }
    if (( $self->info->has_data('releasetime') )
        && ( $self->info->get_data('releasetime')
            =~ /(\d\d\d\d)-?(\d\d)?-?(\d\d)? ?(\d\d)?:?(\d\d)?/ )
        ) {
        my $year = $1;
        my $day  = sprintf( "%02d%02d", $2 || 0, $3 || 0 );
        my $time = sprintf( "%02d%02d", $4 || 0, $5 || 0 );
        $id3v2->remove_frame('TDAT');
        $id3v2->add_frame( 'TDAT', 0, $day );
        $id3v2->remove_frame('TIME');
        $id3v2->add_frame( 'TIME', 0, $time );
        $self->mp3->year_set($year);
        print STDERR "Writing releasedate: $day and time: $time\n";
    }
    if ( !$self->options->{ignore_apic} ) {
        $id3v2->remove_frame('APIC');
        if ( ( $self->options->{apic_cover} ) && ( $self->info->has_data('picture') ) ) {
            $self->status("Saving Cover to APIC frame");
            $id3v2->add_frame( 'APIC', _apic_encode( $self->info->get_data('picture') ) );
        }
    }
    eval { $id3v2->write_tag(); };
    eval { $id3v1->write_tag(); };
    return $self;
}

sub close {
    my $self = shift;
    if ( $self->mp3 ) {
        $self->mp3->close();
        $self->mp3->{ID3v2} = undef;
        $self->mp3->{ID3v1} = undef;
        $self->{'_mp3'}     = undef;
    }
}

sub _apic_encode {
    my $code = shift;
    return (
        0, $code->{"MIME type"},
        $code->{"Picture Type"} || 'Cover (front)',
        $code->{"Description"},
        $code->{_Data}
    );
}

sub _url_encode {
    my $url = shift;
    return ($url);
}

1;

# vim: tabstop=4
__END__

=head1 NAME

Music::Tag::MP3 - Plugin module for Music::Tag to get information from id3 tags

=for readme stop

=head1 SYNOPSIS

	use Music::Tag

	my $info = Music::Tag->new($filename, { quiet => 1 }, "MP3");
	$info->get_tag();
   
	print "Artist is ", $info->artist;

=for readme continue

=head1 DESCRIPTION

Music::Tag::MP3 is used to read id3 tag information. It uses MP3::Tag to read id3v2 and id3 tags from mp3 files. As such, it's limitations are the same as MP3::Tag. It does not write id3v2.4 tags, causing it to have some trouble with unicode.

=begin readme

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires these other modules and libraries:

   Muisc::Tag
   MP3::Tag
   MP3::Info

Do not install an older version of MP3::Tag. 

=head1 NOTE ON ID3v2.4 TAGS

There seems to be a bug with MP3::Tag::ID3v2 0.9709. To use ID3v2.4 tags,
download MP3::Tag from CPAN and apply the following patch:

   patches/MP3-Tag-0.9709.ID3v2.4.patch

To do this change directory to the MP3::Tag download directory and type

   patch -p1 < ../Music-Tag-MP3/patches/MP3-Tag-0.9709.ID3v2.4.patch

Then install as normal

   perl Makefile.PL
   make && make test
   make install

=head1 NOTE ON GAPLESS INFO

This is used for a yet-to-be-maybe-someday released ipod library.  It collects
the required gapless info.  There is a patch to MP3-Info that should be applied
ONLY if you are interested in experimenting with this.  

=head1 TEST FILES

Are based on the sample file for Audio::M4P.  For testing only.
   
=end readme

=for readme stop

=head1 REQUIRED DATA VALUES

No values are required (except filename, which is usually provided on object creation).

=head1 SET DATA VALUES

=over

=item mp3 file info added:

   Currently this includes bitrate, duration, frequency, stereo, bytes, codec, frames, vbr, 

=item auto tag info added:

title, artist, album, track, comment, year, genre, track, totaltracks, disc, totaldiscs, composer, and performer

=item id3v2 tag info added:

label, releasedate, lyrics (using USLT), encoder (using TFLT),  and picture (using apic). 

=item The following information is gathered from the ID3v2 tag using custom tags

=over 4

=item TXXX[ASIN] asin
=item TXXX[Sortname] sortname
=item TXXX[MusicBrainz Album Artist Sortname] albumartist_sortname
=item TXXX[MusicBrainz Album Artist] albumartist
=item TXXX[ALBUMARTISTSORT] albumartist
=item TXXX[MusicBrainz Album Release Country] countrycode
=item TXXX[MusicBrainz Artist Id] mb_artistid
=item TXXX[MusicBrainz Album Id] mb_albumid
=item TXXX[MusicBrainz Album Status] album_type
=item TXXX[MusicBrainz Artist Type] artist_type
=item TXXX[MusicIP PUID] mip_puid
=item TXXX[Artist Begins] artist_start
=item TXXX[Artist Ends] artist_end
=item TXXX[EAN/UPC] ean
=item TXXX[MusicMagic Data] mip_puid
=item TXXX[MusicMagic Fingerprint] mip_fingerprint

=back

=pod

=item Some data in the LAME header is obtained from MP3::Info (requires MP3::Info 1.2.3)

pregap
postgap

=back

=head1 METHODS

=over 4

=item B<default_options()>

Returns the default options for the plugin.  

=item B<set_tag()>

Save object back to ID3v2.3 and ID3v1 tag.

=item B<get_tag()>

Load information from ID3v2 and ID3v1 tags.

=item B<set_values()>

A list of values that can be set by this module.

=item B<saved_values()>

A list of values that can be saved by this module.

=item B<strip_tag()>

Remove the tag from the file.

=item B<close()>

Close the file and destroy the MP3::Tag object.

=item B<mp3()>

Returns the MP3::Tag object

=item B<calculate_gapless()>

Calculate gapless playback information.  Requires patched version of MP3::Info and Math::Int64 to work.

=back

=head1 OPTIONS

=over 4

=item apic_cover

Set to false to disable writing picture to tag.  True by default.

=item ignore_apic

Ignore embedded picture.

=back

=head1 BUGS

ID3v2.4 is not read reliably and can't be written.  Apic cover is unreliable in older versions of MP3::Tag.  

Please use github for bug tracking: L<http://github.com/riemann42/Music-Tag-MP3/issues|http://github.com/riemann42/Music-Tag-MP3/issues>.

=head1 SEE ALSO

L<MP3::Tag|MP3::Tag>, L<MP3::Info|MP3::Info>, L<Music::Tag|Music::Tag>

=for readme continue

=head1 SOURCE

Source is available at github: L<http://github.com/riemann42/Music-Tag-MP3|http://github.com/riemann42/Music-Tag-MP3>.

=head1 AUTHOR 

Edward Allen III <ealleniii _at_ cpan _dot_ org>

=head1 COPYRIGHT

Copyright © 2007,2008,2010 Edward Allen III. Some rights reserved.

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



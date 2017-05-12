package Music::Tag::OGG;
use strict; use warnings; use utf8;
our $VERSION = '0.4101';

# Copyright © 2007,2008,2010 Edward Allen III. Some rights reserved.
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.

use Ogg::Vorbis::Header::PurePerl;
use base qw(Music::Tag::Generic);

our %tagmap = (
	TITLE	=> 'title',
	TRACKNUMBER => 'track',
	TRACKTOTAL => 'totaltracks',
	ARTIST => 'artist',
	ALBUM => 'album',
	COMMENT => 'comment',
	DATE => 'releasedate',
	GENRE => 'genre',
	DISC => 'disc',
	LABEL => 'label',
	ASIN => 'asin',
    MUSICBRAINZ_ARTISTID => 'mb_artistid',
    MUSICBRAINZ_ALBUMID => 'mb_albumid',
    MUSICBRAINZ_TRACKID => 'mb_trackid',
    MUSICBRAINZ_SORTNAME => 'sortname',
    RELEASECOUNTRY => 'countrycode',
    MUSICIP_PUID => 'mip_puid',
    MUSICBRAINZ_ALBUMARTIST => 'albumartist'
);

sub default_options {
	{ vorbiscomment => "vorbiscomment" }
}

sub set_values {
	return ( values %tagmap, 'picture');
}

sub saved_values {
	return ( values %tagmap, 'picture');
}
 
sub ogg {
	my $self = shift;
	unless ((exists $self->{_OGG}) && (ref $self->{_OGG})) {
		if ($self->info->get_data('filename')) {
			$self->{_OGG} = Ogg::Vorbis::Header::PurePerl->new($self->info->get_data('filename'));
			#$self->{_OGG}->load();
		}
		else {
			return undef;
		}
	}
	return $self->{_OGG};
}

sub get_tag {
    my $self     = shift;
    if ( $self->ogg ) {
		foreach ($self->ogg->comment_tags) {
			my $comment = uc($_);
			if (exists $tagmap{$comment}) {
				my $method = $tagmap{$comment};
				$self->info->set_data($method, $self->ogg->comment($comment));
			}
			else {
				$self->status("Unknown comment: $comment");
			}
		}
        $self->info->set_data('secs',$self->ogg->info->{"length"});
        $self->info->set_data('bitrate',$self->ogg->info->{"bitrate_nominal"});
        $self->info->set_data('frequency',$self->ogg->info->{"rate"});
	}
	else {
		print STDERR "No ogg object created\n";
	}
    return $self;
}


sub set_tag {
    my $self = shift;
	unless (open(COMMENT, "|-", $self->options->{vorbiscomment} ." -w ". "\"". $self->info->get_data('filename') . "\"")) {
		$self->status("Failed to open ", $self->options->{vorbiscomment}, ".  Not writing tag.\n");
		return undef;
	}
	while (my ($t, $m) = each %tagmap) {
		if (defined $self->info->get_data($m)) {
			print COMMENT $t, "=", $self->info->get_data($m), "\n";
		}
	}
	close (COMMENT);
    return $self;
}

sub close {
	my $self = shift;
	$self->{_OGG} = undef;
}

1;

__END__
=pod

=head1 NAME

Music::Tag::OGG - Plugin module for Music::Tag to get information from ogg-vorbis headers. 

=head1 SYNOPSIS

	use Music::Tag

	my $filename = "/var/lib/music/artist/album/track.ogg";

	my $info = Music::Tag->new($filename, { quiet => 1 }, "OGG");

	$info->get_info();
   
	print "Artist is ", $info->artist;

=head1 DESCRIPTION

Music::Tag::OGG is used to read ogg-vorbis header information. It uses Ogg::Vorbis::Header::PurePerl. I have gone back and forth with using this
and Ogg::Vorbis::Header.  Finally I have settled on Ogg::Vorbis::Header::PurePerl, because the autoload for Ogg::Vorbis::Header was a pain to work with.

To write Ogg::Vorbis headers I use the program vorbiscomment.  It looks for this in the path, or in the option variable "vorbiscomment."  This tool
is available from L<http://www.xiph.org/> as part of the vorbis-tools distribution.

Music::Tag::Ogg objects should be created by Music::Tag.

=head1 REQUIRED DATA VALUES

No values are required (except filename, which is usually provided on object creation).

=head1 SET DATA VALUES

=over 4

=item B<title, track, totaltracks, artist, album, comment, releasedate, genre, disc, label>

Uses standard tags for these

=item B<asin>

Uses custom tag "ASIN" for this

=item B<mb_artistid, mb_albumid, mb_trackid, mip_puid, countrycode, albumartist>

Uses MusicBrainz recommended tags for these.


=back

=head1 METHODS

=over 4

=item B<default_options()>

Returns the default options for the plugin.  

=item B<set_tag()>

Save info from object back to ogg vorbis file using L<vorbiscomment> 

=item B<get_tag()>

Get info for object from ogg vorbis header using Ogg::Vorbis::Header::PurePerl

=item B<set_values()>

A list of values that can be set by this module.

=item B<saved_values()>

A list of values that can be saved by this module.

=item B<close()>

Close the file and destroy the Ogg::Vorbis::Header::PurePerl object. 

=item B<ogg()>

Returns the Ogg::Vorbis::Header::PurePerl object.

=back

=head1 OPTIONS

=over 4

=item B<vorbiscomment>

The full path to the vorbiscomment program.  Defaults to just "vorbiscomment", which assumes that vorbiscomment is in your path.

=back

=head1 BUGS

No known additional bugs provided by this Module

Please use github for bug tracking: L<http://github.com/riemann42/Music-Tag-OGG/issues|http://github.com/riemann42/Music-Tag-OGG/issues>.

=head1 SEE ALSO

L<Ogg::Vorbis::Header::PurePerl>, L<Music::Tag>, L<http://www.xiph.org/> 

=head1 SOURCE

Source is available at github: L<http://github.com/riemann42/Music-Tag-OGG|http://github.com/riemann42/Music-Tag-OGG>.

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




# vim: tabstop=4

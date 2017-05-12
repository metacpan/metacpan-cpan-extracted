package Palm::ZirePhoto;
#
# ABSTRACT: Handler for Palm Zire71 Photo thumbnail database
#
#	Copyright (C) 2003, Alessandro Zummo.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.

use strict;
use Palm::Raw();
use Palm::StdAppInfo();

use vars qw( $VERSION @ISA );

# One liner, to allow MakeMaker to work.
$VERSION = '1.400';
# This file is part of Palm 1.400 (March 14, 2015)

@ISA = qw( Palm::StdAppInfo Palm::Raw );


#'

sub import
{
	&Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
		[ "Foto", "Foto" ],
		);
}

sub new
{
	my $classname	= shift;
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name}		= "PhotosDB-Foto";	# Default
	$self->{creator}	= "Foto";
	$self->{type}		= "Foto";
	$self->{attributes}{resource} = 0;
				# The PDB is not a resource database by
				# default, but it's worth emphasizing.

	# Give the PDB an empty list of records
	$self->{records} = [];

	return $self;
}

sub ParseRecord
{
	my $self	= shift;
	my %record	= @_;
	my $data	= $record{'data'};

	delete $record{offset};		# This is useless
	delete $record{data};		# No longer necessary

	# when Photo thumbnail records are deleted/archived/whatever, the data section is
	# actually set to zero length. Presumably this is so that thumbnails take up
	# minimum space until a sync purges the records.

	return \%record unless length $data > 36;

	@record{
		'width',
		'height',
		'time1_secs',
		'size',
		'nameSize',
		'time2_secs',
		'thumb',
		'name'
	} = unpack "xxxx n n N N x5 n x5 N x4 N/a a*", $data;

	$record{'thumbSize'} = length($record{'thumb'});

	$record{'time1'} = $record{'time1_secs'} - 2082844800;
	$record{'time2'} = $record{'time2_secs'} - 2082844800;

	$record{'name'} = substr($record{'name'}, 0, $record{'nameSize'});

	return \%record;
}


sub ParseNote
{
	return ($_[0] =~ /NOTE.{8}([^\0]+)\0*ARCPHOTOBASE.{8}$/so) ? $1 : undef;
}


sub ParseAlbum
{
	my $album = shift;

	# make sure it's an expected record format.
	return undef unless $album =~ /^DBFH/o;

	my @records;

	# skip .db file's initial 16 byte header, then grab 292 byte records
	for( my $pos = 16; $pos < length($album); $pos += 292 ) {
		my $buf = substr( $album, $pos, 292 );
		last if length($buf) < 292;

		my %record;
		@record{
			'name',
			'time1_secs',
			'time2_secs',
			'size',
			'width',
			'height'
		} = unpack('a256 x4 N N N x8 n n x8', $buf);

		$record{name} =~ s/\0+$//o;
		$record{time1} = $record{time1_secs} - 2082844800;
		$record{time2} = $record{time2_secs} - 2082844800;
		$record{'thumbSize'} = 0;
		$record{'thumb'} = '';
		$record{'nameSize'} = length $record{name};

		push @records, \%record;
	}

	return @records;
}

1;

__END__

=head1 NAME

Palm::ZirePhoto - Handler for Palm Zire71 Photo thumbnail database

=head1 VERSION

This document describes version 1.400 of
Palm::ZirePhoto, released March 14, 2015
as part of Palm version 1.400.

=head1 SYNOPSIS

    use Palm::ZirePhoto;

=head1 DESCRIPTION

The Zire71 PDB handler is a helper class for the L<Palm::PDB> package. It parses Zire71
Photo thumbnail databases (and, hopefully, Tungsten Photo databases). Actual photos
are separate databases and must be processed separately.

This database is currently only capable of reading.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

=head2 Records

Records may contain no data fields. This occurs when the record has been
marked deleted on the Palm, presumably in order to save space (Photo has no
provision for archiving when deleting and the separate database storage for
the actual images would make it pointless anyways).

    $record = $pdb->{records}[N]

    $record->{'width'}
    $record->{'height'}
    $record->{'size'}

The actual JPEG images dimensions and (compressed) file size.

    $record->{'thumb'}

The thumbnail is a very small (max size approx 84x84) JPEG format image.

    $record->{'name'}

Image name. Appending C<.jpg> to this will give the database name of the actual image
data.

    $record->{'time1'}
    $record->{'time2'}

Unix epoch time of when the image was last modified (C<time1>) and when it was
created (C<time2>).

=head2 Photo Databases

Actual photos are stored in separate databases. Each record is preceded by an 8 byte
header that describes it a) as a data block (B<DBLK>) and b) the size of the block.
Records are generally 4k, except for the last. To convert a Photo database to a JPEG
image, one would do something like:

	use Palm::Raw;

	my $pdb = new Palm::PDB;
	$pdb->Load( "image.jpg.pdb" );
	open F, ">image.jpg";
	for( @{ $pdb->{records} } ) {
		print F substr($_->{'data'}, 8);
	}
	close F;

Notes are stored at the end of the JPEG image. Use C<ParseNote> to get it.

=head1 METHODS

Handling Palm photos can be a bit complicated. Some helper methods are exported to
make some special cases a bit easier.

=head2 ParseNote

	my $photo = read_jpeg_file( "image.jpg" );
	my $note = Palm::ZirePhoto::ParseNote($photo);
	print "Note: $note" if defined $note;

The Palm photo application stores user notes at the end of the JPEG file itself. This
method will extract that note and return it. C<undef> is returned if the note is
unavailable.

=head2 ParseAlbum

	my $album = slurp("/DCIM/Unfiled/Album.db");
	my @records = Palm::ZirePhoto::ParseAlbum( $album );
	print $_->{name},"\n" for( @records );

Photos on memory cards are stored in subdirectories of C</DCIM>. The meta-data for
these images are stored in C<Album.db> files under each category directory. This
method will parse out the meta-data into an array of records similar to those
returned by C<ParseRecord>. Thumbnail information, however, is not available.

=head1 SEE ALSO

L<Palm::PDB>

L<Palm::StdAppInfo>

=head1 CONFIGURATION AND ENVIRONMENT

Palm::ZirePhoto requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHORS

Alessandro Zummo C<< <a.zummo AT towertech.it> >>

Currently maintained by Christopher J. Madsen C<< <perl AT cjmweb.net> >>

Please report any bugs or feature requests
to S<C<< <bug-Palm AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Palm >>.

You can follow or contribute to p5-Palm's development at
L<< https://github.com/madsen/p5-Palm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Andrew Arensburger & Alessandro Zummo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

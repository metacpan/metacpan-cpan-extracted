package Ogg::Vorbis::Header;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.05';

use Inline C => 'DATA',
					LIBS => '-logg -lvorbis -lvorbisfile',
					INC => '-I/inc',
					AUTO_INCLUDE => '#include "inc/vcedit.h"',
					AUTO_INCLUDE => '#include "inc/vcedit.c"',
					VERSION => '0.05',
					NAME => 'Ogg::Vorbis::Header';

# constructors

# wrap this so $obj->new will work right
sub new {
	my ($id, $path) = @_;
	$id = ref($id) || $id;
	_new($id, $path);
}

sub load {
	my ($id, $path) = @_;
	unless (ref($id)) {
		$id = _new($id, $path);
	}
	return $id unless $id;
	$id->_load_info;
	$id->_load_comments;
	return $id;
}

# A number of the instance methods may be handled with perl code.

sub info {
	my ($self, $key) = @_;
	$self->_load_info unless $self->{INFO};
	if ($key) { 
		return $self->{INFO}->{$key}
	}
	return $self->{INFO};
}

sub comment_tags {
	my $self = shift;
	$self->_load_comments unless $self->{COMMENTS};
	return keys %{$self->{COMMENTS}};
}

sub comment {
	my ($self, $key) = @_;
	my $result;
	return undef unless $key;
	$self->_load_comments unless $self->{COMMENTS};
	if (! defined ($result = $self->{COMMENTS}->{$key})) {
		return undef;
	}
	return @{$result};
}

sub add_comments {
	my ($self, @comments) = @_;
	# For now play it safe limit both tag and field to minimal ascii
	# will work on utf8 in field later
	return undef if @comments < 2 or @comments % 2 != 0;
	$self->_load_comments unless $self->{COMMENTS};
	while ($#comments >= 0) {
		my $key = shift @comments;
		$key =~ s/[^\x20-\x3C\x3E-\x7D]//g;
		$key = lc($key);
		my $val = shift @comments;
		$val =~ s/[^\x20-\x7D]//g;
		push @{$self->{COMMENTS}->{$key}}, $val;
	}
	
	return 1;
}

sub edit_comment {
	my ($self, $key, $value, $num) = @_;
	$num ||= 0;

	return undef unless $key and $value and $num =~ /^\d*$/;
	$self->_load_comments unless $self->{COMMENTS};
	
	my $comment = $self->{COMMENTS}->{$key};
	return undef unless $comment;
	$value =~ s/[^\x20-\x7D]//g;
	return undef unless @$comment > $num;

	my $result = $comment->[$num];
	$comment->[$num] = $value;

	return $result;
}

sub delete_comment {
	my ($self, $key, $num) = @_;
	$num ||= 0;

	return undef unless $key and $num =~ /^\d*$/;
	$self->_load_comments unless $self->{COMMENTS};
	
	my $comment = $self->{COMMENTS}->{$key};
	return undef unless $comment;
	return undef unless @$comment > $num;

	my $result = splice @$comment, $num, 1;

	if (@$comment == 0) {
		delete($self->{COMMENTS}->{$key});
	}

	return $result;
}

sub clear_comments {
	my ($self, @keys) = @_;
	
	$self->_load_comments unless $self->{COMMENTS};
	if (@keys) {
		foreach (@keys) {
			return undef unless $self->{COMMENTS}->{$_};
			delete($self->{COMMENTS}->{$_});
		}
	} else {
		foreach (keys %{$self->{COMMENTS}}) {
			delete($self->{COMMENTS}->{$_});
		}
	}
	return 1;
}

sub path {
	my $self = shift;
	return $self->{PATH};
}

1;
__DATA__

=head1 NAME

Ogg::Vorbis::Header - An object-oriented interface to Ogg Vorbis
information and comment fields.

=head1 SYNOPSIS

	use Ogg::Vorbis::Header;
	my $ogg = Ogg::Vorbis::Header->new("song.ogg");
	while (my ($k, $v) = each %{$ogg->info}) {
		print "$k: $v\n";
	}
	foreach my $com ($ogg->comment_tags) {
		print "$com: $_\n" foreach $ogg->comment($com);
	}
	$ogg->add_comments("good", "no", "ok", "yes");
	$ogg->delete_comment("ok");
	$ogg->write_vorbis;
		

=head1 DESCRIPTION

This module presents an object-oriented interface to Ogg Vorbis files
which allows user to view Vorbis info and comments and to modify or
add comments.  

=head1 CONSTRUCTORS

=head2 C<new ($filename)>

Partially opens an Ogg Vorbis file to ensure it exists and is actually
a Vorbis stream.  It then closes the filehandle.  It does not fill in
the object's data fields.  These fields will be automatically filled
the first time they are accessed using the object's instance methods.
Returns C<undef> if there is a problem opening the file or the file is
not valid Ogg Vorbis.

=head2 C<load ([$filename])>

Opens an Ogg Vorbis file, reads its information, and then closes the
filehandle.  Returns C<undef> if there is a problem opening the file
or the file is not valid Ogg Vorbis.  This is both a constructor and
an instance method.  The filename is required in constructor context,
but should be left out when you call this as an instance method on an
object.  When called as an instance method, it (re)loads the info and
comment data from the file.  This can be used to reset the state of
the object if write_vorbis hasn't been called.  Note that the path
parameter is ignored in instance context.

=head1 INSTANCE METHODS

These methods may be called on actual Header objects, using
the -> operator or indirect objects as you prefer.

=head2 C<info ([$key])>

Returns a reference to a hash containing format information about the
Vorbis file.  Hash fields are: version, channels, rate, bitrate_upper,
bitrate_nominal, bitrate_lower, and bitrate_window, length.  The
bitrate_window value is currently unused by the vorbis codec.  You can
modify the referenced hash if you want, but I wouldn't suggest it.

The optional key parameter allows you to extract a single value from
the internal hash (passed by value, not reference).  If the key is
invalid, C<undef> is returned.

=head2 C<comment_tags ()>

Returns an array holding the key values of each comment field.  You
can then use these values to access specific fields using C<comment>.
This may seem somewhat clunky at first but it will speed up most
programs.  In addition, it makes it easier to support the Ogg Vorbis
comment standard which allows multiple fields with the same key.

=head2 C<comment ($key)>

Returns a list of comments given a key.   If the key does not exist,
returns C<undef>.

=head2 C<add_comments ($key, $value, [$key, $value, ...])>

Adds comments with the given keys and values.  Takes an array of
alternating keys and values as parameters.  Keys and values should be
valid ascii in the range 0x20 - 0x7D and the key should exclude 0x3D
('=').  This is a subset of the Vorbis standard which allows this
range for the key field and all of utf8 for the value field.  This
will be fixed in future a release.

If an odd-length array is passed in the routine will fail and return
C<undef>.  Key and value will be trimmed of characters which do not
match the format requirement.

=head2 C<edit_comment ($key, $value, [$num])>

Edits a given comment field.  The optional num field is used to
differentiate between two comments with the same key.  If no num is
supplied, the first value--as reported by C<comment>--is modified.  If
the key or num are invalid, nothing is done and undef is returned.
If all goes well, the old value is returned.

=head2 C<delete_comment ($key, [$num])>

Deletes the comment given by key.  The optional num value can be used
to specify which comment to delete, given duplicate keys.  Leaving num
out will result in only the first instance being deleted.  Returns
C<undef> if key or num are invalid.  If all goes well, the value of
the deleted comment is returned. 

=head2 C<clear_comments ([@keys])>

Deletes all of the comments which match keys in the input array or all
of the comments in the stream if called with no arguments.  Returns
C<undef> if any key is invalid, although all keys in the input array
up until that key will be cleared.  Returns true otherwise.

=head2 C<write_vorbis ()>

Write object to its backing file.  No comment modifications will be
seen in the file until this operation is performed.

=head2 C<path ()>

Returns the path/filename of the file the object represents.

=head1 REQUIRES

Inline::C, libogg, libvorbis, libogg-dev, libvorbis-dev.

=head1 AUTHOR

Dan Pemstein E<lt>dan@lcws.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, Dan Pemstein.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at
your option) any later version.  A copy of this license is included
with this module (LICENSE.GPL).

A library for editing Ogg Vorbis comments is distributed with this
library as unmodified source code (inc/vcedit.h, inc/vcedit.c,
inc/i18n.h).  This library is Copyright (c) Michael Smith
<msmith@labyrinth.net.au>.  It is licensed under the GNU Library
General Public License (LGPL).  A copy of this license is included
with this module (inc/LICENSE.LGPL).

=head1 SEE ALSO

L<Ogg::Vorbis::Decoder>, L<Inline::C>, L<Audio::Ao>.

=cut

__C__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vorbis/codec.h>
#include <vorbis/vorbisfile.h>

#define BUFFSIZE 512

/* Loads info and length from the stream a fills the object's hash */
void _load_info(SV *obj)
{
	OggVorbis_File vf;
	vorbis_info *vi;
	FILE *fd;
	char *ptr;
	HV *th;
	HV *hash = (HV *) SvRV(obj);
	
	/* Open the vorbis stream file */
	ptr = (char *) SvIV(*(hv_fetch(hash, "_PATH", 5, 0)));
	if ((fd = fopen(ptr, "rb")) == NULL) {
		perror("Error opening file in Ogg::Vorbis::Header::_load_info\n");
		return;
	}
	
	if (ov_open(fd, &vf, NULL, 0) < 0) {
		fclose(fd);
		perror("Error opening file in Ogg::Vorbis::Header::_load_info\n");
		return;
	}
	
	vi = ov_info(&vf, -1);
	
	th = newHV();
	hv_store(th, "version", 7, newSViv(vi->version), 0);
	hv_store(th, "channels", 8, newSViv(vi->channels), 0);
	hv_store(th, "rate", 4, newSViv(vi->rate), 0);
	hv_store(th, "bitrate_upper", 13, newSViv(vi->bitrate_upper), 0);
	hv_store(th, "bitrate_nominal", 15, newSViv(vi->bitrate_nominal), 0);
	hv_store(th, "bitrate_lower", 13, newSViv(vi->bitrate_lower), 0);
	hv_store(th, "bitrate_window", 14, newSViv(vi->bitrate_window), 0);
	hv_store(th, "length", 6, newSVnv(ov_time_total(&vf, -1)), 0);
	
	hv_store(hash, "INFO", 4, newRV_noinc((SV *) th), 0);
	
	ov_clear(&vf);
}

/* Loads the commments from the stream and fills the object's hash */
void _load_comments(SV *obj)
{
	OggVorbis_File vf;
	vorbis_comment *vc;
	FILE *fd;
	HV *th;
	SV *ts;
	AV *ta;
	char *half;
	char *ptr;
	int i;
	HV *hash = (HV *) SvRV(obj);

	/* Open the vorbis stream file */
	ptr = (char *) SvIV(*(hv_fetch(hash, "_PATH", 5, 0)));
	if ((fd = fopen(ptr, "rb")) == NULL) {
		perror("Error opening file in Ogg::Vorbis::Header::_load_comments\n");
		return;
	}
	
	if (ov_open(fd, &vf, NULL, 0) < 0) {
		fclose(fd);
		perror("Error opening file in Ogg::Vorbis::Header::_load_comments\n");
		return;
	}

	vc = ov_comment(&vf, -1);
	
	th = newHV();
	for (i = 0; i < vc->comments; ++i) {
		half = strchr(vc->user_comments[i], '=');
		if (half == NULL) {
			warn("Comment \"%s\" missing \'=\', skipping...\n",
						vc->user_comments[i]);
			continue;
		}
		if (! hv_exists(th, vc->user_comments[i],
										half - vc->user_comments[i])) {
			ta = newAV();
			ts = newRV_noinc((SV*) ta);
			hv_store(th, vc->user_comments[i], half - vc->user_comments[i],
				ts, 0);
		} else {
			ta = (AV*) SvRV(*(hv_fetch(th, vc->user_comments[i],
						half - vc->user_comments[i], 0)));
		}
		av_push(ta, newSVpv(half + 1, 0));
	}

	hv_store(hash, "COMMENTS", 8, newRV_noinc((SV *) th), 0);

	ov_clear(&vf);
}

/* Our base object constructor.  Creates a blessed hash. */
SV* _new(char *class, char *path)
{
	/* A few variables */
	FILE *fd;
	char *_path;
	OggVorbis_File vf;
	
	/* Create our new hash and the reference to it. */
	HV *hash = newHV();
	SV *obj_ref = newRV_noinc((SV*) hash);

	/* Save an internal (c-style) rep of the path */
	_path = strdup(path);
	hv_store(hash, "_PATH", 5, newSViv((IV) _path), 0);
	
	/* Open the vorbis stream file */
	if ((fd = fopen(path, "rb")) == NULL)
		return &PL_sv_undef;
	
	if (ov_test(fd, &vf, NULL, 0) < 0) {
		fclose(fd);
		return &PL_sv_undef;
	}

	/* Values stored at base level */
	hv_store(hash, "PATH", 4, newSVpv(path, 0), 0);

	/* Close our OggVorbis_File cause we don't want to keep the file
	 * descriptor open.
	 */
	ov_clear(&vf);
	
	/* Bless the hashref to create a class object */	
	sv_bless(obj_ref, gv_stashpv(class, FALSE));

	return obj_ref;
}

/* These comment manipulation functions use the vcedit library by 
 * Michael Smith.  They also borrow quite a bit from vorbiscomment
 * (vcomment.c) by Michael Smith and Ralph Giles.
 */
int write_vorbis (SV *obj)
{
	vcedit_state *state;
	vorbis_comment *vc;
	char *inpath, *outpath, *key, *val;
	FILE *fd, *fd2, *fd3, *fd4;
	HV *hash = (HV *) SvRV(obj);
	HV *chash;
	AV *vals;
	HE *hval;
	int bytes;
	char buffer[BUFFSIZE];
	I32 i, j, num;


	/* Skip if comments hasn't been opened */
	if (! hv_exists(hash, "COMMENTS", 8)) {
		return 0;
	}

	/* Set up the input and output paths */
	inpath = (char *) SvIV(*(hv_fetch(hash, "_PATH", 5, 0)));
	outpath = malloc(strlen(inpath) + (8 * sizeof(char)));
	strcpy(outpath, inpath);
	strcat(outpath, ".ovitmp");

	/* Open the files */
	if ((fd = fopen(inpath, "rb")) == NULL) {
		perror("Error opening file in Ogg::Vorbis::Header::write\n");
		free(outpath);
		return &PL_sv_undef;
	}

	if ((fd2 = fopen(outpath, "w+b")) == NULL) {
		perror("Error opening temp file in Ogg::Vorbis::Header::write\n");
		fclose(fd);
		free(outpath);
		return &PL_sv_undef;
	}

	/* Setup the state and comments structs */
	state = vcedit_new_state();
	if (vcedit_open(state, fd) < 0) {
		perror("Error opening stream in Ogg::Vorbis::Header::add_comment\n");
		fclose(fd);
		fclose(fd2);
		unlink(outpath);
		free(outpath);
		return &PL_sv_undef;
	}
	vc = vcedit_comments(state);

	/* clear the old comment fields */
	vorbis_comment_clear(vc);
	vorbis_comment_init(vc);

	/* Write the comment fields from the hash
	 * FIX: This doesn't preserve order, which may or may not be a problem
	 */
	chash = (HV *) SvRV(*(hv_fetch(hash, "COMMENTS", 8, 0)));

	num = hv_iterinit(chash);
	for (i = 0; i < num; ++i) {
		hval = hv_iternext(chash);
		key = SvPV_nolen(hv_iterkeysv(hval));
		vals = (AV*) SvRV(*(hv_fetch(chash, key, strlen(key), 0)));
		for (j = 0; j <= av_len(vals); ++j) {
			val = SvPV_nolen(*av_fetch(vals, j, 0));
			vorbis_comment_add_tag(vc, key, val);
		}
	}
	
	/* Write out the new stream */
	if (vcedit_write(state, fd2) < 0) {
		perror("Error writing stream in Ogg::Vorbis::Header::add_comment\n");
		fclose(fd);
		fclose(fd2);
		vcedit_clear(state);
		unlink(outpath);
		free(outpath);
		return &PL_sv_undef;
	}

	fclose(fd);
	fclose(fd2);
	vcedit_clear(state);
	if ((fd = fopen(outpath, "rb")) == NULL) {
		perror("Error copying tempfile in Ogg::Vorbis::Header::add_comment\n");
		unlink(outpath);
		free(outpath);
		return &PL_sv_undef;
	}
	
	if ((fd2 = fopen(inpath, "wb")) == NULL) {
		perror("Error copying tempfile in Ogg::Vorbis::Header::write_vorbis\n");
		fclose(fd);
		unlink(outpath);
		free(outpath);
		return &PL_sv_undef;
	}

	while ((bytes = fread(buffer, 1, BUFFSIZE, fd)) > 0)
		fwrite(buffer, 1, bytes, fd2);
	
	fclose(fd);
	fclose(fd2);
	unlink(outpath);
	free(outpath);

	return 1;
}
		
/* We strdup'd the internal path string so we need to free it */
void DESTROY (SV *obj)
{
	char *ptr;
	HV *hash = (HV *) SvRV(obj);

	ptr = (char *) SvIV(*(hv_fetch(hash, "_PATH", 5, 0)));
	free(ptr);
}

#!/usr/bin/perl -w
# This code is a part of Slash, and is released under the GPL.
# Copyright 1997-2001 by Open Source Development Network. See README
# and COPYING for more information, or see http://slashcode.com/.
# $Id: gallery.pl,v 1.5 2001/12/31 18:31:16 pudge Exp $

use strict;
use Apache::File;
use File::Basename;
use File::Path;
use File::Spec::Functions ':ALL';
use Imager;
use Image::Info qw(image_info dim);

use Slash 2.003;	# require Slash 2.3.x
use Slash::Constants qw(:web);
use Slash::Display;
use Slash::Utility;
use vars qw($VERSION);

($VERSION) = ' $Revision: 1.5 $ ' =~ /\$Revision:\s+([^\s]+)/;

sub main {
	my $gallery   = getObject('Slash::Gallery');
	my $slashdb   = getCurrentDB();
	my $constants = getCurrentStatic();
	my $user      = getCurrentUser();
	my $form      = getCurrentForm();

	my $is_admin = $user->{state}{gallery_admin} =
		($user->{seclev} >= $constants->{gallery_admin_seclev})
		|| $user->{gallery_admin};

# 	return unless $user->{state}{gallery_admin};	# for dev

	my %ops = (
		render_pictures	=> [ $is_admin,	\&render_pictures	],	# ?
		add_pictures	=> [ $is_admin,	\&add_pictures		],	# ?
		list_pictures	=> [ $is_admin,	\&list_pictures		],
		save_picture	=> [ $is_admin,	\&save_picture		],	# 1
		find_unassigned_pictures
				=> [ $is_admin,	\&find_unassigned_pictures ],

		list_groups	=> [ 1,		\&list_groups		],
		edit_group	=> [ $is_admin,	\&edit_group		],
		save_group	=> [ $is_admin,	\&save_group		],	# 1

		display		=> [ 1,		\&display		],
		view		=> [ 1,		\&view			],	# 2
		list		=> [ 1,		\&list			],

		default		=> [ 1,		\&list_groups		]
	);

	# prepare op to proper value if bad value given
	my $op = $form->{op};
	if (!$op || !exists $ops{$op} || !$ops{$op}[ALLOWED]) {
		$op = 'default';
	}

	if ($op eq 'view') {
		my($content, $type, $date) = $ops{$op}[FUNCTION]->(
			$gallery, $constants, $user, $form, $slashdb
		);

		if ($content) {
			$type ||= 'image/jpeg';

			my $r = Apache->request;
			$r->header_out('Cache-control', 'private');
			$r->content_type($type);
			$r->set_last_modified($date) if $date;
			$r->status(200);
			$r->send_http_header;
			$r->rflush;
			$r->print($content);
			$r->status(200);
			return 1;

		} else {  # not handled, fall through
			$op = 'default';
		}
	}

	header(getData('header'));
	print getData('galleryhead');

	$ops{$op}[FUNCTION]->($gallery, $constants, $user, $form, $slashdb);

	print getData('galleryfoot');
	footer();
}

sub edit_group {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	my $group_id = $form->{group_id};
	my $group;
	if ($group_id) {
		my $groups = $gallery->get_groups({ id => $group_id });
		$group  = $groups->{$group_id};
	} else {
		$group = {};
	}

	my $users = join ', ', keys %{$group->{users}};
	$slashdb->createFormkey('gallery');

	slashDisplay('edit_group', {
		group	=> $group,
		users	=> $users,
	});
}

sub save_group {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	my $group_id = $form->{group_id};
	my %data = (
		name		=> $form->{name},
		description	=> $form->{description},
		public		=> $form->{public},
	);

	if (_validFormkey()) {
		if ($group_id) {
			$gallery->set_group($group_id, \%data);
		} elsif ($form->{name}) {
			$group_id = $gallery->create_group(\%data);
		}

		if ($group_id) {
			my @users = split /\s*,\s*/, $form->{users};
			$gallery->set_users_group($group_id, \@users);
		}
	}

	list_groups(@_);
}

sub list_groups {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	my $groups = $gallery->get_groups;

	slashDisplay('list_groups', {
		groups		=> $groups,
		is_admin	=> $user->{state}{gallery_admin},
	});
}

sub add_pictures {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	$gallery->add_pictures_from_disk;

	list_pictures(@_);
}


sub render_pictures {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	my $sizes = $gallery->get_sizes();
	my $pictures = $gallery->get_pictures;

	for my $size (reverse sort keys %$sizes) {
		$form->{size} = $size;
		for my $pic_id (sort { $a <=> $b } keys %$pictures) {
			$form->{pic_id} = $pic_id;
			print STDERR "Rendering $pic_id : $size\n";
			view(@_);
		}
	}
	list_groups(@_);
}

sub find_unassigned_pictures {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	my $pictures = $gallery->get_unassigned_pictures;

	slashDisplay('list_pictures', { pictures => $pictures });
}

sub list_pictures {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	my $pictures = $gallery->get_pictures;

	slashDisplay('list_pictures', { pictures => $pictures });
}

sub save_picture {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	my $pic_id = $form->{pic_id};
	if ($pic_id && _validFormkey()) {
		my $pictures = $gallery->get_pictures({ id => $pic_id });
		my $picture  = $pictures->{$pic_id};
		$form->{rotate} ||= 0;

		if ($picture->{rotate} != $form->{rotate}) {
			my $sizes = $gallery->get_sizes();
			for my $size (reverse sort keys %$sizes) {
				$form->{size} = $size;
				$form->{pic_id} = $pic_id;
				print STDERR "Rendering $pic_id : $size\n";
				view(@_);
			}
		}

		$gallery->set_picture($pic_id, {
			name		=> $form->{name},
			uid		=> $form->{uid},
			date		=> $form->{date},
			description	=> $form->{description},
			rotate		=> $form->{rotate},
		});	

		my @groups = grep $_, map { s/^(\d+).*$/$1/s; $_ }
			@{$form->{groups_multiple}}
			if $form->{groups_multiple};
		$gallery->set_groups_picture($pic_id, \@groups);
	}

	display(@_);
}

sub list {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	my $pictures;
	my $group = $form->{group_id};

	if ($user->{state}{gallery_admin} && !$group) {
		# get all
		$pictures = $gallery->get_pictures;
	} else {
		if (!allow_user(@_, { group_id => $group })) {
			return list_groups(@_);
		}

		$pictures = $gallery->get_pictures({ group => $group });
	}

	my $sizes = $gallery->get_sizes();
	slashDisplay('list', {
		pictures	=> $pictures,
		sizes		=> $sizes,
		group		=> $gallery->get_groups({ id => $group })->{$group},
	});
}

sub display {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	my $pic_id = $form->{pic_id};
	my $pictures = $gallery->get_pictures({ id => $pic_id });
	my $picture  = $pictures->{$pic_id};
	unless ($picture && allow_user(@_, { picture => $picture })) {
		return list_groups(@_);
	}

	$picture->{info} = image_info(catfile(
		$constants->{datadir}, 'gallery', 'full',
		$picture->{filename}
	));

	my $sizes = $gallery->get_sizes();
	$slashdb->createFormkey('gallery');

	slashDisplay('display', {
		picture 	=> $picture,
		sizes		=> $sizes,
		pic_id		=> $pic_id,
		is_admin	=> $user->{state}{gallery_admin},
		gallery		=> $gallery,
	});
}

sub view {
	my($gallery, $constants, $user, $form, $slashdb) = @_;

	return if  $ENV{HTTP_REFERER}
		&& $ENV{HTTP_REFERER} !~ /^(?:https?:)?\Q$constants->{rootdir}\E/;

	my($file, $full, $content, $type, $X, $Y, $qual);
	my $noreturn = $form->{op} eq 'render_pictures' || $form->{op} eq 'save_picture';
	my $size = $form->{size};
	my $sizes = $gallery->get_sizes();

	if (exists $sizes->{$size}) {
		($X, $Y, $qual) = @{$sizes->{$size}}{qw[width height jpegquality]};
	} else {
		$size = 'full';
	}

	# only max_gallery_viewings per time period unless admin
	unless ($user->{state}{gallery_admin} || $noreturn) {
		if (!$sizes->{$size}{id} || $sizes->{$size}{id} > 2) { # greater than small
			$slashdb->createFormkey('galleryview');
			return unless _validFormkey('galleryview', 'max_reads_check');
		}
	}

	my $pic_id = $form->{pic_id};
	my $pictures = $gallery->get_pictures({ id => $pic_id });
	my $picture  = $pictures->{$pic_id};

	unless ($picture && allow_user(@_, { picture => $picture })) {
		return;
	}

	$file = catfile($constants->{datadir}, 'gallery',
		$size, $picture->{filename}
	);
	$full = catfile($constants->{datadir}, 'gallery',
		'full', $picture->{filename}
	);

	if ($noreturn && defined $form->{rotate}) {
		unlink $file unless $file eq $full;
	}

	# if it exists, and is a scaled image and the original
	# has not been modified since the scaled was created,
	# then just show the image from disk ...
	if (-e $file && ($file eq $full || -M $file < -M $full)) {
		unless ($noreturn) {
			my $fh = gensym();
			open $fh, "<" . $file or errorLog("Can't open $file: $!"), return;
			{	local $/;
				$content = <$fh>;
			}
			close $fh;

			my $info = image_info($file);
			$type = $info->{file_media_type};
		}

	# ... else create scaled image on the fly, saving it to disk
	# and returning the image data
	} elsif ($X) {
		my $img = new Imager;
		$img->open(file => $full);

		if (($noreturn && defined $form->{rotate}) || $picture->{rotate}) {
			my $rotate = defined $form->{rotate} ? $form->{rotate} : $picture->{rotate};
			my $rotated = $img->rotate(right => (
				$rotate == 1 ? 90 :
				$rotate == 2 ? 180 :
				$rotate == 3 ? 270 : 0
			));
			$img = $rotated;
		}

		if ($img->getwidth < $img->getheight) {
			($X, $Y) = ($Y, $X);
		}

		my $scaled = $img->scale(xpixels => $X);
		mkpath(dirname($file), 0, 0775);
		$scaled->write(file => $file, jpegquality => $qual);
		$scaled->write(data => \$content, type => 'jpeg', jpegquality => $qual)
			unless $noreturn;
	}

# if we want to include last-modified date for some reason ... ?
# 	return($content, $type, (stat $file)[9]) unless $noreturn;
	return($content, $type) unless $noreturn;
}

sub allow_user {
	my($gallery, $constants, $user, $form, $slashdb, $data) = @_;
	return 1 if $user->{state}{gallery_admin};

	# check if group ID is available for user
	if ($data->{group_id}) {
		my $id = $data->{group_id};

		$user->{gallery_groups} ||= $gallery->get_groups_user($user->{uid});
		return 1 if exists $user->{gallery_groups}{$id};

		my $group = $gallery->get_groups({ id => $id });
		return 1 if $group->{$id}{public};

	# check if user ID is assigned to group
	} elsif ($data->{group}) {
		return 1 if $data->{group}{public};
		return 1 if exists $data->{group}{users}{$user->{uid}};
		return 1 if exists $data->{group}{users}{$constants->{anonymous_coward_uid}};

	# check if picture is in group available to user
	} elsif ($data->{picture}) {
		my $seen;
		$user->{gallery_groups} ||= $gallery->get_groups_user($user->{uid});
		for (keys %{$data->{picture}{groups}}) {
			return 1 if exists $user->{gallery_groups}{$_};
		}

		for (keys %{$data->{picture}{groups}}) {
			my $group = $gallery->get_groups({ id => $_ });
			return 1 if $group->{$_}{public};
		}
	}

	return 0;
}

sub _validFormkey {
	my $error;
	my $formname = shift;
	# this is a hack, think more on it, OK for now -- pudge
	Slash::Utility::Anchor::getSectionColors();

	for (@_, qw(valid_check formkey_check)) {
		last if formkeyHandler($_, $formname, 0, \$error);
	}

	if ($error) {
		return 0;
	} else {
		# why does anyone care the length?
		getCurrentDB()->updateFormkey(0, 1);
		return 1;
	}
}

# get array from rational object (for templates)
sub Image::TIFF::Rational::list { [ $_[0]->[0], $_[0]->[1] ] }

# get a nicer rational number
sub Image::TIFF::Rational::smart {
	my($a, $b) = @{$_[0]}[0, 1];
	my $z = $a/$b;

	if ($z < 1) {
		return sprintf "1/%d", $b/$a;
	} else {
		return sprintf "%.1f", $z;
	}
}

createEnvironment();
main();


1;


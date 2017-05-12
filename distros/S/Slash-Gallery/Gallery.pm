# This code is a part of Slash, and is released under the GPL.
# Copyright 1997-2001 by Open Source Development Network. See README
# and COPYING for more information, or see http://slashcode.com/.
# $Id: Gallery.pm,v 1.6 2002/01/23 04:52:18 pudge Exp $

package Slash::Gallery;

=head1 NAME

Slash::Gallery - Picture gallery plugin for Slash


=head1 SYNOPSIS

	# see README and gallery.pl


=head1 DESCRIPTION

see README and gallery.pl


=head1 METHODS

=cut

use strict;
use File::Find;
use File::Spec::Functions ':ALL';
use Image::Info qw(image_info);
use Slash::Utility;

use vars qw($VERSION);
use base 'Exporter';
use base 'Slash::DB::Utility';
use base 'Slash::DB::MySQL';

$VERSION   = '0.91';

sub new {
	my($class, $user) = @_;
	my $self = {};

	my $slashdb = getCurrentDB();
	my $plugins = $slashdb->getDescriptions('plugins');
	return unless $plugins->{'Gallery'};

	bless($self, $class);
	$self->{virtual_user} = $user;
	$self->sqlConnect;

	return $self;
}

sub set_groups_picture {
	my($self, $pic_id, $groups) = @_;

	my $pic_id_sql = $self->sqlQuote($pic_id);
	# clear out existing entries first
	$self->sqlDelete('gallery_pictures_groups', "pic_id=$pic_id_sql");

	my $count;
	for my $group_id (@$groups) {
		$count += $self->sqlInsert('gallery_pictures_groups', {
			pic_id		=> $pic_id,
			group_id	=> $group_id,
		});
	}

	return $count;
}

sub set_users_group {
	my($self, $group_id, $users) = @_;

	my $group_id_sql = $self->sqlQuote($group_id);
	# clear out existing entries first
	$self->sqlDelete('gallery_users_groups', "group_id=$group_id_sql");

	my $count;
	for my $uid (@$users) {
		$count += $self->sqlInsert('gallery_users_groups', {
			uid		=> $uid,
			group_id	=> $group_id,
		});
	}

	return $count;
}

sub create_group {
	my($self, $data) = @_;

	my $insert = $self->sqlInsert('gallery_groups', {
		name		=> $data->{name},
		description	=> $data->{description},
		public		=> $data->{public} ? 1 : 0,
	});

	if ($insert) {
		my($id) = $self->sqlSelect('LAST_INSERT_ID()');
		return $id;
	} else {
		return;
	}
}

sub get_groups_user {
	my($self, $uid) = @_;

	my $uid_sql = $self->sqlQuote($uid);
	my $groups = $self->sqlSelectAllHashref(
		'group_id',
		'group_id',
		'gallery_users_groups',
		"uid=$uid_sql",
	);
}

sub get_groups {
	my($self, $options) = @_;

	my(@where, $where);
	if ($options->{id}) {
		my $ids = ref($options->{id}) eq 'ARRAY'
			? $options->{id}
			: [$options->{id}];
		my @id_where;
		for (@$ids) {
			push @id_where, "id=" . $self->sqlQuote($_);
		}
		push @where, "(" . join(" OR ", @id_where) . ")";
	}
	$where .= join " AND ", @where;

	my $groups = $self->sqlSelectAllHashref(
		'id',
		'id, name, public, description',
		'gallery_groups',
		$where
	);

	for my $id (keys %$groups) {
		$groups->{$id}{users} = $self->sqlSelectAllHashref(
			'uid',
			'uid',
			'gallery_users_groups',
			"group_id=$id",
		);

		$groups->{$id}{pictures} = $self->sqlSelectAllHashref(
			'pic_id',
			'pic_id',
			'gallery_pictures_groups',
			"group_id=$id",
		);
	}

	return $groups;
}

sub set_group {
	my($self, $id, $data) = @_;

	my $id_sql = $self->sqlQuote($id);
	$self->sqlUpdate('gallery_groups', {
		name		=> $data->{name},
		description	=> $data->{description},
		public		=> $data->{public} ? 1 : 0,
	}, "id=$id_sql");
}

sub add_pictures_from_disk {
	my($self) = @_;
	my $user = getCurrentUser();
	my $dir = catdir(getCurrentStatic('datadir'), 'gallery', 'full');

	# get cache and then skip existing ones?
	my @files;
	find(sub {
		(my $name = my $file = $File::Find::name) =~ s/^\Q$dir\E//;
		return if grep { /^\./ } splitdir($name);
		return if -d $file;
		my $info = image_info($file);

		my($date, $offset);
		if ($info && $info->{DateTimeOriginal} && $info->{DateTimeOriginal} ne "0000:00:00 00:00:00") {
			($date = $info->{DateTimeOriginal}) =~ s/^(\d+):(\d+):/$1-$2-/;
			$offset = -$user->{off_set}; # assume embedded time is in user's TZ
		} else {
			$date = scalar gmtime((stat(_))[9]);
			$offset = 0;
		}
		$date = timeCalc($date, "%Y-%m-%d %H:%M:%S", $offset);

		push @files, [$name, $date];
	}, $dir);

	my(%inserted);
	for (sort { $a->[1] cmp $b->[1] } @files) {
		my($name, $date) = @$_;
		my $insert;
		{
			# we will get a lot of nasty INSERT here for
			# duplicate keys, so for now just ignore them.
			# we could just check for existence, but that's
			# extra DB hits, and more work.
			local $Slash::Utility::NO_ERROR_LOG = 1;
			$insert = $self->sqlInsert('gallery_pictures', {
				filename	=> $name,
				name		=> $name,
				uid		=> $ENV{SLASH_USER},
				date		=> $date,
				description	=> "",
				rotate		=> 0,
			});
		}
		if ($insert) {
			my($id) = $self->sqlSelect('LAST_INSERT_ID()');
			$inserted{$id} = $name;
		}
	}
	return \%inserted;
}

sub get_unassigned_pictures {
	my($self) = @_;

	my $pictures = $self->sqlSelectColArrayref('id', 'gallery_pictures');
	my @ids;
	for my $id (@$pictures) {
		push @ids, $id unless $self->sqlSelectArrayRef(
			'group_id',
			'gallery_pictures_groups',
			"pic_id=$id",
		);
	}
	return $self->get_pictures({ id => \@ids });
}

# for now, return all; will limit by group, uid, etc.
# maybe return group info?
sub get_pictures {
	my($self, $options) = @_;

	my $tables = 'gallery_pictures';
	my(@where, $where);
	if ($options->{id}) {
		my $ids = ref($options->{id}) eq 'ARRAY'
			? $options->{id}
			: [$options->{id}];
		my @id_where;
		for (@$ids) {
			push @id_where, "id=" . $self->sqlQuote($_);
		}
		push @where, "(" . join(" OR ", @id_where) . ")";
	}

	if ($options->{group}) {
		my $ids = ref($options->{group}) eq 'ARRAY'
			? $options->{group}
			: [$options->{group}];
		my @id_where;
		for (@$ids) {
			push @id_where, "group_id=" . $self->sqlQuote($_);
		}
		push @where, "(" . join(" OR ", @id_where) . ")";
		push @where, 'gallery_pictures_groups.pic_id=gallery_pictures.id';
		$tables .= ', gallery_pictures_groups';
	}

	$where .= join " AND ", @where;

	my $pictures = $self->sqlSelectAllHashref(
		'id',
		'gallery_pictures.id AS id, uid, name, description, date, filename, rotate',
		$tables,
		$where
	);

	my $dir = catdir(getCurrentStatic('datadir'), 'gallery', 'full');
	use Time::HiRes 'time';
	for my $id (keys %$pictures) {
		$pictures->{$id}{groups} = $self->sqlSelectAllHashref(
			'group_id',
			'group_id',
			'gallery_pictures_groups',
			"pic_id=$id",
		);
	}

	return $pictures;

}

sub set_picture {
	my($self, $id, $data) = @_;

	my $id_sql = $self->sqlQuote($id);
	$self->sqlUpdate('gallery_pictures', {
		name		=> $data->{name},
		uid		=> $data->{uid},
		date		=> $data->{date},
		description	=> $data->{description},
		rotate		=> $data->{rotate},
	}, "id=$id_sql");
}

sub get_sizes {
	my($self) = @_;

	my $cache = $self->{_size_cache};
	if (! $cache) {
		$cache = $self->sqlSelectAllHashref(
			'id',
			'id,size,width,height,jpegquality',
			'gallery_sizes'
		);
	}

	my %sizes;
	my $user = getCurrentUser();
	my $id = ($user->{state}{gallery_admin} ? 0 :
		   $user->{'gallery_max_size'}
		|| getCurrentStatic('gallery_max_size')
		|| 3
	);

	if ($id) {
		$sizes{$_->{size}} = $_ for grep {$_->{id} <= $id} values %$cache;
	} else {
		@sizes{ map { $_->{size} } values %$cache } = values %$cache;
	}

	return \%sizes;
}

=pod

* security
	v+ view anything in your group
	v+ do nothing else unless seclev >= 10000
	v+ dynamically create paths to images
	v+ don't let people hog bandwidth (formkeys) [ VARS ]
	-+ don't let them perform unsafe operations via GET;
	  use formkeys? [ VARS ]

* files
	v+ picture directory
	v+ all pictures in one directory?  y

* add pictures
	v+ automatically from directory?  y
	-+ add via HTTP upload (set date?)?
* list pictures
	-+ by what?
		# date? name? group?
		# date, list name/group(s)?
		# group->date, list name?
		# list groups (including "uncategorized")?
	-+ how continue?  set num of images per page [ VAR ]
	v+ for now, list by id, with no contiune, and show
	  name and groups
* edit pictures
	-+ delete pictures
		# delete from filesystem?
	v+ edit name
	v+ edit uid
	v+ edit description
	v+ edit date
	v+ edit groups
		v# list all groups?
		v# multiple pickbox?
	v+ save and edit next?

* add groups
	v+ simple add by name
* list groups
	v+ simple list by name?
* edit groups
	-+ delete
	v+ edit name
	v+ edit description
	v+ edit users in groups
		v# add by nickname/uid?
		v# delete

* search pictures
	+ come later?
	+ search by name, date, group?

* view pictures
	v+ use list?
	v+ use thumbnails?
	v+ rotate, scale?
		v# on-disk cache checks date of original
		   before doing conversion
		v# scale by hand

=cut

1;

__END__


=head1 SEE ALSO

Slash(3).

=head1 VERSION

$Id: Gallery.pm,v 1.6 2002/01/23 04:52:18 pudge Exp $

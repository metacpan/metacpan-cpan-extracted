#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

use StorageDisplay::Data::Partition;

package StorageDisplay::Data::Loop;
# ABSTRACT: Handle LVM data for StorageDisplay

our $VERSION = '2.04'; # VERSION

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::WithSize',
    'StorageDisplay::Role::Style::FromBlockState',
    );

has 'deleted' => (
    is    => 'ro',
    isa   => 'Bool',
    required => 1,
    );

has 'noaccess' => (
    is    => 'ro',
    isa   => 'Bool',
    required => 1,
    default => 0,
    );

has 'filename' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

has 'mountpoint' => (
    is    => 'ro',
    isa   => 'Str',
    required => 0,
    predicate => 'has_mountpoint',
    );

has 'offset' => (
    is    => 'ro',
    isa   => 'Num',
    required => 1,
    );

has 'sizelimit' => (
    is    => 'ro',
    isa   => 'Num',
    required => 1,
    lazy  => 1,
    default => sub {
	my $self = shift;
	return $self->size;
    }
    );

has 'ro' => (
    is    => 'ro',
    isa   => 'Bool',
    required => 1,
    );

has 'autoclear' => (
    is    => 'ro',
    isa   => 'Bool',
    required => 1,
    );

sub majmin2dec {
    my $st = shift;
    my $data = shift;
    my @parts = split(':', $data);
    if (scalar(@parts) != 2) {
	$st->warn('Loop device with bad maj/min '.$data);
	return -1;
    }
    return $parts[0]*256+$parts[1];
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $loop = shift;
    my $st = shift;

    $st->log({level=>1}, 'Loop device '.$loop);

    my $info = $st->get_info('loops', $loop);
    my $block = $st->block($loop);

    my $file = $st->get_info('files', $info->{'back-file'});
    my $deleted = 0;
    if ($file->{'deleted'}
	and $file->{'name'} =~ /^(.*) \(deleted\)$/) {
	$file = $st->get_info('files', $1);
	$deleted = 1;
    }
    my @args;

    #print STDERR "Handling ", $file->{'name'}, " ($deleted)\n";
    if ($file->{'deleted'}
	or $file->{'inode'} ne  $info->{'back-ino'}
	or $file->{'st_dev'} != majmin2dec($st, $info->{'back-maj:min'})) {
	if (! $deleted) {
	    $st->warn('Deleted file '.$file->{'name'}.' not announced!');
	    $deleted = 1;
	}
	#if ($info->{'back-file'} =~ /(.*) \(deleted\)$/) {
	#    # file exists, but root does not have access to it
	#    push @args, 'noaccess', 1;
	#}
    } else {
	if ($deleted) {
	    $deleted = 0;
	    $st->warn('File '.$file->{'name'}.' wrongly marked as deleted!');
	}
    }

    if (!$deleted) {
	my $mountpoint = $file->{'mountpoint'};
	push @args, 'mountpoint', $mountpoint;
	my $consumename = $st->fs_mountpoint_blockname($mountpoint);
	push @args, 'consume' => [$st->block($consumename)];
	#print STDERR $block->name, " consomme ", $consumename, "\n";
    }

    return $class->$orig(
        'name' => $block->name,
	'block' => $block,
	'st' => $st,
	'deleted' => $deleted,
	'filename' => $file->{'name'},
	'size' => $block->size,
	'offset' => $info->{'offset'},
	'ro' => $info->{'ro'},
	'autoclear' => $info->{'autoclear'},
	'sizelimit' => $info->{'sizelimit'},
	'provide' => [$block],
	@args,
        @_
        );
};

sub BUILD {
    my $self = shift;

    $self->provideBlock($self->block);
}

sub dotLabel {
    my $self = shift;
    my @label = (
	'Loop device: '.$self->block->dname,
	);

    my @flags;
    if ($self->ro) {
	push @flags, "readonly";
    }
    if ($self->autoclear) {
	push @flags, "autoclear";
    }
    if (scalar(@flags)) {
	push @label, join(', ', @flags);
    }

    push @label, 'Source'.($self->deleted?' [deleted]':'').': '.$self->filename;

    if ($self->offset != 0) {
	push @label, 'Offset: '.$self->disp_size($self->offset);
    }

    if ($self->size != $self->sizelimit) {
	push @label, 'Size limit: '.$self->disp_size($self->sizelimit);
    }

    return @label;
}

around 'dotStyleNode' => sub {
    my $orig = shift;
    my $self = shift;
    return (
        $self->$orig(@_),
        'style=filled',
        'shape=rectangle',
        );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Data::Loop - Handle LVM data for StorageDisplay

=head1 VERSION

version 2.04

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

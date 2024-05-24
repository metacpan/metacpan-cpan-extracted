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

package StorageDisplay::Data::FS;
# ABSTRACT: Handle filesystem data for StorageDisplay

our $VERSION = '2.06'; # VERSION

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::Grey',
    );

has '_swaps' => (
    traits   => [ 'Array' ],
    is    => 'ro',
    isa   => 'ArrayRef[StorageDisplay::Data::FS::SWAP::Elem]',
    required => 1,
    default  => sub { return []; },
    handles  => {
        '_add_swap' => 'push',
            'all_swap' => 'elements',
            'nb_swap' => 'count',
    }
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $st = shift;

    $st->log('Creating FS');
    my $info = $st->get_info('fs')//{};

    return $class->$orig(
        'ignore_name' => 1,
        'consume' => [],
        'st' => $st,
        @_
        );
};

sub keep {
    my $self = shift;
    my $fs = shift;

    return $fs->useblock;
}

sub BUILD {
    my $self=shift;
    my $args=shift;

    my $st = $args->{'st'};
    # in case FS hierachy is not initialized
    # and 'parent' not present (old versions of findmnt)
    my $rootid = $st->fs_mountpoint_id('/');
    my $allfs = $st->get_info('fs')//{};

    foreach my $mp (sort keys %{$allfs->{swap}}) {
        my $fs = $allfs->{swap}->{$mp};
	if ($fs->{'fstype'} eq 'partition') {
	    $self->_add_swap(
		$self->newElem('FS::SWAP::Partition',
			       $fs->{filesystem}, $st, $fs),
		);
	} elsif ($fs->{'fstype'} eq 'file') {
	    $self->_add_swap(
		$self->newElem('FS::SWAP::File',
			       $fs->{filesystem}, $st, $fs),
		);
	} else {
	    $self->error("Unknown swap type ".$fs->{'fstype'}." for ".$fs->{filesystem});
	}
    }
    if ($self->nb_swap == 1) {
        my $s = ($self->all_swap)[0];
        $s->onlyoneswap;
        $self->addChild($s);
    } else {
        $self->newChild('FS::SWAP', $st, [$self->all_swap()]);
    }
    #foreach my $mp (sort keys %{$allfs->{df}}) {
    #    my $fs = $allfs->{df}->{$mp};
    #	$self->newChild('FS::FS', $fs->{filesystem}, $st, $fs);
    #}
    my $fullfs = $allfs->{flatfull};
    my $flat=0;
    if ($flat) {
	foreach my $id (keys %{$fullfs}) {
	    my $fs = $fullfs->{$id};
	    my $fs_elem = $self->newElem('FS::MP::FS', $st, $fs);
	    if ($self->keep($fs_elem)) {
		$self->addChild($fs_elem);
	    }
	}
    } else {
	while ($fullfs->{$rootid}->{parent} != 1) {
	    $rootid = $fullfs->{$rootid}->{parent};
	}
	#my $
	$self->addChild($self->createFS($st, $fullfs, $rootid));
    }
}

sub createFS {
    my $self = shift;
    my $st = shift;
    my $fullfs = shift;
    my $id = shift;

    my $fs = $fullfs->{$id};
    my $fs_elem = $self->newElem('FS::MP::FS', $st, $fs);
    if (! exists($fs->{children})) {
	if ($self->keep($fs_elem)) {
	    return $fs_elem;
	}
	return;
    }
    if (exists($fs->{children})) {
	my @fs_children = map
	{
	    my $fs = $self->createFS($st, $fullfs, $_);
	    defined($fs) ? $fs : ()
	}
	@{$fs->{children}};

	if (scalar(@fs_children) == 0 && ! $self->keep($fs_elem)) {
	    return;
	}
	return $self->newElem('FS::MP',
			      'st' => $st,
			      'fs' => $fs,
			      'fs_elem' => $fs_elem,
			      'fs_children' => \@fs_children);
    }
}

sub dotLabel {
    my $self = shift;
    return "Mounted FS and swap";
}

1;

##################################################################
package StorageDisplay::Data::FS::MP::FS;
# Basic FS info

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::WithUsed',
    );

has 'mountpoint' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    );

has 'fstype' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    );

has 'sourcenames' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    );

has 'special' => (
    is => 'ro',
    isa => 'Bool',
    required => 1,
    default => 0,
    );

has 'useblock' => (
    is => 'ro',
    isa => 'Bool',
    required => 1,
    default => 0,
    );

has 'fsroot' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    );

has 'parentfsid' => (
    is => 'ro',
    isa => 'Num',
    required => 1,
    );

has 'sd' => (
    is => 'ro',
    isa => 'StorageDisplay',
    required => 1,
    );

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    my $st = shift;
    my $fs = shift;

    my @consume = ();
    my $has_sources = exists($fs->{'sources'});
    my @sources;
    if ($has_sources) {
	@sources = @{$fs->{'sources'}};
    } else {
	@sources = ($fs->{'source'});
    }
    my @sourcenames;
    if (! defined($fs->{'fsroot'})) {
	use Data::Dumper;
	use Carp;
	print STDERR Dumper($fs), "\n";
	confess "coucou\n";
    }
    my $use_block = 0;
    my $special = 0;
    for my $source (@sources) {
	if (! $has_sources # old software, no 'sources' entry
	    && $fs->{'fsroot'} ne '/'
	    && $source =~ m,^(.*)\[$fs->{'fsroot'}\]$,) {
	    $source = $1; # only keep relevant part of 'source' entry
	}
	my $block;
	if ($source =~ m,^/dev/,) {
	    $block = $st->block($source);
	    push @sourcenames, 'Device: '.$block->dname;
	    $use_block=1;
	} elsif ($source =~ m,^/,) {
	    # TODO : wrong if $target is not a mountpoint
	    $block = $st->block($source);
	    push @sourcenames, 'Source: '.$source;
	    #$block = $st->block($st->fs_mountpoint_blockname($source));
	} else {
	    push @sourcenames, 'Source: '.$source;
	    $block = $st->block($source);
	    $special = 1;
	}
	push @consume, $block;
    }
    if ($fs->{fsroot} ne '/') {
	push @sourcenames, "Subdir: ".$fs->{fsroot};
    }

    $st->log({level=>1}, $fs->{target});

    my $name = $st->fs_mountpoint_blockname_by_id($fs->{id}, $fs->{target});
    if (not exists($fs->{free})) {
	$fs->{free} = $fs->{avail};
    }
    if (exists($fs->{label})) {
	delete $fs->{label};
    }

    #if ($fs->{parent} != 1) {
    #	push @consume, $st->block($st->fs_mountpoint_blockname_by_id($fs->{parent}));
    #}
    my $block = $st->block($name);
    return $class->$orig(
        'name' => $name,
        'consume' => \@consume,
        'provide' => $block,
        'sd' => $st,
        'block' => $block,
	'free' => $fs->{free},
	'used' => $fs->{used},
	'size' => $fs->{size},
	'special' => $special,
	'useblock' => $use_block,
	'sourcenames' => join("\n", @sourcenames),
	'fsroot' => $fs->{fsroot},
	'fstype' => $fs->{fstype},
	'mountpoint' => $fs->{target},
	'parentfsid' => $fs->{parent},
        #%{$fs},
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    $self->provideBlock($args->{provide});
}

sub dotLabel {
    my $self = shift;
    #if ($self->size == 0 && $self->special) {
    if ($self->sourcenames eq 'Source: '.$self->{fstype}) {
	if ($self->size == 0) {
	    return ($self->mountpoint.' ('.$self->fstype.')');
	} else {
	    return (
		$self->mountpoint,
		$self->fstype,
        );
	}
    }
    return (
        $self->mountpoint,
        $self->sourcenames,
        $self->fstype,
        );
}

around 'sizeLabel' => sub {
    my $orig = shift;
    my $self = shift;

    if ($self->size == 0) {
	return;
    }
    return $self->$orig(@_);
};

around dotLinks => sub {
    my $orig = shift;
    my $self = shift;

    my @links = $self->$orig(@_);
    if ($self->parentfsid != 1) {
	push @links, $self->sd->block($self->sd->fs_mountpoint_blockname_by_id($self->parentfsid))->elem->linkname.' -> '.$self->linkname.' [style=invis]';
    }
    #if ($fs->{parent} != 1) {
    #	push @consume, $st->block($st->fs_mountpoint_blockname_by_id($fs->{parent}));
    #}
    return @links;
};

1;

##################################################################
package StorageDisplay::Data::FS::MP;
# Container for FS that has children FS

use Moose;
use namespace::sweep;

extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::Grey',
    #'StorageDisplay::Role::Style::SubInternal',
    );

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    #my $args = shift;
    #for my $i (@_) {
#	print STDERR "args=$i\n";
    #}
    my %args=(@_);
    my $fs = $args{fs};

    return $class->$orig(
        'name' => $fs->{id}.'@'.$fs->{target},
        %args,
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;

    $self->addChild($args->{fs_elem});
    $self->newChild('FS::MP::C', $args);
}

sub dotLabel {
    return ();
}

1;

##################################################################
package StorageDisplay::Data::FS::MP::C;
# Container for children FS

use Moose;
use namespace::sweep;

extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    #'StorageDisplay::Role::Style::Grey',
    'StorageDisplay::Role::Style::SubInternal',
    #'StorageDisplay::Role::HasBlock',
    #'StorageDisplay::Role::Style::WithUsed',
    );

sub BUILD {
    my $self=shift;
    my $args=shift;

    my $st = $args->{st};
    my $SDFS = $args->{SDFS};
    my $fullfs = $args->{fullfs};
    my $fs = $args->{fs};

    for my $child (@{$args->{fs_children}}) {
	$self->addChild($child);
    }
}

sub dotLabel {
    return ();
}

1;

##################################################################
package StorageDisplay::Data::FS::SWAP;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::WithUsed',
    );

has '_swaps' => (
    traits   => [ 'Array' ],
    is    => 'ro',
    isa   => 'ArrayRef[StorageDisplay::Data::FS::SWAP::Elem]',
    required => 1,
    handles  => {
        '_add_swap' => 'push',
            'all_swap' => 'elements',
            'nb_swap' => 'count',
    }
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $st = shift;
    my $swaps = shift;

    $st->log({level=>1}, "SWAP");

    my $name = '@FS@SWAP';

    my ($size, $free, $used) = (0, 0, 0);
    for my $s (@{$swaps}) {
        $size += $s->size;
        $free += $s->free;
        $used += $s->used;
    }

    return $class->$orig(
        'name' => $name,
        'st' => $st,
        'free' => $free,
        'size' => $size,
        'used' => $used,
        '_swaps' => $swaps,
	@_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;

    for my $s ($self->all_swap) {
        $self->addChild($s);
    }
}

sub dotLabel {
    my $self = shift;
    my $nb_swap = $self->nb_swap;
    return (
        "SWAP",
        );
}

sub dotStyle2 {
    my $orig  = shift;
    my $self = shift;

    return (
        "style=filled;",
        "color=lightgrey;",
        "fillcolor=lightgrey;",
        "node [style=filled,color=lightgrey,fillcolor=lightgrey,shape=rectangle];",
        );
};

around 'dotStyle' => sub {
    my $orig  = shift;
    my $self = shift;

    my @config = (map {
        my $val = $_;
        $val =~ s/^color=.*;/color=white/;
        $val =~ s/,color=[^,]*,/,color=white,/;
        $val;
    } ($self->$orig(@_)));
    return @config;
};

1;

##################################################################
package StorageDisplay::Data::FS::SWAP::Elem;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::WithUsed',
    );

has 'fstype' => (
    is => 'ro',
    isa => 'Str',
    );

has 'standalone' => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    required => 1,
    writer => '_standalone'
    );

sub onlyoneswap {
    my $self = shift;
    return $self->_standalone(1);
}

sub BUILD {
    my $self=shift;
    my $args=shift;
    $self->provideBlock($args->{'provide'});
}

sub dotLabel {
    my $self = shift;
    if ($self->standalone) {
        return (
            'SWAP',
            'Device: '.$self->block->dname,
            );
    }
    return (
        $self->block->dname,
        );
}

1;

##################################################################
package StorageDisplay::Data::FS::SWAP::Partition;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::FS::SWAP::Elem';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $dev = shift;
    my $st = shift;
    my $fs = shift;

    my $block = $st->block($dev);
    $st->log({level=>1}, "SWAP@".$dev);

    my $name = $block->name;

    return $class->$orig(
        'name' => $name,
        'consume' => [$block],
        'provide' => $st->block($st->fs_swap_blockname($name)),
        'st' => $st,
        'block' => $block,
        %{$fs},
        @_
        );
};

1;

##################################################################
package StorageDisplay::Data::FS::SWAP::File;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::FS::SWAP::Elem';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $file = shift;
    my $st = shift;
    my $fs = shift;

    my $block = $st->block($file);
    $st->log({level=>1}, "SWAP@".$file);

    my $name = $file;
    my $fblock = $st->block($st->fs_mountpoint_blockname($fs->{'file-mountpoint'} // '@none@'));
    if (defined($fs->{'file-size'})) {
	$fblock->size($fs->{'file-size'});
    }

    return $class->$orig(
        'name' => $name,
        'consume' => [$fblock],
        'provide' => $st->block($st->fs_swap_blockname($file)),
        'st' => $st,
        'block' => $block,
        %{$fs},
        @_
        );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Data::FS - Handle filesystem data for StorageDisplay

=head1 VERSION

version 2.06

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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

our $VERSION = '1.2.1'; # VERSION

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

sub BUILD {
    my $self=shift;
    my $args=shift;

    my $st = $args->{'st'};
    my $allfs = $st->get_info('fs')//{};

    foreach my $dev (sort keys %{$allfs}) {
        my $fs = $allfs->{$dev};
        if (($fs->{'mountpoint'}//'') eq 'SWAP') {
            if ($fs->{'fstype'} eq 'partition') {
                $self->_add_swap(
                    $self->newElem('FS::SWAP::Partition',
				   $dev, $st, $fs),
                    );
            } elsif ($fs->{'fstype'} eq 'file') {
                $self->_add_swap(
                    $self->newElem('FS::SWAP::File',
				   $dev, $st, $fs),
                    );
            } else {
                $self->error("Unknown swap type ".$fs->{'fstype'}." for ".$dev);
            }
        } else {
            $self->newChild('FS::FS', $dev, $st, $fs);
        }
    }
    if ($self->nb_swap == 1) {
        my $s = ($self->all_swap)[0];
        $s->onlyoneswap;
        $self->addChild($s);
    } else {
        $self->newChild('FS::AllSWAP', $st, [$self->all_swap()]);
    }
}

sub dotLabel {
    my $self = shift;
    return "Mounted FS and swap";
}

1;

##################################################################
package StorageDisplay::Data::FS::FS;

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
    );

has 'fstype' => (
    is => 'ro',
    isa => 'Str',
    );

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    my $dev = shift;
    my $st = shift;
    my $fs = shift;

    my $block = $st->block($dev);
    $st->log({level=>1}, ($fs->{mountpoint}//$dev));

    my $name = $fs->{mountpoint}//$block->name;

    return $class->$orig(
        'name' => $name,
        'consume' => [$block],
        'provide' => $st->block($st->fs_mountpoint_blockname($name)),
        'st' => $st,
        'block' => $block,
        %{$fs},
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
    return (
        $self->mountpoint,
        "Device: ".$self->block->dname,
        $self->fstype,
        );
}

1;

##################################################################
package StorageDisplay::Data::FS::AllSWAP;

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

version 1.2.1

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

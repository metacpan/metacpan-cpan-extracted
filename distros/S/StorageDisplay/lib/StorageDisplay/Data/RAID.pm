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

package StorageDisplay::Data::RAID;
# ABSTRACT: Handle RAID data for StorageDisplay

our $VERSION = '2.06'; # VERSION

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::Grey',
    );

has '_devices' => (
    traits   => [ 'Array' ],
    is    => 'ro',
    isa   => 'ArrayRef[StorageDisplay::Data::RAID::Device]',
    required => 1,
    default  => sub { return []; },
    handles  => {
        '_add_device' => 'push',
            'devices' => 'elements',
    }
    );

has 'raid-devices' => (
    traits   => [ 'Array' ],
    is    => 'ro',
    isa   => 'ArrayRef[StorageDisplay::Data::RAID::RaidDevice]',
    required => 1,
    default  => sub { return []; },
    handles  => {
        '_add_raid_device' => 'push',
            'raid_devices' => 'elements',
    }
    );

around '_add_raid_device' => sub {
    my $orig = shift;
    my $self = shift;
    my $raid_device = shift;
    my $state = shift;
    die "Invalid state" if $state->raid_device != $raid_device;
    $raid_device->_state($state);
    $self->addChild($state);
    return $self->$orig($raid_device);
};

1;

##################################################################
package StorageDisplay::Data::RAID::Container;
use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID';

has 'container-devices' => (
    traits   => [ 'Array' ],
    is    => 'ro',
    isa   => 'ArrayRef[StorageDisplay::Data::RAID::ContainerDevice]',
    required => 1,
    default  => sub { return []; },
    handles  => {
        '_add_container_device' => 'push',
            'container_devices' => 'elements',
    }
    );

sub _add_raid_device {
    die "Internal error";
}

around '_add_container_device' => sub {
    my $orig = shift;
    my $self = shift;
    my $container_device = shift;
    $self->addChild($container_device);
    return $self->$orig($container_device);
};

1;

###########################################################################
package StorageDisplay::Data::RAID::Elem;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

has 'raid' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::RAID',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $raid = shift;
    my $st = shift;

    return $class->$orig(
        'raid' => $raid,
        'st' => $st,
        @_
        );
};

1;

###########################################################################
package StorageDisplay::Data::RAID::State;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::Elem';

with (
    'StorageDisplay::Role::Style::Plain',
    'StorageDisplay::Role::Style::IsSubGraph',
    );

has 'state' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

has 'extra-info' => (
    is    => 'ro',
    isa   => 'Str',
    required => 0,
    predicate => 'has_extra_info',
    reader => 'extra_info',
    );

has 'raid_device' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::RAID::RaidDevice',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $raid_device = shift;
    my $st = shift;

    return $class->$orig(
        $raid_device->raid, $st,
        'consume' => [],
        'raid_device' => $raid_device,
        @_
        );
};

sub dotStyleNode {
    my $self = shift;
    my $color = 'special';
    my $state = $self->state;

    if ($state =~ /degraded|DGD/i) {
        $color = 'warning';
    } elsif ($state =~ /failed|offline/i) {
        $color = 'error';
    } elsif ($state =~ /clean|active|active-idle|optimal|OKY/i) {
        $color = 'ok';
    }

    return (
        "shape=oval",
        "fillcolor=".$self->statecolor($color),
        );
}

sub dotLabel {
    my $self = shift;
    my @label=('state: '.$self->state);
    if ($self->has_extra_info) {
        push @label, $self->extra_info;
    }

    return @label;
}

1;

###########################################################################
package StorageDisplay::Data::RAID::ContainerDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    #'StorageDisplay::Role::Style::Plain',
    );

has 'container-type' => (
    is    => 'ro',
    isa   => 'Str',
    reader => 'container_type',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $raid = shift;
    my $st = shift;
    my $block = shift;

    return $class->$orig(
        $raid, $st,
        'block' => $block,
        'name' => $block->name,
        'consume' => [],
        @_
        );
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    #print STDERR "container device ", $self->name, " with providing block ", $self->block->dname,"\n";
    $self->block->providedBy($self);
}

sub dotLabel {
    my $self = shift;

    return (
        $self->block->dname,
        #$self->container_type,
        );
}

sub dotStyleNode {
    my $self = shift;
    return (
        "shape=oval;",
        "fillcolor=".$self->statecolor('special').";",
        );
};

1;

###########################################################################
package StorageDisplay::Data::RAID::RaidDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::FromBlockState',
    'StorageDisplay::Role::Style::WithSize',
    );

has 'state' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::RAID::State',
    writer => '_state',
    required => 0,
    );

has 'raid-level' => (
    is    => 'ro',
    isa   => 'Str',
    reader => 'raid_level',
    required => 1,
    );

around '_state' => sub {
    my $orig  = shift;
    my $self = shift;
    my $ret = $self->$orig(@_);
    $self->state->addChild($self);
    return $ret;
};

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $raid = shift;
    my $st = shift;
    my $block = shift;

    return $class->$orig(
        $raid, $st,
        'block' => $block,
        'name' => $block->name,
        'consume' => [],
        @_
        );
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    $self->block->providedBy($self);
}

sub dotLabel {
    my $self = shift;

    return (
        $self->block->dname,
        $self->raid_level,
        );
}

1;

###########################################################################
package StorageDisplay::Data::RAID::Device;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::Plain',
    );

has 'state' => (
    is    => 'ro',
    isa   => 'Maybe[Str]',
    required => 0,
    );

has 'raiddevice' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $raid = shift;
    my $st = shift;
    my $devname = shift;
    my $info = shift;
    my $args = { @_ };
    my $container_block = $args->{'container-block'};

    my $block = $st->block($devname);

    #print STDERR "RAID::Device ", $block->dname, " container ", ($container_block // $block)->dname, "\n";

    return $class->$orig(
        $raid, $st,
        'block' => $block,
        'name' => $block->name,
        'consume' => [$container_block // $block],
        'state' => $info->{state},
        'raiddevice' => $info->{raiddevice},
        @_
        );
};

around 'dotStyleNode' => sub {
    my $orig = shift;
    my $self = shift;
    my @text = $self->$orig(@_);

    my $state = $self->state;
    my $s;

    if (not defined($state)) {
        # devices in RAID containers
        $s = 'used';
    } elsif ($state =~ /active|Online, Spun Up|OPT|RDY/i) {
        $s = 'used';
    } elsif ($state =~ /rebuild|RBLD/i) {
        $s = 'warning';
    } elsif ($state =~ /spare|HSP/i) {
        $s = 'free';
    } elsif ($state =~ /faulty|error|FLD|MIS|bad|offline/i) {
        $s = 'error';
    } elsif ($state =~ /Unconfigured.*good|AVL/i) {
        $s = 'unused';
    } elsif ($state =~ /JBOD/i) {
        $s = $self->block->state;
    } else {
        $s = 'warning';
    }
    my $color = $self->statecolor($s);

    push @text, "fillcolor=$color";
    return @text;
};

sub dotLabel {
    my $self = shift;
    my @label = ($self->raiddevice.': '.$self->block->dname);
    if (defined($self->state)) {
        push @label, $self->state;
    }
    return @label;
}

1;

###########################################################################
package StorageDisplay::Data::RAID::RawDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::Device';
with(
    'StorageDisplay::Role::Style::WithSize',
    );

has 'model' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

has 'slot' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

sub dotLabel {
    my $self = shift;

    return (
        $self->model,
        $self->raiddevice.': slot '.$self->slot,
        $self->state,
        );
}

1;

##################################################################
package StorageDisplay::Data::RAID::MD::Container;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::Container';

with(
    'StorageDisplay::Role::HasBlock',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $devname = shift;
    my $st = shift;

    #$st->get_infos
    $st->log({level=>1}, 'MD Container managed by '.$devname);

    my $info = $st->get_info('md', $devname);
    my $block = $st->block($devname);
    #print STDERR "MD::Container $devname -> ", $block->dname, "\n";

    return $class->$orig(
        'name' => $block->name,
        'block' => $block,
        'consume' => [],
        'st' => $st,
        'raid-name' => '', # in case $info has no name
        %{$info},
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    my $container_device = StorageDisplay::Data::RAID::ContainerDevice->new(
        $self, $st,
        $self->block,
        'container-type' => $args->{'raid-version'},
        );
    $self->_add_container_device($container_device);

    foreach my $dev (sort keys %{$args->{'devices'}}) {
        my $d = StorageDisplay::Data::RAID::Device->new($self, $st, $dev, $args->{'devices'}->{$dev});
        $self->_add_device($d);
        $self->addChild($d);
    }

    return $self;
};

has 'raid-version' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    reader => 'container_type',
    );

sub dname {
    my $self=shift;
    return 'MD: '.$self->block->dname;
}

sub dotLabel {
    my $self = shift;
    return (
        'Software RAID container',
        'Type: '.$self->container_type,
        #$self->disp_size($self->used_dev_size).' used per device',
        );
}

sub dotLinks {
    my $self = shift;
    # Always one container device for MD RAID
    my $raidlinkname = ($self->container_devices)[0]->linkname;
    return (
        map {
            $_->linkname.' -> '.$raidlinkname
        } $self->devices
    );
}

1;

##################################################################
package StorageDisplay::Data::RAID::MD;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID';

with(
    'StorageDisplay::Role::HasBlock',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $devname = shift;
    my $st = shift;

    #$st->get_infos
    $st->log({level=>1}, 'MD Raid for device '.$devname);

    my $info = $st->get_info('md', $devname);
    my $block = $st->block($devname);

    return $class->$orig(
        'name' => $block->name,
        'block' => $block,
        'consume' => [],
        'st' => $st,
        'raid-name' => '', # in case $info has no name
        %{$info},
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    my $raid_device = $self->newElem(
	'RAID::MD::State::RaidDevice', $self, $st, $self->block,
	'raid-level' => $args->{'raid-level'},
	'size' => $args->{'array-size'});
    my $state = $self->newElem(
	'RAID::MD::State', $raid_device, $st,
	'state' => $args->{'raid-state'},
	'ignore_name' => 1,
	);
    $self->_add_raid_device($raid_device, $state);

    my $container_device_block = undef;
    if (exists($args->{'raid-container-device'})) {
        $container_device_block = $st->block($args->{'raid-container-device'});
        #print STDERR "RAID::MD Container ", $args->{'raid-container-device'}, " -> ",
        #    $container_device_block->dname, "\n";
    }

    foreach my $dev (sort keys %{$args->{'devices'}}) {
        my $d = $self->newChild(
	    'RAID::MD::Device',
	    $self, $st, $dev, $args->{'devices'}->{$dev},
            'container-block' => $container_device_block);
        $self->_add_device($d);
    }

    return $self;
};

has 'used-dev-size' => (
    is    => 'ro',
    isa   => 'Int',
    required => 0, # not present with RAID0
    predicate => 'has_used_dev_size',
    reader => 'used_dev_size',
    );

has 'raid-name' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    reader => 'raid_name',
    );

sub dname {
    my $self=shift;
    return 'MD: '.$self->block->dname;
}

sub dotLabel {
    my $self = shift;
    my @label = ($self->raid_name);
    if ($self->has_used_dev_size) {
	push @label, $self->disp_size($self->used_dev_size).' used per device';
    }
    return @label;
}

sub dotLinks {
    my $self = shift;
    # Always one raid device for MD RAID
    my $raidlinkname = ($self->raid_devices)[0]->linkname;
    return (
        map {
            $_->linkname.' -> '.$raidlinkname
        } $self->devices
    );
}

1;

##################################################################
package StorageDisplay::Data::RAID::MD::State;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::State';

1;

##################################################################
package StorageDisplay::Data::RAID::MD::State::RaidDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::RaidDevice';

1;

##################################################################
package StorageDisplay::Data::RAID::MD::Device;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::Device';

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::Megacli;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID';

has 'controller' => (
    is    => 'ro',
    isa   => 'Num',
    required => 1,
    );

has 'hw_model' => (
    is    => 'ro',
    isa   => 'Str',
    init_arg => 'H/W Model',
    required => 1,
    );

has 'ID' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

has 'named-raid-devices' => (
    traits   => [ 'Hash' ],
    is    => 'ro',
    isa   => 'HashRef[StorageDisplay::Data::RAID::RaidDevice]',
    required => 1,
    default  => sub { return {}; },
    handles  => {
        '_add_named_raid_device' => 'set',
            'raid_device' => 'get',
    }
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $controller = shift;
    my $st = shift;

    #$st->get_infos
    $st->log({level=>1}, 'Megacli Raid controller '.$controller);

    my $info = $st->get_info('lsi-megacli', $controller);

    return $class->$orig(
        'name' => $controller,
        'controller' => $controller,
        'consume' => [],
        'st' => $st,
        %{$info->{'Controller'}->{'c'.$controller}},
        %{$info},
        @_
        );
};

sub hwsize {
    my $self = shift;
    my $hwsize = shift;

    if ($hwsize =~ /^[0-9]+$/) {
        return $hwsize;
    } elsif ($hwsize =~ /^([0-9]+)([BKMGTP])$/) {
        my %pow = (
            'B' => 0,
            'K' => 1,
            'M' => 2,
            'G' => 3,
            'T' => 4,
            'P' => 5,
            );
        return $1 * (1024 ** $pow{$2});
    } else {
        print STDERR "Warning: cannot interpret size $hwsize, using -1\n";
        return -1;
    }
}

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    #my $state = StorageDisplay::Data::RAID::State->new($self, $st,
    #                                             'state' => $args->{'raid-state'});
    #$self->addChild($state);

    #$self->_add_raid_device(StorageDisplay::Data::RAID::RaidDevice->new($self, $st,
    #                                                              $self->block,
    #                                                              $state,
    #                                                              'size' => $args->{'array-size'}));
    my $cid = $self->controller;

    #use Data::Dumper;
    #print STDERR Dumper($st);
    $self->newChild('RAID::LSI::Megacli::BBU::Status',
		    $self, $st, 'status' => $args->{'BBU'});

    use bignum qw/hex/;
    foreach my $dev (sort { $a->{'LSI ID'} <=> $b->{'LSI ID'} }
                     (values %{$args->{'Disk'}})) {
	my $devname = $dev->{'Path'} // '';
        my $devpath = 'LSI@'.$dev->{'Slot ID'};
        if ($dev->{'ID'} !~ /^c[0-9]+uXpY$/) {
            $devpath = 'LSI@'.$dev->{'ID'};
        }
	my $block;
	my @block;
	if ($devname ne '' && $devname ne 'N/A') {
		$block = $st->block($devname);
		@block = ('block' => $block);
	}
        my $d = $self->newChild(
	    'RAID::LSI::Megacli::RawDevice',
            $self, $st, $devpath, $dev,
            'raiddevice' => $dev->{'ID'},
            'state' => $dev->{'Status'},
            'model' => $dev->{'Drive Model'},
            'slot' => $dev->{'Slot ID'},
            'size' => (hex($dev->{'# sectors'}) * ($dev->{'sector size'} // 512))->numify(),
	    @block,
            );
        $self->_add_device($d);
	if ($block) {
		$d->provideBlock($block);
	}
    }
    foreach my $dev (sort { $a->{'ID'} cmp $b->{'ID'} }
                     (values %{$args->{'Array'}})) {
        #print STDERR Dumper($dev);
        my $devname = $dev->{'OS Path'};
        my $block = $st->block($devname);
        #print STDERR Dumper($block->blk_info("SIZE")//$self->hwsize($dev->{'Size'}));
        my $raid_device = $self->newElem(
	    'RAID::LSI::Megacli::State::RaidDevice',
            $self, $st, $block,
            # If the disk is not attached to linux (or have been 'deleted')
            # the SIZE would be unknown from blk
            'size' => $block->blk_info("SIZE")//$self->hwsize($dev->{'Size'}),
            'raid-level' => $dev->{'Type'},
            %{$dev},
            );
        my %inprogress=();
        if ($dev->{'InProgress'} ne 'None') {
            %inprogress=('extra-info' => $dev->{'InProgress'});
        }
        my $state = $self->newElem(
	    'RAID::LSI::Megacli::State', $raid_device, $st,
	    'state' => $dev->{'Status'},
	    'name' => $raid_device->block->name,
	    %inprogress);

        $self->_add_raid_device($raid_device, $state);
        $self->_add_named_raid_device($dev->{'ID'}, $raid_device);
    }

    return $self;
};

sub dname {
    my $self=shift;
    return 'MegaCli: Controller '.$self->ID;
}

sub dotLabel {
    my $self = shift;
    return (
        $self->hw_model,
        "Controller: ".$self->ID,
        #$self->raid_level.': '.$self->raid_name,
        #$self->disp_size($self->used_dev_size).' used per device',
        );
}

sub dotLinks {
    my $self = shift;
    return (
        map {
            if ($_->raiddevice =~ /^(c[0-9]+u[0-9]+)p([0-9]+|Y)$/) {
                my $raid_device = $self->raid_device($1);
                $_->linkname.' -> '.$raid_device->linkname;
            }
        } $self->devices
    );
}

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::Megacli::BBU::Status;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::Elem';

has 'status' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $raid = shift;
    my $st = shift;

    return $class->$orig(
        $raid, $st,
        'ignore_name' => 1,
        'consume' => [],
        @_
        );
};

sub dotStyleNode {
    my $self = shift;
    my $color = 'special';
    my $status = $self->status;

    if ($status =~ /REPL|error/i) {
        $color = 'red';
    } elsif ($status =~ /missing/i || $status eq '') {
        $color = 'warning';
    } elsif ($status =~ /absent/i) {
        $color = 'unused';
    } elsif ($status =~ /good/i) {
        $color = 'ok';
    }

    return (
        "shape=oval",
        "fillcolor=".$self->statecolor($color),
        );
}

sub dotLabel {
    my $self = shift;

    return (
        'BBU Status: '.$self->status,
        );
}

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::Megacli::State;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::State';

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::Megacli::RawDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::RawDevice';

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::Megacli::State::RaidDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::RaidDevice';

has 'lsi-id' => (
    is    => 'ro',
    isa   => 'Str',
    init_arg => 'ID',
    reader=> 'lsi_id',
    required => 1,
    );

around 'dotLabel' => sub {
    my $orig  = shift;
    my $self = shift;
    my @ret = $self->$orig(@_);
    $ret[0] .= " (".$self->lsi_id.")";
    return @ret;
};

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::SASIrcu;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID';

my $missing_count=0;

has 'controller' => (
    is    => 'ro',
    isa   => 'Num',
    init_arg => 'controllerID',
    required => 1,
    );

has 'hw_model' => (
    is    => 'ro',
    isa   => 'Str',
    init_arg => 'controller-type',
    required => 1,
    );

has 'named-raw-devices' => (
    traits   => [ 'Hash' ],
    is    => 'ro',
    isa   => 'HashRef[StorageDisplay::Data::RAID::RawDevice]',
    required => 1,
    default  => sub { return {}; },
    handles  => {
        '_add_named_raw_device' => 'set',
            'raw_device' => 'get',
    }
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $controller = shift;
    my $st = shift;

    #$st->get_infos
    $st->log({level=>1}, 'LSI Raid controller (SAS2Ircu) '.$controller);

    my $info = $st->get_info('lsi-sas-ircu', $controller);

    return $class->$orig(
        'name' => $controller,
        'controllerID' => $controller,
        'consume' => [],
        'st' => $st,
        %{$info->{'controller'}},
        %{$info},
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    my $cid = $self->controller;
    my $cur_missing_count = $missing_count;
    foreach my $dev (sort { $a->{'enclosure'} <=> $b->{'enclosure'}
                            or $a->{'slot'} <=> $b->{'slot'}
                     }
                     @{$args->{'devices'}}) {
        my ($id,$d);
        if ($dev->{'state'} =~ /MIS/) {
            # disk missing
            $id = $dev->{'enclosure'}.":".$dev->{'slot'}." (".($missing_count++).")";
            my $devpath = 'LSISASIrcu@'.$id;
            $d = $self->newChild(
		'RAID::LSI::SASIrcu::MissingRawDevice',
                $self, $st, $devpath, $dev,
                'raiddevice' => $id,
                'state' => $dev->{'state'},
                'model' => 'Disk missing',
                'size' => 0,
                'slot' => 'none',
                );
        } else {
            $id=$dev->{'enclosure'}.":".$dev->{'slot'};
            if ($id eq '0:0') { # can be the case of FLD drives
                $id .= ' ('.($cur_missing_count++).')';
            }
            #print STDERR "Adding $id\n";
            my $devpath = 'LSISASIrcu@'.$id;
            my $block;
            {
                my $serial = $dev->{'serial-no'}//'';
                if ($serial ne '') {
                    #print STDERR "Serial for $id is $serial\n";
                    $block = $st->blockBySerial($serial);
                }# else { # GUID/WWN is not always unique
                #    $serial = $dev->{'guid'}//'';
                #    if ($serial ne '') {
                #        print STDERR "Guid for $id is $serial\n";
                #        $block = $st->blockBySerial($serial);
                #    }
                #}
            }
            $d = $self->newChild(
		'RAID::LSI::SASIrcu::RawDevice',
                $self, $st, $devpath, $dev,
                'raiddevice' => $id,
                'state' => $dev->{'state'},
                'model' => join(' ', $dev->{'manufacturer'}, $dev->{'model-number'}, $dev->{'serial-no'}),
                'size' => $dev->{'size'}//'0', # No size on some FLD devices
                'slot' => $id,
                );
            if (defined($block)) {
                #print STDERR "$id provide ", $block->name,"\n";
                $d->provideBlock($block);
            }
        }
        $self->_add_device($d);
        $self->_add_named_raw_device($id, $d);
    }
    my $defined_missing_count = $cur_missing_count;
    $cur_missing_count = $missing_count;
    foreach my $dev (sort { $a->{'id'} cmp $b->{'id'} }
                     @{$args->{'volumes'}}) {
        my $devname = $args->{'wwid'}->{$dev->{'wwid'}};
        my $block = $st->block($devname);
        my $raid_device = $self->newElem(
	    'RAID::LSI::SASIrcu::State::RaidDevice',
            $self, $st, $block,
            'size' => $block->blk_info("SIZE"),
            'raid-level' => $dev->{'Type'},
            %{$dev},
            );
        my $state = $self->newElem(
	    'RAID::LSI::SASIrcu::State', $raid_device, $st,
	    'state' => $dev->{'status'},
	    'name' => $raid_device->block->name
	    );

        $self->_add_raid_device($raid_device, $state);
        foreach my $phyid (keys %{$dev->{'PHY'} // {}}) {
            my $phy = $dev->{'PHY'}->{$phyid};
            my $id = $phy->{'enclosure'}.":".$phy->{'slot'};
            if ($id eq '0:0') {
                $id .= ' ('.($cur_missing_count++).')';
            }
            #print STDERR "Getting $id\n";
            my $rdsk = $self->raw_device($id);
            $rdsk->volume($raid_device);
            $rdsk->phyid($phyid);
        }
    }
    if ($cur_missing_count != $defined_missing_count) {
        print STDERR "Internal warning: wrong total of missing drives: $cur_missing_count != $defined_missing_count\n";
    }
    $missing_count = ($cur_missing_count > $defined_missing_count)?$cur_missing_count:$defined_missing_count;
    return $self;
};

sub dname {
    my $self=shift;
    return 'MegaCli: Controller '.$self->controller;
}

sub dotLabel {
    my $self = shift;
    return (
        $self->hw_model,
        #$self->ID,
        #$self->raid_level.': '.$self->raid_name,
        #$self->disp_size($self->used_dev_size).' used per device',
        );
}

sub dotLinks {
    my $self = shift;
    return (
        map {
            if ($_->has_volume) {
                $_->linkname.' -> '.$_->volume->linkname;
            }
        } $self->devices
    );
}

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::SASIrcu::MissingRawDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::RawDevice';

#with (
#    'StorageDisplay::Role::Style::WithSize',
#    );

has 'volume' => (
    is       => 'rw',
    isa      => 'StorageDisplay::Data::RAID::RaidDevice',
    required => 0,
    predicate => 'has_volume',
    );

has 'phyid' => (
    is       => 'rw',
    isa      => 'Num',
    required => 0,
    predicate => 'has_phyid',
    );

around 'dotLabel' => sub {
    my $orig  = shift;
    my $self = shift;
    my @ret = $self->$orig(@_);
    if ($self->has_phyid) {
        $ret[1] = $self->phyid.": enc/slot: ".$self->slot;
    } else {
        $ret[1] = "enc/slot: ".$self->slot;
    }
    return @ret;
};

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::SASIrcu::RawDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::RawDevice';

has 'volume' => (
    is       => 'rw',
    isa      => 'StorageDisplay::Data::RAID::RaidDevice',
    required => 0,
    predicate => 'has_volume',
    );

has 'phyid' => (
    is       => 'rw',
    isa      => 'Num',
    required => 0,
    predicate => 'has_phyid',
    );

around 'dotLabel' => sub {
    my $orig  = shift;
    my $self = shift;
    my @ret = $self->$orig(@_);
    if ($self->has_phyid) {
        $ret[1] = $self->phyid.": enc/slot: ".$self->slot;
    } else {
        $ret[1] = "enc/slot: ".$self->slot;
    }
    return @ret;
};

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::SASIrcu::State;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::State';

1;

##################################################################
package StorageDisplay::Data::RAID::LSI::SASIrcu::State::RaidDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::RAID::RaidDevice';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Data::RAID - Handle RAID data for StorageDisplay

=head1 VERSION

version 2.06

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

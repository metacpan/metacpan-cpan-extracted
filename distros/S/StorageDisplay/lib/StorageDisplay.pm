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
use 5.14.0;

package StorageDisplay;
# ABSTRACT: Collect and display storages on linux machines

our $VERSION = '2.05'; # VERSION

## Main object

use Moose;
use namespace::sweep;
use Carp;
use StorageDisplay::Block;
use StorageDisplay::Data::Root;
use StorageDisplay::Data::Partition;
use StorageDisplay::Data::LVM;
use StorageDisplay::Data::RAID;
use StorageDisplay::Data::LUKS;
use StorageDisplay::Data::FS;
use StorageDisplay::Data::Libvirt;
use StorageDisplay::Data::Loop;

has 'blocks' => (
    is       => 'ro',
    isa      => 'HashRef[StorageDisplay::Block]',
    traits   => [ 'Hash' ],
    default  => sub { return {}; },
    lazy     => 1,
    handles  => {
	'addBlock'  => 'set',
	    'has_block' => 'exists',
	    '_block'     => 'get',
            'allBlocks' => 'values'
    },
    );

has 'blocksRoot' => (
    is     => 'ro',
    isa    => 'StorageDisplay::BlockTreeElement',
    lazy   => 1,
    builder => '_loadAllBlocks',
    );

has 'infos' => (
    is     => 'ro',
    isa    => 'HashRef',
    required => 1,
    traits   => [ 'Hash' ],
#    handles  => {
#	'get_info'  => 'get',
#    }
    );

sub get_info {
    my $self = shift ;
    my @keys=@_;

    my $infos=$self->infos;

    while (defined(my $k = shift @keys)) {
        return if not defined($infos->{$k});
        $infos = $infos->{$k};
    }
    return $infos;
}

#has 'connect' => (
#    is       => 'ro',
#    isa      => 'StorageDisplay::Connect',
#    required => 0,
#    );

sub _allocateBlock {
    my $self=shift;
    my $name=shift;
    my $alloc=shift;

    if (! $self->has_block($name)) {
        my $block=$alloc->();
        foreach my $n ($block->names_str()) {
            if ($self->has_block($n)) {
                print STDERR "W: duplicate block name '$n' for ".$block->name.
                    " and ".$self->_block($n)->name."\n";
            } else {
                #print STDERR "I: in $self Registering block name '$n' for ".$block->name."\n";
            }
            $self->addBlock($n, $block);
        }
    }
    return $self->_block($name);
}

sub systemBlock {
    my $self=shift;
    my $name=shift;

    return $self->_allocateBlock(
        $name, sub {
            return StorageDisplay::Block::System->new(
                $name,
                $self);
        });
}

sub block {
    my $self=shift;
    my $name=shift;

    if ($name =~m,^/dev/(.*)$,) {
        $name=$1;
    }
    return $self->_allocateBlock(
        $name, sub {
            return StorageDisplay::Block::NoSystem->new(
                'name' => $name,
                );
        });
}

sub blockBySerial {
    my $self=shift;
    my $serial=shift;

    foreach my $block ($self->allBlocks()) {
        #print STDERR "  Testing ", ($block->name), "\n";
        if (($block->blk_info('SERIAL')//'') eq $serial) {
            return $block;
        }
        if (($block->udev_info('ID_SCSI_SERIAL')//'') eq $serial) {
            return $block;
        }
        # WWN is not always unique :-(
        #$serial =~ s/^0x//;
        #if (($block->blk_info('WWN')//'') eq $serial) {
        #    return $block;
        #}
        #if (($block->blk_info('WWN')//'') eq '0x'.$serial) {
        #    return $block;
        #}
    }
    #print STDERR "$serial not found in $self\n";
    return;
}

sub _loadAllBlocks {
    my $self=shift;

    my $blocks=$self->get_info('lsblk-hierarchy');

    my $handle_bloc;
    $handle_bloc = sub {
        my $jcur = shift;
        my $bparent = shift;
        my @children = (@{$jcur->{'children'}//[]});
        #print STDERR Dumper($jcur);
        my $bcur = $self->systemBlock($jcur->{'kname'});
        $bparent->addChild($bcur);
        foreach my $jchild (@children) {
            my $bchild = $handle_bloc->($jchild, $bcur);
        }
        return $bcur;
    };

    my $root=StorageDisplay::BlockTreeElement->new('name' => 'Root');

    foreach my $b (values %$blocks) {
        $handle_bloc->($b, $root);
    }
    return $root;
}

sub dumpBlocks {
    my $self = shift;

    foreach my $b ($self->allBlocks) {
        print $b->name, "\n";
    }
}

sub _log {
    my $self = shift;
    my $opts = shift;
    my $info = shift;

    if (ref($info) =~ /^HASH/) {
        $opts = { %{$opts}, %{$info} };
        $info = shift;
    }

    print STDERR $opts->{type}, ': ', ('  'x$opts->{level}), $info, "\n";
    foreach my $line (@_) {
        print STDERR '   ', ('  'x$opts->{level}), $line, "\n";
    }
}


sub log {
    my $self = shift;

    return $self->_log(
        {
            'level' => 0,
                'type' => 'I',
                'verbose' => 1,
        }, @_);
}

sub warn {
    my $self = shift;

    return $self->_log(
        {
            'level' => 0,
                'type' => 'W',
                'verbose' => 1,
        }, @_);
}

sub error {
    my $self = shift;

    return $self->_log(
        {
            'level' => 0,
                'type' => 'E',
                'verbose' => 1,
        }, @_);
}

###################
has '_providedBlocks' => (
    is       => 'ro',
    isa      => 'HashRef[StorageDisplay::Data::Elem]',
    traits   => [ 'Hash' ],
    default  => sub { return {}; },
    lazy     => 1,
    handles  => {
	'_addProvidedBlock' => 'set',
            '_provideBlock' => 'exists',
    }
    );

has 'elemsRoot' => (
    is       => 'ro',
    isa      => 'StorageDisplay::Data::Root',
    default  => sub {
	my $self = shift;
        return StorageDisplay::Data::Root->new(
	    $self->get_info('hostname'));
    },
    lazy     => 1,
    );

sub _registerElement {
    my $self = shift;
    my $elem = shift;
    my @providedBlockNames = map {
        StorageDisplay::Block::asname($_)
    } $elem->allProvidedBlocks;

    foreach my $bn (@providedBlockNames) {
        if ($self->provide($bn)) {
            carp "Duplicate provider for $bn";
            return 0;
        }
    }
    foreach my $bn (@providedBlockNames) {
        $self->_addProvidedBlock($bn, $elem);
    }
    #use Data::Dumper;
    #print STDERR Dumper($elem);
    #print STDERR $elem->isa("StorageDisplay::Data::Elem"), " DONE\n";
    $self->elemsRoot->addChild($elem);
    return 1;
}

sub provide {
    my $self = shift;
    my $block = shift;
    my $blockname = StorageDisplay::Block::asname($block);

    return $self->_provideBlock($blockname);
}

sub createElems {
    my $self = shift;
    $self->blocksRoot();
    my $root=$self->elemsRoot;
    $self->removeVMsPartitions;
    $self->createPartitionTables($root);
    $self->createLVMs($root);
    $self->createLUKSs($root);
    $self->createMDs($root);
    $self->createLSIMegaclis($root);
    $self->createLSISASIrcus($root);
    $self->createFSs($root);
    $self->createVMs($root);
    $self->createLoops($root);
    # Must be last, to avoid to create already existing disks
    $self->createEmptyDisks($root);
    $self->computeUsedBlocks;
}

sub removeVMsPartitions {
    my $self = shift;
    my $partitions = $self->get_info('partitions')//{};
    my $vms = $self->get_info('libvirt')//{};
    my $vmblocks={};
    $self->log("Removing partitions of virtual machines disks");
    foreach my $vm (values %$vms) {
        foreach my $bname (keys %{$vm->{blocks}//{}}) {
            my $b = $self->block($bname);
            foreach my $n ($b->names_str) {
                $vmblocks->{$n} = $vm->{name}//1;
            }
        }
    }
    foreach my $p (keys %$partitions) {
        my $b = $self->block($p);
        if (exists($vmblocks->{$b->name})) {
            $self->log({level=>1}, "Removing ".$b->dname." (in VM ".$vmblocks->{$b->name}.")");
            delete($partitions->{$p});
        }
    }
}

sub createPartitionTables {
    my $self = shift;
    my $root = shift;
    $self->log("Creating partition tables");
    if (defined($self->get_info('partitions'))) {
	foreach my $p (sort keys %{$self->get_info('partitions')}) {
	    next if defined($self->get_info('partitions', $p, 'dos-extended'));
	    $self->createPartitionTable($root, $p);
	}
    }
}

sub createPartitionTable {
    my $self = shift;
    my $root = shift;
    my $dev = shift;

    my $block = $self->block($dev);
    my $elem;

    my $pttype = $block->blk_info("PTTYPE");
    $pttype //= $self->get_info('partitions', $dev, 'type');
    if (! defined($pttype)) {
        $self->error("Unkown partition table for ".$block->name);
	return;
    }

    if ($pttype eq "gpt") {
        $elem = $root->newChild('Partition::GPT', $block, $self, @_);
    } elsif ($pttype eq "dos" || $pttype eq "msdos") {
        $elem = $root->newChild('Partition::MSDOS', $block, $self, @_);
    } else {
        $self->warn("Unknown partition type ".$pttype." for ".$block->name);
        return;
    }
    if (!$self->_registerElement($elem)) {
        $self->error("Cannot register partition table for ".$block->name);
        return;
    }
}

sub createEmptyDisks {
    my $self = shift;
    my $root = shift;

    $self->log("Creating disks without partitions");
    if (defined($self->get_info('disks-no-part'))) {
	foreach my $p (sort keys %{$self->get_info('disks-no-part')}) {
	    $self->createEmptyDisk($root, $p);
	}
    }
}

sub createEmptyDisk {
    my $self = shift;
    my $root = shift;
    my $dev = shift;

    my $block = $self->block($dev);
    my $elem;

    if ($block->provided) {
        $self->log("  skipping $dev already created");
        return;
    }

    $elem = $root->newChild('Partition::None', $block, $self, @_);
    if (!$self->_registerElement($elem)) {
        $self->error("Cannot register empty disk for ".$block->name);
        return;
    }
}

sub createLVMs {
    my $self = shift;
    my $root = shift;

    $self->log('Creating LVM volume groups');
    for my $vgname (sort keys %{$self->get_info('lvm') // {}}) {
        my $elem;
        if ($vgname eq '') {
            $elem = $root->newChild('LVM::UnassignedPVs', $vgname, $self);
        } else {
            $elem = $root->newChild('LVM::VG', $vgname, $self);
        }
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register LVM vg ".$vgname);
            return;
        }
    }
}

sub createLUKSs {
    my $self = shift;
    my $root = shift;

    $self->log("Creating LUKS devices");
    for my $devname (sort keys %{$self->get_info('luks') // {}}) {
        my $elem = $root->newChild('LUKS', $devname, $self);
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register LUKS device ".$devname);
            return;
        }
    }
}

sub createMDs {
    my $self = shift;
    my $root = shift;

    $self->log("Creating MD devices");
    for my $devname (sort keys %{$self->get_info('md') // {}}) {
        my $elem;
        if ($self->get_info('md')->{$devname}->{'raid-container'} // 0 eq 1) {
            $elem = $root->newChild('RAID::MD::Container', $devname, $self);
        } else {
            $elem = $root->newChild('RAID::MD', $devname, $self);
        }
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register MD device ".$devname);
            return;
        }
    }
}

sub createLSIMegaclis {
    my $self = shift;
    my $root = shift;

    $self->log("Creating Megacli controllers");
    for my $cnum (sort keys %{$self->get_info('lsi-megacli') // {}}) {
        my $elem = $root->newChild('RAID::LSI::Megacli', $cnum, $self);
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register Megacli controller #".$cnum);
            return;
        }
    }
}

sub createLSISASIrcus {
    my $self = shift;
    my $root = shift;

    $self->log("Creating SAS LSI controllers");
    for my $cnum (sort keys %{$self->get_info('lsi-sas-ircu') // {}}) {
        my $elem = $root->newChild('RAID::LSI::SASIrcu', $cnum, $self);
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register SAS LSI controller #".$cnum);
            return;
        }
    }
}

sub createFSs {
    my $self = shift;
    my $root = shift;

    my $elem = $root->newChild('FS', $self);
    if (!$self->_registerElement($elem)) {
        print STDERR "Cannot register FS\n";
        return;
    }
    return $elem;
}

sub createVMs {
    my $self = shift;
    my $root = shift;

    my $elem = $root->newChild('Libvirt', $self);
    if (!$self->_registerElement($elem)) {
        print STDERR "Cannot register Libvirt\n";
        return;
    }
    return $elem;
}

sub createLoops {
    my $self = shift;
    my $root = shift;

    $self->log("Creating Loop devices");
    for my $loop (sort keys %{$self->get_info('loops') // {}}) {
        my $elem = $root->newChild('Loop', $loop, $self);
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register loop device ".$loop);
            return;
        }
    }
}

sub computeUsedBlocks {
    my $self = shift;

    my $it = $self->elemsRoot->iterator(recurse => 1);
    while (defined(my $e=$it->next)) {
        my @blocks = grep {
            $_->provided
        } $e->consumedBlocks;

        if (scalar(@blocks)>0) {
            foreach my $block (@blocks) {
                $block->state("used");
                #print STDERR "Block ", $block->name, " used due to ", $e->name, "\n";
            }
        }
        #else {
        #    print STDERR "No providers for ",
        #        join(",",
        #             (map { $_->name } $e->consumedBlocks)), "\n";
        #}
    }

}

sub display {
    my $self = shift;
    print join("\n", $self->dotNode), "\n";
}

has '_mountpoints' => (
    is       => 'ro',
    isa      => 'HashRef[Num]',
    traits   => [ 'Hash' ],
    required => 1,
    lazy     => 1,
    builder  => '_compute_mp',
    handles  => {
	'has_mp' => 'exists',
	    'fs_mountpoint_blockname'     => 'get',
	    'fs_mountpoint_id'     => 'get',
    },
    );

sub _compute_mp {
    my $self = shift;

    my $st = $self;
    my $allfs = $st->get_info('fs', 'hierarchy');
    my $flatfs = $st->get_info('fs', 'flatfull');
    my $mp = {};
    my $comp_rec;
    $comp_rec = sub {
	my $node = shift;
	my $parent = shift;
	if (not defined($flatfs->{$node->{id}})) {
	    $self->warn($node->{id}.' not defined');
	} elsif (not defined($flatfs->{$node->{id}}->{parent})) {
	    $flatfs->{$node->{id}}->{parent} = $parent;
	} elsif ($flatfs->{$node->{id}}->{parent} != $parent) {
	    $self->warn('FS: wrong parent for '.$node->{target}
			.' got: '.$flatfs->{$node->{id}}->{parent}
			.' expects: '.$parent);
	}
	if ($parent != 1) {
	    push @{$flatfs->{$parent}->{children}}, $node->{id};
	}
	$mp->{$node->{target}} = $node->{id};
	if (exists($node->{children})) {
	    for my $child (@{$node->{children}}) {
		$comp_rec->($child, $node->{id});
	    }
	}
    };
    $comp_rec->($allfs, 1);
    return $mp;
}

around 'fs_mountpoint_blockname' => sub {
    my $orig = shift;
    my $self = shift;
    my $mountpoint = shift;

    # must return an unique (per machine) fake blockname
    # for the provided mount point
    if (not $self->has_mp($mountpoint)) {
	$self->warn("No mountpoint for $mountpoint");
	return 'FS@-1@'.$mountpoint;
    }
    my $id = $self->$orig($mountpoint, @_);

    return $self->fs_mountpoint_blockname_by_id($id, $mountpoint);
};

sub fs_mountpoint_blockname_by_id {
    my $self = shift;
    my $id = shift;
    my $mp = shift;

    my $target = $self->get_info('fs', 'flatfull', $id)->{target};

    if (defined($mp) and not ($target eq $mp)) {
	$self->warn("Bad mountpoint: got $mp, expects $target");
    }

    return 'FS@'.$id.'@'.$target;
}

sub fs_swap_blockname {
    # must return an unique (per machine) fake blockname
    # for the provided device/file swap
    my $self = shift;
    my $swappath = shift;

    return 'FS@SWAP@'.$swappath;
}

# FIXME: to remove when StorageDisplay will be a StorageDisplay::Data::Elem
sub pushDotText {
    my $self = shift;
    my $text = shift;
    my $t = shift // "\t";

    my @pushed = map { $t.$_ } @_;
    push @{$text}, @pushed;
}

sub dotNode {
    my $self = shift;
    my $t = shift // "\t";
    my @text = map { $_." // HEADER: MACHINE"} (
        'digraph "'.$self->elemsRoot->host.'"{',
        $t."rankdir=LR;",
    );
    $self->pushDotText(\@text, $t, $self->elemsRoot->dotNode("$t"));
    push @text, "} // FOOTER: MACHINE";

    return @text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay - Collect and display storages on linux machines

=head1 VERSION

version 2.05

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2020 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package StorageDisplay;
# ABSTRACT: Collect and display storages on linux machines

our $VERSION = '1.0.4'; # VERSION

1;

package StorageDisplay::Moose::Cached;

use Carp;

our %orig_has;  # save original 'has' sub routines here

sub import {
    my $callpkg = caller 0;
    {
        no strict 'refs'; ## no critic
        no warnings 'redefine';
        $orig_has{$callpkg} = *{$callpkg."::has"}{CODE};
        *{$callpkg."::has"} = \&cached_has;
    }
    return;
}

sub cached_has {
    my ($attr, %args) = @_;

    my $callpkg = caller 0;
    if (exists $args{cached_hash} ) {
        my $compute = $args{compute};
        my $type = $args{cached_hash};
        croak "'compute' attribute required" if not exists  $args{compute};
        my $cache_set = '_cached_set_'.$attr;
        my $cache_has = '_cached_has_'.$attr;
        my $cache_get = '_cached_get_'.$attr;
        $args{handles}->{$cache_set} = 'set';
        $args{handles}->{$cache_has} = 'exists';
        $args{handles}->{$cache_get} = 'get';
        %args = (
            is       => 'bare',
            required => 1,
            default  => sub { return {}; },
            lazy     => 1,
            init_arg => undef, # prevent from being set by constructor
            %args,
            traits   => [ 'Hash' ],
            isa      => "HashRef[$type]",
        );
        delete $args{cached_hash};
        delete $args{compute};
        #print STDERR "My cached arg $attr\n";
        $callpkg->meta->add_method(
            $attr => sub {
                my $self = shift;
                my $name = shift;

                if ($self->$cache_has($name)) {
                    return $self->$cache_get($name);
                }
                my $elem = $compute->($self, $name, @_);
                if (defined($elem)) {
                    $self->$cache_set($name, $elem);
                }
                return $elem;

            });
    }
    $orig_has{$callpkg}->($attr, %args);
}

BEGIN {
    # Mark current package as loaded;
    my $p = __PACKAGE__;
    $p =~ s,::,/,g;
    chomp(my $cwd = `pwd`);
    $INC{$p.'.pm'} = $cwd.'/'.__FILE__;#k"current file";
}

1;

##################################################################
package StorageDisplay::Role::Iterable;

use MooseX::Role::Parameterized;

use Carp;

parameter iterable => (
    isa      => 'Str',
    required => 1,
    );

role {
    my $p = shift;

    my $iterable = $p->iterable;
    my $iterator = $iterable.'::Iterator';
    my $iteratorframe = $iterator.'::Frame';

    has 'name' => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
        );

    has '_parents' => (
        traits   => [ 'Hash' ],
        is       => 'ro',
        isa      => "HashRef[$iterable]",
        required => 1,
        default  => sub { return {}; },
        handles  => {
            '_add_parents' => 'set',
                'hasParent' => 'exists',
                '_getParent' => 'get',
        }
        );

    has '_parents_tab' => (
        traits   => [ 'Array' ],
        is       => 'ro',
        isa      => "ArrayRef[$iterable]",
        required => 1,
        default  => sub { return []; },
        handles  => {
            '_add_parents_tab' => 'push',
                'parents' => 'elements',
        }
        );

    method "_addParent" => sub {
        my $self = shift;
        my $parent = shift;
        my $parent_name = $parent->name;
        if ($self->hasParent($parent_name)) {
            if ($parent != $self->_getParent($parent_name)) {
                croak "Two different parents with name $parent_name for ".$self->name;
            }
        } else {
            $self->_add_parents($parent_name, $parent);
            $self->_add_parents_tab($parent);
        }
    };

    has '_children' => (
        traits   => [ 'Hash' ],
        is       => 'ro',
        isa      => "HashRef[$iterable]",
        required => 1,
        default  => sub { return {}; },
        handles  => {
            '_addChild' => 'set',
                'hasChild' => 'exists',
                '_getChild' => 'get',
        }
        );

    has '_children_tab' => (
        traits   => [ 'Array' ],
        is       => 'ro',
        isa      => "ArrayRef[$iterable]",
        required => 1,
        default  => sub { return []; },
        handles  => {
        '_addChild_tab' => 'push',
            'children' => 'elements',
        }
        );

    method "addChild" => sub {
        my $self = shift;
        my $child = shift;
        my $child_name = $child->name;
        if ($self->hasChild($child_name)) {
            if ($child != $self->_getChild($child_name)) {
                croak "Two different children with name $child_name for ".$self->name;
            }
        } else {
            $self->_addChild($child_name, $child);
            $self->_addChild_tab($child);
        }
        $child->_addParent($self);
        return $child;
    };

    method "iterator" => sub {
        my $self = shift;

        return "$iterator"->new(
            $self,
            @_,
            );
    };
    ######################################################
    ######################################################
    # ::Iterator class
    my $iteratorclass = Moose::Meta::Class->create(
        $iterator,
        #attributes => [],
        #roles => [],
        #methods => {},
        superclasses => ["Moose::Object"],
        );

    $iteratorclass->add_attribute(
        'recurse' => (
            is  => 'ro',
            isa => 'Bool',
            required => 1,
            default => 1,
        ));
    $iteratorclass->add_attribute(
        'with-self' => (
            is  => 'bare',
            reader => 'with_self',
            isa => 'Bool',
            required => 1,
            default => 0,
        ));
    $iteratorclass->add_attribute(
        '_seen' => (
            traits => [ 'Hash' ],
            is  => 'ro',
            isa => 'HashRef[Bool]',
            required => 1,
            default => sub { return {}; },
            handles  => {
                '_found' => 'exists',
                    '_mark' => 'set',
            }
        ));
    $iteratorclass->add_attribute(
        'uniq' => (
            is  => 'ro',
            isa => 'Bool',
            required => 1,
            default => 0,
        ));
    $iteratorclass->add_attribute(
        'postfix' => (
            is => 'ro',
            isa => 'Bool',
            required => 1,
            default => 0,
        ));
    $iteratorclass->add_attribute(
        '_stack_frame' => (
            traits => [ 'Array' ],
            is  => 'ro',
            isa => "ArrayRef[$iteratorframe]",
            required => 1,
            default => sub { return []; },
            handles  => {
                '_push_frame' => 'push',
                    '_pop_frame' => 'pop',
            }
        ));
    $iteratorclass->add_attribute(
        '_init_block' => (
            is  => 'ro',
            isa => $iterable,
            required => 1,
        ));
    $iteratorclass->add_attribute(
        '_cur_frame' => (
            is  => 'rw',
            isa => "Maybe[$iteratorframe]",
            required => 1,
            lazy => 1,
            default => sub {
                my $self = shift;
                return $iteratorframe->new(
                    $self->_init_block,
                    $self,
                    );
            },
        ));
    $iteratorclass->add_attribute(
        '_next_computed' => (
            is  => 'rw',
            isa => 'Bool',
            required => 0,
            default => 0,
        ));
    $iteratorclass->add_attribute(
        '_next' => (
            is  => 'rw',
            isa => "Maybe[$iterable]",
            required => 0,
            default => undef,
        ));
    $iteratorclass->add_method(
        'has_next' => sub {
            my $self = shift;
            if (! $self->_next_computed) {
                $self->_compute_next;
            }
            return defined($self->_next);
        });
    $iteratorclass->add_method(
        'next' => sub {
            my $self = shift;
            if (! $self->_next_computed) {
                $self->_compute_next;
            }
            $self->_next_computed(0);
            return $self->_next;
        });
    $iteratorclass->add_attribute(
        'filter' => (
            traits  => ['Code'],
            is      => 'ro',
            isa     => 'CodeRef',
            default => sub {
                sub { 1; }
            },
            handles => {
                do_filter => 'execute',
            },
        ));
    $iteratorclass->add_method(
        '_compute_next' => sub {
            my $self = shift;

            $self->_next_computed(1);
            if (!defined($self->_cur_frame)) {
                $self->_next(undef);
                return;
            }
            #print STDERR "****\nBegin compute: ", $self->_cur_frame->dump, "\n";
            do {
                do {
                    my $n = $self->_cur_frame->next_child;
                    while (! defined($n)) {
                        # nothing more in this frame. Poping it.
                        my $cur_frame = $self->_cur_frame;
                        $self->_cur_frame($self->_pop_frame);
                        if ($self->postfix) {
                            $n=$cur_frame->current;
                            #print STDERR "Poping frame and found: ", $n->name, "\n";
                            if ($n == $self->_init_block) {
                                $self->_next(undef);
                                return;
                            }
                            $self->_next($n);
                            $n=undef;
                            last;
                        } else {
                            if (!defined($self->_cur_frame)) {
                                $self->_next(undef);
                                return;
                            }
                            #print STDERR "Poping frame: ", $self->_cur_frame->dump, "\n";
                            $n = $self->_cur_frame->next_child;
                        }
                    }
                    while (defined($n)) {
                        # $n : next in _cur_frame
                        my @children = ($n->children);
                        if (! $self->recurse || scalar(@children) == 0) {
                            # no children for current node (or no recursion), just using it and go
                            $self->_next($n);
                            #print STDERR "Found no children: ", $n->name, "\n";
                            last;
                        } else {
                            # Building new frame
                            my $new_frame = $iteratorframe->new(
                                $n,
                                $self,
                                );
                            #print STDERR "Building new frame: ", $new_frame->dump, "\n";
                            $self->_push_frame($self->_cur_frame);
                            $self->_cur_frame($new_frame);
                            if (! $self->postfix) {
                                $self->_next($n);
                                last;
                            } else {
                                $n = $new_frame->next_child;
                            }
                        }
                    }
                } while ($self->uniq && $self->_found($self->_next));
                $self->_mark($self->_next, 1);
                #FIXME# if not a real bloc, accept it
                #last if not $self->_next->isa($iterable);
            } while (
                ($self->with_self || $self->_next != $self->_init_block)
                && !$self->do_filter($self->_next)
                );


            #if ($self->has_next) {
            #    print STDERR "Found: ", $self->_next->name, "\n";
            #}
            #use Data::Dumper;
            #$Data::Dumper::Maxdepth = 3;
            #print STDERR Dumper($self);
        });
    $iteratorclass->add_around_method_modifier(
        'BUILDARGS' => sub {
            my $orig  = shift;
            my $class = shift;
            my $init_block = shift;
            my %args = (@_);

            $args{'_init_block'}=$init_block;
            return $class->$orig(
                %args,
                );
        });
    ######################################################
    ######################################################
    # ::Iterator::Frame class
    my $iteratorframeclass = Moose::Meta::Class->create(
        $iteratorframe,
        #attributes => [],
        #roles => [],
        #methods => {},
        superclasses => ["Moose::Object"],
        );
    $iteratorframeclass->add_attribute(
        'current' => (
            is  => 'ro',
            isa => $iterable,
            required => 1,
        ));
    $iteratorframeclass->add_attribute(
        '_children' => (
            traits => [ 'Array' ],
            is  => 'ro',
            isa => "ArrayRef[$iterable]",
            required => 1,
            handles  => {
                'next_child' => 'shift',
                    '_all_children' => 'elements',
            }
        ));
    $iteratorframeclass->add_attribute(
        'it' => (
            is  => 'ro',
            isa => $iterator,
            required => 1,
        ));
    $iteratorframeclass->add_around_method_modifier(
        'BUILDARGS' => sub {
            my $orig  = shift;
            my $class = shift;
            my $current = shift;
            my $it = shift;

            return $class->$orig(
                'current' => $current,
                'it' => $it,
                '_children' => [ $current->children ],
                );
        });
};

##################################################################
package StorageDisplay;

## Main object

use Moose;
use namespace::sweep;
use Carp;

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

    my $block=$alloc->();
    foreach my $n ($block->names_str()) {
        if ($self->has_block($n)) {
            print STDERR "W: duplicate block name '$n' for ".$block->name.
                " and ".$self->_block($n)->name."\n";
        } else {
            #print STDERR "I: Registering block name '$n' for ".$block->name."\n";
        }
        $self->addBlock($n, $block);
    }
}

sub systemBlock {
    my $self=shift;
    my $name=shift;

    if (! $self->has_block($name)) {
        $self->_allocateBlock(
            $name, sub {
                return StorageDisplay::Block::System->new(
                    $name,
                    $self);
            });
    }
    return $self->_block($name);
}

sub block {
    my $self=shift;
    my $name=shift;

    if ($name =~m,^/dev/(.*)$,) {
        $name=$1;
    }
    if (! $self->has_block($name)) {
        $self->_allocateBlock(
            $name, sub {
                return StorageDisplay::Block::NoSystem->new(
                    'name' => $name,
                    );
            });
    }
    return $self->_block($name);
}

sub _loadAllBlocks {
    my $self=shift;

    use JSON::MaybeXS qw(decode_json);
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
    isa      => 'HashRef[StorageDisplay::Elem]',
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
    isa      => 'StorageDisplay::Root',
    default  => sub {
        return StorageDisplay::Root->new(); #FIXME add host
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
    #print STDERR $elem->isa("StorageDisplay::Elem"), " DONE\n";
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
    my $root=$self->blocksRoot();
    $self->removeVMsPartitions;
    $self->createPartitionTables;
    $self->createLVMs;
    $self->createLUKSs;
    $self->createMDs;
    $self->createLSIMegaclis;
    $self->createLSISASIrcus;
    $self->createFSs;
    $self->createVMs;
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
    $self->log("Creating partition tables");
    foreach my $p (sort keys %{$self->get_info('partitions')}) {
        next if defined($self->get_info('partitions', $p, 'dos-extended'));
        $self->createPartitionTable($p);
    }
}

sub createPartitionTable {
    my $self = shift;
    my $dev = shift;
    my $block = $self->block($dev);
    my $elem;

    if ($block->blk_info("PTTYPE") eq "gpt") {
        $elem = StorageDisplay::Partition::GPT->new($block, $self);
    } elsif ($block->blk_info("PTTYPE") eq "dos") {
        $elem = StorageDisplay::Partition::MSDOS->new($block, $self);
    } else {
        $self->warn("Unknown partition type ".$block->blk_info("PTTYPE")." for ".$block->name);
        return;
    }
    if (!$self->_registerElement($elem)) {
        $self->error("Cannot register partition table for ".$block->name);
        return;
    }
}

sub createLVMs {
    my $self = shift;
    $self->log('Creating LVM volume groups');
    for my $vgname (sort keys %{$self->get_info('lvm') // {}}) {
        my $elem;
        if ($vgname eq '') {
            $elem = StorageDisplay::LVM::OnlyPV->new($vgname, $self);
        } else {
            $elem = StorageDisplay::LVM->new($vgname, $self);
        }
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register LVM vg ".$vgname);
            return;
        }
    }
}

sub createLUKSs {
    my $self = shift;
    $self->log("Creating LUKS devices");
    for my $devname (sort keys %{$self->get_info('luks') // {}}) {
        my $elem = StorageDisplay::LUKS->new($devname, $self);
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register LUKS device ".$devname);
            return;
        }
    }
}

sub createMDs {
    my $self = shift;
    $self->log("Creating MD devices");
    for my $devname (sort keys %{$self->get_info('md') // {}}) {
        my $elem = StorageDisplay::RAID::MD->new($devname, $self);
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register MD device ".$devname);
            return;
        }
    }
}

sub createLSIMegaclis {
    my $self = shift;
    $self->log("Creating Megacli controllers");
    for my $cnum (sort keys %{$self->get_info('lsi-megacli') // {}}) {
        my $elem = StorageDisplay::RAID::LSI::Megacli->new($cnum, $self);
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register Megacli controller #".$cnum);
            return;
        }
    }
}

sub createLSISASIrcus {
    my $self = shift;
    $self->log("Creating SAS LSI controllers");
    for my $cnum (sort keys %{$self->get_info('lsi-sas-ircu') // {}}) {
        my $elem = StorageDisplay::RAID::LSI::SASIrcu->new($cnum, $self);
        if (!$self->_registerElement($elem)) {
            $self->error("Cannot register SAS LSI controller #".$cnum);
            return;
        }
    }
}

sub createFSs {
    my $self = shift;
    my $elem = StorageDisplay::FS->new($self);
    if (!$self->_registerElement($elem)) {
        print STDERR "Cannot register FS\n";
        return;
    }
}

sub createVMs {
    my $self = shift;
    my $elem = StorageDisplay::Libvirt->new($self);
    if (!$self->_registerElement($elem)) {
        print STDERR "Cannot register Libvirt\n";
        return;
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
            }
        }
    }

}

sub display {
    my $self = shift;
    print join("\n", $self->dotNode), "\n";
}

sub dotNode {
    my $self = shift;
    return $self->elemsRoot->dotNode("\t");
}

1;

##################################################################
package StorageDisplay::Role::HasBlock;

use Moose::Role;

has 'block' => (
    is       => 'ro',
    isa      => 'StorageDisplay::Block',
    required => 1,
    );

1;

##################################################################
package StorageDisplay::Role::Style::Base;

use Moose::Role;

1;

##################################################################
package StorageDisplay::Role::Style::Base::Elem;

use Moose::Role;

use Carp;

sub dotJoinStyle {
    my $self = shift;
    my $t = shift // "\t";

    return join(';', grep { defined($_) } @_);
}

sub dotIndent {
    my $self = shift;
    my $t = shift // "\t";

    return map { $t.$_ } @_;
}

sub dotLabel {
    my $self = shift;
    return ($self->_dotDefaultLabel(@_));
}

sub dotFullLabel {
    my $self = shift;
    return $self->_dotDefaultFullLabel(@_);
}

sub dotNode {
    my $self = shift;
    #print STDERR "dotNode in ".__PACKAGE__." for ".$self->name."\n";
    return $self->_dotDefaultNode(@_);
}

sub dotStyleNode {
    my $self = shift;
    return $self->_dotDefaultStyleNode(@_);
}

sub dotStyleNodeState {
    my $self = shift;

    return $self->_dotDefaultStyleNodeState;
}

sub dotFormatedFullLabel {
    my $self = shift;
    my $t = shift;

    return join($self->_dotLabelNL,
                $self->dotFullLabel);
}

# default implementations

# will be overrided when a Table is generated
sub _dotTableLabel {
    my $self = shift;
    return $self->dotFormatedFullLabel(@_);
}

sub _dotDefaultLabel {
    my $self = shift;
    return ($self->name);
}

sub _dotDefaultStyleNodeState {
    my $self = shift;

    return ();
}

sub _dotDefaultStyleNode {
    my $self = shift;
    my @style = grep { $_ !~ m/[node]/ } $self->dotStyle(@_);

    push @style, $self->dotStyleNodeState(@_);
    return @style;
}

sub _dotLabelNL {
    my $self = shift;
    return '\n';
}

# will be overrided with Size, Used, Free infos
sub _dotDefaultFullLabel {
    my $self = shift;

    return ($self->dotLabel(@_));
}

# will be overrided for HTML
sub _dotDefaultLabelLine {
    my $self = shift;
    my @label = $self->dotFormatedFullLabel(@_);
    confess "Multiline formated label!" if scalar(@label) > 1;
    return 'label="";' if scalar(@label) == 0;

    return ('label="'.$label[0].'";');
}

# will be overrided when another node kind is selected
sub _dotDefaultNode {
    my $self = shift;
    my $t = shift // "\t";

    #print STDERR "coucou2 from ".$self->name."\n";
    my @text = (
        "{ ".'"'.$self->name.'" [',
        $self->dotIndent(
            $t,
            $self->_dotDefaultLabelLine($t, @_),
            $self->dotStyleNode(),
        ),
        ']; }',
        );
    return @text;
}

1;

##################################################################
package StorageDisplay::Role::Style::Base::HTML;

use Moose::Role;

around '_dotLabelNL' => sub {
    my $orig = shift;
    my $self = shift;
    return '<BR/>';
};

around '_dotDefaultLabelLine' => sub {
    my $orig = shift;
    my $self = shift;
    my $t = shift;

    my @text=$self->dotIndent($t, $self->_dotTableLabel($t, @_));

    if (scalar(@text) == 0) {
        return ('label=<>;')
    }

    $text[0] =~ s/^\s+//;
    $text[0] = 'label=<'.$text[0];
    push @text, '>;';

    return @text;
};

1;

##################################################################
package StorageDisplay::Role::Style::IsLabel;

use Moose::Role;

with (
    'StorageDisplay::Role::Style::Base',
    );

around '_dotDefaultNode' => sub {
    my $orig = shift;
    my $self = shift;

    #print STDERR "coucou from ".$self->name."\n";
    return $self->_dotTableLabel(@_);
};

1;

##################################################################
package StorageDisplay::Role::Style::IsSubGraph;

use Moose::Role;

sub dotSubGraph {
    my $self = shift;
    return $self->_dotDefaultSubGraph(@_);
}

sub _dotDefaultSubGraph {
    my $self = shift;
    my $t = shift;

    my @text;
    my $it = $self->iterator(recurse => 0);
    while (defined(my $e = $it->next)) {
        push @text, $e->dotNode($t, @_);
    }
    return @text;
}

around '_dotDefaultNode' => sub {
    my $orig = shift;
    my $self = shift;
    my $t = shift // "\t";

    my @text = (
        'subgraph "cluster_'.$self->name.'" {',
        $self->dotIndent(
            $t,
            $self->dotStyle($t, @_),
            $self->dotSubGraph($t, @_),
            $self->_dotDefaultLabelLine($t, @_),
            $self->dotStyleNode(),
        ),
        '}',
        );
    return @text;
};

around '_dotDefaultStyleNode' => sub {
    my $orig = shift;
    my $self = shift;

    return ();
};

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::Label::HTML;

use Moose::Role;

with (
    'StorageDisplay::Role::Style::Base::HTML',
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::Label::HTML::Table;

use Moose::Role;

sub dotStyleTable {
    return '';
};

around '_dotTableLabel' => sub {
    my $orig = shift;
    my $self = shift;
    my $t = shift;
    my $it = $self->iterator(recurse => 0);

    return ('<TABLE '.$self->dotStyleTable(@_).'>',
            $self->dotIndent(
                $t,
                $self->dotTable($t, $it, @_),
            ),
            '</TABLE>',
        );
};

sub dotTable {
    my $self=shift;

    return $self->_dotDefaultTable(@_);
}

sub _dotDefaultTable {
    my $self=shift;
    my $t = shift;
    my $it = shift;

    my @text;
    while (defined(my $e = $it->next)) {
        push @text, '<TR><TD>',
            $self->dotIndent($t, $e->dotNode($t, @_)),
            '</TD></TR>'
    }

    return @text;
}

with (
    'StorageDisplay::Role::Style::Base::HTML',
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::Plain;

use Moose::Role;

sub dotStyle {
    my $orig  = shift;
    my $self = shift;

    return ( );
};

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::WithSize;

use Moose::Role;

has 'size' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    );

sub dotStyle {
    my $orig  = shift;
    my $self = shift;

    return (
        "style=filled;",
        "color=lightgrey;",
        "fillcolor=lightgrey;",
        "node [style=filled,color=lightgrey,fillcolor=lightgrey,shape=rectangle];",
        );
};

around '_dotDefaultFullLabel' => sub {
    my $orig  = shift;
    my $self = shift;

    return (
        $self->$orig(@_),
        "Size: ".$self->disp_size($self->size),
        );
};

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::WithFree;

use Moose::Role;

with 'StorageDisplay::Role::Style::WithSize';

has 'free' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    );

around _dotDefaultStyleNode => sub {
    my $orig  = shift;
    my $self = shift;

    my $fillcolor='"green"';
    if ($self->size != $self->free) {
        $fillcolor=
            '"pink;'.
                       sprintf("%f.2", ($self->size - $self->free) / $self->size).
                       ':green"';
    }

    return $self->dotJoinStyle(
        $self->$orig(@_),
        'shape=rectangle',
        'style=striped',
        'fillcolor='.$fillcolor,
        );
};

around '_dotDefaultFullLabel' => sub {
    my $orig  = shift;
    my $self = shift;

    return (
        $self->$orig(@_),
        "Free: ".$self->disp_size($self->free),
        );
};

1;

##################################################################
package StorageDisplay::Role::Style::WithUsed;

use Moose::Role;

with 'StorageDisplay::Role::Style::WithFree';

has 'used' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    );

sub dotStyle {
    my $orig  = shift;
    my $self = shift;

    return (
        "style=filled;",
        "color=lightgrey;",
        "fillcolor=lightgrey;",
        "node [style=filled,color=lightgrey,fillcolor=lightgrey,shape=rectangle];",
        );
};

around '_dotDefaultFullLabel' => sub {
    my $orig  = shift;
    my $self = shift;

    my $label = $self->$orig(@_);
    return (
        $self->$orig(@_),
        "Used: ".$self->disp_size($self->used),
        );
};

1;

##################################################################
package StorageDisplay::Role::Style::SubInternal;

use Moose::Role;

sub dotStyle {
    my $self = shift;
    my $t = shift // "\t";

    return (
		#"style=filled;",
		"color=white;",
		"fillcolor=white;",
		#"node [style=filled,color=lightgrey,fillcolor=lightgrey,shape=rectangle];",
        );
}

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::Grey;

use Moose::Role;

sub dotStyle {
    my $self = shift;
    my $t = shift // "\t";

    return (
        "style=filled;",
        "color=lightgrey;",
        "fillcolor=lightgrey;",
        "node [style=filled,color=white,fillcolor=lightgrey,shape=rectangle];",
        );
}

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::FromBlockState;

use Moose::Role;

sub _dotDefaultStyleNodeState {
    my $self = shift;

    my $state = "unknown";
    if (defined($self->block)) {
        $state = $self->block->state;
    }

    return 'fillcolor="'.$self->statecolor($state).'"';
}

##################################################################
##################################################################
package StorageDisplay::BlockTreeElement;

## Base package for block device DAG

use Moose;
use namespace::sweep;

use Carp;

with "StorageDisplay::Role::Iterable"
    => { iterable => "StorageDisplay::BlockTreeElement" };

sub dname {
    my $self;
    return $self->name;
}

1;

##################################################################
package StorageDisplay::Block;
use Moose;
use namespace::sweep;

extends 'StorageDisplay::BlockTreeElement';

use Path::Class::Dir;

use Carp;

has 'names' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[Path::Class::Dir]',
    required => 1,
    handles  => {
        'addname' => 'set',
        'names_str' => 'keys',
    }
    );

has 'path' => (
    is       => 'rw',
    isa      => 'Path::Class::Dir',
    required => 1,
    );

has 'state' => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'unknown',
    lazy     => 1,
    );

has 'elem' => (
    is       => 'ro',
    isa      => 'StorageDisplay::Elem',
    writer   => '_elem',
    required => 0,
    );

sub provided {
    my $self = shift;

    return defined($self->elem);
}

sub providedBy {
    my $self = shift;
    my $elem = shift;
    my $name = shift;

    if ($self->provided) {
        croak "Duplicate provider for ".$self->name.": ".$self->elem." and ".$elem;
    }
    $self->_elem($elem);
}

sub dname {
    my $self = shift;
    my $best_name=$self->name;
    my $score = 0;
    #print STDERR "name for ", $self->name, "\n";
    #use Data::Dumper;
    #print STDERR Dumper($self->names), "\n";
     foreach my $n ($self->names_str) {
        my $s=0;
        if ($n =~ m,^disk/,) {
            $s = 20;
        } elsif ($n =~ m,^dm-,) {
            $s = 30;
        } elsif ($n =~ m,^mapper/,) {
            $s = 40;
        } elsif ($n =~ m,/,) {
            $s = 60;
        } else {
            $s = 50;
        }
        if ($s > $score) {
            #print STDERR "  prefer ", $n, "\n";
            $score = $s;
            $best_name = $n;
        }
    }

    return '/dev/'.
         $best_name;
}

has 'size' => (
    is => 'rw',
    isa => 'Int',
    default => -1,
    );

## function, not method
sub asname {
    my $block = shift;
    my $blockname;

    if (blessed($block) && $block->isa("StorageDisplay::BlockTreeElement")) {
        $blockname = $block->name;
    } else {
        $blockname = $block;
    }
    return $blockname;
}

##################################################################
package StorageDisplay::Block::NoSystem;
use Moose;
use namespace::sweep;

extends 'StorageDisplay::Block';

has 'parent' => (
    is       => 'ro',
    isa      => 'StorageDisplay::Block',
    required => 0,
    );

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    );

has 'dname' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

use Carp;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args = (@_);

    my $name = $args{'name'} // $args{'parent'}->name.'@'.$args{'id'};

    my $dname = $args{'name'} // $args{'parent'}->dname.'@'.$args{'id'};

    return $class->$orig(
        'name' => $name,
        'dname' => $dname,
        'names' => { $name => Path::Class::Dir->new() },
        'path' => Path::Class::Dir->new(),
        %args,
        );
};

##################################################################
package StorageDisplay::Block::System;
use Moose;
use namespace::sweep;
use JSON::MaybeXS qw(decode_json);

extends 'StorageDisplay::Block';

use Carp;

has '_blk_infos' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => [ 'Hash' ],
    required => 1,
    handles  => {
        'blk_info' => 'get',
    }
    );
has '_udev_infos' => (
    is       => 'ro',
    isa      => 'HashRef[Str]',
    traits   => [ 'Hash' ],
    required => 1,
    handles  => {
        'udev_info' => 'get',
    }
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $name = shift;
    my $st = shift;
    my $blk_info = $st->get_info('lsblk', $name);
    my %args;

    if ( @_ != 0 || ref $name ) {
        croak "Invalid call to new";
    }
    my $f;

    my $udev_info = $st->get_info('udev', $name);
    foreach my $k (keys %{$udev_info}) {
        if ($k eq 'path') {
            $args{$k}=Path::Class::Dir->new($udev_info->{$k});
        } elsif ($k eq 'names') {
            $args{$k} = { map { $_ => Path::Class::Dir->new($_) } @{$udev_info->{$k}} };
        } else {
            $args{$k}=$udev_info->{$k};
        }
    }

    if (defined($blk_info)) {
        my %hash;
        %hash = map {
            if (defined($blk_info->{$_})) {
                uc $_ => $blk_info->{$_}
            } else {
                ()
            }
        } keys %$blk_info;
        $args{'_blk_infos'}=\%hash;
    } else {
        croak "coucou";
    }

    return $class->$orig(
        %args,
        );
};

##################################################################
##################################################################
##################################################################

##################################################################
package StorageDisplay::Elem;

use Moose;
use namespace::sweep;

use Object::ID;

with (
    "StorageDisplay::Role::Iterable"
    => { iterable => "StorageDisplay::Elem" },
    "StorageDisplay::Role::Style::Base::Elem"
    );

has 'consume' => (
    is       => 'ro',
    isa      => 'ArrayRef[StorageDisplay::Block]',
    traits   => [ 'Array' ],
    default  => sub { return []; },
    lazy     => 1,
    handles  => {
	'consumeBlock' => 'push',
            'consumedBlocks' => 'elements',
    }
    );

has 'provide' => (
    is       => 'ro',
    isa      => 'ArrayRef[StorageDisplay::Block]',
    traits   => [ 'Array' ],
    default  => sub { return []; },
    lazy     => 1,
    handles  => {
	'provideBlock' => 'push',
            'allProvidedBlocks' => 'elements',
    },
    init_arg => undef,
    );

around 'provideBlock' => sub {
      my $orig = shift;
      my $self = shift;

      for my $b (@_) {
          $b->providedBy($self);
      }
      return $self->$orig(@_);
  };

has 'label' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => "NO LABEL",
    );

sub disp_size {
    my $self = shift;
    my $size = shift;
    my $unit = 'B';
    my $d=2;

    {
        use bigint;
        my $divide = 1;
        if ($size >= 1024) { $unit = 'kiB'; }
        if ($size >= 1048576) { $unit = 'MiB'; $divide *= 1024; }
        if ($size >= 1073741824) { $unit = 'GiB'; $divide *= 1024; }
        if ($size >= 1099511627776) { $unit = 'TiB'; $divide *= 1024; }
        if ($size >= 1125899906842624) { $unit = 'PiB'; $divide *= 1024; }
        if ($size >= 1152921504606846976) { $unit = 'EiB'; $divide *= 1024; }

        if ($unit eq 'B') {
            return "$size B";
        } else {
            $size /= $divide;
        }
        $size = $size * 1000 / 1024;
        if ($size >= 10000) { $d = 1;}
        if ($size >= 100000) { $d = 0;}
    }
    return sprintf("%.$d"."f $unit", $size/1000);
}

sub statecolor {
    my $self = shift;
    my $state = shift;

    if ($state eq "free") {
        return "green";
    } elsif ($state eq "ok") {
        return "green";
    } elsif ($state eq "used") {
        return "yellow";
    } elsif ($state eq "busy") {
        return "pink";
    } elsif ($state eq "unused") {
        return "white";
    } elsif ($state eq "unknown") {
        return "lightgrey";
    } elsif ($state eq "special") {
        return "mediumorchid1";
    } elsif ($state eq "warning") {
        return "orange";
    } elsif ($state eq "error") {
        return "red";
    } else {
        return "red";
    }
}

sub dname {
    my $self = shift;
    return $self->name;
}

sub linkname {
    my $self = shift;
    return '"'.$self->name.'"';
}

sub pushDotText {
    my $self = shift;
    my $text = shift;
    my $t = shift // "\t";

    my @pushed = map { $t.$_ } @_;
    push @{$text}, @pushed;
}

sub dotSubNodes {
    my $self = shift;
    my $t = shift // "\t";
    my @text=();
    my $it = $self->iterator(recurse => 0);
    while (defined(my $e=$it->next)) {
        push @text, $e->dotNode($t);
    }
    return @text;
}

sub dotLinks {
    my $self = shift;
    return ();
}

1;

###################################################################
#################################################################
package StorageDisplay::Root;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

sub dotNode {
    my $self = shift;

    my $t = shift // "\t";
    my @text = (
        'digraph "'.$self->host.'"{',
        $t."rankdir=LR;",
        );

    my @subnodes=$self->dotSubNodes($t);
    $self->pushDotText(\@text, $t,
                       $self->dotSubNodes($t));

    my $it = $self->iterator(recurse => 1);
    while (defined(my $e=$it->next)) {
        my @links = $e->dotLinks($t);
        if (scalar(@links)>0) {
            $self->pushDotText(
                \@text, $t,
                '// Links from '.$e->dname,
                $e->dotLinks($t, @_),
                );
        }
    }
    $it = $self->iterator(recurse => 1);
    while (defined(my $e=$it->next)) {
        my @blocks = grep {
            $_->provided
        } $e->consumedBlocks;

        if (scalar(@blocks)>0) {
            $self->pushDotText(
                \@text, $t,
                '// Links for '.$e->dname,
                (map { $_->elem->linkname.' -> '.$e->linkname } @blocks),
                );
        }
    }
    push @text, "}";
    return @text;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $host = shift // 'machine';

    return $class->$orig(
        'name' => '@'.$host,
        'host' =>  $host,
        @_
        );
};

###################################################################
#################################################################
package StorageDisplay::Partition;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::Label::HTML::Table',
    'StorageDisplay::Role::Style::WithSize',
    );

sub disk {
    my $self = shift;
    return $self->block(@_);
}

has 'kind' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $block = shift;
    my $st = shift;

    $st->log({level=>1}, 'Partition table on '.$block->dname);

    return $class->$orig(
        'name' => '@Part: '.$block->name,
        'part_infos' => $st->get_info('partitions', $block->name),
        'block' => $block,
        'consume' => [$block],
        @_
        );
};

has 'table' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Partition::Table',
    required => 1,
    default  => sub {
        my $self = shift;
        return $self->addChild(
            StorageDisplay::Partition::Table->new(
                'name' => $self->name.'@@table',
                'partition' => $self,
            ));
    },
    lazy => 1,
    );

sub dotStyleNode {
    my $self=shift;
    my $t=shift;

    my $fc='';
    my $it = $self->table->iterator(
        recurse => 1,
        filter => sub {
            my $part = shift;
            return ! $part->isa('StorageDisplay::Partition::Table::Part::SubTable');
        },
        );
    while (defined(my $part = $it->next)) {
        my $state="free";
        if (! $part->isa("StorageDisplay::Partition::Table::Part::Free")) {
            $state = "busy";#$part->block->state;
        }
        my $color=$self->statecolor($state);
        $fc .= ':' if $fc ne '';
        $fc .= "$color;".sprintf("%.6f", $part->size/$self->size);
    }
    return (
        $self->_dotDefaultStyleNode($t, @_),
        "// Style node",
        "color=white;",
        "fillcolor=lightgrey;",
        'shape="rectangle";',
        #'gradientangle="270";',
        'style=striped;',
        'fillcolor="'.$fc.'";',
        );
}

sub dotStyleTable {
    my $self=shift;

    return "BORDER=\"0\" CELLPADDING=\"0\" CELLSPACING=\"0\"";
}

sub dotLabel {
    my $self = shift;
    return (
        $self->disk->dname,
        'Label: '.$self->kind,
        );
}

sub dotTable {
    my $self = shift;
    my $t = shift // "\t";
    my $it = shift;

    my @tablecontents = (
        "<TR> <TD COLSPAN=\"2\">".$self->label."</TD> </TR>".
        "<TR><TD >".$self->dotFormatedFullLabel($t, @_)."</TD>".
        "    <TD BGCOLOR=\"lightgrey\">",
        $self->table->dotNode($t, @_),
        "</TD> </TR>".
        "<TR> <TD COLSPAN=\"2\"> </TD> </TR>");

    return @tablecontents;
}

1;

##################
package StorageDisplay::Partition::Table;

use Moose;
use namespace::sweep;

use Carp;

extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::Style::IsLabel',
    'StorageDisplay::Role::Style::Label::HTML::Table',
    );

has 'disk' => (
    is       => 'ro',
    isa      => 'StorageDisplay::Block',
    default  => sub {
        my $self = shift;
        return $self->elem->disk;
    },
    lazy     => 1,
    required => 1,
    );

has 'partition' => (
    is       => 'ro',
    isa      => 'StorageDisplay::Partition',
    required => 1,
    );

sub elem {
    my $self = shift;
    return $self->partition(@_);
}

sub addPart {
    my $self = shift;
    my $part = shift;

    if ($part->isa('StorageDisplay::Partition::Table::Part::SubTable')) {
        $part->block->state("special");
    } elsif ($part->isa('StorageDisplay::Partition::Table::Part::Data')) {
        if ($part->label =~ /efi|grub/i || $part->flags =~ /boot/i) {
            $part->block->state("special");
        }
    } elsif ($part->isa('StorageDisplay::Partition::Table::Part::Free')) {

    } else {
        carp "W: unsupported part ".$part->name." (".$part.")\n";
    }
    return $self->addChild($part);
}

sub dotTable {
    my $self = shift;
    return $self->partDotTable(@_);
}

sub partDotTable {
    my $self = shift;
    my $t = shift;
    my $it = shift;

    my @text;
    #print STDERR "dotTable in ".$self->name." (".$self.")\n";
    while (defined(my $e = $it->next)) {
        push @text, '<TR>',
            $self->dotIndent($t, $e->dotNode($t, @_)),
            '</TR>';
    }
    #use Data::Dumper;
    #print STDERR "RES: ", Dumper(\@text);
    return @text;
}

1;

##################
package StorageDisplay::Partition::Table::Part;

use Moose;
use namespace::sweep;

extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::Style::Label::HTML',
    'StorageDisplay::Role::Style::IsLabel',
    'StorageDisplay::Role::Style::WithSize',
    );

has 'table' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Partition::Table',
    required => 1,
    );

has 'start' => (
    is    => 'ro',
    isa   => 'Int',
    required => 1,
    );

has 'label' => (
    is    => 'ro',
    isa   => 'Str',
    required => 0,
    );

sub BUILD {
    my $self = shift;

    #print STDERR "BUILD in ".__PACKAGE__."\n";
    $self->table->addPart($self);
}

sub partStyle {
    my $self = shift;

    return '';
}

sub dotNode {
    my $self = shift;
    return  (
        "<TD ".$self->partStyle(@_).">",
        $self->_dotDefaultNode(@_),
        "</TD>",
        );
}

1;

##################
package StorageDisplay::Partition::Table::Part::Data;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Partition::Table::Part';

has 'id' => (
    is    => 'ro',
    isa   => 'Int',
    required => 1,
    );

has 'flags' => (
    is    => 'ro',
    isa   => 'Str',
    required => 0,
    );


use Carp;
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $args = { @_ };

    my $block;

    #print STDERR "BUILDARGS in ".__PACKAGE__."\n";
    my $part_id = $args->{id};
    my $table = $args->{table};
    my $it = $table->disk->iterator(
        'recurse' => 0,
        'uniq' => 1,
        );
    while(defined(my $b=$it->next)) {
        # PARTN does not exists for kpartx mapped partitions
        my $num = $b->udev_info("ID_PART_ENTRY_NUMBER") // -1;
        next if $num != $part_id;
        $block = $b;
        last;
    }
    if (! defined($block)) {
        my $b = StorageDisplay::Block::NoSystem->new(
            'parent' => $table->disk,
            'id' => $part_id,
            );
        $block=$b;
    }

    return $class->$orig(
        'name' => $block->name,
        'block' => $block,
        %{$args},
        );
};

sub BUILD {
    my $self = shift;

    #print STDERR "BUILD in ".__PACKAGE__."\n";
    #print STDERR "Looking for ", $self->id, " into ", $self->table->disk->name, "\n";
    $self->provideBlock($self->block);
}

sub linkname {
    my $self = shift;

    return $self->table->elem->linkname.':"'.$self->id.'"';
}

sub partStyle {
    my $self = shift;

    my $state = "unknown";
    if (defined($self->block)) {
        $state = $self->block->state;
    }

    return 'PORT="'.$self->id.'"'.
        ' BGCOLOR="'.$self->statecolor($state).'"';
}

sub dotLabel {
    my $self = shift;
    my $dev;
    if (defined($self->block)) {
        $dev = $self->block->dname;
    } else {
        $dev = $self->name;
    }
    if ($self->label) {
        return ($dev, $self->label);
    } else {
        return $dev;
    }
}

with (
    'StorageDisplay::Role::HasBlock',
    );

1;

##################
package StorageDisplay::Partition::Table::Part::SubTable;

use Moose;
use namespace::sweep;

# keep Table::Part::Data first to pick its dotNode redefinition
extends
    'StorageDisplay::Partition::Table::Part::Data',
    'StorageDisplay::Partition::Table';

sub dotNode {
    my $self = shift;
    my $t = shift;
    #print STDERR "BUILD in ".__PACKAGE__."\n";
    return (
        '<TD>',
        $self->dotIndent(
            $t,
            '<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0"><TR>',
            '<TD '.$self->partStyle($t, @_).'>',
            #$self->dotLabel($t, @_),
            $self->dotFormatedFullLabel($t, @_),
            '</TD></TR><TR><TD>',
            $self->_dotDefaultNode(@_),
            '</TD></TR></TABLE>',
        ),
        '</TD>',
        );
}

sub dotTable {
    my $self = shift;
    return $self->partDotTable(@_);
}

with (
    'StorageDisplay::Role::Style::IsLabel',
    'StorageDisplay::Role::Style::Label::HTML::Table',
    );

1;

##################
package StorageDisplay::Partition::Table::Part::Free;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Partition::Table::Part';

sub block {
    my $self = shift;
    return
}

sub dotLabel {
    my $self = shift;
    return "Free";
}

sub partStyle {
    my $self = shift;
    return 'bgcolor="green"';
}

1;

##################################################################
package StorageDisplay::Partition::GPT;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Partition';

use Carp;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $block = shift;
    my $st = shift;

    return $class->$orig(
        $block,
        $st,
        'kind' => 'gpt',
        %{$st->get_info('partitions', $block->name) // {} }, # size, label, parts
        @_
        );
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    #print STDERR "Managing ".$self->disk->dname." (".($self->disk).")\n";

    my $id_free = 1;

    foreach my $part (@{$args->{'parts'}}) {
        #print STDERR "*******************\n";

        if ($part->{kind} eq 'free') {
            delete($part->{kind});
            StorageDisplay::Partition::Table::Part::Free->new(
                'name' => $self->name.'@@Free@'.$id_free,
                'table' => $self->table,
                %{$part},
                );
            $id_free ++;
        } elsif ($part->{kind} eq 'part') {
            delete($part->{kind});
            StorageDisplay::Partition::Table::Part::Data->new(
                'table' => $self->table,
                %{$part},
                );
        } else {
            use Data::Dumper;
            print STDERR Dumper($part);
            croak "ARghh for ".$self->disk->dname;
        }
    }
}

1;

##################################################################
package StorageDisplay::Partition::MSDOS;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Partition';

use Carp;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $block = shift;
    my $st = shift;

    my $info = $st->get_info('partitions', $block->name) // {};

    return $class->$orig(
        $block,
        $st,
        'kind' => 'msdos',
        (map { $_ => $info->{$_} } ("size", "label", "parts")),
        'extended_num' => $info->{'extended'},
        @_
        );
};

has 'extended' => (
    is    => 'rw',
    isa   => 'StorageDisplay::Partition::Table',
    required => 0,
    );

sub BUILD {
    my $self = shift;
    my $args = shift;

    my $extended = $args->{'extended_num'} // '';
    my $id_free = 1;

    foreach my $part (@{$args->{'parts'}}) {
        if ($part->{kind} eq 'free') {
            delete($part->{kind});
            StorageDisplay::Partition::Table::Part::Free->new(
                'name' => $self->name.'@@Free@'.$id_free,
                'table' => $self->table,
                %{$part},
                );
            $id_free ++;
        } elsif ($part->{kind} eq 'part') {
            delete($part->{kind});
            if ($part->{id} eq $extended) {
                $self->extended(
                    StorageDisplay::Partition::Table::Part::SubTable->new(
                        'table' => $self->table,
                        'partition' => $self,
                        %{$part},
                    ));
            } elsif ($part->{id} <= 4) {
                StorageDisplay::Partition::Table::Part::Data->new(
                    'table' => $self->table,
                    %{$part},
                    );
            } else {
                confess if not defined($self->extended);
                StorageDisplay::Partition::Table::Part::Data->new(
                    'table' => $self->extended,
                    %{$part},
                    );
            }
        } else {
            croak "ARghh";
        }
    }
}

1;

##################################################################
##################################################################
package StorageDisplay::LVM::Group;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

with ('StorageDisplay::Role::Style::IsSubGraph');

has 'vg' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Block',
    required => 1,
    );

has 'pvs' => (
    is    => 'ro',
    isa   => 'StorageDisplay::LVM::PVs::Base',
    writer => '_pvs',
    required => 0,
    );

sub dname {
    my $self=shift;
    return 'LVM VG: '.$self->name;
}

sub dotLabel {
    my $self = shift;
    return 'LVM: '.$self->name;
}

sub _xv {
    my $self = shift;
    my $kind = shift;
    my $name = shift;

    my $it = $self->$kind->iterator(recurse => 0);
    while (defined(my $e=$it->next)) {
        return $e if $e->lvmname eq $name;
    }
    print STDERR "E: no $kind with name $name\n";
    return;
}

use StorageDisplay::Moose::Cached;

has 'pv' => (
    cached_hash => "StorageDisplay::LVM::PV",
    compute => sub {
        my $self = shift;
        my $name = shift;
        return $self->_xv("pvs", $name);
    },
    );

##################################################################
package StorageDisplay::LVM::OnlyPV;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LVM::Group';

with (
    'StorageDisplay::Role::Style::Grey',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vgname = shift;
    my $st = shift;

    $st->log({level=>1}, 'Unassigned PVs');

    my $vgblock = StorageDisplay::Block::NoSystem->new(
        'name' => '@LVM@UnassignedPVs',
        );

    my $info = $st->get_info('lvm', $vgname);

    return $class->$orig(
        'name' => 'Unassigned PVs',
        'vg' => $vgblock,
        'consume' => [],
        'lvm-info' => $info,
        'st' => $st,
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    $self->_pvs(StorageDisplay::LVM::OnlyPV::PVs->new($self, $st, $args->{'lvm-info'}));
    $self->addChild($self->pvs);
    return $self;
};

1;

##################################################################
package StorageDisplay::LVM;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LVM::Group';

with (
    'StorageDisplay::Role::Style::WithFree',
    );

has 'lvs' => (
    is    => 'ro',
    isa   => 'StorageDisplay::LVM::LVs',
    writer => '_lvs',
    required => 0,
    );

has '_pv_lv_links' => (
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => "ArrayRef",
    required => 1,
    default  => sub { return []; },
    handles  => {
        '_add_link' => 'push',
            'internal_links' => 'elements',
    }
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vgname = shift;
    my $st = shift;

    $st->log({level=>1}, 'VG '.$vgname);

    my $vgblock = StorageDisplay::Block::NoSystem->new(
        'name' => $vgname,
        );

    my $info = $st->get_info('lvm', $vgname);

    return $class->$orig(
        'name' => $vgname,
        'vg' => $vgblock,
        'consume' => [],
        'lvm-info' => $info,
        'st' => $st,
        'size' => ($info->{'vgs-vg'}->{'vg_size'} =~ s/B$//r),
        'free' => ($info->{'vgs-vg'}->{'vg_free'} =~ s/B$//r),
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    $self->_pvs(StorageDisplay::LVM::PVs->new($self, $st, $args->{'lvm-info'}));
    $self->addChild($self->pvs);
    if ($args->{'name'} ne '') {
        #print STDERR "name: ", $args->{'name'}, "\n";
        $self->_lvs(StorageDisplay::LVM::LVs->new($self, $st, $args->{'lvm-info'}));
        $self->addChild($self->lvs);
        my $links = $args->{'lvm-info'}->{'pvs'};
        foreach my $l (@{$links}) {
            if ($l->{segtype} ne "free"
                && $l->{lv_role} ne "private,pool,spare"
                && $l->{lv_role} ne "private,thin,pool,metadata"
                && $l->{lv_role} ne "private,thin,pool,data") {
                $self->_add_link({pv => $l->{pv_name},
                                  lv => $l->{lv_name}});
            }
        }
    }
    return $self;
};

use StorageDisplay::Moose::Cached;

has 'lv' => (
    cached_hash => "StorageDisplay::LVM::LV",
    compute => sub {
        my $self = shift;
        my $name = shift;
        return $self->_xv("lvs", $name);
    },
    );

sub dotLinks {
    my $self = shift;
    return map {
        $self->pv($_->{pv})->linkname.' -> '.$self->lv($_->{lv})->linkname
    } $self->internal_links;
}

1;

##################################################################
package StorageDisplay::LVM::Elem;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

has 'vg' => (
    is    => 'ro',
    isa   => 'StorageDisplay::LVM::Group',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vg = shift;
    my $st = shift;
    my $info = shift;

    return $class->$orig(
        'vg' => $vg,
        'st' => $st,
        'lvm-info' => $info,
        @_
        );
};

1;

##################################################################
package StorageDisplay::LVM::PVs::Base;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LVM::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::SubInternal',
    );

1;

##################################################################
package StorageDisplay::LVM::PVs;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LVM::PVs::Base';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vg = shift;

    return $class->$orig(
        $vg,
        @_,
        'name' => join('@', $vg->name,"PV"),
        'consume' => [],
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my @pvnames = sort keys %{$args->{'lvm-info'}->{'vgs-pv'}};
    if (scalar(@pvnames) == 0) {
        # PV without a VG
        @pvnames = map { $_->{'pv_name'} } @{$args->{'lvm-info'}->{'pvs'}};
    }
    foreach my $pv_name (sort keys %{$args->{'lvm-info'}->{'vgs-pv'}}) {
        $self->addChild(
            StorageDisplay::LVM::PV->new(
                $pv_name, $self->vg, $args->{st}, $args->{'lvm-info'}
            ));
    }
    return $self;
};

sub dotLabel {
    my $self = shift;
    return ($self->vg->name.'\'s PVs');
}

1;

##################################################################
package StorageDisplay::LVM::OnlyPV::PVs;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LVM::PVs::Base';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vg = shift;

    return $class->$orig(
        $vg,
        @_,
        'name' => join('@', $vg->name,"PV"),
        'consume' => [],
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    foreach my $pv_name (sort map { $_->{'pv_name'} } @{$args->{'lvm-info'}->{'pvs'}}) {
        $self->addChild(
            StorageDisplay::LVM::PV->new(
                $pv_name, $self->vg, $args->{st}, $args->{'lvm-info'}
            ));
    }
    return $self;
};

sub dotLabel {
    my $self = shift;
    return ();
}

1;

##################################################################
package StorageDisplay::LVM::LVs;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LVM::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::SubInternal',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vg = shift;

    return $class->$orig(
        $vg,
        @_,
        'name' => join('@', $vg->name,"LV"),
        'consume' => [],
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;

    foreach my $lv_name (sort keys %{$args->{'lvm-info'}->{'vgs-lv'}}) {
        $self->addChild(
            StorageDisplay::LVM::LV->new(
                $lv_name, $self->vg, $args->{st}, $args->{'lvm-info'}
            ));
    }
    return $self;
};

sub dotLabel {
    my $self = shift;
    return ($self->vg->name.'\'s LVs');
}
1;

##################################################################
package StorageDisplay::LVM::XV;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LVM::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    );

has 'lvmname' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vg = shift;
    my $st = shift;
    my $info = shift;
    my $lvmname = shift;
    my $block = shift;

    return $class->$orig(
        $vg, $st, $info,
        'lvmname' => $lvmname,
        'block' => $block,
        @_
        );
};

1;

##################################################################
package StorageDisplay::LVM::PV;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LVM::XV';

with (
    'StorageDisplay::Role::Style::WithUsed',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $pvblockname = shift;
    my $vg = shift;
    my $st = shift;
    my $info = shift;

    my $pvblock = $st->block($pvblockname);

    my $pvinfo = $info->{'vgs-pv'}->{$pvblockname};

    if (not defined($pvinfo)) {
        # only PV, no assigned VG
        my @pv = grep { $_->{'pv_name'} eq $pvblockname } @{$info->{'pvs'}};
        $pvinfo = $pv[0];
    }

    return $class->$orig(
        $vg, $st, $info, $pvblockname, $pvblock,
        'name' => join('@', 'LVM', $vg->name,"PV",$pvblock->name),
        'consume' => [$pvblock],
        'size' => ($pvinfo->{'pv_size'} =~ s/B$//r),
        'free' => ($pvinfo->{'pv_free'} =~ s/B$//r),
        'used' => ($pvinfo->{'pv_used'} =~ s/B$//r),
        @_
        );
};

sub dotLabel {
    my $self = shift;
    return ('PV: '.$self->block->dname);
}

1;

##################################################################
package StorageDisplay::LVM::LV;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LVM::XV';

with (
    'StorageDisplay::Role::Style::WithSize',
    'StorageDisplay::Role::Style::FromBlockState',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $lvname = shift;
    my $vg = shift;
    my $st = shift;
    my $info = shift;

    my $lvblock = $st->block($vg->name.'/'.$lvname);

    my $lvinfo = $info->{'vgs-lv'}->{$lvname};

    return $class->$orig(
        $vg, $st, $info, $lvname, $lvblock,
        'name' => $lvblock->name,
        'consume' => [],
         'size' => ($lvinfo->{'lv_size'} =~ s/B$//r),
        @_
        );
};

sub BUILD {
    my $self = shift;
    $self->provideBlock($self->block);
}

sub dotLabel {
    my $self = shift;
    return ('LV: '.$self->lvmname);
}

1;

##################################################################
##################################################################
package StorageDisplay::FS;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::Grey',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $st = shift;

    $st->log('Creating FS');
    my $info = $st->get_info('fs')//{};

    return $class->$orig(
        'name' => '@FS',
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
        $self->addChild(
            StorageDisplay::FS::FS->new($dev, $st, $fs),
            );
    }
}

sub dotLabel {
    my $self = shift;
    return "Mounted FS and swap";
}

1;

##################################################################
package StorageDisplay::FS::FS;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

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

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $dev = shift;
    my $st = shift;
    my $fs = shift;

    my $block = $st->block($dev);
    $st->log({level=>1}, ($fs->{mountpoint}//$dev));

    my $name = '@FS@'.($fs->{mountpoint}//$block->name);

    return $class->$orig(
        'name' => $name,
        'consume' => [$block],
        'provide' => $st->block($name),
        'st' => $st,
        'block' => $block,
        %{$fs},
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    $self->provideBlock($args->{'provide'});
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
##################################################################
package StorageDisplay::LUKS;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::Grey',
    );

has 'encrypted' => (
    is    => 'ro',
    isa   => 'StorageDisplay::LUKS::Encrypted',
    writer => '_encrypted',
    required => 0,
    );

has 'decrypted' => (
    is    => 'ro',
    isa   => 'StorageDisplay::LUKS::Decrypted',
    writer => '_decrypted',
    required => 0,
    );

has 'luks_version' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $devname = shift;
    my $st = shift;

    #$st->get_infos
    $st->log({level=>1}, 'LUKS for device '.$devname);

    my $info = $st->get_info('luks', $devname);
    my $block = $st->block($devname);

    return $class->$orig(
        'name' => join('@','@LUKS',$block->name),
        'block' => $block,
        'consume' => [],
        'st' => $st,
        'luks-info' => $info,
        'luks_version' => $info->{VERSION},
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    $self->_encrypted(StorageDisplay::LUKS::Encrypted->new($self, $st, $args->{'luks-info'}));
    $self->addChild($self->encrypted);
    if (defined($args->{'luks-info'}->{decrypted})) {
        $self->_decrypted(StorageDisplay::LUKS::Decrypted::Present->
                          new($self, $st, $args->{'luks-info'}));
    } else {
        $self->_decrypted(StorageDisplay::LUKS::Decrypted::None->
                          new($self, $st, $args->{'luks-info'}));
    }
    $self->addChild($self->decrypted);
    return $self;
};

sub dname {
    my $self=shift;
    return 'LUKS: '.$self->block->dname;
}

sub dotLabel {
    my $self = shift;
    return (
        $self->block->dname,
        'LUKS version '.$self->luks_version,
        );
}

sub dotLinks {
    my $self = shift;
    return (
        $self->encrypted->linkname.' -> '.$self->decrypted->linkname
    );
}

1;

##################################################################
package StorageDisplay::LUKS::Encrypted;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::WithSize',
    'StorageDisplay::Role::Style::FromBlockState',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $luks = shift;
    my $st = shift;
    my $info = shift;

    my $block = $luks->block;

    return $class->$orig(
        'name' => join('@', $luks->name, $block->name),
        'consume' => [$block],
        'block' => $block,
        'size' => $st->get_info('lsblk', $block->name, 'size'),
        @_,
        );
};

sub dotLabel {
    my $self = shift;
    return ($self->block->dname);
}

1;

##################################################################
package StorageDisplay::LUKS::Decrypted;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

1;

##################################################################
package StorageDisplay::LUKS::Decrypted::Present;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LUKS::Decrypted';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::WithSize',
    'StorageDisplay::Role::Style::FromBlockState',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $luks = shift;
    my $st = shift;
    my $info = shift;

    my $block = $st->block($info->{'decrypted'}//($luks->name."none"));

    return $class->$orig(
        'name' => $block->name,
        'consume' => [],
        'block' => $block,
        'size' => $st->get_info('lsblk', $block->name, 'size'),
        @_,
        );
};

sub BUILD {
    my $self = shift;
    $self->provideBlock($self->block);
}

sub dotLabel {
    my $self = shift;
    return ($self->block->dname);
}

1;

##################################################################
package StorageDisplay::LUKS::Decrypted::None;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::LUKS::Decrypted';

with (
    'StorageDisplay::Role::Style::Plain',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $luks = shift;
    my $st = shift;
    my $info = shift;

    return $class->$orig(
        'name' => $luks->name."@@",
        'consume' => [],
        @_,
        );
};

sub BUILD {
    my $self = shift;
}

sub dotLabel {
    my $self = shift;
    return ('Not decrypted');
}

1;

##################################################################
##################################################################
package StorageDisplay::RAID;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::Grey',
    );

has '_devices' => (
    traits   => [ 'Array' ],
    is    => 'ro',
    isa   => 'ArrayRef[StorageDisplay::RAID::Device]',
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
    isa   => 'ArrayRef[StorageDisplay::RAID::RaidDevice]',
    required => 1,
    default  => sub { return []; },
    handles  => {
        '_add_raid_device' => 'push',
            'raid_devices' => 'elements',
    }
    );

around '_add_raid_device' => sub {
    my $orig  = shift;
    my $self = shift;
    my $raid_device = shift;
    my $state = shift;
    die "Invalid state" if $state->raid_device != $raid_device;
    $raid_device->_state($state);
    $self->addChild($state);
    return $self->$orig($raid_device);
};



1;

###########################################################################
package StorageDisplay::RAID::Elem;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

has 'raid' => (
    is    => 'ro',
    isa   => 'StorageDisplay::RAID',
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
package StorageDisplay::RAID::State;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID::Elem';

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
    isa   => 'StorageDisplay::RAID::RaidDevice',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $raid_device = shift;
    my $st = shift;

    return $class->$orig(
        $raid_device->raid, $st,
        'name' => join('@@',$raid_device->name,'state'),
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
package StorageDisplay::RAID::RaidDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::FromBlockState',
    'StorageDisplay::Role::Style::WithSize',
    );

has 'state' => (
    is    => 'ro',
    isa   => 'StorageDisplay::RAID::State',
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
package StorageDisplay::RAID::Device;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::Plain',
    );

has 'state' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
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

    my $block = $st->block($devname);

    return $class->$orig(
        $raid, $st,
        'block' => $block,
        'name' => join('@dev@',$raid->name,$block->name),
        'consume' => [$block],
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

    if ($state =~ /active|Online, Spun Up|OPT/i) {
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

    return (
        $self->raiddevice.': '.$self->block->dname,
        $self->state,
        );
}

1;

###########################################################################
package StorageDisplay::RAID::RawDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID::Device';
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
package StorageDisplay::RAID::MD;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID';

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
        'name' => join('@','@MD',$block->name),
        'block' => $block,
        'consume' => [],
        'st' => $st,
        %{$info},
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    my $raid_device = StorageDisplay::RAID::RaidDevice->new($self, $st,
                                                            $self->block,
                                                            'raid-level' => $args->{'raid-level'},
                                                            'size' => $args->{'array-size'});
    my $state = StorageDisplay::RAID::State->new($raid_device, $st,
                                                 'state' => $args->{'raid-state'});
    $self->_add_raid_device($raid_device, $state);

    foreach my $dev (sort keys %{$args->{'devices'}}) {
        my $d = StorageDisplay::RAID::Device->new($self, $st, $dev, $args->{'devices'}->{$dev});
        $self->_add_device($d);
        $self->addChild($d);
    }

    return $self;
};

has 'used-dev-size' => (
    is    => 'ro',
    isa   => 'Int',
    required => 1,
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
    return (
        $self->raid_name,
        $self->disp_size($self->used_dev_size).' used per device',
        );
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
package StorageDisplay::RAID::LSI::Megacli::RaidDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID::RaidDevice';

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


##################################################################
package StorageDisplay::RAID::LSI::Megacli::BBU::Status;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID::Elem';

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
        'name' => join('@@',$raid->name,'BBUStatus'),
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
package StorageDisplay::RAID::LSI::Megacli;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID';

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
    isa   => 'HashRef[StorageDisplay::RAID::RaidDevice]',
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
        'name' => join('@','@LSIMegacli',$controller),
        'controller' => $controller,
        'consume' => [],
        'st' => $st,
        %{$info->{'Controller'}->{'c'.$controller}},
        %{$info},
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    #my $state = StorageDisplay::RAID::State->new($self, $st,
    #                                             'state' => $args->{'raid-state'});
    #$self->addChild($state);

    #$self->_add_raid_device(StorageDisplay::RAID::RaidDevice->new($self, $st,
    #                                                              $self->block,
    #                                                              $state,
    #                                                              'size' => $args->{'array-size'}));
    my $cid = $self->controller;

    #use Data::Dumper;
    #print STDERR Dumper($st);
    $self->addChild(StorageDisplay::RAID::LSI::Megacli::BBU::Status->new(
                        $self, $st, 'status' => $args->{'BBU'}));

    use bignum qw/hex/;
    foreach my $dev (sort { $a->{'LSI ID'} <=> $b->{'LSI ID'} }
                     (values %{$args->{'Disk'}})) {
	my $devname = $dev->{'Path'} // '';
        my $devpath = 'LSIMegaCli@'.$dev->{'Slot ID'};
        if ($dev->{'ID'} !~ /^c[0-9]+uXpY$/) {
            $devpath = 'LSIMegaCli@'.$dev->{'ID'};
        }
	my $block;
	my @block;
	if ($devname ne '' && $devname ne 'N/A') {
		$block = $st->block($devname);
		@block = ('block' => $block);
	}
        my $d = StorageDisplay::RAID::RawDevice->new(
            $self, $st, $devpath, $dev,
            'raiddevice' => $dev->{'ID'},
            'state' => $dev->{'Status'},
            'model' => $dev->{'Drive Model'},
            'slot' => $dev->{'Slot ID'},
            'size' => (hex($dev->{'# sectors'}) * ($dev->{'sector size'} // 512))->numify(),
	    @block,
            );
        $self->_add_device($d);
        $self->addChild($d);
	if ($block) {
		$d->provideBlock($block);
	}
    }
    foreach my $dev (sort { $a->{'ID'} cmp $b->{'ID'} }
                     (values %{$args->{'Array'}})) {
        my $devname = $dev->{'OS Path'};
        my $block = $st->block($devname);
        my $raid_device = StorageDisplay::RAID::LSI::Megacli::RaidDevice->new(
            $self, $st, $block,
            'size' => $block->blk_info("SIZE"),
            'raid-level' => $dev->{'Type'},
            %{$dev},
            );
        my %inprogress=();
        if ($dev->{'InProgress'} ne 'None') {
            %inprogress=('extra-info' => $dev->{'InProgress'});
        }
        my $state = StorageDisplay::RAID::State->new($raid_device, $st,
                                                     'state' => $dev->{'Status'},
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
package StorageDisplay::RAID::LSI::SASIrcu::RawDevice;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID::RawDevice';

with (
    'StorageDisplay::Role::Style::WithSize',
    );

has 'volume' => (
    is       => 'rw',
    isa      => 'StorageDisplay::RAID::RaidDevice',
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
package StorageDisplay::RAID::LSI::SASIrcu;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::RAID';

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
    isa   => 'HashRef[StorageDisplay::RAID::RawDevice]',
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
        'name' => join('@','@LSISASIrcu',$controller),
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
    foreach my $dev (sort { $a->{'enclosure'} <=> $b->{'enclosure'}
                            or $a->{'slot'} <=> $b->{'slot'}
                     }
                     @{$args->{'devices'}}) {
        my $id=$dev->{'enclosure'}.":".$dev->{'slot'};
        my $devpath = 'LSISASIrcu@'.$id;
        my $d = StorageDisplay::RAID::LSI::SASIrcu::RawDevice->new(
            $self, $st, $devpath, $dev,
            'raiddevice' => $id,
            'state' => $dev->{'state'},
            'model' => join(' ', $dev->{'manufacturer'}, $dev->{'model-number'}, $dev->{'serial-no'}),
            'size' => $dev->{'size'},
            'slot' => $id,
            );
        $self->_add_device($d);
        $self->addChild($d);
        $self->_add_named_raw_device($id, $d);
    }
    foreach my $dev (sort { $a->{'id'} cmp $b->{'id'} }
                     @{$args->{'volumes'}}) {
        my $devname = $args->{'wwid'}->{$dev->{'wwid'}};
        my $block = $st->block($devname);
        my $raid_device = StorageDisplay::RAID::RaidDevice->new(
            $self, $st, $block,
            'size' => $block->blk_info("SIZE"),
            'raid-level' => $dev->{'Type'},
            %{$dev},
            );
        my $state = StorageDisplay::RAID::State->new($raid_device, $st,
                                                     'state' => $dev->{'status'});

        $self->_add_raid_device($raid_device, $state);
        foreach my $phyid (keys %{$dev->{'PHY'} // {}}) {
            my $phy = $dev->{'PHY'}->{$phyid};
            my $id = $phy->{'enclosure'}.":".$phy->{'slot'};
            my $rdsk = $self->raw_device($id);
            $rdsk->volume($raid_device);
            $rdsk->phyid($phyid);
        }
    }

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
##################################################################
package StorageDisplay::Libvirt;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::Grey',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $st = shift;

    #$st->get_infos
    $st->log('Creating libvirt virtual machines');

    my $info = $st->get_info('libvirt');

    return $class->$orig(
        'name' => '@libvirt',
        'consume' => [],
        'st' => $st,
        'vms' => [ sort keys %{$info} ],
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    foreach my $vm (@{$args->{'vms'}}) {
        my $d = StorageDisplay::Libvirt::VM->new($self, $st, $vm);
        $self->addChild($d);
    }

    return $self;
};

sub dname {
    my $self=shift;
    return 'Libvirt Virtual Machines';
}

sub dotLabel {
    my $self = shift;
    return 'Libvirt Virtual Machines';
}

1;

##################################################################
package StorageDisplay::Libvirt::VM;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::SubInternal',
    );

has 'vmname' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

has 'state' => (
    is    => 'ro',
    isa   => 'Maybe[Str]',
    required => 1,
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $parent = shift;
    my $st = shift;
    my $vm = shift;

    my $vminfo = $st->get_info('libvirt', $vm) // {};

    $st->log({level=>1}, $vm);

    return $class->$orig(
        @_,
        'name' => join('@', $parent->name,$vm),
        'vmname' => $vm,
        'consume' => [],
        'st' => $st,
        'vm-info' => $vminfo,
        'state' => $vminfo->{state},
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $blocks=$args->{'vm-info'}->{'blocks'} // {};

    foreach my $disk (sort keys %{$blocks}) {
        $self->addChild(
            StorageDisplay::Libvirt::VM::Block->new(
                $self, $args->{'st'}, $disk, $blocks->{$disk}
            ));
    }
    return $self;
};

around 'dotStyleNode' => sub {
    my $orig = shift;
    my $self = shift;
    my @text = $self->$orig(@_);

    if ($self->state // '' eq 'running') {
        my $color = $self->statecolor('used');
        push @text, "fillcolor=$color";
    }

    return @text;
};

sub dotLabel {
    my $self = shift;
    return ($self->vmname);
}

1;

##################################################################
package StorageDisplay::Libvirt::VM::Block;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::Grey',
    );

has 'target' => (
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

has 'type' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    );

has 'vm' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Libvirt::VM',
    required => 1,
    );


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vm = shift;
    my $st = shift;
    my $bname = shift;
    my $binfo = shift;

    my $block = $st->block($bname);

    my @mountpoint;
    my $consumename=$bname;
    if ($binfo->{'type'} eq 'file') {
        my $mountpoint=$binfo->{'mount-point'};
        if (defined($mountpoint)) {
            @mountpoint=('mountpoint' => $mountpoint);
        }
        $consumename='@FS@'.($mountpoint // '@none@');
    }

    return $class->$orig(
        @_,
        'name' => join('@', $vm->name,$block->name),
        'block' => $block,
        'vm' => $vm,
        'consume' => [$st->block($consumename)],
        @mountpoint,
        'st' => $st,
        'target' => $binfo->{'target'},
        'type' => $binfo->{'type'},
        );
};

around 'dotStyleNode' => sub {
    my $orig = shift;
    my $self = shift;
    my @text = $self->$orig(@_);

    for my $i (1) { # just to be able to call 'last'
        if ($self->type ne 'block') {
            my $color = $self->statecolor('special');
            if ($self->type eq 'file') {
                if ($self->has_mountpoint) {
                    last;
                }
            }
            push @text, "fillcolor=$color";
        }
    };

    return @text;
};

sub BUILD {
    my $self=shift;
    my $args=shift;

    return $self;
};

sub dotLabel {
    my $self = shift;
    return (
        $self->block->dname,
        '('.($self->target//'').')',
        );
}

1;

###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
package StorageDisplay::Collect::CMD::Remote;

# FIXME
use lib qw(.);
use StorageDisplay::Collect;
use Net::OpenSSH;
use Term::ReadKey;
END {
    ReadMode('normal');
}
use Moose;
use MooseX::NonMoose;
extends 'StorageDisplay::Collect::CMD';

has 'ssh' => (
    is    => 'ro',
    isa   => 'Net::OpenSSH',
    required => 1,
    );


sub open_cmd_pipe {
    my $self = shift;
    my $ssh = $self->ssh;
    my @cmd = @_;
    print STDERR "[SSH]Running: ", join(' ', @cmd), "\n";
    my ($dh, $pid) = $ssh->pipe_out(@cmd) or
    die "pipe_out method failed: " . $ssh->error." for '".join("' '", @cmd)."'\n";
    return $dh;
}

sub open_cmd_pipe_root {
    my $self = shift;
    my @cmd = (qw(sudo -S -p), 'sudo password:'."\n", '--', @_);
    ReadMode('noecho');
    my $dh = $self->open_cmd_pipe(@cmd);
    my $c = ord($dh->getc);
    $dh->ungetc($c);
    ReadMode('normal');
    return $dh;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $remote = shift;

    my $ssh = Net::OpenSSH->new($remote);
    $ssh->error and
    die "Couldn't establish SSH connection: ". $ssh->error;

    return $class->$orig(
        'ssh' => $ssh,
        );
};

1;

###########################################################################
package StorageDisplay::Collect::CMD::Replay;

use parent -norequire => "StorageDisplay::Collect::CMD";
use Scalar::Util 'blessed';
use Data::Dumper;
use Data::Compare;

sub new {
    my $class = shift;
    my %args = ( @_ );
    if (not exists($args{'replay-data'})) {
        die 'replay-data argument required';
    }
    my $self = $class->SUPER::new(@_);
    $self->{'_attr_replay_data'} = $args{'replay-data'};
    $self->{'_attr_replay_data_nextid'}=0;
    return $self;
}

sub _replay {
    my $self = shift;
    my $args = shift;
    my $ignore_keys = shift;
    my $msgerr = shift;

    my $entry = $self->{'_attr_replay_data'}->[$self->{'_attr_replay_data_nextid'}++];
    if (not defined($entry)) {
        print STDERR "E: no record for $msgerr\n";
        die "No records anymore\n";
    }
    foreach my $k (keys %{$args}) {
        if (not exists($entry->{$k})) {
            print STDERR "E: no record for $msgerr\n";
            die "Missing '$k' in record:\n".Data::Dumper->Dump([$entry], ['record'])."\n";
        }
    }
    if (! Compare($entry, $args, { ignore_hash_keys => $ignore_keys })) {
        print STDERR "E: record for different arguments\n";
        foreach my $k (@{$ignore_keys}) {
            delete($entry->{$k});
        }
        die "Bad record:\n".
            Data::Dumper->Dump([$args, $entry], ['requested', 'recorded'])."\n";
    }
    return $entry;
}

sub _replay_cmd {
    my $self = shift;
    my $args = { @_ };
    my $cmd = $self->_replay(
        $args,
        ['stdout', 'root'],
        "command ".$self->cmd2str(@{$args->{'cmd'}}),
        );
    my $cmdrequested = $self->cmd2str(@{$args->{'cmd'}});
    if ($args->{'root'} != $cmd->{'root'}) {
        print STDERR "W: Root mode different for $cmdrequested\n";
    }
    print STDERR "Replaying".($cmd->{'root'}?' (as root)':'')
        .": ", $cmdrequested, "\n";
    my @infos = @{$cmd->{'stdout'}};
    my $infos = join("\n", @infos);
    if (scalar(@infos)) {
        # will add final endline
        $infos .= "\n";
    }
    open(my $fh, "<",  \$infos);
    return $fh;
}

sub open_cmd_pipe {
    my $self = shift;
    return $self->_replay_cmd(
        'root' => 0,
        'cmd' => [ @_ ],
        );
}

sub open_cmd_pipe_root {
    my $self = shift;
    return $self->_replay_cmd(
        'root' => 1,
        'cmd' => [ @_ ],
        );
}

sub has_file {
    my $self = shift;
    my $filename = shift;
    my $fileaccess = $self->_replay(
        {
            'filename' => $filename,
        },
        [ 'value' ],
        "file access check to '$filename'");
    return $fileaccess->{'value'};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay - Collect and display storages on linux machines

=head1 VERSION

version 1.0.4

Replay commands

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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

package StorageDisplay::Data::Libvirt;
# ABSTRACT: Handle Libvirt data for StorageDisplay

our $VERSION = '2.02'; # VERSION

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

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
        'ignore_name' => 1,
        'consume' => [],
        'st' => $st,
        'vms' => [ sort { $b cmp $a } keys %{$info} ],
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $st = $args->{st};

    foreach my $vm (@{$args->{'vms'}}) {
        my $d = $self->newChild('Libvirt::VM', $st, $vm);
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
package StorageDisplay::Data::Libvirt::VM;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

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

has 'hostname' => (
    is    => 'rw',
    isa   => 'Str',
    required => 0,
    predicate => 'has_hostname',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $st = shift;
    my $vm = shift;

    my $vminfo = $st->get_info('libvirt', $vm) // {};

    $st->log({level=>1}, $vm);

    return $class->$orig(
        'name' => $vm,
        'vmname' => $vm,
        'consume' => [],
        'st' => $st,
        'vm-info' => $vminfo,
        'state' => $vminfo->{state},
        @_
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    my $blocks=$args->{'vm-info'}->{'blocks'} // {};

    my $ga_disks=$args->{'vm-info'}->{ga}->{disks} // {};

    if (exists($args->{'vm-info'}->{ga}->{hostname})) {
	$self->hostname($args->{'vm-info'}->{ga}->{hostname});
    }

    foreach my $disk (sort keys %{$blocks}) {
        $self->newChild(
            'Libvirt::VM::Block',
	    $self, $args->{'st'}, $disk, $blocks->{$disk},
	    $ga_disks->{$blocks->{$disk}->{'target'}} // {});
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
    my @label = ($self->vmname);
    if ($self->has_hostname) {
	push @label, "hostname: ".$self->hostname;
    } else {
	#push @label, "No QEMU Guest Agent running";
    }
    return @label;
}

1;

##################################################################
package StorageDisplay::Data::Libvirt::VM::Block;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::Grey',
    'StorageDisplay::Role::Style::WithSize' => {
	-excludes => 'dotStyle',
    },
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
    isa   => 'StorageDisplay::Data::Libvirt::VM',
    required => 1,
    );

has 'hostdevice' => (
    is    => 'rw',
    isa   => 'Str',
    required => 0,
    predicate => 'has_hostdevice',
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vm = shift;
    my $st = shift;
    my $bname = shift;
    my $binfo = shift;
    my $gainfo = shift;

    my $block = $st->block($bname);

    my @optional_infos;

    my $consumename=$bname;
    my $size = 0;
    if ($binfo->{'type'} eq 'file') {
        my $mountpoint = $binfo->{'mount-point'};
        if (defined($mountpoint)) {
            push @optional_infos, 'mountpoint' => $mountpoint;
	    $consumename = $st->fs_mountpoint_blockname($mountpoint);
        } else {
	    $consumename=undef;
	}
	$size = $binfo->{'size'} // $size;
    } elsif ($binfo->{'type'} eq 'block') {
	eval {
	    # unknown (deleted?) blocks are NoSystem block with no size method
	    $size = $block->size;
	}
    }
    if (defined($consumename)) {
	my $consumeblock = $st->block($consumename);
	push @optional_infos, 'consume' => [$consumeblock];
    }
    if (defined($size)) {
	$block->size($size);
    }

    if (exists($gainfo->{name})) {
	push @optional_infos, 'hostdevice' => $gainfo->{name};
    }

    return $class->$orig(
        'name' => $binfo->{'target'},
        'block' => $block,
        'vm' => $vm,
	'size' => $size,
        @optional_infos,
        'st' => $st,
        'target' => $binfo->{'target'},
        'type' => $binfo->{'type'},
        @_
        );
};

around 'dotStyleNode' => sub {
    my $orig = shift;
    my $self = shift;
    my @text = $self->$orig(@_);

    for my $i (1) { # just to be able to call 'last'
	if ($self->size == 0) {
	    my $color = $self->statecolor('missing');
	    push @text, "fillcolor=$color";
	} elsif ($self->type ne 'block') {
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
    my @label = ($self->block->dname);
    if ($self->has_hostdevice) {
	push @label, '['.$self->hostdevice.']';
    } else {
	push @label, '('.$self->target.')';
    }
    return @label;
}

around 'sizeLabel' => sub {
    my $orig = shift;
    my $self = shift;
    if ($self->size eq 0) {
	return;
    }
    return $self->$orig(@_);
};

around dotLinks => sub {
    my $orig = shift;
    my $self = shift;

    my @links = $self->$orig(@_);
    my ($devname, $hostname);
    if ($self->has_hostdevice) {
	$devname = $self->hostdevice;	
	$devname =~ s,^/dev/,,;
	$hostname = $self->vm->hostname;
    } else {
	$devname = '('.$self->target.')';
	$hostname = $self->vm->vmname;
    }
    push @links, "// SOURCE LINK: ".$hostname." ".
	$self->block->size." ".
	$devname." ".$self->linkname;

    return @links;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Data::Libvirt - Handle Libvirt data for StorageDisplay

=head1 VERSION

version 2.02

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

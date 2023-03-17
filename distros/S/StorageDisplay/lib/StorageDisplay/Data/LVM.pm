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

package StorageDisplay::Data::LVM;
# ABSTRACT: Handle LVM data for StorageDisplay

our $VERSION = '1.2.1'; # VERSION

1;

##################################################################
package StorageDisplay::Data::LVM::Group;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with ('StorageDisplay::Role::Style::IsSubGraph');

has 'vg' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Block',
    required => 1,
    );

has 'vgname' => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    init_arg => undef,
    lazy     => 1,
    default  => sub {
	my $self = shift;
	return $self->vg->name;
    },
    );

has 'pvs' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::LVM::PVs::Base',
    writer => '_pvs',
    required => 0,
    );

sub dname {
    my $self=shift;
    return 'LVM VG: '.$self->name;
}

sub dotLabel {
    my $self = shift;
    return 'LVM: '.$self->vgname;
}

sub _xv {
    my $self = shift;
    my $kind = shift;
    my $name = shift;

    my $it = $self->$kind->iterator(recurse => 0);
    while (defined(my $e=$it->next)) {
        return $e if $e->lvmname eq $name;
    }
    #print STDERR "E: no $kind with name $name\n";
    return;
}

use StorageDisplay::Moose::Cached;

has 'pv' => (
    cached_hash => "StorageDisplay::Data::LVM::VG::PVs::PV",
    compute => sub {
        my $self = shift;
        my $name = shift;
        return $self->_xv("pvs", $name);
    },
    );

##################################################################
package StorageDisplay::Data::LVM::UnassignedPVs;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LVM::Group';

with (
    'StorageDisplay::Role::Style::Grey',
    'StorageDisplay::Role::Elem::Kind'
    => { kind => "Unassigned PVs" }
    );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vgname = shift;
    my $st = shift;

    $st->log({level=>1}, 'Unassigned PVs');

    my $vgblock = StorageDisplay::Block::NoSystem->new(
        'name' => $class,
        );

    my $info = $st->get_info('lvm', $vgname);

    return $class->$orig(
        'ignore_name' => 1,
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

    $self->_pvs($self->newChild('LVM::UnassignedPVs::PVs',
				$self, $st, $args->{'lvm-info'}));
    return $self;
};

1;

##################################################################
package StorageDisplay::Data::LVM::VG;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LVM::Group';

with (
    'StorageDisplay::Role::Style::WithFree',
    );

has 'lvs' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::LVM::VG::LVs',
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

    $self->_pvs($self->newChild('LVM::VG::PVs', $self, $st,
				$args->{'lvm-info'}));
    if ($args->{'name'} ne '') {
        #print STDERR "name: ", $args->{'name'}, "\n";
        $self->_lvs($self->newChild('LVM::VG::LVs', $self, $st,
				    $args->{'lvm-info'}));
        #my $links = $args->{'lvm-info'}->{'pvs'};
        #foreach my $l (@{$links}) {
        #    if ($l->{segtype} ne "free"
        #        && $l->{lv_role} ne "private,pool,spare"
        #        && $l->{lv_role} ne "private,thin,pool,metadata"
        #        && $l->{lv_role} ne "private,thin,pool,data") {
        #        $self->_add_link({pv => $l->{pv_name},
        #                          lv => $l->{lv_name}});
        #    }
        #}
        my $links = $args->{'lvm-info'}->{'lvs'};
        foreach my $l (@{$links}) {
            if ($l->{'pool_lv'} ne '') {
                $self->_add_link({source_name => $l->{'pool_lv'},
                                  source_type => 'lv',
                                  lv => $l->{lv_name}});
            }
            if ($l->{'lv_parent'} ne '') {
                $self->_add_link({source_name => $l->{lv_name},
                                  source_type => 'lv',
                                  lv => $l->{lv_parent}});
            }
            foreach my $devpos (split(/,/, $l->{'seg_le_ranges'})) {
                if ($devpos !~ m/^(.*):[0-9]+-[0-9]+$/) {
                    $st->warn("Cannot parse seg_le_ranges $devpos for ".$l->{lv_name});
                } else {
                    my $source_name = $1;
                    #$st->warn("Parsing seg_pe_ranges $devpos for ".$l->{lv_name});
                    my $type = 'pv';
                    if (index($l->{'seg_pe_ranges'},$devpos) == -1) {
                        $type = 'lv';
                        #$st->warn("switching to LV for $devpos for ".$l->{lv_name});
                    #} else {
                    #    $st->warn("ok : $devpos in ".$l->{'seg_pe_ranges'});
                    }
                    $self->_add_link({source_name => $source_name,
                                      source_type => $type,
                                      lv => $l->{lv_name}});
                }
            }
        }
    }
    return $self;
};

use StorageDisplay::Moose::Cached;

has 'lv' => (
    cached_hash => "StorageDisplay::Data::LVM::VG::LVs::LV",
    compute => sub {
        my $self = shift;
        my $name = shift;
        return $self->_xv("lvs", $name);
    },
    );

sub dotLinks {
    my $self = shift;
    my $source = sub {
        my $name = shift;
        my $type = shift;
        my $source =  $self->$type($name);
        if (defined($source)) {
            return $source->linkname;
        }
        print STDERR "E: FIXME: No source for $name ($type)\n";
        return "''";
    };
    return map {
        $source->($_->{source_name}, $_->{source_type}).' -> '.$self->lv($_->{lv})->linkname
    } $self->internal_links;
}

1;

##################################################################
package StorageDisplay::Data::LVM::Elem;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

has 'vg' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::LVM::Group',
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
package StorageDisplay::Data::LVM::PVs::Base;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LVM::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::SubInternal',
    );

1;

##################################################################
package StorageDisplay::Data::LVM::VG::PVs;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LVM::PVs::Base';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vg = shift;

    return $class->$orig(
        $vg,
        @_,
        'ignore_name' => 1,
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
        $self->newChild('LVM::VG::PVs::PV', $pv_name, $self->vg, $args->{st},
			$args->{'lvm-info'});
    }
    return $self;
};

sub dotLabel {
    my $self = shift;
    return ($self->vg->vgname.'\'s PVs');
}

1;

##################################################################
package StorageDisplay::Data::LVM::UnassignedPVs::PVs;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LVM::PVs::Base';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $vg = shift;

    return $class->$orig(
        $vg,
        @_,
	'ignore_name' => 1,
        'consume' => [],
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;
    foreach my $pv_name (sort map { $_->{'pv_name'} } @{$args->{'lvm-info'}->{'pvs'}}) {
        $self->newChild('LVM::UnassignedPVs::PV', $pv_name, $self->vg,
			$args->{st}, $args->{'lvm-info'});
    }
    return $self;
};

sub dotLabel {
    my $self = shift;
    return ();
}

1;

##################################################################
package StorageDisplay::Data::LVM::VG::LVs;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LVM::Elem';

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
        'ignore_name' => 1,
        'consume' => [],
        );
};

sub BUILD {
    my $self=shift;
    my $args=shift;

    foreach my $lv_name (sort keys %{$args->{'lvm-info'}->{'vgs-lv'}}) {
        $self->newChild('LVM::VG::LVs::LV', $lv_name, $self->vg,
			$args->{st}, $args->{'lvm-info'});
    }
    return $self;
};

sub dotLabel {
    my $self = shift;
    return ($self->vg->vgname.'\'s LVs');
}
1;

##################################################################
package StorageDisplay::Data::LVM::XV;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LVM::Elem';

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
package StorageDisplay::Data::LVM::VG::PVs::PV;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LVM::XV';

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
        'name' => $pvblock->name,
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
package StorageDisplay::Data::LVM::VG::LVs::LV;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LVM::XV';

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

    my $lvblock = $st->block($vg->vgname.'/'.$lvname);

    my $lvinfo = $info->{'vgs-lv'}->{$lvname};

    return $class->$orig(
        $vg, $st, $info, $lvname, $lvblock,
        'name' => $lvname,
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

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Data::LVM - Handle LVM data for StorageDisplay

=head1 VERSION

version 1.2.1

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

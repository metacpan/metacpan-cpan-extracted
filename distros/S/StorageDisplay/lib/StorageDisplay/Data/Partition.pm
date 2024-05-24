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

package StorageDisplay::Data::Partition;
# ABSTRACT: Handle partition tables data for StorageDisplay

our $VERSION = '2.06'; # VERSION

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

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
        'name' => $block->name,
        'part_infos' => $st->get_info('partitions', $block->name),
        'block' => $block,
        'consume' => [$block],
        @_
        );
};

has 'table' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::Partition::Table',
    required => 1,
    default  => sub {
        my $self = shift;
        return $self->newChild(
	    'Partition::Table',
	    'ignore_name' => 1,
	    'partition' => $self,
            );
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
            return ! $part->isa('StorageDisplay::Data::Partition::Table::Part::SubTable');
        },
        );
    while (defined(my $part = $it->next)) {
        my $state="free";
        if (! $part->isa("StorageDisplay::Data::Partition::Table::Part::Free")) {
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
    my @label = ($self->disk->dname);
    if (defined($self->disk->blk_info('MODEL'))) {
        push @label, 'Model: '.$self->disk->blk_info('MODEL');
    }
    if (defined($self->disk->blk_info('SERIAL'))) {
        push @label, 'Serial: '.$self->disk->blk_info('SERIAL');
    }
    push @label, 'Label: '.$self->kind;
    return @label;
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
package StorageDisplay::Data::Partition::Table;

use Moose;
use namespace::sweep;

use Carp;

extends 'StorageDisplay::Data::Elem';

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
    isa      => 'StorageDisplay::Data::Partition',
    required => 1,
    );

sub elem {
    my $self = shift;
    return $self->partition(@_);
}

sub addPart {
    my $self = shift;
    my $part = shift;

    if ($part->isa('StorageDisplay::Data::Partition::Table::Part::SubTable')) {
        $part->block->state("special");
    } elsif ($part->isa('StorageDisplay::Data::Partition::Table::Part::Data')) {
        if ($part->label =~ /efi|grub/i || $part->flags =~ /boot/i) {
            $part->block->state("special");
        }
    } elsif ($part->isa('StorageDisplay::Data::Partition::Table::Part::Free')) {

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
package StorageDisplay::Data::Partition::Table::Part;

use Moose;
use namespace::sweep;

extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::Style::Label::HTML',
    'StorageDisplay::Role::Style::IsLabel',
    'StorageDisplay::Role::Style::WithSize',
    );

has 'table' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::Partition::Table',
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
package StorageDisplay::Data::Partition::Table::Part::Data;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Partition::Table::Part';

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
            'id' => $part_id,
            );
        $block=$b;
    }

    return $class->$orig(
        'name' => $block->name,
        'block' => $block,
        @_
        );
};

sub BUILD {
    my $self = shift;

    #print STDERR "BUILD in ".__PACKAGE__."\n";
    #print STDERR "Looking for ", $self->id, " into ", $self->table->disk->name, "\n";
    $self->provideBlock($self->block);
}

sub rawlinkname {
    my $self = shift;

    confess "No rawlinkname for ".$self->fullname;
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
package StorageDisplay::Data::Partition::Table::Part::SubTable;

use Moose;
use namespace::sweep;

# keep Table::Part::Data first to pick its dotNode redefinition
extends
    'StorageDisplay::Data::Partition::Table::Part::Data',
    'StorageDisplay::Data::Partition::Table';

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
package StorageDisplay::Data::Partition::Table::Part::Free;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Partition::Table::Part';

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
package StorageDisplay::Data::Partition::None;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::WithSize',
    'StorageDisplay::Role::Style::FromBlockState',
    );

sub disk {
    my $self = shift;
    return $self->block(@_);
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $block = shift;
    my $st = shift;

    $st->log({level=>1}, 'Disk with no partition tables on '.$block->dname);

    return $class->$orig(
        'name' => $block->name,
        'block' => $block,
        'provide' => [$block],
        'size' => $st->get_info('lsblk', $block->name, 'size'),
        @_
        );
};

sub BUILD {
    my $self = shift;

    #print STDERR "BUILD in ".__PACKAGE__."\n";
    #print STDERR "Looking for ", $self->id, " into ", $self->table->disk->name, "\n";
    $self->provideBlock($self->block);
}

sub dotLabel {
    my $self = shift;
    my @label = ($self->disk->dname);
    if (defined($self->disk->blk_info('MODEL'))) {
        push @label, 'Model: '.$self->disk->blk_info('MODEL');
    }
    if (defined($self->disk->blk_info('SERIAL'))) {
        push @label, 'Serial: '.$self->disk->blk_info('SERIAL');
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

##################################################################
package StorageDisplay::Data::Partition::GPT;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Partition';

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
            StorageDisplay::Data::Partition::Table::Part::Free->new(
                'name' => '_'.$id_free,
                'table' => $self->table,
                %{$part},
                );
            $id_free ++;
        } elsif ($part->{kind} eq 'part') {
            delete($part->{kind});
            StorageDisplay::Data::Partition::Table::Part::Data->new(
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
package StorageDisplay::Data::Partition::MSDOS;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Partition';

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
    isa   => 'StorageDisplay::Data::Partition::Table',
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
            StorageDisplay::Data::Partition::Table::Part::Free->new(
                'name' => '_'.$id_free,
                'table' => $self->table,
                %{$part},
                );
            $id_free ++;
        } elsif ($part->{kind} eq 'part') {
            delete($part->{kind});
            if ($part->{id} eq $extended) {
                $self->extended(
                    StorageDisplay::Data::Partition::Table::Part::SubTable->new(
                        'table' => $self->table,
                        'partition' => $self,
                        %{$part},
                    ));
            } elsif ($part->{id} <= 4) {
                StorageDisplay::Data::Partition::Table::Part::Data->new(
                    'table' => $self->table,
                    %{$part},
                    );
            } else {
                confess if not defined($self->extended);
                StorageDisplay::Data::Partition::Table::Part::Data->new(
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

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Data::Partition - Handle partition tables data for StorageDisplay

=head1 VERSION

version 2.06

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

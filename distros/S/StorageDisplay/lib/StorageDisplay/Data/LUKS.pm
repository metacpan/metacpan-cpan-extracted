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

package StorageDisplay::Data::LUKS;
# ABSTRACT: Handle LUKS data for StorageDisplay

our $VERSION = '2.06'; # VERSION

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::HasBlock',
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::Grey',
    );

has 'encrypted' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::LUKS::Encrypted',
    writer => '_encrypted',
    required => 0,
    );

has 'decrypted' => (
    is    => 'ro',
    isa   => 'StorageDisplay::Data::LUKS::Decrypted',
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
        'name' => $block->name,
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

    $self->_encrypted($self->newChild('LUKS::Encrypted',
				      $self, $st, $args->{'luks-info'}));
    if (defined($args->{'luks-info'}->{decrypted})) {
        $self->_decrypted(
	    $self->newChild('LUKS::Decrypted::Present',
			    $self, $st, $args->{'luks-info'}));
    } else {
        $self->_decrypted(
	    $self->newChild('LUKS::Decrypted::None',
			    $self, $st, $args->{'luks-info'}));
    }
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
package StorageDisplay::Data::LUKS::Encrypted;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

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
        'name' => $block->name,
        'consume' => [$block],
        'block' => $block,
        'size' => $st->get_info('lsblk', $block->name, 'size'),
        @_
        );
};

sub dotLabel {
    my $self = shift;
    return ($self->block->dname);
}

1;

##################################################################
package StorageDisplay::Data::LUKS::Decrypted;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

1;

##################################################################
package StorageDisplay::Data::LUKS::Decrypted::Present;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LUKS::Decrypted';

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
        @_
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
package StorageDisplay::Data::LUKS::Decrypted::None;

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::LUKS::Decrypted';

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
        @_
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

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Data::LUKS - Handle LUKS data for StorageDisplay

=head1 VERSION

version 2.06

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

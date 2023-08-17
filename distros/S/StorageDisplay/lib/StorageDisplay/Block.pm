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

package StorageDisplay::Block;
# ABSTRACT: Base package for block devices DAG

our $VERSION = '2.05'; # VERSION

1;

package StorageDisplay::BlockTreeElement;

use Moose;
use namespace::sweep;

use Carp;
use StorageDisplay::Role;

with "StorageDisplay::Role::Iterable"
    => {
        iterable => "StorageDisplay::BlockTreeElement",
        name => "Plain",
};

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
    isa      => 'StorageDisplay::Data::Elem',
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
    #print STDERR "Provider for ".$self->name.": ".$elem."\n";
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
            #print STDERR "  prefer($s) ", $n, "\n";
            $score = $s;
            $best_name = $n;
        } elsif ($s == $score && $n gt $best_name) {
            #print STDERR "  prefer($s/alpha) ", $n, "\n";
            $best_name = $n;
        #} else {
        #    print STDERR "  reject($s) ", $n, "\n";
        }
    }

    return '/dev/'.
         $best_name;
}

has 'size' => (
    is => 'rw',
    isa => 'Int',
    lazy => 1,
    default => sub {
	my $self = shift;
	confess "Method 'size' not implemented or set in ".ref($self)."@".$self->name;
	#return -1;
    },
    );

sub blk_info {
    my $self=shift;
    my $key=shift;
    return;
}

sub udev_info {
    my $self=shift;
    my $key=shift;
    return;
}

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

1;

##################################################################
package StorageDisplay::Block::NoSystem;
use Moose;
use namespace::sweep;

extends 'StorageDisplay::Block';

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

    my $name = $args{'name'} // $args{'id'};

    my $dname = $args{'name'} // $args{'id'};

    return $class->$orig(
        'name' => $name,
        'dname' => $dname,
        'names' => { $name => Path::Class::Dir->new() },
        'path' => Path::Class::Dir->new(),
        @_
        );
};

##################################################################
package StorageDisplay::Block::System;
use Moose;
use namespace::sweep;

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

sub size {
    my $self = shift;
    return $self->blk_info('SIZE');
}

sub kname {
    my $self = shift;
    return $self->blk_info('KNAME');
}

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
        %args, @_
        );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Block - Base package for block devices DAG

=head1 VERSION

version 2.05

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

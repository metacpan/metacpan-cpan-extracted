#===============================================================================
#  DESCRIPTION:  test for Net::IP::Identifier overlapping netblocks
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  11/14/2014 01:06:01 PM
#===============================================================================

use 5.008;
use strict;
use warnings;

use Test::More
    tests => 13;

package Local::Parent;  # a parent network
use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

# VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    $self->ips(qw(
        10.0.0.0/8
    ));
    return $self;
}

sub name {
    return 'Parent';
}

1;

package Local::Entity;  # the network
use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

# VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    $self->ips(qw(
        10.11.0.0/16
    ));
    return $self;
}

sub name {
    return 'Entity';
}

1;

package Local::Child;  # a child network
use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

# VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    $self->ips(qw(
        10.11.12.0/24
    ));
    return $self;
}

sub name {
    return 'Child';
}

1;

package main;
# VERSION

use_ok('Net::IP::Identifier', qw( [] ));   # load no entities

my $identifier = Net::IP::Identifier->new(overlaps => 1);
is (ref $identifier, 'Net::IP::Identifier',  'instantiate Identifier');




check_overlap([qw( Entity Entity )],    # load twice
                '',     # ignored
            );

check_overlap([qw( Entity Child )],   # load child after
                'Entity:10.11.0.0/16 => Child:10.11.12.0/24',
            );
check_overlap([qw( Child Entity )],   # load child before
                'Entity:10.11.0.0/16 => Child:10.11.12.0/24',
            );

check_overlap([qw( Entity Parent )],  # load parent after
                'Parent:10.0.0.0/8 => Entity:10.11.0.0/16',
            );
check_overlap([qw( Parent Entity )],  # load parent before
                'Parent:10.0.0.0/8 => Entity:10.11.0.0/16',
            );

# all combinations of three
check_overlap([qw( Parent Entity Child )], 
                'Parent:10.0.0.0/8 => Entity:10.11.0.0/16 => Child:10.11.12.0/24',
            );
check_overlap([qw( Parent Child Entity )], 
                'Parent:10.0.0.0/8 => Entity:10.11.0.0/16 => Child:10.11.12.0/24',
            );
check_overlap([qw( Entity Parent Child )], 
                'Parent:10.0.0.0/8 => Entity:10.11.0.0/16 => Child:10.11.12.0/24',
            );
check_overlap([qw( Entity Child Parent )], 
                'Parent:10.0.0.0/8 => Entity:10.11.0.0/16 => Child:10.11.12.0/24',
            );
check_overlap([qw( Child Parent Entity )], 
                'Parent:10.0.0.0/8 => Entity:10.11.0.0/16 => Child:10.11.12.0/24',
            );
check_overlap([qw( Child Entity Parent )], 
                'Parent:10.0.0.0/8 => Entity:10.11.0.0/16 => Child:10.11.12.0/24',
            );

sub check_overlap {
    my ($plugins, @expect) = @_;

    my @e;
    for my $p ( @{$plugins} ) {
        push @e, "Local::$p"->new;
    }
    $identifier->{entities} = \@e;
    delete $identifier->{ip_tree};

    my $error;
    $identifier->identify('1.1.1.1');
    my @returns = $identifier->tree_overlaps;
    while (@expect) {
        my $return = shift @returns;
        my @r = map { $identifier->join($_->payload->entity, $_->payload->ip); } @{$return};
        my $expect = shift @expect;
        is(join(' => ', @r), $expect, "overlap " . join(' ', @{$plugins}));
    }
}

package Sweat::Group;

use warnings;
use strict;
use Types::Standard qw(ArrayRef Str);

use List::Util qw(shuffle);
use Try::Tiny;

use Sweat::Drill;

use Moo;
use namespace::clean;

has 'drills' => (
    is => 'ro',
    required => 1,
    isa => ArrayRef,
);

has 'name' => (
    is => 'ro',
    required => 1,
    isa => Str,
);

has 'sweat' => (
    is => 'ro',
    required => 1,
    weaken => 1,
);

sub BUILD {
    my ( $self, $args ) = @_;

    # We reset the drills immediately upon building so that restrictive
    # preferences (e.g. no-jumping) can get applied immediately.
    $self->reset_drills;

}

# reset_drills: Set the "is_used" bit for each drill to 0, *unless* that drill
#               is restricted according to current config. In that case, it
#               gets "is_used" set to 1.
sub reset_drills {
    my $self = shift;

    my %restriction_map = (
        jumping => 'requires_jumping',
        chair => 'requires_a_chair',
    );

    for my $drill ( @{ $self->drills } ) {
        $drill->is_used(0);
        for my $restriction ( keys %restriction_map ) {
            my $attribute = $restriction_map{$restriction};
            if ( $drill->$attribute && !$self->sweat->$restriction ) {
                $drill->is_used(1);
                last;
            }
        }
    }

    unless ($self->unused_drills) {
        die "The current configuration makes every drill in the "
            . $self->name
            . " group unavailable, and we can't have that.\n";
    }
}

sub new_from_config_data {
    my ( $class, $sweat, $data ) = @_;
    my @groups;
    try {
        for my $group_data ( @$data ) {
            my @drills;
            for my $drill_data ( @{$group_data->{drills} } ) {
                my $drill = Sweat::Drill->new( $drill_data );
                push @drills, $drill;
            }
            my $group = $class->new(
                drills => \@drills,
                name => $group_data->{name},
                sweat => $sweat,
            );
            push @groups, $group;
        }
    }
    catch {
        die "Sorry... I can't parse the provided drill-group config data. $_\n";
    };
    return @groups;
}

sub unused_drills {
    my $self = shift;

    return grep { not $_->is_used } @{ $self->drills };
}

1;

=head1 Sweat::Group - Library for the `sweat` command-line program

=head1 DESCRIPTION

This library is intended for internal use by the L<sweat> command-line program,
and as such offers no publicly documented methods.

=head1 SEE ALSO

L<sweat>

=head1 AUTHOR

Jason McIntosh <jmac@jmac.org>

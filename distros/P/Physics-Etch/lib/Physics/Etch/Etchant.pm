package Physics::Etch::Etchant;

use strict;
use warnings;

our $VERSION = '0.01';

# The chemistry that does the etching.
#
#   name         short key, e.g. 'FeCl3'
#   type         'wet' or 'dry'
#   composition  human string, e.g. 'Ferric chloride 40 Baume'
#                or plasma feed gases, e.g. 'SF6 / O2'
#   mechanism    'chemical' | 'physical' | 'ion-assisted'
#   notes        free text

my %VALID_TYPE = ( wet => 1, dry => 1 );

sub new {
    my ( $class, %args ) = @_;

    my $name = $args{name}
        or die "Physics::Etch::Etchant: 'name' is required\n";
    my $type = $args{type}
        or die "Physics::Etch::Etchant: 'type' (wet|dry) is required\n";
    die "Physics::Etch::Etchant: type must be 'wet' or 'dry', got '$type'\n"
        unless $VALID_TYPE{$type};

    my $self = {
        name        => $name,
        type        => $type,
        composition => $args{composition} // $name,
        mechanism   => $args{mechanism}
            // ( $type eq 'wet' ? 'chemical' : 'ion-assisted' ),
        notes => $args{notes} // '',
    };

    return bless $self, $class;
}

sub name        { $_[0]->{name} }
sub type        { $_[0]->{type} }
sub composition { $_[0]->{composition} }
sub mechanism   { $_[0]->{mechanism} }
sub notes       { $_[0]->{notes} }

sub is_wet { $_[0]->{type} eq 'wet' }
sub is_dry { $_[0]->{type} eq 'dry' }

1;

__END__

=head1 NAME

Physics::Etch::Etchant - the chemistry used by an etch process

=head1 SYNOPSIS

    use Physics::Etch::Etchant;

    my $fecl3 = Physics::Etch::Etchant->new(
        name        => 'FeCl3',
        type        => 'wet',
        composition => 'Ferric chloride, ~40 Baume',
        mechanism   => 'chemical',
    );

    my $sf6 = Physics::Etch::Etchant->new(
        name        => 'SF6/O2',
        type        => 'dry',
        composition => 'SF6 45 sccm / O2 5 sccm',
        mechanism   => 'ion-assisted',
    );

=head1 DESCRIPTION

Describes an etchant. Wet etchants are liquid chemistries; dry etchants are
plasma feed-gas mixtures. C<mechanism> records whether removal is dominated by
C<chemical> reaction, C<physical> sputtering, or synergistic C<ion-assisted>
etching.

=cut

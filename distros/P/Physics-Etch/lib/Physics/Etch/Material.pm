package Physics::Etch::Material;

use strict;
use warnings;

our $VERSION = '0.01';

# A thin film / bulk material that can be etched or used as mask/substrate.
#
#   name      short key, e.g. 'copper'
#   formula   chemical formula, e.g. 'Cu'
#   pretty    display name, e.g. 'Copper'
#   density   g/cm^3 (optional, informational)
#   thickness nm     (optional; the film thickness to be removed)

sub new {
    my ( $class, %args ) = @_;

    my $name = $args{name}
        or die "Physics::Etch::Material: 'name' is required\n";

    my $self = {
        name      => $name,
        formula   => $args{formula} // '',
        pretty    => $args{pretty}  // _titlecase($name),
        density   => $args{density},                # g/cm^3
        thickness => $args{thickness},              # nm
    };

    return bless $self, $class;
}

sub name      { $_[0]->{name} }
sub formula   { $_[0]->{formula} }
sub pretty    { $_[0]->{pretty} }
sub density   { $_[0]->{density} }

sub thickness {
    my ( $self, $value ) = @_;
    $self->{thickness} = $value if defined $value;
    return $self->{thickness};
}

sub label {
    my ($self) = @_;
    return $self->{formula}
        ? sprintf( '%s (%s)', $self->{pretty}, $self->{formula} )
        : $self->{pretty};
}

sub _titlecase {
    my ($s) = @_;
    $s =~ s/_/ /g;
    $s =~ s/\b(\w)/\U$1/g;
    return $s;
}

1;

__END__

=head1 NAME

Physics::Etch::Material - a material (film, mask, or substrate) in an etch model

=head1 SYNOPSIS

    use Physics::Etch::Material;

    my $cu = Physics::Etch::Material->new(
        name      => 'copper',
        formula   => 'Cu',
        pretty    => 'Copper',
        density   => 8.96,     # g/cm^3
        thickness => 500,      # nm
    );

    print $cu->label, "\n";    # Copper (Cu)

=head1 DESCRIPTION

A lightweight value object describing a material. C<thickness> is used by the
etch models as the amount of film to remove; it is mutable so a single material
definition can be reused with different film thicknesses.

=cut

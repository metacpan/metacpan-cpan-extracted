#
# Coordinates system related functions
#

package OpenGL::Earth::Coords;

# (1/360.0) * 2 * 3.14159265
use constant DEG_TO_RAD => 0.0174532925;

# Convert earth latitude/longitude to 3D coords
sub earth_to_xyz ($$$) {
    my ($lat, $lon, $radius) = @_;

    $lat *= DEG_TO_RAD;
    $lon *= DEG_TO_RAD;

	my $cos_lat = $radius * cos($lat);

    my $x = $cos_lat * cos($lon);
    my $y = $cos_lat * sin($lon);
    my $z = $radius  * sin($lat);

    return ($x, $y, $z);
}

1;

__END__

=pod

=head1 NAME

OpenGL::Earth::Coords

=head1 SYNOPSIS

    # Where's Oslo on a 3D Sphere of radius 1.0?
    use OpenGL::Earth::Coords;
    my ($x, $y, $z) = OpenGL::Earth::Coords::earth_to_xyz(59.9167, 10.75, 1.0);
    printf "x=%.3f y=%.3f z=%.3f\n", $x, $y, $z;

=head1 DESCRIPTION

Just a quick and dirty module to convert lat/long coordinates
into 3D x, y, z coordinates, assuming the Earth is a perfect
sphere, which we know is not.

=head1 AUTHORS

Cosimo Streppone, cosimo@cpan.org

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

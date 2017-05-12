package Net::UPS::Package;

# $Id: Package.pm,v 1.6 2005/09/11 05:05:25 sherzodr Exp $

=head1 NAME

Net::UPS::Package - Class representing a UPS Package

=head1 SYNOPSIS

    $pkg = Net::UPS::Package->new();
    $pkg->packaging_type('PACKAGE');
    $pkg->measurement_system('metric');
    $pkg->length(40);
    $pkg->width(30);
    $pkg->height(2);
    $pkg->weight(10);

=head1 DESCRIPTION

Net::UPS::Package represents a single UPS package. In addition to the above attributes, I<id> attribute will be set once package is submitted for a rate quote. I<id> starts at I<1>, and will be incremented by one for each subsequent package submitted at single request. The purpose of this attribute is still not clear. Comments are welcome.

=head1 METHODS

In addition to all the aforementioned attributes, following method(s) are supported

=over 4

=cut

use strict;
use Carp ( 'croak' );
use XML::Simple;
use Class::Struct;

$Net::UPS::Package::VERSION = '0.02';

struct(
    id                  => '$',
    packaging_type      => '$',
    measurement_system  => '$',
    length              => '$',
    width               => '$',
    height              => '$',
    weight              => '$'
);


sub PACKAGE_CODES() {
    return {
        LETTER          => '01',
        PACKAGE         => '02',
        TUBE            => '03',
        UPS_PAK         => '04',
        UPS_EXPRESS_BOX => '21',
        UPS_25KG_BOX    => '24',
        UPS_10KG_BOX    => '25'
    };
}

sub _packaging2code {
    my $self    = shift;
    my $label   = shift;

    unless ( defined $label ) {
        croak "_packaging2code(): usage error";
    }
    $label =~ s/\s+/_/g;
    $label =~ s/\W+//g;
    my $code = PACKAGE_CODES->{$label};
    unless ( defined $code ) {
        croak "Nothing known about package type '$label'";
    }
    return $code;
}





sub as_hash {
    my $self = shift;

    my $measurement_system = $self->measurement_system || 'english';

    my $weight_measure  = ($measurement_system eq 'metric') ? 'KGS' : 'LBS';
    my $length_measure  = ($measurement_system eq 'metric') ? 'CM'  : 'IN';
    my %data = (
        Package => {
            PackagingType       => {  
                Code => $self->packaging_type ? sprintf("%02d", $self->_packaging2code($self->packaging_type)) : '02',
            },
            Dimensions          => {
                UnitOfMeasurement => {
                    Code => $length_measure
                }
            },
            DimensionalWeight   => {
                UnitOfMeasurement => {
                    Code => $weight_measure
                }
            },
            PackageWeight       => {
                UnitOfMeasurement => {
                    Code => $weight_measure
                }
            }
        }
    );
    if ( $self->length ) {
        $data{Package}->{Dimensions}->{Length}= $self->length;
    }
    if ( $self->width ) {
        $data{Package}->{Dimensions}->{Width} = $self->width;
    }
    if ( $self->height ) {
        $data{Package}->{Dimensions}->{Height} = $self->height;
    }
    if ( $self->weight ) {
        $data{Package}->{PackageWeight}->{Weight} = $self->weight;
    }
    if (my $oversized = $self->is_oversized ) {
        $data{Package}->{OversizePackage} = $oversized;
    }
    return \%data;
}


=item is_oversized

Convenience method. Return value indicates if the package is oversized, and if so, its oversize level. Possible return values are I<0>, I<1>, I<2> and I<3>. I<0> means not oversized.

=cut

# Scoob correction Feb 26th 2006 / cpan@pickledbrain.com
#
# Definitions of oversize categories:
#   http://www.ups.com/content/us/en/resources/prepare/oversize.html
#
# Length and Girth: Length + 2x Width + 2x Height
# Where Length is the longuest side of pkg rounded to nearest inch.
# And Girth is: 2x Width + 2x Height) (round width & height to nearest inch)
#
# Also as described in: 
#    http://www.ups.com/content/us/en/resources/prepare/guidelines/index.html
# - Packages can be up to 150 lbs (70 kg)
# - Packages can be up to 165 inches (419 cm) in length and girth combined
# - Packages can be up to 108 inches (270 cm) in length
# - Packages that weigh more than 70 lbs (31.5 kg, 25 kg within the EU) require a special heavy-package label
# - Oversize packages and packages with a large size-to-weight ratio require special pricing 
#   and dimensional weight calculations
#
# Understand that "Oversize" OS[123] package is a rating to compensate for
# a package that is very large but weights very little.  UPS charges for
# a "billing weight" that is larger than the actual weight for OS packages.
# So for a package to be OS1 is must be 84 < size < 108  *AND* weight < 30lbs 
# If a package is size 104" and has weight: 33lbs, is is NOT OS1 (because it is
# heavy enough that UPS will be fairly compensated by charging for weight only.
#
###
sub is_oversized {
    my $self = shift;

    unless ( $self->width && $self->height && $self->length && $self->weight) {
        return 0;
    }

    my @sides = sort ($self->length, $self->width, $self->height);
    my $len = pop(@sides);  # Get longest side
    my $girth = ((2 * $sides[0]) + (2 * $sides[1]));
    my $size = $len + $girth;
    
    if (($len > 108) || ($self->weight > 150) || ($size > 165)) {
	croak "Such package size/weight is not supported";  
    }

    return 0 if ( $size <= 84 );                   # Below OS1
    if ($size <= 108) {                            # OS1 pgk is billed for 30lbs 
	return (($self->weight < 30) ? 1 : 0);     # Not OS1 if weight > 30lbs
    }
    if ($size <= 130) {                            # OS2 pgk is billed for 70lbs 
	return (($self->weight < 70) ? 2 : 0);     # Not OS2 if weight > 70lbs
    }
    if ($size <= 165) {                            # OS3 pgk is billed for 90lbs 
	return (($self->weight < 90) ? 3 : 0);     # Not OS3 if weight > 90lbs
        return 3;
    }

}





sub as_XML {
    my $self = shift;
    return XMLout( $self->as_hash, NoAttr=>1, KeepRoot=>1, SuppressEmpty=>1 )
}






sub cache_id {
    my $self = shift;
    my $packaging_type =  $self->packaging_type || 'PACKAGE';
    return $packaging_type . ':' . $self->length . ':' . $self->width .':'. $self->height .
        ':'. $self->weight;
}




sub rate {
    my $self = shift;
    my $ups = Net::UPS->instance();
    return $ups->rate( $_[0], $_[1], $self, $_[2]);
}


1;

__END__


=back

=head1 AUTHOR AND LICENSING

For support and licensing information refer to L<Net::UPS|Net::UPS/"AUTHOR">

=cut


package Net::UPS::Service;

# $Id: Service.pm,v 1.4 2005/11/09 18:23:52 sherzodr Exp $

use strict;
use Carp ( 'croak' );
use Class::Struct;

struct(
    code            => '$',
    label           => '$',
    total_charges   => '$',
    rates           => '@',
    rated_packages  => '@',
    guaranteed_days => '$',
);

sub SERVICE_CODES () {
    return {
        NEXT_DAY_AIR            => '01',
        '2ND_DAY_AIR'           => '02',
        GROUND                  => '03',
        WORLDWIDE_EXPRESS       => '07',
        WORLDWIDE_EXPEDITED     => '08',
        STANDARD                => '11',
        '3_DAY_SELECT'          => '12',
        '3DAY_SELECT'           => '12',
        NEXT_DAY_AIR_SAVER      => '13',
        NEXT_DAY_AIR_EARLY_AM   => '14',
        WORLDWIDE_EXPRESS_PLUS  => '54',
        '2ND_DAY_AIR_AM'        => '59'
    };
}

sub SERVICE_CODES_REVERSE () {
    return {
        map { SERVICE_CODES->{$_}, $_ } keys %{SERVICE_CODES()}
    };
}


sub new_from_code {
    my $class = shift;
    my $code  = shift;

    unless ( defined $code ) {
        croak "new_from_code(): usage error";
    }

    $code = sprintf("%02d", $code);

    my $label = SERVICE_CODES_REVERSE->{$code};
    unless ( defined $label ) {
        croak "new_from_code(): no such service code '$code'";
    }
    return $class->new(code=>$code, label=>$label);
}


sub new_from_label {
    my $class = shift;
    my $label = shift;

    unless ( defined $label ) {
        croak "new_from_label(): usage error";
    }
    my $code = SERVICE_CODES->{$label};
    unless ( defined $code ) {
        croak "new_from_label(): no such service '$label'";
    }
    return $class->new(code=>$code, label=>$label);
}


sub name {
    my $self = shift;
    unless ( $self->label ) {
        return "UNKNOWN";
    }
    my $name = $self->label();
    $name =~ s/_/ /g;
    return $name;
}


sub cache_id { $_[0]->code }

1;

__END__;

=head1 NAME

Net::UPS::Service - Class representing a UPS service

=head1 SYNOPSIS

    $services = $ups->shop_for_rates($from, $to, $package);
    unless ( defined $services ) {
        die $ups->errstr;
    }
    unless ( @$services ) {
        die "There are no services available for your address";
    }
    print "Following services are available for your address to ship that package:\n";
    while (my $service = shift @$services ) {
        printf("%s => \$.2f\n", $service->label, $service->total_charges);
    }

=head1 DESCRIPTION

Net::UPS::Service represents a single UPS shipping service. In typical programming environment, the only time you will interact with this object is when it's returned from C<shop_for_rates()> method of Net::UPS.

=head1 ATTRIBUTES

Following attributes are available in all Services

=over 4

=item code()

Two digit service code as used by UPS Online Tools. It is not something useful for an average programmer.

=item label()

Label assigned by Net::UPS to each service code, to rid programmer of having to have service codes table in front of him the whole time he's coding.

=item total_charges()

Monetary value of total cost of shipping package(s). If you had multiple packages passed to C<shop_for_rates()> method, then total_charges() is the total of all the rates' C<total_charges()>. Don't get confused!

=item rates()

An array reference to a list of rates quoted by this service. Amount of rates always equals amount of packages being rated, so there is always only one rate per package. If there was only one package rated, than C<rates()> returns an arrayref with a single Net::UPS::Rate object.

=item rated_packages()

Reference to a list of packages rated using this service. If there was only one package rated, rated_packages() returns an arrayref containing a single element. Each package represented by Net::UPS::Package instance.

=item guaranteed_days()

Guaranteed days in transit. You can use this option to calculate the exact date the customer can expect the package delivered. This attributes seems to be undef for GROUND service.

=back

=head1 METHODS

Net::UPS::Service is a Class::Struct. In addition, following methods are provided:

=over 4

=item new_from_code($code)

Creates a Net::UPS::Service instance using the service code. Example:

    $service = Net::UPS::Service->new_from_code('03');
    printf("Service is: %s\n", $service->label);

    # outputs:
    Service is: GROUND

=item new_from_label($label)

Create Net::UPS::Service instance using the service label. Example:
    
    $service = Net::UPS::Service->new_from_label('2ND_DAY_AIR');
    printf("Service code is: %s\n", $service->code);

    # Outputs:
    Service code is: 02

=item name()

Similar to label(), except underscores will be removed before output. For example:

    $service = Net::UPS::Service->new_from_code('07');
    printf("Service label is: %s\n", $service->label);
    printf("Service name  is: %s\n", $service->name);

    # Outputs:
    Service label is: WORLDWIDE_EXPRESS
    Service name  is: WORLDWIDE EXPRESS

=back

=head1 AUTHOR AND LICENSING

For support and licensing information refer to L<Net::UPS|Net::UPS/"AUTHOR">

=cut

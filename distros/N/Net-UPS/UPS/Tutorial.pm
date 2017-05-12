package Net::UPS::Tutorial;

$Net::UPS::Tutorial::VERSION = '1.00';


=pod

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::UPS::Tutorial - Simple class implementing UPSOnlineTools API

=head1 SYNOPSIS

    use Net::UPS;
    $ups = Net::UPS->new("username", "password", "BADFASR143124ABAS");

    # prepare package
    $pkg = Net::UPS::Package->new(length=>24, width=>20, height=>2, weight=>4);

    # calculate rate
    $rate = $ups->rate(15241, 48823, $pkg);

    printf("Total Charges: \$.2f\n", $rate->total_charges);


=head1 DESCRIPTION

Net::UPS implements UPS Online Tools API, as documented at http://www.ups.com/content/us/en/bussol/itprof/online_tools.html . Currently implemented APIs are:

=over 4

=item UPS Rates and Services

=item UPS U.S. Address Verification Service

=back

To add UPS functionality to your e-commerce web site, you first have to register with UPS.com, request a Developers Key and XML Access Key. Developers Key will grant  you access to online documentation, which you may no longer need, since Net::UPS is packed with all that knowledge. XML Access Key grants you access to UPS.com's resources. Net::UPS requires you obtain XML Access Key.

=head1 PROGRAMMING STYLE

=head2 OVERVIEW

Programming style of Net::UPS is somewhat straightforward. For example, for I<Rates and Services> API, you first have to prepare your package, define shipper's and recipients's address, and submit request. For I<Address Verification>, you have to prepare the address to be verified, and you have to submit it for verification.

In true e-commerce environment, you usually use more than one of these APIs at the same time. For example, during a checkout, customer may be prompted for a shipping address, because without this you will not be able to provide the customer the most accurate shipping and handling charge. Once you have customer's shipping address, you may want to verify the address using UPS Address Verification Service. If address verifies, you create a package out of the customer's shopping cart, and submit it back to UPS to calculate the rates, or get the list of rates and services available from your address to that of the customer.

For that purpose, we designed Net::UPS to be singleton, and you have to create Net::UPS object at the start of the process. You will not be required to provide your access information any more.

Any classes that require your access information will consult in-memory Net::UPS object. That's how you create Net::UPS object:

    $ups = Net::UPS->new($username, $password, $xml_access_key);

$username and $password are your login information to your UPS.com profile. $xml_access_key is something you were supposed to get from UPS after receiving your Developer's Key.

Above code doesn't try to authenticate the account at this point, thus it never returns an error of any kind. If any of the above information are not correct, you will not find out about it until Net::UPS actually connects to UPS.com.

=head2 UPS RATES AND SERVICES

To calculate UPS Rates and Services for a single package, using a specific service, you first have to create Net::UPS instance as described above. Then, you have to prepare your packages using Net::UPS::Package. Suppose, we have a print of size 18" by 30". We could package the print in a box of 24 by 34, which will be about 1.5" thick, weighing about a pound:

    $package = Net::UPS::Package->new(
        length  => 34, 
        width   => 24, 
        height  => 1.5, 
        weight  => 1
    );

By default Net::UPS uses English system of measurement. If you want to use metric units:

    $package = Net::UPS::Package->new(
        length              =>  70, 
        width               => 50, 
        height              => 3, 
        weight              => 1,
        measurement_system  =>'metric'
    );

Now all the length units are in centimeters, and weight is measured in KG.

You can prepare multiple packages. Just repeat the above procedure for all the packages, before you request a rate from UPS. By doing so you save network resources. For limits on number of packages submitted at single request consult with UPS Online Tools API, for Net::UPS does not enforce any limit.

Before you can submit your package for a rate quote,  you have to prepare two more objects, Shipper's (Your) address, and Recipients's (the customer's) address. That's where Net::UPS::Address comes in.

In calculating shipping cost, the only essential part of the address is the destination and origination zip code (for US). So instead of preparing an address object, you could alternatively pass raw zip code string to C<rate()> method, like so:

    my $rate = $ups->rate($zip_from, $zip_to, $package);

If you had multiple packages to submit:

    $ups->rate($zip_from, $zip_to, \@packages);

Alternatively, $zip_from and $zip_to can be replaced with instances of Net::UPS::Address class.

If C<rate()> fails, it returns undef. Reason for failure can be found by calling $ups->errstr.

On success, return value of C<rate()> is an instance of L<Net::UPS::Rate|Net::UPS::Rate> class. If you passed more than one package, it returns a list of Net::UPS::Rate instances, one for each package. The order of the rates returned correspond to the order of the packages. If you prefer to loose track of the order of packages, you can alternatively consult L<rated_package|Net::UPS::Rate/rated_package> accessor method to get to the instance of rated Net::UPS::Package object. Consider the following example, which rates a single package:

    $rate = $ups->rate($zip_from, $zip_to, $package);
    unless ( defined $rate ) {
        die "Couldn't calculate rates for your package: " . $ups->errstr;
    }
    printf("Sending this package will cost you \$%.2f\n", $rate->total_charges);

Following example shows how to rate multiple packages:

    $rates = $ups->rate($zip_from, $zip_to, \@packages);
    unless ( defined $rates ) {
        die "Couldn't calculate rates for submitted packages: " . $ups->errstr);
    }
    while ($rate = shift @$rates ) {
        printf("PKG %d => %.2f\n", $rate->rated_package->id, $rate->total_charges);
    }


See L<Net::UPS::Rate|Net::UPS::Rate> for details.

More often than not you want to be able to display all the shipping options your customer has to ship particular package. C<shop_for_rates()> does just that. It's syntax is identical to that of C<rate()>, but returns an array of available services, each an instance of Net::UPS::Service class, regardless of the number of packages being rated.

    $services = $ups->shop_for_rates($zip_from, $zip_to, $package);
    unless ( defined @services ) {
        die "shop_for_rates() failed: " . $ups->errstr;
    }
    while ($service = shift @$services ) {
        printf("%22s => \$.2f\n", $service->label, $service->total_charges);
    }

C<< $service->rates() >> returns an arrayref of Net::UPS::Rate instances, for each package. If there's only one package, C<< $service->rates() >> returns an arrayref with a single element.

In the previous example do not confuse C<< $rate->total_charges() >> with C<< $service->total_charges() >>. There is a subtle, but very important distinction. C<< $rate->total_charges() >> returns your total cost for shipping a particular package using a particular service. C<< $service->total_charges() >>, on the other hand, returns your total cost for shipping all the packages using a particular service. In the case where you're shipping a single package, your C<< $service->total_charges() >> and C<< $rate->total_charges() >> will be identical.

Alternatively, you can rate a single package directly using Net::UPS::Package:

    $rate = $package->rate($zip_from, $zip_to);
    printf("Your package costs \$%.2f to ship to %s\n", $rate->cost, $rate

This envokes C<Net::UPS::rate()>.

See L<Net::UPS::Package> and L<Net::UPS::Service> for more details.

=head3 SPECIFYING SERVICE OPTIONS

While rating, Net::UPS assumes defaults appropriate for a typical retailer. However, not all the defaults might be true about your business.

For example, your rate may be different if you have a daily pickup type, than if you have an occasional pickup. Your rate may be different if you charge all the orders to your UPS account, than if you don't. Your rate can also be determined by your CustomerClassification field.

Opotions discussed in this section allow you to set/unset these options to get the most accurate rate.

=over 4

=item service

Specifies service type. UPS Online Tools understands service code, but symbolic names are supported by Net::UPS for ease of use. Available service types are I<NEXT_DAY_AIR>, I<2ND_DAY_AIR>, I<GROUND>, I<WORLDWIDE_EXPRESS>, I<WORLDWIDE_EXPDEDITED>, I<STANDARD>, I<3 DAY_SELECT>, I<NEXT_DAY_AIR_SAVER>, I<NEXT_DAY_AIR_EARLY_AM>, I<WORLDWIDE_EXPRESS_PLUS>, I<2ND_DAY_AIR_AM>. These are all the service types available for US as of this writing. Some of the services originating from outside the US, although have the same name as that of US origin, their codes might be different. Care should be exercised in using Net::UPS if package's place of origin is not US. In these cases service type should be provided in the form of Codes, as documented in UPS Online Tools API documentation

=item packaging

Specifies type of packaging used. Default is I<PACKAGE>. Additional available options are I<TUBE>, I<PAK>, I<EXPRESS_BOX>, I<25KG_BOX>, I<10KG_BOX>. Any other options should be specified in the form of Codes, as documented in UPS Online Tools API.

=item pickup_type

Type of pickup. Available symbolic values are "DAILY", "OCCASIONAL", "ONE_TIME". Any other values should be specified using their codes as documented in UPS Online Tools API.

=back

=head1 AUTHOR

Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt>

=head1 SEE ALSO

L<Business::UPS>, L<Business::Shipping>

=cut

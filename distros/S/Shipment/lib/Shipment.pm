# ABSTRACT: Interface to Popular Shipping Services
package Shipment;
$Shipment::VERSION = '3.07';
use Shipment::Address;
use Shipment::Package;

use Shipment::Generic;
use Shipment::FedEx;
use Shipment::Purolator;
use Shipment::UPS;
use Shipment::Temando;




sub generic {
    shift; return Shipment::Generic->new(@_)
}


sub canadapost {
    shift; return Shipment::CanadaPost->new(@_)
}



sub fedex {
    shift; return Shipment::FedEx->new(@_)
}


sub purolator {
    shift; return Shipment::Purolator->new(@_)
}


sub ups {
    shift; return Shipment::UPS->new(@_)
}


sub temando {
    shift; return Shipment::Temando->new(@_)
}


sub address {
    shift; return Shipment::Address->new(@_)
}


sub package {
    shift; return Shipment::Package->new(@_)
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment - Interface to Popular Shipping Services

=head1 VERSION

version 3.07

=head1 SYNOPSIS

  use Shipment;

  my $shipment = Shipment->new;
     
  $shipment->ups(
    from_address => $shipment->address(...),
    to_address => $shipment->address(...),
    packages => [$shipment->package(...)]
  );

  foreach my $service ( $shipment->all_services ) {
    print $service->id . "\n";
  }

  $shipment->rate( 'express' );
  print $service->cost . "\n";

  $shipment->ship( 'ground' );
  $shipment->get_package(0)->label->save;

=head1 DESCRIPTION

This library provides an interface to popular shipping/courier services.

See the relevant module for details on usage.

For code examples, see https://github.com/pullingshots/Shipment/tree/master/eg

=over

=item generic

  The generic method returns a L<Shipment::Generic> object. See L<Shipment::Generic> for
  more details.

=item canadapost

The fedex method returns a L<Shipment::CanadaPost> object. See L<Shipment::CanadaPost> for more details.

=item fedex

The fedex method returns a L<Shipment::FedEx> object. See L<Shipment::FedEx> for more details.

=item purolator

The purolator method returns a L<Shipment::Purolator> object. See L<Shipment::Purolator> for more details.

=item ups

The ups method returns a L<Shipment::UPS> object. See L<Shipment::UPS> for more details.

=item temando

The temando method returns a L<Shipment::Temando> object. See L<Shipment::Temando> for more details.

=item address

The address method returns a L<Shipment::Address> object. See L<Shipment::Address> for more details.

=item package

The package method returns a L<Shipment::Package> object. See L<Shipment::Package> for more details.

=back

=head1 AUTHOR

Andrew Baerg @ <andrew at pullingshots dot ca>

http://pullingshots.ca/

=head1 BUGS

Issues can be submitted at https://github.com/pullingshots/Shipment/issues

=head1 COPYRIGHT

Copyright (C) 2016 Andrew J Baerg, All Rights Reserved

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Andrew Baerg <baergaj@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andrew Baerg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

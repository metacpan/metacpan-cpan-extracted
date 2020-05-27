package Shipment::Service;
$Shipment::Service::VERSION = '3.05';
use strict;
use warnings;


use Data::Currency;
use Scalar::Util qw/blessed/;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw( DateAndTime );
use Shipment::Base qw/coerce_datetime/;
use namespace::clean;


has 'id' => (
    is  => 'rw',
    isa => Str,
);

has 'carrier_id' => (
    is  => 'rw',
    isa => Str,
);


has 'name' => (
    is  => 'rw',
    isa => Str,
);

has 'carrier_name' => (
    is  => 'rw',
    isa => Str,
);

has 'service_name' => (
    is  => 'rw',
    isa => Str,
);


has 'package' => (
    is  => 'rw',
    isa => InstanceOf ['Shipment::Package'],
);


has 'etd' => (
    is  => 'rw',
    isa => Num,
);

has 'pickup_etd' => (
    is  => 'rw',
    isa => Num,
);


has 'ship_date' => (
    is     => 'rw',
    isa    => DateAndTime,
    coerce => \&Shipment::Base::coerce_datetime,
);


has 'eta' => (
    is     => 'rw',
    isa    => DateAndTime,
    coerce => \&Shipment::Base::coerce_datetime,
);


has 'guaranteed' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);


has 'cost' => (
    is      => 'rw',
    isa     => InstanceOf ['Data::Currency'],
    default => sub { Data::Currency->new(0) },
);

has 'base_cost' => (
    is      => 'rw',
    isa     => InstanceOf ['Data::Currency'],
    default => sub { Data::Currency->new(0) },
);

has 'tax' => (
    is      => 'rw',
    isa     => InstanceOf ['Data::Currency'],
    default => sub { Data::Currency->new(0) },
);


has 'extra_charges' => (
    is      => 'rw',
    isa     => InstanceOf ['Data::Currency'],
    default => sub { Data::Currency->new(0) },
);

has 'adjustments' => (
    is      => 'rw',
    isa     => InstanceOf ['Data::Currency'],
    default => sub { Data::Currency->new(0) },
);


has 'options' => (
    is  => 'rw',
    isa => HashRef [Str],
);


has 'extras' => (
    is  => 'rw',
    isa => HashRef [InstanceOf ['Shipment::Service']],
    default => sub { {} },
);


has 'discount' => (
    is      => 'rw',
    isa     => InstanceOf ['Data::Currency'],
    default => sub { Data::Currency->new(0) },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Service

=head1 VERSION

version 3.05

=head1 SYNOPSIS

  use Shipment::Service;
  use Data::Currency;

  my $service = Shipment::Service->new(
    id => '02',
    name => 'Domestic Ground',
    cost => Data::Currency->new(10, 'USD'),
  );

=head1 NAME

Shipment::Service - a shipping service

=head1 ABOUT

This class defines a shipping service. It is used in a Shipment::Base class
for listing available services or storing details about a rate.

=head1 Class Attributes

=head2 id, carrier_id

The service id and carrier id as defined by a shipping service

type: String

=head2 name, carrier_name, service_name

A descriptive name for the service

type: String

=head2 package

The package type accepted by this service

type: Shipment::Package

=head2 etd, pickup_etd

The estimated transit days for the service

type: Number

=head2 ship_date

The shipment date

type: DateAndTime

=head2 eta

The estimated time of arrival

type: DateAndTime

=head2 guaranteed

Whether or not the eta is guaranteed by the carrier

type: Bool

=head2 cost, base_cost, tax

The cost of the service

type: Data::Currency

=head2 extra_charges, adjustments

Any extra charges and adjustments that will be applied, but are not included in the cost

type: Data::Currency

=head2 options

Available options for the service (this attribute was added for Purolator)

type: HashRef[Str]

=head2 extras

Extra service charges (Insurance, Carbon Offset, etc) - this attribute was added for Temando

type: HashRef[L<Shipment::Service>]

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

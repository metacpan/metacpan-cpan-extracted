package Shipment::Package;
$Shipment::Package::VERSION = '2.03';
use strict;
use warnings;


use Data::Currency;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;


has 'id' => (
    is  => 'rw',
    isa => Str,
);


has 'type' => (
    is  => 'rw',
    isa => Str,
);


has 'name' => (
    is  => 'rw',
    isa => Str,
);


has 'notes' => (
    is  => 'rw',
    isa => Str,
);


has 'fragile' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);


has 'weight' => (
    is  => 'rw',
    isa => Num,
);


has 'length' => (
    is  => 'rw',
    isa => Num,
);

has 'width' => (
    is  => 'rw',
    isa => Num,
);

has 'height' => (
    is  => 'rw',
    isa => Num,
);


has 'insured_value' => (
    is      => 'rw',
    isa     => InstanceOf ['Data::Currency'],
    default => sub { Data::Currency->new(0) },
);


has 'goods_value' => (
    is      => 'rw',
    isa     => InstanceOf ['Data::Currency'],
    lazy    => 1,
    builder => 1,
);

sub _build_goods_value {
    return shift->insured_value;
}


has 'label' => (
    is  => 'rw',
    isa => InstanceOf ['Shipment::Label'],
);


has 'tracking_id' => (
    is  => 'rw',
    isa => Str,
);


has 'cost' => (
    is      => 'rw',
    isa     => InstanceOf ['Data::Currency'],
    default => sub { Data::Currency->new(0) },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Package

=head1 VERSION

version 2.03

=head1 SYNOPSIS

  use Shipment::Package;

  my $package = Shipment::Package->new(
    weight => 10,
    length => 18,
    width  => 18,
    height => 24,
  );

=head1 NAME

Shipment::Package - a package to be shipped

=head1 ABOUT

This class defines a package to be shipped. It also includes attributes which
are set after a shipment has been created (label, cost, tracking_id)

=head1 Class Attributes

=head2 id

The package type id as defined by a shipping service

type: String

=head2 type

The package type as defined by a shipping service (i.e. "envelope")

type: String

=head2 name

A descriptive name for the package (i.e. "12x12x12 box")

type: String

=head2 notes

Notes (i.e. to describe the package contents)

type: String

=head2 fragile

Whether or not the items being sent are fragile

=head2 weight

The weight of the package. Units are determined by the Shipment::Base class

type: Number

=head2 length, width, height

The dimensions of the package. Units are determined by the Shipment::Base class

type: Number

=head2 insured_value

The value of the contents to be insured

type: Data::Currency

=head2 goods_value

The value of the contents

type: Data::Currency

=head2 label

The shipping label. Set by a Shipment::Base class

type: Shipment::Label

=head2 tracking_id

The tracking id. Set by a Shipment::Base class. 

Also can be used to define a tracking id to cancel or track.

type: String

=head2 cost

The cost to ship this package. Set by a Shipment::Base class

type: Data::Currency

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

This software is copyright (c) 2016 by Andrew Baerg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

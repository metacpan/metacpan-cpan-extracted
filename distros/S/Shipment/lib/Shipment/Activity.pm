package Shipment::Activity;
$Shipment::Activity::VERSION = '3.10';
use strict;
use warnings;


use Shipment::Address;
use Scalar::Util qw/blessed/;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw( DateAndTime );
use Shipment::Base qw/coerce_datetime/;
use namespace::clean;


has 'description' => (
  is => 'rw',
  isa => Str,
);


has 'date' => (
    is     => 'rw',
    isa    => DateAndTime,
    coerce => \&Shipment::Base::coerce_datetime,
);


has 'location' => (
  is => 'rw',
  isa => InstanceOf['Shipment::Address'],
);



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Activity

=head1 VERSION

version 3.10

=head1 SYNOPSIS

  use Shipment::Activity;

  my $activity = Shipment::Activity->new(
    status => 'Delivered',
    status_date => '2016-09-04 22:14:53'
  );

=head1 NAME

Shipment::Activity - a tracking activity

=head1 ABOUT

This class defines a shipment tracking activity. It is used in a Shipment::Base class
for storing tracking activities.

=head1 Class Attributes

=head2 description

The description of the activity.

type: String

=head2 date

The date of the activity

type: DateAndTime

=head2 location

The location of the activity

type: Shipment::Address

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

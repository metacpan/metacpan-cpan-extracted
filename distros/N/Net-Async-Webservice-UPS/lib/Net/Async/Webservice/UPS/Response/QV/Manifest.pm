package Net::Async::Webservice::UPS::Response::QV::Manifest;
$Net::Async::Webservice::UPS::Response::QV::Manifest::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::QV::Manifest::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str Bool ArrayRef HashRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use Types::DateTime DateTime => { -as => 'DateTimeT' };
use namespace::autoclean;

# ABSTRACT: a Quantum View "manifest" event


has pickup_date => (
    is => 'ro',
    isa => DateTimeT,
    required => 0,
);

has scheduled_delivery_date => (
    is => 'ro',
    isa => DateTimeT,
    required => 0,
);

has service => (
    is => 'ro',
    isa => Service,
    required => 0,
);

has shipper => (
    is => 'ro',
    isa => Shipper,
    required => 0,
);

has from => (
    is => 'ro',
    isa => Address,
    required => 0,
);

has to => (
    is => 'ro',
    isa => Contact,
    required => 0,
);

has reference_number => (
    is => 'ro',
    isa => HashRef,
    required => 0,
);

has document_only => (
    is => 'ro',
    isa => Str,
    required => 0,
);

has packages => (
    is => 'ro',
    isa => ArrayRef[QVPackage],
    required => 0,
);

has saturday_delivery => (
    is => 'ro',
    isa => Bool,
    required => 0,
);

has saturday_pickup => (
    is => 'ro',
    isa => Bool,
    required => 0,
);

has call_tag => (
    is => 'ro',
    isa => HashRef,
    required => 0,
);

# TODO continue from page 60

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::QV::Manifest - a Quantum View "manifest" event

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

B<INCOMPLETE and UNUSED!>

Object representing the
C<QuantumViewEvents/SubscriptionEvents/SubscriptionFile/Manifest>
elements in the Quantum View response. Attribute descriptions come
from the official UPS documentation.

=for Pod::Coverage pickup_date
scheduled_delivery_date
service
shipper
from
to
reference_number
document_only
packages
saturday_delivery
saturday_pickup
call_tag

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

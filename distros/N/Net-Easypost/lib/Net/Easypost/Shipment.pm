package Net::Easypost::Shipment;
$Net::Easypost::Shipment::VERSION = '0.18';
use Moo;
with qw/Net::Easypost::PostOnBuild/;
with qw/Net::Easypost::Resource/;

use Carp qw/croak/;
use Types::Standard qw/ArrayRef HashRef InstanceOf Str/;

has [qw/from_address to_address/] => (
   is       => 'ro',
   isa      => InstanceOf['Net::Easypost::Address'],
   required => 1,
);

has 'parcel' => (
   is       => 'rw',
   isa      => InstanceOf['Net::Easypost::Parcel'],
   required => 1,
);

has 'customs_info' => (
   is  => 'rw',
   isa => InstanceOf['Net::Easypost::CustomsInfo'],
);

has 'scan_form' => (
   is  => 'rw',
   isa => InstanceOf['Net::Easypost::ScanForm'],
);

has 'rates' => (
   is  => 'rwp',
   isa => ArrayRef[InstanceOf['Net::Easypost::Rate']],
);

has 'options' => (
   is  => 'rw',
   isa => HashRef[Str],
);

sub _build_fieldnames { 
    return [qw/to_address from_address parcel customs_info scan_form rates options/];
}

sub _build_role      { 'shipment'   }
sub _build_operation { '/shipments' }

sub BUILD {}
after BUILD => sub {
   my ($self) = @_;

   my $resp = $self->requester->post(
      $self->operation,
      $self->serialize,
   );
   $self->_set_id( $resp->{id} );
   $self->_set_rates(
      [  map {
            Net::Easypost::Rate->new(
               id          => $_->{id},
               carrier     => $_->{carrier},
               service     => $_->{service},
               rate        => $_->{rate},
               shipment_id => $self->id,
            )
         } @{ $resp->{rates} }
      ]
   );
};

sub serialize {
   my ($self) = @_;

   # want a hashref of e.g., shipment[to_address][id] => foo from all defined attributes
   return {
       map { $self->role . "[$_][id]" => $self->$_->id }
       grep { defined $self->$_ }
          qw(to_address from_address parcel)
   };
}

sub clone {
   my ($self) = @_;

   return Net::Easypost::Shipment->new(
       map  { $_ => $self->$_ }
       grep { defined $self->$_ }
          'id', @{ $self->fieldnames }
   );
}

sub buy {
   my ($self, %options) = @_;

   my $rate; 
   if ( exists $options{rate} && $options{rate} eq 'lowest' ) {
      ($rate) = 
         sort { $a->{rate} <=> $b->{rate} } @{ $self->rates };
   } 
   elsif ( exists $options{service_type} ) {
      ($rate) =
         grep { $options{service_type} eq $_->service } @{ $self->rates };
   }
   else {
      croak "Missing 'service' or 'rate' from options hash";
   }

   unless ( $rate ) {
      my $msg = "Allowed services and rates for this shipment are:\n";
      foreach my $rate ( @{ $self->rates } ) {
         $msg .= sprintf("\t%-15s: %4.2f\n", $rate->service, $rate->rate);
      }

      croak "Invalid service '$options{service_type}' selected for shipment " . $self->id . "\n$msg";
   }

   my $response = $self->requester->post(
      $self->operation . '/' . $self->id . '/buy',
      $rate->serialize
   );

   my $label = $response->{postage_label};
   return Net::Easypost::Label->new(
      id            => $label->{id},
      tracking_code => $response->{tracking_code},
      url           => $label->{label_url},
      filetype      => $label->{label_file_type},
      rate          => Net::Easypost::Rate->new($response->{selected_rate}),
      filename      => 'EASYPOST_LABEL_'
                        . $label->{id}
                        . '.'
                        . substr($label->{label_file_type}, index($label->{label_file_type}, '/') + 1),
   );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Easypost::Shipment

=head1 VERSION

version 0.18

=head1 SYNOPSIS

Net::Easypost::Shipment->new

=head1 NAME 

Net::Easypost::Shipment

=head1 ATTRIBUTES

=over 4 

=item to_address

Address this Shipment is going to

=item from_address

Address this Shipment is coming from

=item parcel

Parcel that is being shipped

=item customs_info

Customs information about this Shipment, optional (only for international shipments)

=item scan_form

USPS Tracking information, optional

=item rates

Array of Net::Easypost::Rate objects

=item options

Array of shipping options, may not be supported by all carriers

=back

=head1 METHODS

=over 4 

=item _build_fieldnames

Attributes that make up an Address, from L<Net::Easypost::Resource>

=item _build_role

Prefix to data when POSTing to the Easypost API about Address objects

=item _build_operation

Base API endpoint for operations on Address objects

=item BUILD

Constructor for a Shipment object, overrides the base BUILD method in L<Net::Easypost::PostOnBuild>

=item clone

return a deep-copy of this object

=item serialize

Format this object into a form suitable for use with the Easypost service.
Overrides base implementation in L<Net::Easypost::PostOnBuild>

=item buy

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>, Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

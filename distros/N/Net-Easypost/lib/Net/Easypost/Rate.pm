package Net::Easypost::Rate;
$Net::Easypost::Rate::VERSION = '0.19';
use Moo;
with qw(Net::Easypost::Resource);

has 'carrier' => (
    is      => 'ro',
    default => 'USPS',
);

has [qw/service rate shipment_id/] => (
    is => 'ro',
);

sub _build_fieldnames { 
    return [qw(carrier service rate shipment_id)];
}
sub _build_role      { 'rate' }
sub _build_operation { ''     }

sub serialize {
   my ($self) = @_;

   return { 
       'rate[id]' => $self->id 
   };
}

sub clone {
   my ($self) = @_;

   return Net::Easypost::Rate->new(
       map  { $_ => $self->$_ }
       grep { defined $self->$_ }
           'id', @{ $self->fieldnames }
   );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Easypost::Rate

=head1 VERSION

version 0.19

=head1 NAME 

Net::Easypost::Rate

=head1 SYNOPSIS 

Net::Easypost::Rate->new

=head1 ATTRIBUTES 

=over 4 

=item carrier

The shipping carrier. At the current time, the United States Postal Service (USPS) is the only
supported carrier.

=item service

The shipping service name. For example, for the USPS, these include 'Priority', 'Express',
'Media Mail' and others.

=item rate

The price in US dollars to ship using the associated carrier and service.

=item shipment_id

ID of the shipment that this Rate object relates to

=back

=head1 METHODS 

=over 4 

=item _build_fieldnames 

=item _build_role 

=item clone 

returns a new Rate object that is a deep-copy of this Rate object

=item serialize

serialized form of Rate objects

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>, Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

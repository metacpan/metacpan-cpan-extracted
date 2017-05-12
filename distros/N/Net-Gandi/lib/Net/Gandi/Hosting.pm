#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Hosting;
{
  $Net::Gandi::Hosting::VERSION = '1.122180';
}

# ABSTRACT: Hosting interface

use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

use Net::Gandi::Types Client => { -as => 'Client_T' };
use Net::Gandi::Hosting::Datacenter;
use Net::Gandi::Hosting::VM;
use Net::Gandi::Hosting::Disk;
use Net::Gandi::Hosting::Image;
use Net::Gandi::Hosting::Iface;
use Net::Gandi::Hosting::IP;

has client => (
    is       => 'rw',
    isa      => Client_T,
    required => 1,
);


sub vm {
    my ( $self, $id ) = validated_list(
        \@_,
        id => { isa => 'Int', optional => 1 }
    );

    my %args  = ( client => $self->client );
    $args{id} = $id if $id;

    my $vm = Net::Gandi::Hosting::VM->new(%args);

    return $vm;
}


sub disk {
    my ( $self, $id ) = validated_list(
        \@_,
        id => { isa => 'Int', optional => 1 }
    );

    my %args  = ( client => $self->client );
    $args{id} = $id if $id;

    my $disk = Net::Gandi::Hosting::Disk->new(%args);

    return $disk;
}


sub image {
    my ( $self, $id ) = validated_list(
        \@_,
        id => { isa => 'Int', optional => 1 }
    );

    my %args  = ( client => $self->client );
    $args{id} = $id if $id;

    my $image = Net::Gandi::Hosting::Image->new(%args);

    return $image;
}


sub iface {
    my ( $self, $id ) = validated_list(
        \@_,
        id => { isa => 'Int', optional => 1 }
    );

    my %args  = ( client => $self->client );
    $args{id} = $id if $id;

    my $iface = Net::Gandi::Hosting::Iface->new(%args);

    return $iface;
}


sub ip {
    my ( $self, $id ) = validated_list(
        \@_,
        id => { isa => 'Int', optional => 1 }
    );

    my %args  = ( client => $self->client );
    $args{id} = $id if $id;

    my $ip = Net::Gandi::Hosting::IP->new(%args);

    return $ip;
}


sub datacenter {
    my ( $self ) = @_;

    my $datacenter = Net::Gandi::Hosting::Datacenter->new(
        client => $self->client,
    );

    return $datacenter;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Net::Gandi::Hosting - Hosting interface

=head1 VERSION

version 1.122180

=head1 METHODS

=head2 vm

  my $vm = $hosting->vm;

Initialize the virtual machine environnement, and return an object representing it.

  input: id (Int) : optional, id of virtual machine
  output: A Net::Gandi::Hosting::VM object

=head2 disk

  my $disk = $hosting->disk;

Initialize the disk environnement, and return an object representing it.

  input: id (Int) : optional, id of disk
  output: A Net::Gandi::Hosting::Disk object

=head2 image

  my $image = $hosting->image;

Initialize the image environnement, and return an object representing it.

  input: id (Int) : optional, id of image
  output: A Net::Gandi::Hosting::Image object

=head2 iface

  my $iface = $hosting->iface;

Initialize the iface environnement, and return an object representing it.

  input: id (Int) : optional, id of iface
  output: A Net::Gandi::Hosting::Iface object

=head2 ip

  my $ip = $hosting->ip;

Initialize the ip environnement, and return an object representing it.

  input: id (Int) : optional, id of ip
  output: A Net::Gandi::Hosting::IP object

=head2 datacenter

  my $datacenter = $hosting->datacenter;

Initialize the datacenter environnement, and return an object representing it.

  input: none
  output: A Net::Gandi::Hosting::Datacenter object

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


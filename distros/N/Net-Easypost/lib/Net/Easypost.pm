package Net::Easypost;
$Net::Easypost::VERSION = '0.18';
use Data::Dumper;
use Carp qw(croak);
use Hash::Merge::Simple qw(merge);
use Moo;

use Net::Easypost::Address;
use Net::Easypost::Label;
use Net::Easypost::Parcel;
use Net::Easypost::Rate;
use Net::Easypost::Request;
use Net::Easypost::Shipment;

# ABSTRACT: Perl client for the Easypost web service



has 'requester' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { return Net::Easypost::Request->new }
);


sub verify_address {
    my ($self, $params) = @_;

    if ( ref($params) eq 'HASH' ) {
        return Net::Easypost::Address->new( $params )->verify;
    }
    elsif ( ref($params) eq 'Net::Easypost::Address' ) {
        return $params->verify;
    }
    else {
        croak "verify_address expects either a hashref or an instance of Net::Easypost::Address\n";
    }
}


sub get_rates {
    my $self = shift; # shift is important here

    my $params;
    if ( scalar @_ == 1 ) {
        if ( ref( $_[0] ) ne 'HASH' ) {
            croak 'get_rates expects a hashref not a '. ref($params) .'\n';
        }
        else {
            $params = shift;
        }
    }
    else {
        $params = { @_ };
    }

    return Net::Easypost::Shipment->new(
        to_address   => $params->{to},
        from_address => $params->{from},
        parcel       => $params->{parcel},
    )->rates;
}


sub buy_label {
    my ($self, $shipment, %options) = @_;

    croak 'Buy label expects a parameter of type Net::Easypost::Shipment'
        unless $shipment || ref($shipment) ne 'Net::Easypost::Shipment';

    return $shipment->buy(%options);
}


sub get_label {
    my ($self, $label_filename) = @_;

    my $resp = $self->requester->post(
        '/postage/get', 
        { label_file_name => $label_filename } 
    );

    return Net::Easypost::Label->new(
        rate          => Net::Easypost::Rate->new( $resp->{rate} ),
        tracking_code => $resp->{tracking_code},
        filename      => $resp->{label_file_name},
        filetype      => $resp->{label_file_type},
        url           => $resp->{label_url}
    );
}


sub list_labels {
    my ($self) = @_;

    my $resp = $self->requester->get( 
        $self->requester->_build_url('/postage/list') 
    );

    return $resp->{postages};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Easypost - Perl client for the Easypost web service

=head1 VERSION

version 0.18

=head1 SYNOPSIS

   use Net::Easypost;

   my $to = Net::Easypost::Address->new(
      name    => 'Johnathan Smith',
      street1 => '710 East Water Street',
      city    => 'Charlottesville',
      state   => 'VA',
      zip     => '22902',
      phone   => '(434)555-5555',
      country => 'US',
   );

   my $from = Net::Easypost::Address->new(
      name    => 'Jarrett Streebin',
      phone   => '3237078576',
      city    => 'Half Moon Bay',
      street1 => '310 Granelli Ave',
      state   => 'CA',
      zip     => '94019',
      country => 'US',
   );

   my $parcel = Net::Easypost::Parcel->new(
      length => 10.0,
      width  => 5.0,
      height => 8.0,
      weight => 10.0,
   );

   my $shipment = Net::Easypost::Shipment->new(
      to_address   => $to,
      from_address => $from,
      parcel       => $parcel,
   );

   my $ezpost = Net::Easypost->new;
   my $label = $ezpost->buy_label($shipment, ('rate' => 'lowest'));

   printf("You paid \$%0.2f for your label to %s\n", $label->rate->rate, $to);
   $label->save;
   printf "Your postage label has been saved to '" . $label->filename . "'\n";

=head1 OVERVIEW

This is a Perl client for the postage API at L<Easypost|https://www.easypost.com/docs/api>. Consider this
API at beta quality mostly because some of these library calls have an inconsistent input
parameter interface which I'm not super happy about. Still, there's enough here to get
meaningful work done, and any future changes will be fairly cosmetic.

Please note! B<All API errors are fatal via croak>. If you need to catch errors more gracefully, I
recommend using L<Try::Tiny> in your implementation.

API key:

You must have your API key stored in an environment variable named 
EASYPOST_API_KEY

=head1 ATTRIBUTES

=head2 requester

HTTP client to POST and GET

=head1 METHODS

=head2 verify_address

This method attempts to validate an address. This call expects to take the same parameters
(in a hashref) or an instance of L<Net::Easypost::Address>, namely:

=over

=item * street1

=item * street2

=item * city

=item * state

=item * zip

=item * country

=back

You may omit some of these attributes like city, state if you supply a zip, or
zip if you supply a city, state.

This call returns a new L<Net::Easypost::Address> object.

Along with the validated address, the C<phone> and C<name> fields will be
copied from the input parameters, if they're set.

The verification works only for addresses in US. If you pass a country
other than US (the default), a warning will be issued, but the
L<Net::Easypost::Address> object will be returned.

=head2 get_rates

This method will get postage rates between two zip codes. It takes the following input parameters:

=over

=item * to => an instance of L<Net::Easypost::Address>

=item * from => an instance of L<Net::Easypost::Address>

=item * parcel => an instance of L<Net::Easypost::Parcel>

=back

This call returns an array of L<Net::Easypost::Rate> objects in an arbitrary order.

=head2 buy_label

This method will attempt to purchase postage and generate a shipping label.

It takes as input:

=over

=item * A L<Net::Easypost::Shipment> object

=item * A L<Net::Easypost::Rate> object

=back

It returns a L<Net::Easypost::Label> object.

=head2 get_label

This method retrieves a label from a past purchase. It takes the label filename as its
only input parameter. It returns a L<Net::Easypost::Label> object.

=head2 list_labels

This method returns an arrayref with all past purchased label filenames. It takes no
input parameters.

=head1 SUPPORT

Please report any bugs or feature requests to "bug-net-easypost at
rt.cpan.org", or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Easypost>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Or, if you wish, you may report bugs/features on Github's Issue Tracker.
L<https://github.com/mrallen1/Net-Easypost/issues>

=head1 SEE ALSO

=over

=item * L<Easypost API docs|https://www.easypost.com/docs/api>

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>, Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

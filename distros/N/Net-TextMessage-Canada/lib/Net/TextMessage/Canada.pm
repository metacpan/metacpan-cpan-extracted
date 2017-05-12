package Net::TextMessage::Canada;
use 5.006;
use Moose;

=head1 NAME
 
Net::TextMessage::Canada - determine the email address for a mobile phone
 
=cut

our $VERSION = '0.02';

=head1 SYNOPSIS
 
This module will determine the email address for a canadian mobile phone
from the phone number and mobile provider.
 
  use Net::TextMessage::Canada;

  my $ntmc = Net::TextMessage::Canada->new;

  # Get the list of providers and their nice names
  my $providers = $ntmc->providers;
  for (@$providers) { ... }

  # Convert a mobile phone provider + phone number into an email
  my $email = $ntmc->to_email( $provider, $mobile_number );

=head1 DESCRIPTION

This module provides an easy interface to map a mobile phone to an
email address to send them a text message.

If this list becomes out of date, please send me updated details.

=head2 IMPORTANT NOTE

The functionality of the email-to-SMS gateway is carrier dependent.  That is to say: some carriers that appreciate you as a human being make it work seamlessly.  Other carriers that want to maximize their wallets may make receiving these messages expensive and awkward.  YMMV, IANAL, see store for details.

=cut
 
has 'provider_map' => (is => 'ro', isa => 'HashRef', lazy_build => 1);

=head1 METHODS
 
=head2 $ntmc->providers();
 
This method returns an arrayref containing a hashref for each
mobile provider in Canada.  The hashref has two keys: id and name
that contain a short id and the full name of the mobile provider.
 
=cut

sub providers {
    my $self = shift;
    my $map = $self->provider_map;
    return [ map { {id => $_, name => $map->{$_}{name}} } 
             sort { $map->{$a}{name} cmp $map->{$b}{name} } keys %$map ];
}

=head2 $ntmc->to_email( $provider, $number );
 
This method returns the email address for the given number and 
mobile provider.
 
=cut

sub to_email {
    my $self = shift;
    my $provider = shift;
    my $number = shift;
    
    my $map = $self->provider_map;
    my $p = $map->{$provider};
    die "$provider is not a valid provider!" unless defined $p;

    return join '@', $number, $p->{domain};
}


sub _build_provider_map {
    my $self = shift;
    return {
        bell => {
            name => 'Bell Canada',
            domain => 'txt.bell.ca',
        },
        rogers => {
            name => 'Rogers Wireless',
            domain => 'pcs.rogers.com',
        },
        fido => {
            name => 'Fido',
            domain => 'fido.ca',
        },
        telus => {
            name => 'Telus',
            domain => 'msg.telus.com',
        },
        virgin => {
            name => 'Virgin Mobile',
            domain => 'vmobile.ca',
        },
        pcmobile => {
            name => 'PC Mobile',
            domain => 'mobiletxt.ca',
        },
        koodo => {
            name => 'Koodo Mobile',
            domain => 'msg.koodomobile.com',
        },
        sasktel => {
            name => 'SaskTel',
            domain => 'sms.sasktel.com',
        },
    };
}

=head1 AUTHOR
 
Luke Closs, C<< <cpan at 5thplane.com> >>
 
=head1 BUGS
 
Please report any bugs or feature requests to C<bug-net-textmessage-canada at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-TextMessage-Canada>. 
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.
 
=head1 SUPPORT
 
You can find documentation for this module with the perldoc command.
 
perldoc Net::TextMessage::Canada
 
You can also look for information at:
 
=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-TextMessage-Canada>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Net-TextMessage-Canada>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Net-TextMessage-Canada>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Net-TextMessage-Canada/>
 
=back
 
=head1 ACKNOWLEDGEMENTS
 
Thanks to Canada's wonderful mobile phone companies for providing this service.
 
=head1 COPYRIGHT & LICENSE
 
Code is copyright 2009 Luke Closs, all rights reserved.
All company names and email domains are obviously owned by those companies.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut

__PACKAGE__->meta->make_immutable;
1;

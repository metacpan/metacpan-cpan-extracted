package WWW::Scraper::Request::ZIPplus4;

use strict;

use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use WWW::Scraper::Request;
use base qw( WWW::Scraper::Request );

sub new {
    my $self = WWW::Scraper::Request::new(
         'ZIPplus4'
        ,{
             'Firm' => ''
            ,'Urbanization' => ''
            ,'DeliveryAddress' => '' # required
            ,'address2' => '' # optional
            ,'City' => ''     # required unless Zip is provided
            ,'State' => ''    # required unless Zip is provided
            ,'ZipCode' => ''  # recommended, else City and State are required
         }
        ,@_);
    return $self;
}

sub GetFieldNames {
    return {
             'Firm' => 'Firm'
            ,'Urbanization' => 'Urbanization'
            ,'DeliveryAddress' => 'Delivery Address'
            ,'City' => 'City'
            ,'State' => 'State'
            ,'ZipCode' => 'Zip Code'
           }
}
sub FieldTitles {
    return {
             'Firm' => 'Firm'
            ,'Urbanization' => 'Urbanization'
            ,'DeliveryAddress' => 'Delivery Address'
            ,'City' => 'City'
            ,'State' => 'State'
            ,'Zip_Code' => 'Zip Code'
           }
}


1;

__END__

=head1 NAME

WWW::Scraper::Request::ZIPplus4 - Canonical form for Scraper::ZIPplus4 requests

=head1 SYNOPSIS

    use WWW::Scraper::Request::ZIPplus4;

    $rqst = new WWW::Scraper::Request::ZIPplus4;
    $rqst->DeliveryAddress('1600 Pennsylvania Ave');
    $rqst->City('Washington');
    $rqst->State('DC');

=head1 DESCRIPTION

This module provides a canonical taxonomy for specifying requests to search engines (via Scraper modules).
C<Request::ZIPplus4> is targeted toward zip+4 validations.

See the C<WWW::Scraper::Request> module for a description of how this interfaces with Scraper modules.

=head1 SPECIAL THANKS

=over 8

=item To Klemens Schmid (klemens.schmid@gmx.de), for FormSniffer.

This tool is an excellent compliment to Scraper to almost instantly discover form and CGI parameters for configuring new Scraper modules.
It instantly revealed what I was doing wrong in the new ZIPplus4 format one day (after hours of my own clumsy attempts).
See FormSniffer at http://www.wap2web.de/formsniffer2.aspx (Win32 only).

=back

=head1 AUTHOR

C<WWW::Scraper::Request> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut




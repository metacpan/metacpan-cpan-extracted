package WWW::Scraper::Request::WSDL;
use strict;

use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

use WWW::Scraper::Request;
use base qw( WWW::Scraper::Request );

sub new {
    my $class = shift;
    my ($scraper, $native_query, $native_options) = @_;
  
    my $servicesDef = $scraper->{'_service'};
    $servicesDef = $servicesDef->{'_servicesDef'};
#    my $serviceDef = $$servicesDef{(keys %{$servicesDef})[0]};
    my @methods = ();
    for my $rpc ( keys %{$servicesDef} ) {
        map { push @methods, $_ } keys %{$$servicesDef{$rpc}};
        last;
    }

    my $self = WWW::Scraper::Request::new(
         'WSDL'
        , \@methods
        ,@_);

    return $self;
}

sub GetFieldNames {
    return {
             'Firm' => 'Firm'
            ,'Urbanization' => 'Urbanization'
            ,'Delivery Address' => 'Delivery Address'
            ,'City' => 'City'
            ,'State' => 'State'
            ,'Zip Code' => 'Zip Code'
           }
}
sub FieldTitles {
    return {
             'Firm' => 'Firm'
            ,'Urbanization' => 'Urbanization'
            ,'Delivery_Address' => 'Delivery Address'
            ,'City' => 'City'
            ,'State' => 'State'
            ,'Zip_Code' => 'Zip Code'
           }
}


1;

__END__

=head1 NAME

WWW::Scraper::Request::WSDL - Canonical form for Scraper::WSDL requests

=head1 SYNOPSIS

    use WWW::Scraper::Request::WSDL;

    $rqst = new WWW::Scraper::Request::WSDL;
    $rqst->skills(['Perl', '!Java']);
    $rqst->locations('CA-San Jose');
    $rqst->payrate('100000/A');

=head1 DESCRIPTION

This module provides a canonical taxonomy for specifying requests to search engines (via Scraper modules).
C<Request::WSDL> is targeted toward job searches.

See the C<WWW::Scraper::Request> module for a description of how this interfaces with Scraper modules.

=head1 AUTHOR

C<WWW::Scraper::Request> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut




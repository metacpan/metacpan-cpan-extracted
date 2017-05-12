use SOAP::Lite;
{ package SOAP::Lite;
    # This is exactly the same as SOAP::Lite::service, except that %services is saved in {'_serviceDefs'}
no warnings;
sub service {
   my $field = '_service';
   my $self = shift->new;
   return $self->{$field} unless @_;
    
   my %services = %{SOAP::Schema->schema($self->{$field} = shift)->parse(@_)->load->services};
   Carp::croak "Cannot activate service description with multiple services through this interface\n" 
     if keys %services > 1; 
      
   my $rtn = (keys %services)[0]->new;
   $rtn->{'_servicesDef'} = \%services;
   return $rtn;
 }
}

package WWW::Scraper::WSDL;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Scraper(qw(2.22));
use WWW::Scraper::Request::WSDL;
use strict;


my $scraperRequest = 
        { 
            'type' => 'WSDL'
#            ,'formNameOrNumber' => undef
#            ,'submitButton' => 'Submit'
            
            # This is the basic URL on which to get the form to build the query.
#            ,'url' => 'http://www.usps.com/ncsc/lookups/lookup_zip+4.html'
            ,'url' => 'http://www.xmethods.net/sd/StockQuoteService.wsdl'
           # specify defaults, by native field names
#           ,'nativeQuery' => 'Delivery+Address'
           ,'nativeDefaults' => { 
                                }
            
            # specify translations from canonical fields to native fields
           ,'defaultRequestClass' => 'WSDL'
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {     
                                 '*' => '*'
                           }
                   }
            # Miscellaneous options for the Scraper operation.
       };

sub new {
    my ($subclass, $serviceAdr, $native_query, $native_options) = @_;
    
    my ($self, $wantsNativeRequest);
    $wantsNativeRequest = $subclass =~ s/^NativeRequest\:\:(.*)$/$1/;
    $self = {};
    bless $self, 'WWW::Scraper::WSDL';
    $self->_wantsNativeRequest($wantsNativeRequest);

    $self->{'agent_name'} = "Mozilla/WWW::Scraper::WSDL/$VERSION";
    $self->{'agent_e_mail'} = 'glenwood@alumni.caltech.edu;MartinThurn@iname.com';

    $self->{'scraperQF'} = 0; # Explicitly declare 'scraperQF' as the deprecated mode.
    $self->{'scraperName'} = 'WSDL';

    $self->{cache} = []; # This eliminates some useless "warnings" from WWW::Search(lines 544-549) during make test.
    # Finally, call the sub-scraper's init() method.
    $self->init($serviceAdr, $native_query, $native_options);
    return $self;
}

use WWW::Scraper::Request::WSDL;
sub init {
    my ($self, $serviceAdr, $native_query, $native_options) = @_;
    $scraperRequest->{'url'} = $serviceAdr if $serviceAdr;
    
    $self->{'_service'} = SOAP::Lite -> service($scraperRequest->{'url'});

    $self->SetRequest( new WWW::Scraper::Request::WSDL($self, $native_query, $native_options) ) unless ( $self->GetRequest());
    return $self;
}


my $scraperFrame =
       [ 'WSDL', 
        [ [
        ] ]
       ];


{
no warnings;
sub testParameters {
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return {
                 'SKIP' => 'WSDL is still in a primitive experimental state.'#'WSDL test parameters have not yet been fixed' 
                ,'TODO' => 'WSDL is still in a primitive experimental state.'
                ,'testNativeQuery' => 'MSFT'
                ,'testNativeOptions' => {
                                             'getQuote' => 'MSFT'
                                        }
                ,'expectedOnePage' => 1
                ,'expectedMultiPage' => 1
                ,'expectedBogusPage' => 1
           };
}
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

1;


__END__
=pod

=head1 NAME

WWW::Scraper::WSDL


=head1 SYNOPSIS

=over 1

=item Simple

 use WWW::Scraper::WSDL(qw(1.00));

 my $WSDL = new WWW::Scraper(
         'WSDL',
        ,{   'Delivery_Address' => '1600 Pennsylvannia Ave'
            ,'City'             => 'Washington'
            ,'State'            => 'DC'
            ,'Zip_Code'         => '20500'
         } );

 while ( my $response = $WSDL->next_response() )
 {    
     print $response->zip()."\n";
 }

=item Complete

 use WWW::Scraper(qw(1.48));
 use WWW::Scraper::Request::WSDL;

 my $WSDL = new WWW::Scraper( 'WSDL' );

 my $request = new WWW::Scraper::Request::WSDL;
 
 # Note: Delivery_Address(), and either Zip_Code(), or City() and State(), are required.
 $request->Delivery_Address('1600 Pennsylvannia Ave');
 $request->City('Washington');
 $request->State('DC');
 $request->Zip_Code('20500');

 $WSDL->scraperRequest($request);
 while ( my $response = $WSDL->next_response() )
 {    
     for ( qw(address city state zip county carrierRoute checkDigit deliveryPoint) ) {
         print "$_: ".${$response->$_()}."\n";
     }
 }

=back

=head1 DESCRIPTION

This class is an WSDL specialization of WWW::Scraper.
It handles making and interpreting WSDL searches
F<http://www.WSDL.com>.

=head1 AUTHOR and CURRENT VERSION


C<WWW::Scraper::WSDL> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



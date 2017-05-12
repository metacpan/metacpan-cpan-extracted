=head1 NAME

Net::Google::Service - SOAP widget(s) for Net::Google

=head1 SYNOPSIS

 use Net::Google::Service;
 my $search = Net::Google::Service->search({debug=>1});

=head1 DESCRIPTION

SOAP widget(s) for Net::Google

=cut

package Net::Google::Service;
use strict;

$Net::Google::Service::VERSION = '1.0';

use SOAP::Lite;
use Carp;

# This clever hack is courtesy Matt Webb:
# http://interconnected.org/home/more/GoogleSearch.pl.txt

# Redefine how the default deserializer handles booleans.
# Workaround because the 1999 schema implementation incorrectly doesn't
# accept "true" and "false" for boolean values.
# See http://groups.yahoo.com/group/soaplite/message/895

*SOAP::XMLSchema1999::Deserializer::as_boolean =
  *SOAP::XMLSchemaSOAP1_1::Deserializer::as_boolean = 
  \&SOAP::XMLSchema2001::Deserializer::as_boolean;

use constant SERVICES => {
			  "cache"    => "GoogleSearch.wsdl",
			  "search"   => "GoogleSearch.wsdl",
			  "spelling" => "GoogleSearch.wsdl",
			 };

use constant SERVICE_CACHE => {};

=head1 PACKAGE METHODS

=head2 __PACKAGE__->search(\%args)

=cut

sub search {
  my $pkg = shift;
  return $pkg->_soap("search",@_);
}

=head2 __PACKAGE__->spelling(\%args)

=cut

sub spelling {
  my $pkg = shift;
  return $pkg->_soap("spelling",@_);
}

=head2 __PACKAGE_->cache(\%args)

=cut

sub cache {
  my $pkg = shift;
  return $pkg->_soap("cache",@_);
}

# Private methods

sub _soap {
  my $pkg     = shift;
  my $service = shift;
  my $args    = shift;

  my $soap = SOAP::Lite->service("file:".__PACKAGE__->_service($service));

  if ($args->{'http_proxy'}) {
    # Get the SOAP transport object
    # Then get its proxy object (note the args)
    # Which is really just an LWP::UserAgent
    # so we get that and set the args (again)
    $soap->transport()->proxy($args->{'http_proxy'})->proxy(http=>$args->{'http_proxy'});
  }

  if ($args->{'debug'}) {
    SOAP::Trace->import(debug=>((ref($args->{debug}) eq "CODE") ? $args->{'debug'} : sub {print STDERR @_}));
  }

  $soap->on_fault(sub{
		    my ($soap,$res) = @_; 
		    my $err = (ref($res)) ? $res->faultstring() : $soap->transport()->status();
		    carp $err;
		    return undef;
		  });

  return $soap;
}

sub _service {
  my $pkg     = shift;
  my $service = shift;

  # This is not the droid you're looking for.
  # We're talking to the constants this way
  # for two reasons :

  # 1) The SERVICE_CACHE->{foo} syntax causes Perl
  #    Perl 5.00502 to break since the "inlined
  #    subroutined-ness" of scalar constants
  #    https://rt.cpan.org/Ticket/Display.html?id=1753

  # 2) Rather than creating a whole bunch of separate
  #    subroutines to abstract away all the ($] > 5.00502)
  #    stuff, I might as well just tack the '&' on
  #    now and be done with it.

  if (exists &SERVICE_CACHE->{$service}) {
    return &SERVICE_CACHE->{$service}
  }

  foreach my $dir (@INC) {
    if (-f "$dir/Net/Google/Services/".&SERVICES->{$service}) {
      &SERVICE_CACHE->{$service} = "$dir/Net/Google/Services/".&SERVICES->{$service};
      return &SERVICE_CACHE->{$service};
    }
  }

  return undef;
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 20:49:03 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Google>

=head1 LICENSE

Copyright (c) 2002-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

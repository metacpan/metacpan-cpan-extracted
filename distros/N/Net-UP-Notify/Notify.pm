package Net::UP::Notify;

use strict;
use vars qw($VERSION);
use LWP::UserAgent;


$VERSION = '1.01';

sub new {
  my $package = shift;
  return bless({}, $package);
  };

sub subscriberid {
	my $self = shift;
	if (@_) {
		$self->{'subscriberid'} = shift;
		($self->{'connecthost'}) = ( $self->{'subscriberid'} =~ /\_(.+)/ );
	};
	return $self->{'subscriberid'};
};

sub location {
	my $self = shift;
        if (@_) {
                $self->{'location'} = shift;
        };
	return $self->{'location'};
};

sub description {
        my $self = shift;
        if (@_) {
                $self->{'description'} = shift;
	};
return $self->{'description'};
};

sub urgency {
        my $self = shift;
        if (@_) {
                $self->{'urgency'} = shift;
	};
return $self->{'urgency'};
};



sub send {
  my $self = shift;
  if (! $self->{'urgency'}) { $self->{'urgency'} = "HIGH" };
  my $ua = LWP::UserAgent->new;
  $ua->agent("up-notify.pl/1.0");
  my $req = HTTP::Request->new(POST => 'http://'.$self->{'connecthost'}.':4445/ntfn/add');
  $req->header("x-up-upnotifyp-version" => "upnotifyp/3.0");
  $req->header("x-up-subno" => "$self->{'subscriberid'}");
  $req->header("x-up-ntfn-ttl" => "0");
  $req->header("x-up-ntfn-channel" => "push");
  $req->header("Content-Location" => "$self->{'location'}");
  my $xmldoc= "<?xml version=\"1.0\"?> \n<!DOCTYPE ALERT \nPUBLIC \"-//PHONE.COM//DTD ALERT 1.0//EN\" \n\"http://www.phone.com/dtd/alert1.xml\"> \n<ALERT LABEL = \"$self->{'description'}\" \nCOUNT = \"1\" \nHREF = \"\" \nURGENCY = \"$self->{'urgency'}\" />\n";
  $req->content_type('application/vnd.uplanet.alert');
  $req->content($xmldoc);
   my $res = $ua->request($req);
   my $toreturn;
	return $res->content;
};

1;
__END__
# Below is stub documentation for your module. You better edit it!
                                                                                
=head1 NAME
                                                                                
Net::UP::Notify - Send "Net Alerts" to cellular phones with the "Unwired Planet" browser (AKA phone.com, AKA OpenWave UP.Browser)
                                                                               
=head1 SYNOPSIS
                                                                                
  use Net::UP::Notify;
  $blah=new Net::UP::Notify;
  $blah->subscriberid("111111111-9999999_atlsnup2.adc.nexteldata.net");
  $blah->location("http://www.perl.com/");
  $blah->description("The Perl.com Homepage");
  print $blah->send;

                                                                                
=head1 DESCRIPTION
                                                                                
This allows you to send a Net Alert to a cellular phone, provided you 
know the subscriber ID of the user.
This also requires the end user to have the Wireless Web service on
their phone, and they also must have it provisioned by the carrier.

This was designed and tested using a Nextel phone, but I think that
both Cingular and Sprint PCS should be supported here when given the
proper subscriberid string.

My intention is to completely support the entire UP SDK, but for right
now, I can only support the sending of Net Alerts.
                                                                                
=head1 AUTHOR
                                                                                
Paul Timmins, E<lt>paul@timmins.netE<gt>
                                                                                
=head1 SEE ALSO
                                                                                
L<perl>. L<LWP::UserAgent>. L<LWP::Request>.
                                                                                
=cut


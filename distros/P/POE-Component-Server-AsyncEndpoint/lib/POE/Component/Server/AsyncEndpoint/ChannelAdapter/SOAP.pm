package POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP;


use warnings;
use strict;
our @EXPORT = ( );
use Switch;

use Carp qw(croak);
use POE;
use base qw(Exporter POE::Component::Client::SOAP);
use vars qw($VERSION);
$VERSION = '0.10';


sub spawn{

  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;
  my %args = @_;

  my $proxy = $args{proxy};
  my $service = $args{service};
  my $to_session = $args{to_session};
  my $to_handler = $args{to_handler};
  my $debug = $args{debug};

  croak "Cannot init SOAP client without valid proxy and service"
    unless ($proxy && $service);

  croak "Cannot init SOAP client without session and callback"
    unless ($to_session && $to_handler);

  # init SOAP client
  my $self = $package->SUPER::spawn(
    proxy => $proxy,
    service => $service,
    retry_reconnect => 1,
    debug => $debug,
  );

  $self->{soc_stat} = 0;
  $self->{to_session} = $to_session;
  $self->{to_handler} = $to_handler;

  return $self;

}

#-----------------------------------------------------
# overloaded methods from POE::Component::Client::SOAP
#-----------------------------------------------------

# should not be overriden
sub handle_result {
  my ($kernel, $self, $result) = @_[KERNEL,OBJECT,ARG0];
  $kernel->post($self->{to_session},$self->{to_handler}, $result);
}

# usually overriden
sub log {
  my ($self, $kernel, $level, $message) = @_;
  $kernel->post($self->{to_session}, 'logit', $level, $message."\n");
}


# these may be overiden with care of the status flag

sub handle_connected {
  my ($kernel, $self) = @_[KERNEL,OBJECT];
  $self->{soc_stat} = 1;
}


sub handle_error {
  my ($kernel, $self, $result) = @_[KERNEL,OBJECT,ARG0];
  $self->{soc_stat} = 0;
  $kernel->post($self->{to_session},$self->{to_handler}, $result);
}


1;


__END__

=head1 NAME

POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP

=head1 SYNOPSIS

When you init your Endpoint:

        my $soc = POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP->spawn({
          proxy   => $self->{config}->soap_proxy,
          service => $self->{config}->soap_service,
          to_session => $Alias,
          to_handler => 'soap_return',
          retry_reconnect => 1,
        });

        # $self->{config}->soap_proxy is defined in your config file
        # and usually has something like: 'http://yourserver.yourdomain/webservices.php'

        # $self->{config}->soap_service is defined in your config file
        # and usually has something like: 'http://yourserver.yourdomain/soapservices.wsdl'

Later in your Endpoint:

        # make a SOAP call as if it were local
        my $call = $soc->yourSOAPCall(
          $self->{config}->socuser,
          $self->{config}->socpass,
          @params,
        );


=head1 DESCRIPTION

Non-blocking SOAP Client for PoCo::Server::AsyncEndpoint

=head2 Methods


=over 4

=item spawn

This sole method requires four parameters: 
   B<proxy> a valid URL to your SOAP server
   B<service> URL where the WSDL file can be fetched
   B<to_session> What session to post SOAP result
   B<to_handler> What event to post to in this session


=head1 SEE ALSO

L<POE::Component::Client::SOAP>
L<SOAP::Lite>

L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp>
L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::Config>

L<POE::Component::Server::AsyncEndpoint>
L<POE>

=head1 AUTHOR

Alejandro Imass <ait@p2ee.org>
Alejandro Imass <aimass@corcaribe.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alejandro Imass / Corcaribe Tecnología C.A. for the P2EE Project

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

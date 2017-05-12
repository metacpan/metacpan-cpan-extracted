package Sentry::Log::Raven;

=head1 NAME

Sentry::Log::Raven - sending exception log messages to Sentry.

=cut

our $VERSION = '1.03';


=head1 SYNOPSIS


 my $raven = Sentry::Log::Raven->new(
    sentry_public_key => "public",
    sentry_secret_key => "secret",
    domain_url        => "http(s)://sentry domain",
    project_id        => "sentry project id",
    sentry_version    => 4 # can be omitted
    ssl_verify        => 0 # can be omitted

 );


 $raven->message({ message => "Alert!" });

=head1 EXPORT


=cut

use strict;
use warnings;

use HTTP::Request::Common;
use LWP::UserAgent;
use JSON;
use MIME::Base64 'encode_base64';
use Time::HiRes (qw(gettimeofday));
use DateTime;
use Sys::Hostname;
use Mozilla::CA;
use IO::Socket::SSL;

=head4 new

Constructor. Use like:

    my $raven = Sentry::Log::Raven->new(
        sentry_public_key => "public",
        sentry_secret_key => "secret",
        domain_url        => "http(s)://sentry domain",
        project_id        => "sentry project id",
        sentry_version    => 4 # can be omitted
	ssl_verify        => 0 # can be omitted
    );

=cut
sub new {
    my ( $class, %options ) = @_;

    foreach (qw(sentry_public_key sentry_secret_key domain_url project_id)) {
        if (!exists $options{$_}) {
            die "Mandatory paramter '$_' not defined";
        }
    }

    my $self = {
    	ua => LWP::UserAgent->new(),
        %options,
    };

    $self->{'ssl_verify'} ||= 0;

    if ($self->{domain_url} !~ m/^http/) {
         die "Domain url not defined correctly";
    }

    if ($self->{domain_url} =~ m/^https/) {
	if ($self->{'ssl_verify'} == 1) {
		$self->{ua}->ssl_opts( SSL_ca_file => Mozilla::CA::SSL_ca_file() );
    	} else {
		$self->{ua}->ssl_opts( verify_hostname => 0 );
	}
    }

    $self->{'sentry_version'} ||= 4;

    bless $self, $class;
}

=head4 message

Send message to Sentry server.

  $raven->message( { 
    'message'     => "Message", 
    'logger'      => "Name of the logger",                  # defult "root"
    'level'       => "Error level",                         # default 'error'
    'platform'    => "Platform name",                       # default 'perl',
    'culprit'     => "Module or/and function raised error", # default ""
    'tags'        => "Hashref of tags",                     # default {}
    'server_name' => "Server name where error occured",     # current host name is default
    'modules'     => "list of relevant modules",
    'extra'       => "extra params described below"
  } );

The structure of 'modules' list is:

    [
        {
            "my.module.name": "1.0"
        }
    ]

The structure of 'extra' field is:

  {
    "my_key"           => 1,
    "some_other_value" => "foo bar"
  }


=cut
sub message {
    my ( $self, $params ) = @_;
    
    my $message = $self->buildMessage( $params );
    my $stamp = gettimeofday();
    $stamp = sprintf ( "%.12g", $stamp );

    my $header_format = sprintf ( 
            "Sentry sentry_version=%s, sentry_timestamp=%s, sentry_key=%s, sentry_client=%s, sentry_secret=%s",
            $self->{sentry_version},
            time(),
            $self->{'sentry_public_key'},
            "perl_client/0.01",
            $self->{'sentry_secret_key'},
        );
    my %header = ( 'X-Sentry-Auth' => $header_format );

    my $sentry_url;
   
    if ($self->{'sentry_version'} > 3) {
        $sentry_url = $self->{domain_url} . '/api/' . $self->{project_id} . '/store/';
    } else {
        $sentry_url = $self->{domain_url};
    }

    my $request = POST($sentry_url, %header, Content => $message);
    my $response = $self->{'ua'}->request( $request );
    
    return $response;
}


sub buildMessage {
    my ( $self, $params ) = @_;
 
    my $data = {
        'event_id'    => sprintf("%x%x%x", time(), time() + int(rand()), time() + int(rand())),
        'message'     => $params->{'message'},
        'timestamp'   => time(),
        'level'       => $params->{'level'} || 'error',
        'logger'      => $params->{'logger'} || 'root',
        'platform'    => $params->{'platform'} || 'perl',
        'culprit'     => $params->{'culprit'} || "",
        'tags'        => $params->{'tags'} || {},
        'server_name' => $params->{server_name} || hostname,
        'modules'     => $params->{'modules'},
        'extra'       => $params->{'extra'} || {}
    };

    my $json = JSON->new->utf8(1)->pretty(1)->allow_nonref(1);
    return $json->encode( $data );
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 by Enginuity Search Media

daniel@theenginuity.com

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

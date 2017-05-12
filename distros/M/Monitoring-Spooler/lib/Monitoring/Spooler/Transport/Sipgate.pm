package Monitoring::Spooler::Transport::Sipgate;
$Monitoring::Spooler::Transport::Sipgate::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Transport::Sipgate::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a monitoring spooler transport for the sipgate service

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use HTTP::Cookies;
use XMLRPC::Lite;

# extends ...
extends 'Monitoring::Spooler::Transport';
# has ...
has 'cookies' => (
    'is'      => 'ro',
    'isa'     => 'HTTP::Cookies',
    'lazy'    => 1,
    'builder' => '_init_cookies',
);
has 'client' => (
    'is'      => 'ro',
    'isa'     => 'XMLRPC::Lite',
    'lazy'    => 1,
    'builder' => '_init_client',
);
has 'url' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'lazy' => '1',
    'builder' => '_init_url',
);
has 'username' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'required' => 1,
);
has 'password' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'required' => 1,
);
has 'responses' => (
    'is'    => 'ro',
    'isa'   => 'HashRef',
    'lazy'  => 1,
    'builder' => '_init_responses',
);
# with ...
# initializers ...
sub _init_url {
    my $self = shift;

    my $url = 'https://'.$self->username().':'.$self->password().'@samurai.sipgate.net/RPC2';

    return $url;
}

sub _init_cookies {
    my $self = shift;

    my $Cookies = HTTP::Cookies::->new( ignore_discard => 1, );

    return $Cookies;
}

sub _init_client {
    my $self = shift;

    my $Client = XMLRPC::Lite::->proxy( $self->url() );
    $Client->transport()->cookie_jar( $self->cookies() );
    if ( $Client->transport()->can('ssl_opts') ) {
        $Client->transport()->ssl_opts( verify_hostname => 0, );
    }

    my $resp = $Client->call(
        'samurai.ClientIdenfity',
        {
            'ClientName' => 'Monitoring::Spooler::Transport::Sipgate',
            'ClientVersion' => '0.1',
            'ClientVendor' => 'RandomCompany',
        }
    );
    # ignore the result of this call since it seems not to be essential

    return $Client;
}

sub _init_responses {
    my $self = shift;

    # see http://www.sipgate.de/beta/public/static/downloads/basic/api/sipgate_api_documentation.pdf, page 30ff.
    my $resp_ref = {
        '200'   => 'Method success',
        '400'   => 'Method not supported',
        '401'   => 'Request denied (no reason specified)',
        '402'   => 'Internal error',
        '403'   => 'Invalid arguments',
        '404'   => 'Resources exceeded',
        '405'   => 'Invalid parameter name',
        '406'   => 'Invalid parameter type',
        '407'   => 'Invalid parameter value',
        '408'   => 'Attempt to set a non-writable parameter',
        '409'   => 'Notification request denied',
        '410'   => 'Parameter exceeds maximum size',
        '411'   => 'Missig parameter',
        '412'   => 'Too many requests',
        '500'   => 'Date out of range',
        '501'   => 'URI does not belong to user',
        '502'   => 'Unknown type of service',
        '503'   => 'Selected payment method failed',
        '504'   => 'Selected currecy not supported',
        '505'   => 'Amount exceeds limit',
        '506'   => 'Malformed SIP URI',
        '507'   => 'URI not in list',
        '508'   => 'Format is not valid E.164',
        '509'   => 'Unknown status',
        '510'   => 'Unknown ID',
        '511'   => 'Invalid timevalue',
        '512'   => 'Referenced session not found',
        '513'   => 'Only single value per TOS allowed',
        '514'   => 'Malformed VCARD format',
        '515'   => 'Malformed PID format',
        '516'   => 'Presence information not available',
        '517'   => 'Invalid label name',
        '518'   => 'Label not assigned',
        '519'   => "Label doesn't exist",
        '520'   => 'Parameter includes invalid characters',
        '521'   => 'Bad password. (Rejected due to security concerns)',
        '522'   => 'Malformed timezone format',
        '523'   => 'Delay exceeds limit',
        '524'   => 'Requested VPN type not available',
        '525'   => 'Requested TOS not available',
        '526'   => 'Unified messaging not available',
        '527'   => 'URI not available for registration',
    };
    for my $i (900 .. 999) {
        $resp_ref->{$i} = 'Vendor defined status code';
    }

    return $resp_ref;
}

# your code here ...
sub provides {
    my $self = shift;
    my $type = shift;

    if($type =~ m/^text$/i) {
        return 1;
    }

    return;
}

sub run {
    my $self = shift;
    my $destination = shift;
    my $message = shift;

    $destination = $self->_clean_number($destination);
    $message = substr($message,0,159);

    my $resp = $self->client()->call(
        'samurai.SessionInitiate',
        {
            'RemoteUri' => 'sip:'.$destination.'@sipgate.net',
            'TOS'       => 'text',
            'Content'   => $message,
        }
    );
    my $result = $resp->result();

    if($result && $result->{'StatusCode'} == 200) {
        $self->logger()->log( message => 'Sent '.$message.' to '.$destination, level => 'debug', );
        return 1;
    } else {
        my $errstr = $result->{'StatusCode'};
        if($self->responses()->{$result->{'StatusCode'}}) {
            $errstr .= ' ('.$result->responses()->{$result->{'StatusCode'}}.')';
        }
        $errstr .= ' - '.$result->{'StatusString'};
        $self->logger()->log( message => 'Failed to send '.$message.' to '.$destination.'. Error: '.$errstr, level => 'debug', );
        return;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Transport::Sipgate - a monitoring spooler transport for the sipgate service

=head1 SYNOPSIS

    use Monitoring::Spooler::Transport::Sipgate;
    my $Mod = Monitoring::Spooler::Transport::Sipgate::->new();

=head1 DESCRIPTION

The class implements a text transport using the provider sipgate.

=head1 METHODS

=head2 run

This method takes the two arguments destination number and message and tries
to send a text message using this providers XMLRPC API.

=head1 NAME

Monitoring::Spooler::Transport::Sipgate - Sipgate text transport

=head1 CONFIGURATION

Two only two required constructor arguments are the username and the password.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

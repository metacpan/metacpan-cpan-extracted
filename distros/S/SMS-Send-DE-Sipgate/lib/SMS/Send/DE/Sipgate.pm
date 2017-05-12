package SMS::Send::DE::Sipgate;

# ABSTRACT: SMS::Send driver to send via sipgate.de

use warnings;
use strict;
use HTTP::Cookies;
use XMLRPC::Lite;

use parent qw(SMS::Send::Driver);

=head1 NAME

SMS::Send::DE::Sipgate - An SMS::Send driver for the sipgate.de service.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    # create the sender object
    my $sender = SMS::Send::->new('DE::Sipgate',
        _login => '123',
        _password => '456',
    );
    # send a message
    my $sent = $sender->send_sms(
        text    => 'You message may use up to 160 chars',
        to'     => '0555 4444', # only german numbers allowed for this driver
    );
    
    if ( $sent ) {
        print "Sent message\n";
    } else {
        print "Failed to send test message\n";
    }
    
=head1 DESCRIPTION

L<SMS::Send::DE::Sipgate> is an regional L<SMS::Send> driver for
the Sipgate.de service.

=head2 Preparing to use this driver

You need to sign-up on L<http://www.sipgate.de> and get an Account as well
as a local number.

=head2 Disclaimer

The authors of this driver take no responibility for any cost accured on your bill
by using this module.

Using this driver will cost you money. B<YOU HAVE BEEN WARNED>

=head1 METHODS

=head2 new

    # Create new sender using this driver.
    my $sender = SMS::Send::->new(
        'DE::Sipgate',
        _login => '123',
        _password  => '456',
    );
    
The C<new> constructor takes two parameter, which should be passed
throuh from the L<SMS::Send> constructor.

=over

=item _login

The C<_login> param is your sipgate.de username.

=item _password

The C<_password> param is your sipgate.de password.

Returns a new C<SMS::Send::DE::Sipgate> object, or dies on error.

=back

=cut

sub new {
    my $class   = shift;
    my %params  = @_;
    exists $params{_login}
        or die $class."->new requires _login parameter\n";
    exists $params{_password}
        or die $class."->new requires _password parameter\n";
    exists $params{_verbose}
        or $params{_verbose} = 1;
    my $self = \%params;
    bless $self, $class;
    
    $self->{_url} = 'https://'.$self->{_login}.':'.$self->{_password}.'@samurai.sipgate.net/RPC2';
    $self->{_cookies} = HTTP::Cookies::->new( ignore_discard => 1, );
    return $self;
}

=head2 client

Lazy initialization of the XMLRPC client.

=cut

sub client {
    my $self = shift;
    
    if(!$self->{_client}) {
        $self->{_client} = $self->_init_client();
    }
    
    return $self->{_client};
}

sub _init_client {
    my $self = shift;

    my $Client = XMLRPC::Lite::->proxy( $self->{_url} );
    $Client->transport()->cookie_jar( $self->{_cookies} );
    if ( $Client->transport()->can('ssl_opts') ) {
        $Client->transport()->ssl_opts( verify_hostname => 0, );
    }
    
    my $resp = $Client->call(
        'samurai.ClientIdenfity',
        {
            'ClientName' => 'SMS::Send::DE::Sipgate',
            'ClientVersion' => '0.1',
            'ClientVendor' => 'CPAN',
        }
    );
    # ignore the result of this call since it seems not to be essential

    return $Client;
}

=head2 responses

List all known response codes with their explaination.

=cut

sub responses {
    my $self = shift;
    
    if(!$self->{_responses}) {
        $self->{_responses} = $self->_init_responses();
    }
    
    return $self->{_responses};
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

=head2 send_sms

Send an SMS. See L<SMS::Send> for the details.

=cut

sub send_sms {
    my $self = shift;
    my %params = @_;
    
    my $destination = $self->_clean_number($params{'to'});
    my $message = substr($params{'text'},0,159);
    
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
        print 'Sent '.$message.' to '.$destination."\n" if $self->{_verbose};
        return 1;
    } else {
        my $errstr = $result->{'StatusCode'};
        if($self->responses()->{$result->{'StatusCode'}}) {
            $errstr .= ' ('.$result->responses()->{$result->{'StatusCode'}}.')';
        }
        $errstr .= ' - '.$result->{'StatusString'};
        warn 'Failed to send '.$message.' to '.$destination.'. Error: '.$errstr if $self->{_verbose};
        return;
    }
}

sub _clean_number {
    my $self = shift;
    my $number = shift;
    
    # strip all non-number chars
    $number =~ s/\D//g;
    # make sure to use the country prefix for germany
    $number =~ s/^01/491/;
    # never prefix country with 00
    $number =~ s/^00491/491/;
    
    return $number;
}

=head1 AUTHOR

Dominik Schulz, C<< <dominik.schulz at gauner.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-send-de-sipgate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-DE-Sipgate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::DE::Sipgate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-DE-Sipgate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-DE-Sipgate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Send-DE-Sipgate>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Send-DE-Sipgate/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dominik Schulz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SMS::Send::DE::Sipgate

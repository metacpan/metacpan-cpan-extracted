package SMS::Send::Smstrade;

use warnings;
use strict;
use LWP::UserAgent;
use URI::Escape;

use parent qw(SMS::Send::Driver);

=head1 NAME

SMS::Send::Smstrade - An SMS::Send driver for the smstrade.de service

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    # create the sender object
    my $sender = SMS::Send::->new('Smstrade',
        _apikey => '123',
        _route  => 'basic',
    );
    # send a message
    my $sent = $sender->send_sms(
        text    => 'You message may use up to 160 chars',
        to'     => '+49 555 4444', # always use the intl. calling prefix
    );
    
    if ( $sent ) {
        print "Sent message\n";
    } else {
        print "Failed to send test message\n";
    }

=head1 DESCRIPTION

L<SMS::Send::Smstrade> is an international L<SMS::Send> driver for
the smstrade service. It is a paid service which offers very competitive
prices.

=head2 Preparing to use this driver

You need to sign-up on L<http://www.smstrade.eu> and get an API key.

This API key is used instead of a username and password to authenticate yourself.

=head2 Disclaimer

The authors of this driver take no responibility for any cost accured on your bill
by using this module.

Using this driver will cost you money. B<YOU HAVE BEEN WARNED>

=head1 METHODS

=head2 new

    # Create new sender using this driver.
    my $sender = SMS::Send::->new(
        'Smstrade',
        _apikey => '123',
        _route  => 'basic',
    );
    
The C<new> constructor requires at least one parameter, which should be passed
throuh from the L<SMS::Send> constructor.

=over

=item _apikey

The C<_apikey> param is the api key you get after signing up with smstrade.

=item _route

The C<_route> param determines how much the messages sent will cost you.
The more expensive routes offer you more options. See L<http://www.smstrade.eu>
for more details. Not all features of the different routes are supported right now.

Returns a new C<SMS::Send::Smstrade> object, or dies on error.

=back

=cut

sub new {
    my $class   = shift;
    my %params  = @_;
    exists $params{_apikey}
        or die $class."->new requires _apikey parameter\n";
    if(exists $params{_route}) {
        if($params{_route} !~ m/^(?:basic|gold|direct)/) {
            die $class."->new's _route parameter takes only one of: basic, gold or direct\n";
        }
    } else {
        $params{_route} = 'basic';
    }
    exists $params{_from}
        or $params{_from} = 'SMS::Send::Smstrade';
    exists $params{_verbose}
        or $params{_verbose} = 1;
    my $self = \%params;
    bless $self, $class;
    
    $self->{_url} = 'https://gateway.smstrade.de/';
    $self->{_ua} = LWP::UserAgent::->new();
    $self->{_ua}->agent('SMS::Send::Smstrade/0.1');
    if($self->{_ua}->can('ssl_opts')) {
        $self->{_ua}->ssl_opts( verify_hostname => 0, );
    }
    
    return $self;
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
    
    # see http://www.smstrade.de/pdf/SMS-Gateway_HTTP_API_v2_de.pdf, page 5
    my $resp_ref = {
        '10'    => 'Destination Number not correct (Parameter: to)',
        '20'    => 'Source Number not correct (Parameter: from)',
        '30'    => 'Message not correct (Parameter: message)',
        '31'    => 'Message type not correct (Parameter: messagetype)',
        '40'    => 'SMS Route not correct (Parameter: route)',
        '50'    => 'Identification failed (Parameter: key)',
        '60'    => 'Insufficient Funds.',
        '70'    => 'Destination Network not covered. Use another route.',
        '71'    => 'Feature not available. Use another route.',
        '80'    => 'Failed to submit to SMS-C. Use another route or contact support.',
        '100'   => 'SMS successfull submitted.',
    };
    
    return $resp_ref;
}

=head2 send_sms

Send an SMS. See L<SMS::Send> for the details.

=cut

sub send_sms {
    my $self = shift;
    my %params = @_;
    
    my $destination = $self->_clean_number($params{to});
    my $message = substr($params{text},0,159);
    
    my %args = (
        'key'       => $self->{_apikey},
        'message'   => $message,
        'to'        => $destination,
        'route'     => $self->{_route},
        'from'      => $self->{_from},
        'cost'      => 1,
        'message_id' => 1,
        'count'     => 1,
    );
    
    my $content = join('&', map { uri_escape($_).'='.uri_escape($args{$_}) } keys %args);
    
    my $url = $self->{_url}.'?'.$content;
    my $req = HTTP::Request::->new( GET => $url, );
    my $res = $self->{_ua}->request($req);
    
    print 'Requesting URL '.$url."\n" if $self->{_verbose};
    
    if($res->is_success() && $res->content() =~ m/^100\D/) {
        print 'Sent '.$message.' to '.$destination."\n" if $self->{_verbose};
        return 1;
    } else {
        my $errstr = $res->content();
        if($self->responses()->{$errstr}) {
            $errstr .= ' - '.$self->responses()->{$errstr};
        }
        warn 'Failed to send '.$message.' to '.$destination.'. Error: '.$errstr if $self->{_verbose};
        return;
    }
}

sub _clean_number {
    my $self = shift;
    my $number = shift;
    
    # strip all non-number chars
    $number =~ s/\D//g;
    
    return $number;
}

=head1 AUTHOR

Dominik Schulz, C<< <dominik.schulz at gauner.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-send-smstrade at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-Smstrade>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::Smstrade


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-Smstrade>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-Smstrade>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Send-Smstrade>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Send-Smstrade/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dominik Schulz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SMS::Send::Smstrade

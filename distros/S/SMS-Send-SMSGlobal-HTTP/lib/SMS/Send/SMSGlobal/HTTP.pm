package SMS::Send::SMSGlobal::HTTP;

use warnings;
use strict;

use 5.006;

use parent 'SMS::Send::Driver', 'Class::Accessor';

require LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use Try::Tiny;
use Scalar::Util qw();

sub __fields {
    return qw(action text to _user _password _from _maxsplit _scheduledatetime
              _api _userfield __transport __verbose __ua __address __responses)
};

use fields __PACKAGE__->__fields;
__PACKAGE__->mk_accessors( __PACKAGE__->__fields );

=head1 NAME

SMS::Send::SMSGlobal::HTTP - SMS::Send SMSGlobal.com Driver

=head1 VERSION

VERSION 0.12

=cut

our $VERSION = '0.12';

=head1 DESCRIPTION

SMS::Send::SMSGlobal::HTTP is a simple driver for L<SMS::Send> for sending
messages via www.smsglobal.com using the SMS Global HTTP API.

=head1 SUBROUTINES/METHODS

=head2 new

    use SMS::Send;

    my $sender = SMS::Send->new('SMSGlobal::HTTP',
               _user       => 'my-username',
               _password   => 'my-password',
               __transport => 'https',
               __verbose   =>  1
           );

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Create the object
    my $self = fields::new ($class);

    #
    # Allow _user and _password aliases; just to ease interchange
    # with other sms drivers
    #

    $self->{_user} = delete($args{_user})
        || delete($args{_username})
        || delete($args{_login});

    $self->{_password} = delete $args{_pass}
        || delete $args{_password};

    foreach (sort keys %args) {
        $self->{$_} = $args{$_};
    }

    $self->{_maxsplit} ||= 3;

    $self->{__ua} ||= LWP::UserAgent->new;

    return $self;
}

=head2 send_sms

    my $sent = $sender->send_sms(
        to        => '+61 4 8799 9999',
        text      => 'Go to the window!',
        _from     => 'Clang',
        _scheduledtime => DateTime
                             ->now(time_zone => 'Australia/Melbourne')
                             ->add(minutes => 5)
    );

=head3 Basic Options

=over 4

=item C<to>

The recipient number. This can either be an international number (prefixed
with C<+>) or an local number (with a leading C<0>).

Note: In the case of a local number, the country will be determined by your
C<Default SMS Country> Locale Setting in your account preferences.

=item C<text>

The text of the message.

=item C<_from>

Sets the from caller-ID. This can either be a reply telephone number, or an
alphanumeric identifier matching C<^[0-9a-zA-Z_]+$>. For details. see
http://www.routomessaging.com/dynamic-sender-id-service.pmx .

=item C<_maxsplit> (default 3)

The maximum number of 150 character (approx) transmission chunks. You may need
to increase this to send longer messages.

Note: Each chunk is metered as a separate message.

=item C<_scheduledtime>

Lets you delay sending of messages. This can be either (a) a string formatted
as C<yyyy-mm-dd hh:mm:ss> or (b) an object that supports C<ymd> and
C<hms> methods. For example L<DateTime> or L<Time::Piece> objects.

Note: Your date times need to to be specified in the same timezone as set in
your SMSGlobal account preferences.

=back

=head3 HTTP-2WAY Options

Some extra options for handling SMS replies. These are useful when you are
using dedicated incoming numbers, with your account. See
L<http://www.smsglobal.com/docs/HTTP-2WAY.pdf>:

=over 4

=item C<_api>

Set to 0, to disabled two-way messaging. The default is 1 (enabled).

=item C<_userfield>

Custom field to store internal IDs or other information (Maximum of
255 characters)

=back

=head3 Configuration Options

=over 4

=item C<__address> 

SMSGlobal gateway address (default: 'http://www.smsglobal.com/http-api.php');

=item C<__transport>

Transport to use: 'http' (default) or 'https'.

Transport over 'https' is encrypted and more secure. However, this option
requires either L<Crypt::SSLeay> or L<IO::Socket::SSL> to be installed. More
information is available at
L<http://search.cpan.org/dist/libwww-perl/README.SSL>.

=item C<__verbose>

Set to true to enable tracing.

=back

=cut

sub send_sms {
    my $self = shift;
    my %opt = @_;

    $self->__responses( [] );        

    my $msg = ref($self)->new( %$self, %opt );

    my %http_params = (
        action => 'sendsms',
        );

    foreach (sort keys %$msg) {
        next if m{^__};

        if (defined (my $val = $msg->{$_}) ) {
            (my $key = $_) =~ s{^_}{};
            $http_params{$key} = $val;
        }
    }

    if (ref $http_params{scheduledatetime} ) {
        #
        # stringify objects that support ymd & hms methods
        #
        for ( $http_params{scheduledatetime} ) {
            $_ = $_->ymd('-') .' '.$_->hms(':')
                if (Scalar::Util::blessed($_) && try {
                    $_->can('ymd') && $_->can('hms')
                    })
        }
    }

    if ( defined $http_params{to} ) {

        $http_params{to} = join(',', @{ $http_params{to} })
            if (ref( $http_params{to} || '') eq 'ARRAY');
        #
        # smsglobl/http will accept 'to' as a comma-separated list of
        # telephone numbers. Omit all but commas and alphanumerics.
        #
        $http_params{to} =~ s{[^\w,]}{}g;
    }

    if ( defined $http_params{from} ) {
        #
        # restrict 'from' to an alphanumeric caller-ID
        #
        $http_params{from} =~ s{[^\w]}{}g;
    }

    if ($msg->__verbose) {
        print STDERR "http params:\n";
        foreach (sort keys %http_params) {
            print STDERR "  $_: $http_params{$_}\n"
        }
    }

    my $address = $msg->__address || 'http://www.smsglobal.com/http-api.php';

    if (my $transport = $msg->__transport) {

        if ($transport eq 'http') {
            $address =~ s{^https:}{http:}i;
        }
        elsif ($transport eq 'https') {
            $address =~ s{^http:}{https:}i;
        }
        else {
            die "transport '$transport': not 'http' or 'https'" 
        }
    }

    print STDERR "Address : $address" if $msg->__verbose;

    my $req = POST($address => [ %{ \%http_params } ]);

    my $response = $msg->__ua->request($req);

    die "unable to get response"
        unless $response;

    if ($msg->__verbose ) {
        print STDERR "**Status**\n",$response->status_line,"\n";
        print STDERR "**Headers**\n",$response->headers_as_string,"\n";
        print STDERR "**Content**\n",$response->content,"\n";
    }

    my $sent = 0;

    if ( $response->is_success ) {

        my @responses = split (/[\n\r]+/, $response->content);

        foreach (@responses) {
            push ( @{ $self->__responses }, $_ );

            if ( m{^(OK|SMSGLOBAL DELAY)} ) {
                $sent++;
            }
        }
    }
    else {
        die $response->status_line;
    }

    return $sent;
}

=head2 Sending SMS to Multiple Recipients

It is possible to specify multiple recipients in a request. However, this
requires direct use of the C<SMS::Send::SMSGlobal::HTTP> driver:

    use SMS::Send::SMSGlobal::HTTP;

    my $driver = SMS::Send::SMSGlobal::HTTP->new(
        _user => $sms_login,
        _password => $sms_pass,
        __verbose => 1,
        __transport => 'https',
    );

The driver can accept either an array of mobile numbers or a string containing
a comma-separated list of mobile numbers.

   my @recipients = ( '+61(4)770090099', '0419 123 456' );

   my $sent = $driver->send_sms( _from => $caller_id,
                                 to    => \@recipients,
                                 text  => 'Hi everyone!',
                                );

The return value is the number of messages queued for delivery to individual
recipients.

C<__responses> contains sucesss or error codes for each recipient.

    if ( $sent < scalar @recipients ) {
        warn "failed to send to some participants";

        my @responses = @{ $driver->__responses || [] };
        for ( @responses ) {
            warn $_ if m{ERROR};
        }
    }

=head1 AUTHOR

David Warring, C<< <david.warring at gmail.com> >>

=head1 BUGS AND LIMITATIONS

This module only attempts to implement the simple HTTP/S C<sendsms> command as
described in L<http://www.smsglobal.com/docs/HTTP.pdf> and L<http://www.smsglobal.com/docs/HTTP-2WAY.pdf>. 

There are other API's available (L<http://www.smsglobal.com/en-au/technology/developers.php>). Among the more fully featured are the SOAP interface (L<http://www.smsglobal.com/docs/SOAP.pdf>) and SMPP (L<http://www.smsglobal.com/docs/SMPP.pdf>).

Please report any bugs or feature requests to C<bug-sms-send-au-smsglobal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-SMSGlobal-HTTP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::SMSGlobal::HTTP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-SMSGlobal-HTTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-SMSGlobal-HTTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Send-SMSGlobal-HTTP>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Send-SMSGlobal-HTTP/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 David Warring.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of SMS::Send::SMSGlobal::HTTP

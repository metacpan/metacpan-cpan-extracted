package Net::AWS::SES;
use strict;
use warnings;
use Carp ('croak');
use MIME::Base64;
use Time::Piece;
use HTTP::Headers;
use LWP::UserAgent;
use Digest::HMAC_SHA1;
use Net::AWS::SES::Response;
our $VERSION = '0.04';

sub __timestamp {
    return localtime->datetime;
}

sub __signature {
    my $self = shift;
    my ($date) = @_;
    unless ($date) {
        croak "signature(): usage error";
    }
    my $hmac = Digest::HMAC_SHA1->new( $self->secret_key );
    $hmac->add($date);
    return encode_base64( $hmac->digest );
}
sub __user_agent {
    my $self = shift;
    my $ua   = LWP::UserAgent->new(
        agent           => sprintf( "%s/%s", __PACKAGE__, $VERSION ),
        default_headers => $self->__header
    );
    return $ua;
}

sub __header {
    my $self = shift;
    my $h    = HTTP::Headers->new;
    $h->date(time);
    $h->header(
        'Content-type'         => 'application/x-www-form-urlencoded',
        'X-Amzn-Authorization' => sprintf(
            "AWS3-HTTPS AWSAccessKeyId=%s,Algorithm=HmacSHA1,Signature=%s",
            $self->access_key, $self->__signature( $h->header('Date') )
        )
    );
    return $h;
}

sub new {
    my $class = shift;
    my %data  = (
        access_key   => '',
        secret_key   => '',
        region       => 'us-east-1',
        from         => '',
        __user_agent => undef,
        __response   => undef,
        @_
    );
    unless ( $data{access_key} && $data{secret_key} ) {
        croak "new(): usage error";
    }
    return bless \%data, $class;
}

sub DESTROY {
    my $self = shift;
    $self->{__response} = undef;
}

sub response {
    my $self = shift;
    return $self->{__response};
}

sub access_key {
    my $self = shift;
    my ($key) = @_;
    return $self->{access_key} unless $key;
    return $self->{access_key} = $key;
}

sub secret_key {
    my $self = shift;
    my ($key) = @_;
    return $self->{secret_key} unless $key;
    return $self->{secret_key} = $key;
}

sub region {
    my $self = shift;
    my ($key) = @_;
    return $self->{region} unless $key;
    return $self->{region} = $key;
}

sub call {
    my $self = shift;
    my ( $action, $args, $responseClass ) = @_;
    unless ($action) {
        croak "call(): usage error";
    }
    $args->{AWSAccessKeyId} = $self->access_key;
    $args->{Action}         = $action;
    $args->{Timestamp}      = $self->__timestamp;
    my $ua = $self->__user_agent;
    my $response =
      $ua->post( "https://email." . $self->region . ".amazonaws.com",
        $args );
    return Net::AWS::SES::Response->new( $response, $action );
}

sub send {
    my $self = shift;
    return $self->send_mime(@_) if ( @_ == 1 );
    my (%args) = @_;
    unless ( ref( $args{To} ) ) {
        $args{To} = [ $args{To} ];
    }
    my $from = $args{From} || $self->{from};
    unless ($from) {
        croak "send(): usage error";
    }
    unless ( $from && ( $args{Body} || $args{Body_html} ) && $args{To} ) {
        croak "Usage Error";
    }
    my %call_args = (
        'Message.Subject.Data'    => $args{Subject},
        'Message.Subject.Charset' => 'UTF-8',
        'Source'                  => $from
    );
    if ( $args{Body} ) {
        $call_args{'Message.Body.Text.Data'}    = $args{Body};
        $call_args{'Message.Body.Text.Charset'} = 'UTF-8',;
    }
    if ( $args{Body_html} ) {
        $call_args{'Message.Body.Html.Data'}    = $args{Body_html};
        $call_args{'Message.Body.Html.Charset'} = 'UTF-8';
    }
    if ( $args{ReturnPath} ) {
        $call_args{'ReturnPath'} = $args{ReturnPath};
    }
    for ( my $i = 0 ; $i < @{ $args{To} } ; $i++ ) {
        my $email = $args{To}->[$i];
        $call_args{ sprintf( 'Destination.ToAddresses.member.%d', $i + 1 ) } =
          $email;
    }
    my $r = $self->call( 'SendEmail', \%call_args );
} ## end sub send

sub verify_email {
    my ( $self, $email ) = @_;
    unless ($email) {
        croak "verify_email(): usage error";
    }
    return $self->call( 'VerifyEmailIdentity', { EmailAddress => $email } );
}
*delete_domain = \&delete_identity;
*delete_email  = \&delete_identity;

sub delete_identity {
    my ( $self, $identity ) = @_;
    unless ($identity) {
        croak "delete_identity(): usage error";
    }
    return $self->call( 'DeleteIdentity', { Identity => $identity } );
}

sub list_emails {
    my $self      = shift;
    my %args      = @_;
    my %call_args = ( IdentityType => 'EmailAddress' );
    if ( $args{limit} ) {
        $call_args{MaxItems} = $args{limit};
    }
    if ( $args{offset} ) {
        $call_args{NextToken} = $args{offset};
    }
    my $r = $self->call( 'ListIdentities', \%call_args );
}

sub list_domains {
    my $self      = shift;
    my %args      = @_;
    my %call_args = ( IdentityType => 'Domain' );
    if ( $args{limit} ) {
        $call_args{MaxItems} = $args{limit};
    }
    if ( $args{offset} ) {
        $call_args{NextToken} = $args{offset};
    }
    my $r = $self->call( 'ListIdentities', \%call_args );
}

sub get_quota {
    my $self = shift;
    return $self->call('GetSendQuota');
}

sub get_statistics {
    my $self = shift;
    return $self->call('GetSendStatistics');
}

sub send_mime {
    my $self = shift;
    my $msg = $_[0] if ( @_ == 1 );
    if ( $msg && ref($msg) && $msg->isa("MIME::Entity") ) {
        my $r = $self->call( 'SendRawEmail',
            { 'RawMessage.Data' => encode_base64( $msg->stringify ) } );
        return $r;
    }
}

sub get_dkim_attributes {
    my $self       = shift;
    my @identities = @_;
    my %call_args  = ();
    for ( my $i = 0 ; $i < @identities ; $i++ ) {
        my $id = $identities[$i];
        $call_args{ 'Identities.member.' . ( $i + 1 ) } = $id;
    }
    return $self->call( 'GetIdentityDkimAttributes', \%call_args );
}
__END__

=head1 NAME

Net::AWS::SES - Perl extension that implements Amazon Simple Email Service (SES) client

=head1 SYNOPSIS

    use Net::AWS::SES;

    my $ses = Net::AWS::SES->new(access_key => '....', secret_key => '...');
    my $r = $ses->send(
        From    => 'sherzodr@cpan.org',
        To      => 'sherzodr@gmail.com',
        Subject => 'Hello World from SES',
        Body    => "Hello World"
    );

    unless ( $r->is_success ) {
        die "Could not deliver the message: " . $r->error_message;
    }

    printf("Sent successfully. MessageID: %s\n", $r->message_id);

    ######### sending attachments
    my $msg = MIME::Entity->build();
    my $r = $ses->send( $msg );

=head1 DESCRIPTION

Implements Amazon Web Services' Simple Email Service (SES). Sess L<http://docs.aws.amazon.com/ses/latest/DeveloperGuide/Welcome.html> for details and to sign-up for the service.

=head1 GETTING STARTED

After you sign-up for AWS SES service you need to create an C<IAM> credentials and create an C<access_key> and a C<secret_key>, which you will be needing to interface with the SES. Do not forget to grant permission to your C<IAM> to use SES. Read L<http://docs.aws.amazon.com/ses/latest/DeveloperGuide/using-credentials.html> for details.

=head1 METHODS

I attempted to make the method names as Perlish as possible, as opposed to direct copy/paste from the API reference. This way I felt you didn't have to be familiar with the full API reference in order to use the basic features of the service.

If you are avid AWS developer there is a C<call()> method, which gives you access to all the documented Query actions of the AWS SES. In fact, that's what all the methods use to hide the complexity of the request/response. There are few examples of the C<call()> method in later sections.

All the methods (including C<call()>) returns an instance of L<Response|Net::AWS::SES::Response>. You should check if the the call is success by testing for C<is_success> attribute of the response. If you want to gain full access to the raw parsed conents of the response I<(which originally is in XML, but we parse it into Perl hashref for you)>, C<result> attribute is all you will be needing. For the details see L<Response manual|Net::AWS::SES::Response>. Since C<result()> is the most important attribute of the resonse I will be giving you a sample result data in JSON notation for your reference.

=head2 new(access_key => $key, secret_key => $s_key)

=head2 new(access_key => $key, secret_key => $s_key, region => $region)

=head2 new(access_key => $key, secret_key => $s_key, from => 'default@from.address')

Returns a Net::AWS::SES instance. C<access_key> and C<secret_key> arguments are required. C<region> is optional, and can be overriden in respective api calls. Must be a valid SES region: C<us-east-1>, C<us-west-2> or C<eu-west-1>. Default is C<us-east-1>. C<from> is optional, and can be overriden in respective api calls. Must be your verified identity. 

=head2 send( $msg )

=head2 send(%options)

Sends an email address and returns L<Response|Net::AWS::SES::Response> instance.

If the only argument is passed, it must be an instance of MIME::Entity. Example:

    $msg = MIME::Entity->build(
        From    => 'sherzodr@cpan.org',
        To      => 'sherzodr@example.com',
        Subject => 'MIME msg from AWS SES',
        Data    => "<h1>Hello world from AWS SES</h1>",
        Type    => 'text/html'
    );

    $msg->attach(
        Path     => File::Spec->catfile( 't', 'image.gif' ),
        Type     => 'image/gif',
        Encoding => 'base64'
    );

    $ses = Net::AWS::SES->new(....);
    $r = $ses->send($msg);

    unless ( $r->is_success ) {
        die $r->error_message;
    }

If you don't have MIME::Entity instance handy you may use the following arguments to have AWS SES build the message for you (bold entries are required): C<From>, B<To>, B<Subject>, B<Body>, C<Body_html>, C<ReturnPath>. To send e-mail to multiple emails just pass an arrayref to C<To>.

If C<From> is missing it defaults to your default e-mail given to C<new()>. Remember: this must be a verified e-mail. Example:

    $r = $ses->send(
        From    => 'sherzodr@cpan.org',
        To      => 'sherzodr@example.com',
        Subject => 'Hello World'
        Body    => 'Hello World'
    );
    unless ( $r->is_success ) {
        die $r->error_message;
    }

You may provide an alternate html content by passing C<Body_html> header.

C<Charset> of the e-mail is set to 'UTF-8'. As of this writing I didn't make any way to affect this.

Success calls also return a C<message_id>, which can be accessed using a shortcut C<$r->message_id> syntax. See L<Response class|Net::AWS::SES::Response>.

Sample successful response looks like this in JSON:

    {
        "MessageId": "00000141344ce1a8-0664c3c5-e9a0-4b47-aa2e-12b0bdf6070e-000000"
    }

Sample error response looks like as:

    {
        "Error": {
            "Code":     "MessageRejected",
            "Type":     "Sender",
            "Message":  "Email address is not verified."
        },
        "xmlns":    "http://ses.amazonaws.com/doc/2010-12-01/",
        "RequestId":"0d04b41a-20dd-11e3-b01b-51d07c103915"
    }


=head2 verify_email($email)

Verifies a given C<$email> with AWS SES. This results a verification e-mail be sent from AWS to the e-mail with a verification link, which must be clicked before this e-mail address appears in C<From> header. Returns a L<Response|Net::AWS::SES::Response> instance.

Sample successful response:

    {}      # right, it's empty.

=head2 list_emails()

Retrieves list e-mail addresses. Returns L<Response|Net::AWS::SES::Response> instance.

Sample response:

    {
        "Identities": ["example@example.com", "sample@example.com"]
    }

=head2 list_domains()

Retrieves list of domains. Returns L<Response|Net::AWS::SES::Response> instance.

    {
        "Identities": ["talibro.com", "lubebase.com"]
    }

=head2 delete_email($email)

=head2 delete_domain($domain)

Deletes a given email or domain name from the SES. Once the identity is deleted you cannot use it in your C<From> headers. Returns L<Response|Net::AWS::SES::Response> instance.

Sample response:

    { }     # empty


=head2 get_quota()

Gets your quota. Returns L<Response|Net::AWS::SES::Response> instance.

Sample response:

    {
        "Max24HourSend":    "10000.0",
        "MaxSendRate":      "5.0",
        "SentLast24Hours":  "15.0"
    }


=head2 get_statistics()

Gets your usage statistics. Returns L<Response|Net::AWS::SES::Response> instance.

Sample response:

    "SendDataPoints" : {
      "member" : [
         {
            "Rejects" : "0",
            "Timestamp" : "2013-09-14T13:07:00Z",
            "Complaints" : "0",
            "DeliveryAttempts" : "1",
            "Bounces" : "0"
         },
         {
            "Rejects" : "0",
            "Timestamp" : "2013-09-17T09:37:00Z",
            "Complaints" : "0",
            "DeliveryAttempts" : "2",
            "Bounces" : "0"
         },
         {
            "Rejects" : "0",
            "Timestamp" : "2013-09-17T10:07:00Z",
            "Complaints" : "0",
            "DeliveryAttempts" : "4",
            "Bounces" : "0"
         },
         # ..................
      ]
   }

=head2 get_dkim_attributes($email)

=head2 get_dkim_attributes($domain)

    {
        "DkimAttributes":[{
            "entry":{
                "value": {
                    "DkimEnabled":"true",
                    "DkimTokens":["iz26kxoyadfasfsafdsafg42jjh33gpcm","adtzf6s4edagadsfasdfsafsafr7rhvcf2c","yybjqlduafasfsafdsfc3a33dzqyyfr"],
                    "DkimVerificationStatus":"Success"
                },
                "key":"example@example.com"
            }
        }]
    }

=head1 ADVANCED API CALLS

Methods documented in this library are shortcuts for C<call()> method, which is a direct interface to AWS SES. So if there is an API call that you need which does not have a shortcut here, use the C<call()> method instead. For example, instead of using C<send($message)> as above, you could've done:

    my $response = $self->call( 'SendRawEmail', {
        'RawMessage.Data' => encode_base64( $msg->stringify )
    } );

Those of you who are familiar with SES API will notice that you didn't have to pass any C<Timestamp>, C<AccessKey>, or sign your message with your C<SecretKey>. This library does it for you. You just have to pass the data that is documented in the SES API reference.

=head1 TODO

=over 4

=item *

Ideally all API calls must returns their own respective responce instances, as opposed to a common L<Net::AWS::SES::Response|Net::AWS::SES::Response>.

=item *

All documented API queries must have respective methods in the library.

=back

=head1 SEE ALSO

L<JSON>, L<MIME::Base64>, L<Digest::HMAC_SHA1>, L<LWP::UserAgent>, L<Net::AWS::SES::Response>, L<XML::Simple>

=head1 AUTHOR

Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by L<Talibro LLC|https://www.talibro.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

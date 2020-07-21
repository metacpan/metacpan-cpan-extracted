package Net::AWS::SES::Signature4;

use strict;
use warnings;
use Carp ('croak');
use MIME::Base64;
use Time::Piece;
use HTTP::Headers;
use LWP::UserAgent;
use Digest::HMAC_SHA1;
use Net::AWS::SES::Response;
use AWS::Signature4;
use HTTP::Request::Common;


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use Net::AWS::SES::Signature4 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.09';


# Preloaded methods go here.

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

sub __signer {
    my $self = shift;
	my $signer = AWS::Signature4->new(-access_key => $self->access_key, -secret_key => $self->secret_key);	
    return $signer;
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
		__signer     => undef,
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
	my $ua = LWP::UserAgent->new();
	my $request = POST("https://email." . $self->region . ".amazonaws.com", [$args]);		
	my $signer = $self->__signer;
	$signer->sign($request);
	my $response = $ua->request($request);
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

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::AWS::SES::Signature4 - Perl extension that implements Amazon Simple Email Service (Amazon SES) API requests that are signed using Signature Version 4 processes

=head1 SYNOPSIS

	use Net::AWS::SES::Signature4;

	my $ses = Net::AWS::SES::Signature4->new(access_key => '....', secret_key => '...');
	my $r = $ses->send(
		From    => 'verifiedemail@cpan.org',
		To      => 'recipientemail@gmail.com',
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

Implements Amazon Web Services Simple Email Service (Amazon SES) API requests that are signed using Signature Version 4. Visit L<http://docs.aws.amazon.com/ses/latest/DeveloperGuide/Welcome.html> for details and to sign-up for the service.

=head2 EXPORT

None by default.

=head1 METHODS

Same as L<Net::AWS::SES>

=head1 SEE ALSO

L<AWS::Signature4>

=head1 AUTHOR

Partha Pratim Sarkar, E<lt>partha@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by L<Partha Pratim Sarkar |https://www.blogger.com/profile/03088030362090267110>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.

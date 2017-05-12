package Net::EC2::Tiny;
{
  $Net::EC2::Tiny::VERSION = '0.03';
}

use 5.014;

use POSIX qw(strftime);
use Digest::SHA qw(hmac_sha256);
use MIME::Base64 qw(encode_base64);
use HTTP::Tiny;
use Carp qw(croak);

use XML::Simple qw(XMLin);
use Moo;

# ABSTRACT: Basic EC2 client



has 'AWSAccessKey'       => ( is => 'ro', required => 1 );


has 'AWSSecretKey'       => ( is => 'ro', required => 1 );


has 'debug'              => ( is => 'ro', required => 0, default => sub { 0 } );


has 'version'            => ( is => 'ro', required => 1, default => sub { '2012-07-20' } );


has 'region'             => ( is => 'ro', required => 1, default => sub { 'us-east-1' } );


has 'base_url'           => ( 
    is          => 'ro', 
    required    => 1,
    lazy        => 1,
    default     => sub {
        'https://ec2.' . $_[0]->region . '.amazonaws.com';
    }
);


has 'ua'                 => (
    is          => 'ro',
    required    => 1,
    lazy        => 1,
    default     => sub {
        HTTP::Tiny->new(
            'agent' => 'Net::EC2::Tiny ',
        );
    }
);

has '_base_url_host'     => (
    is          => 'ro',
    required    => 1,
    lazy        => 1,
    default     => sub {
        ($_[0]->ua->_split_url($_[0]->base_url))[1]
    }
);

sub _timestamp {
    return strftime("%Y-%m-%dT%H:%M:%SZ",gmtime);
}
    
sub _sign {
    my $self                        = shift;
    my %args                        = @_;
    my $action                      = delete $args{Action};
    
    croak "Action must be defined!\n" if not defined $action;

    my %sign_hash                   = %args;
    my $timestamp                   = $self->_timestamp;

    $sign_hash{AWSAccessKeyId}      = $self->AWSAccessKey;
    $sign_hash{Action}              = $action;
    $sign_hash{Timestamp}           = $timestamp;
    $sign_hash{Version}             = $self->version;
    $sign_hash{SignatureVersion}    = "2";
    $sign_hash{SignatureMethod}     = "HmacSHA256";

    my $sign_this = "POST\n";
    $sign_this .= $self->_base_url_host . "\n";
    $sign_this .= "/\n";


    $sign_this .= $self->ua->www_form_urlencode(\%sign_hash);

    warn "QUERY TO SIGN: $sign_this" if $self->debug;
    my $encoded = encode_base64(hmac_sha256($sign_this, $self->AWSSecretKey), '');

    my %params = (
        Action                => $action,
        SignatureVersion      => "2",
        SignatureMethod       => "HmacSHA256",
        AWSAccessKeyId        => $self->AWSAccessKey,
        Timestamp             => $timestamp,
        Version               => $self->version,
        Signature             => $encoded,
        %args
    );

    return \%params;
}

sub _request {
    my $self   = shift;
    my $params = shift;

    return $self->ua->post_form( $self->base_url, $params );
}

sub _process {
    my $self = shift;
    my $data = shift;

    my $xml = XMLin( $data,
            ForceArray    => qr/(?:item|Errors)/i,
            KeyAttr       => '',
            SuppressEmpty => undef,
    );

    return $xml;
}


sub send {
    my $self     = shift;
    my $request  = $self->_sign(@_);
    my $response = $self->_request($request);

    if ( $response->{success} ) {
        my $xml = $self->_process( $response->{content} );
        if ( defined $xml->{Errors} ) {
            croak "Error: $response->{content}\n";
        }
        return $xml;
    }

    croak "POST Request failed: $response->{status} $response->{reason} $response->{content}\n";
}


1;

__END__

=pod

=head1 NAME

Net::EC2::Tiny - Basic EC2 client

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use 5.014;
  use Net::EC2::Tiny;

  my $ec2 = Net::EC2::Tiny->new(
        AWSAccessKey => $ENV{AWS_ACCESS_KEY},
        AWSSecretKey => $ENV{AWS_SECRET_KEY}',
        region       => $ENV{AWS_REGION},
        debug        => 1,
  );

  # We are essentially encoding 'raw' EC2 API calls with a v2 
  # signature and turning XML responses into Perl data structures

  my $xml = $ec2->send(
        Action       => 'DescribeRegions',
      'RegionName.1' => 'us-east-1',
  );

  # prints ec2.us-east-1.amazonaws.com
  say $xml->{regionInfo}->{item}->[0]->{regionEndpoint};

=head1 OVERVIEW

This module is intended to be a quick-n-dirty glue layer between a script and some 
L<Amazon EC2 API calls|http://docs.aws.amazon.com/AWSEC2/latest/APIReference/OperationList-query.html>.
Normally I'd use something like bash and curl for this, but Amazon's API signature 
requirements demand a little bit more than bash and curl doesn't support Amazon's 
signature schema.

All errors are fatal and reported via croak.

If you want to do "serious" development with the EC2 API, you probably ought to
use something like L<Net::Amazon::EC2> or L<VM::EC2>.

=head1 ATTRIBUTES

=head2 AWSAccessKey

This is the Amazon API access code. B<Required> at object construction time.

=head2 AWSSecretKey

This is the Amazon API secret key. B<Required> at object construction time.

=head2 debug

Set this to a true value if you want debugging information. Defaults to false.

=head2 version

This is the AWS EC2 API version. Defaults to 2012-07-20.

=head2 region

This is the EC2 region to which to make calls. Defaults to 'us-east-1'

=head2 base_url

This is the base URL used by the module to send encoded requests to. Defaults to
C<https://ec2.us-east-1.amazonaws.com> This attribute uses the region attribute 
automatically.

=head2 ua

The user agent object which sends requests. Defaults to L<HTTP::Tiny>

=head1 METHODS

=head2 send

This method expects key/value pair list with a required 'Action' key set to 
a valid EC2 API call.  Subsequent parameters in the list must be appropriate
parameters for the specified Action.

The request will be signed with a valid v2 signature and submitted to AWS. The
XML response will be turned into a Perl data structure using L<XML::Simple> 
and returned.

=head1 SUPPORT

Please report any bugs or feature requests to "bug-net-ec2-tiny at
rt.cpan.org", or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-EC2-Tiny>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Or, if you wish, you may report bugs/features on Github's Issue Tracker.
L<https://github.com/mrallen1/Net-EC2-Tiny/issues>

=head1 SEE ALSO

This library is pretty useless without the EC2 API docs.

=over

=item * L<EC2 API docs|http://docs.aws.amazon.com/AWSEC2/latest/APIReference/OperationList-query.html>

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

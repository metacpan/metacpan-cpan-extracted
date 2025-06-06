package Nexmo::SMS::WAPPushMessage;

use strict;
use warnings;

use Nexmo::SMS::Response;

use LWP::UserAgent;
use JSON::PP;

# ABSTRACT: Module that respresents a WAPPush message for the Nexmo SMS API!

our $VERSION = '0.02';

my %attrs = (
    title             => 'required',
    url               => 'required',
    type              => 'required',
    from              => 'required',
    to                => 'required',
    server            => 'required',
    username          => 'required',
    password          => 'required',
    status_report_req => 'optional',
    client_ref        => 'optional',
    network_code      => 'optional',
    validity          => 'optional',
);

for my $attr ( keys %attrs ) {
    no strict 'refs';
    *{ __PACKAGE__ . '::' . $attr } = sub {
        my ($self,$value) = @_;
        
        my $key = '__' . $attr . '__';
        $self->{$key} = $value if @_ == 2;
        return $self->{$key};
    };
}


sub new {
    my ($class,%param) = @_;
    
    my $self = bless {}, $class;
    
    for my $attr ( keys %attrs ) {
        if ( exists $param{$attr} ) {
            $self->$attr( $param{$attr} );
        }
    }
    
    $self->user_agent(
        LWP::UserAgent->new(
            agent => 'Perl module ' . __PACKAGE__ . ' ' . $VERSION,
        ),
    );
    
    return $self;
}


sub user_agent {
    my ($self,$ua) = @_;
    
    $self->{__ua__} = $ua if @_ == 2;
    return $self->{__ua__};
}


sub errstr {
    my ($self,$message) = @_;
    
    $self->{__errstr__} = $message if @_ == 2;
    return $self->{__errstr__};
}


sub send {
    my ($self) = shift;
    
    my %optional;
    $optional{'client-ref'}        = $self->client_ref        if $self->client_ref;
    $optional{'status-report-req'} = $self->status_report_req if $self->status_report_req;
    $optional{'network-code'}      = $self->network_code      if $self->network_code;
    $optional{'validity'}          = $self->validity          if $self->validity;
    
    my $response = $self->user_agent->post(
        $self->server,
        {
            %optional,
            username => $self->username,
            password => $self->password,
            from     => $self->from,
            to       => $self->to,
            title    => $self->title,
            url      => $self->url,
            type     => $self->type,
        },
    );
    
    if ( !$response || !$response->is_success ) {
        $self->errstr("Request was not successful: " . $response->status_line);
        warn $response->content if $response;
        return;
    }
    
    my $json            = $response->content;
    my $response_object = Nexmo::SMS::Response->new( json => $json );
    
    if ( $response_object->is_error ) {
        $self->errstr( $response_object->errstr );
    }
    
    return $response_object;
}


sub check_needed_params {
    my ($class,%params) = @_;
    
    my @params_not_ok;
    
    for my $attr ( keys %attrs ) {
        if ( $attrs{$attr} eq 'required' and !$params{$attr} ) {
            push @params_not_ok, $attr;
        }
    }
    
    return join ", ", @params_not_ok;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Nexmo::SMS::WAPPushMessage - Module that respresents a WAPPush message for the Nexmo SMS API!

=head1 VERSION

version 0.10

=head1 SYNOPSIS

This module simplifies sending SMS through the Nexmo API.

    use Nexmo::SMS::WAPPushMessage;

    my $nexmo = Nexmo::SMS::WAPPushMessage->new(
        server   => 'http://rest.nexmo.com/sms/json',
        username => 'testuser1',
        password => 'testpasswd2',
        text     => 'This is a test',
        from     => 'Test02',
        to       => '452312432',
    );
        
    my $response = $sms->send || die $sms->errstr;
    
    if ( $response->is_success ) {
        print "SMS was sent...\n";
    }

=head1 METHODS

=head2 new

create a new object

    my $message = Nexmo::SMS::WAPPushMessage->new(
        server   => 'http://rest.nexmo.com/sms/json',
        username => 'testuser1',
        password => 'testpasswd2',
    );

This method recognises these parameters:

    title             => 'required',
    url               => 'required',
    type              => 'required',
    from              => 'required',
    to                => 'required',
    server            => 'required',
    username          => 'required',
    password          => 'required',
    status_report_req => 'optional',
    client_ref        => 'optional',
    network_code      => 'optional',
    validity          => 'optional',

=head2 user_agent

Getter/setter for the user_agent attribute of the object. By default a new
object of LWP::UserAgent is used, but you can use your own class as long as it
is compatible to LWP::UserAgent.

  $sms->user_agent( MyUserAgent->new );
  my $ua = $sms->user_agent;

=head2 errstr

return the "last" error as string.

    print $sms->errstr;

=head2 send

This actually calls the Nexmo SMS API. It returns a L<Nexmo::SMS::Response> object or
C<undef> (on failure).

   my $sms = Nexmo::SMS::WAPPushMessage->new( ... );
   $sms->send or die $sms->errstr;

=head2 check_needed_params

This method checks if all needed parameters are passed.

  my $params_not_ok = Nexmo::SMS::WAPPushMessage->check_needed_params( ... );
  if ( $params_not_ok ) {
      print "Please check $params_not_ok";
  }

=head1 Attributes

These attributes are available for C<Nexmo::SMS::TextMessage> objects:

=over 4

=item * client_ref

=item * from

=item * network_code

=item * password

=item * server

=item * status_report_req

=item * title

=item * url

=item * type

=item * to

=item * username

=item * validity

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

package Nexmo::SMS::GetBalance;

use strict;
use warnings;

use LWP::UserAgent;
use JSON::PP;

# ABSTRACT: Module to ask for the balance for the Nexmo SMS API!

our $VERSION = '0.02';

my %attrs = (
    server            => 'required',
    username          => 'required',
    password          => 'required',
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

=head1 SYNOPSIS

This module simplifies sending SMS through the Nexmo API.


    use Nexmo::SMS::GetBalance;

    my $nexmo = Nexmo::SMS::GetBalance->new(
        server   => 'http://rest.nexmo.com/sms/json',
        username => 'testuser1',
        password => 'testpasswd2',
    );
        
    my $balance = $sms->get_balance;

=head1 METHODS

=head2 new

create a new object

    my $object = Nexmo::SMS::GetBalance->new(
        server   => 'http://rest.nexmo.com/sms/json',
        username => 'testuser1',
        password => 'testpasswd2',
    );

This method recognises these parameters:

    server            => 'required',
    username          => 'required',
    password          => 'required',

=cut

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

=head2 user_agent

Getter/setter for the user_agent attribute of the object. By default a new
object of LWP::UserAgent is used, but you can use your own class as long as it
is compatible to LWP::UserAgent.

  $sms->user_agent( MyUserAgent->new );
  my $ua = $sms->user_agent;

=cut

sub user_agent {
    my ($self,$ua) = @_;
    
    $self->{__ua__} = $ua if @_ == 2;
    return $self->{__ua__};
}

=head2 get_balance

This actually calls the Nexmo SMS API. It returns the balance of the account.

   my $balance = $object->get_balance;

=cut

sub get_balance {
    my ($self) = shift;
    
    my $url = sprintf "%saccount/get-balance/%s/%s",
        $self->server,
        $self->username,
        $self->password;
    
    my $ua = $self->user_agent;
    $ua->default_header( 'Accept' => 'application/json' );
    
    my $response = $ua->get(
        $url,
    );
    
    if ( !$response || !$response->is_success ) {
        return;
    }
    
    my $json  = $response->content;
    my $coder = JSON::PP->new->utf8->pretty->allow_nonref;
    my $perl  = $coder->decode( $json );
    
    return if !$perl || ref $perl ne 'HASH';    
    return $perl->{'value'};
}

=head1 Attributes

These attributes are available for C<Nexmo::SMS::GetBalance> objects. For each
attribute there is a getter/setter:

  $nexmo->server( 'servername' );
  my $server = $nexmo->server;

=over 4

=item * password

=item * server

=item * username

=back

=cut

1;


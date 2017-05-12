package Nexmo::SMS::Response::Message;

use strict;
use warnings;

# ABSTRACT: Module that represents a single message in the response from Nexmo SMS API!

our $VERSION = '0.02';

# create getter/setter
my @attrs = qw(
    error_text status message_id client_ref remaining_balance 
    message_price status_text status_desc
);

for my $attr ( @attrs ) {
    no strict 'refs';
    *{ __PACKAGE__ . '::' . $attr } = sub {
        my ($self,$value) = @_;
        
        my $key = '__' . $attr . '__';
        $self->{$key} = $value if @_ == 2;
        return $self->{$key};
    };
}

my %status_map = (
    0  => [ 'Success', 'The message was successfully accepted for delivery by nexmo' ],
    1  => [ 'Throttled',	'You have exceeded the submission capacity allowed on this account, please back-off and retry' ],
    2  => [ 'Missing params', 'Your request is incomplete and missing some mandatory parameters' ],
    3  => [ 'Invalid params', 'Thevalue of one or more parameters is invalid' ],
    4  => [ 'Invalid credentials', 'The username / password you supplied is either invalid or disabled' ],
    5  => [ 'Internal error', 'An error has occurred in the nexmo platform whilst processing this message' ],
    6  => [ 'Invalid message', 'The Nexmo platform was unable to process this message, for example, an un-recognized number prefix' ],
    7  => [ 'Number barred',	'The number you are trying to submit to is blacklisted and may not receive messages' ],
    8  => [ 'Partner account barred', 'The username you supplied is for an account that has been barred from submitting messages' ],
    9  => [ 'Partner quota exceeded', 'Your pre-pay account does not have sufficient credit to process this message' ],
    10 => [ 'Too many existing binds', 'The number of simultaneous connections to the platform exceeds the capabilities of your account' ],
    11 => [	'Account not enabled for REST', 'This account is not provisioned for REST submission, you should use SMPP instead' ],
    12 => [ 'Message too long',	'Applies to Binary submissions, where the length of the UDF and the message body combined exceed 140 octets' ],
);

=head1 SYNOPSIS

This module represents a single message in a response from Nexmo.


    use Nexmo::SMS::Response::Message;

    my $nexmo = Nexmo::SMS::Response::Message->new(
        json => '{
              "status":"4",
              "message-id":"message001",
              "client-ref":"Test001 - Reference",
              "remaining-balance":"20.0",
              "message-price":"0.05",
              "error-text":""
              }',
    );
    
    print $nexmo->message_price;

=head1 METHODS

=head2 new

create a new object

    my $foo = Nexmo::SMS::Response::Message->new(
        json => '
              {
              "status":"4",
              "message-id":"message001",
              "client-ref":"Test001 - Reference",
              "remaining-balance":"20.0",
              "message-price":"0.05",
              "error-text":""
              }',
    );

=cut

sub new {
    my ($class,%param) = @_;
    
    my $self = bless {}, $class;
    
    for my $attr ( @attrs ) {
        (my $key = $attr) =~ tr/_/-/;
        $self->$attr( $param{$key} );
    }
    
    my $status = $param{status};
    
    if ( exists $status_map{$status} ) {
        my $info = $status_map{$status};
        $self->status_text( $info->[0] );
        $self->status_desc( $info->[1] );
    }
    
    return $self;
}

1;

=head1 ATTRIBUTES

These attributes are available for C<Nexmo::SMS::TextMessage> objects:

  $nexmo->client_ref( 'client_ref' );
  my $client_ref = $nexmo->client_ref;

=over 4

=item * client_ref

=item * error_text

=item * message_price

=item * remaining_balance

=item * status_desc

=item * status message_id

=item * status_text

=back


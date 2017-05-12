package Nexmo::SMS::Response;

use strict;
use warnings;

use Nexmo::SMS::Response::Message;

use JSON::PP;

# ABSTRACT: Module that represents a response from Nexmo SMS API!

our $VERSION = '0.01';

# create getter/setter
my @attrs = qw(json message_count status);

for my $attr ( @attrs ) {
    no strict 'refs';
    *{ __PACKAGE__ . '::' . $attr } = sub {
        my ($self,$value) = @_;
        
        my $key = '__' . $attr . '__';
        $self->{$key} = $value if @_ == 2;
        return $self->{$key};
    };
}

=head1 SYNOPSIS

This module represents a response from Nexmo.


    use Nexmo::SMS::Response;

    my $nexmo = Nexmo::SMS::Response->new(
        json => '{
            "message-count":"1",
            "messages":[
              {
              "status":"4",
              "message-id":"message001",
              "client-ref":"Test001 - Reference",
              "remaining-balance":"20.0",
              "message-price":"0.05",
              "error-text":""
              }
            ]
        }',
    );
    
    for my $message ( $response ) {
        print $message->status;
    }

=head1 METHODS

=head2 new

create a new object

    my $foo = Nexmo::SMS::Response->new(
        json => '{
            "message-count":"1",
            "messages":[
              {
              "status":"4",
              "message-id":"message001",
              "client-ref":"Test001 - Reference",
              "remaining-balance":"20.0",
              "message-price":"0.05",
              "error-text":""
              }
            ]
        }',
    );

=cut

sub new {
    my ($class,%param) = @_;
    
    my $self = bless {}, $class;
    
    return $self if !$param{json};
    
    # decode json
    my $coder = JSON::PP->new->utf8->pretty->allow_nonref;
    my $perl  = $coder->decode( $param{json} );
    
    $self->message_count( $perl->{'message-count'} );
    $self->status( 0 );
    
    # for each message create a new message object
    for my $message ( @{ $perl->{messages} || [] } ) {
        $self->_add_message(
            Nexmo::SMS::Response::Message->new( %{$message || {}} )
        );
    }
    
    return $self;
}

=head2 messages

returns the list of messages included in the response. Each element is an
object of L<Nexmo::SMS::Response::Message>.

    my @messages = $response->messages;

=cut

sub messages {
    my ($self) = @_;
    
    return @{ $self->{__messages__} || [] };
}

sub _add_message {
    my ($self,$message) = @_;
    
    if ( @_ == 2 and $message->isa( 'Nexmo::SMS::Response::Message' ) ) {
        push @{$self->{__messages__}}, $message;
        if ( $message->status != 0 ) {
            $self->status(1);
            $self->errstr( $message->status_text . ' (' . $message->status_desc . ')' );
        }
    }
}

=head2 errstr

return the "last" error as string.

    print $response->errstr;

=cut


sub errstr {
    my ($self,$message) = @_;
    
    $self->{__errstr__} = $message if @_ == 2;
    return $self->{__errstr__};
}

=head2 is_success

returns 1 if all messages have a status = 0, C<undef> otherwise.

=cut

sub is_success {
    my ($self) = @_;
    return !$self->status;
}

=head2 is_error

Returns 1 if an error occured, 0 otherwise...

=cut

sub is_error {
    my ($self) = @_;
    return $self->status;
}

1;

=head1 ATTRIBUTES

These attributes are available for C<Nexmo::SMS::TextMessage> objects:

  $nexmo->status( 'status' );
  my $status = $nexmo->status;

=over 4

=item * json

=item * message_count

=item * status

=back


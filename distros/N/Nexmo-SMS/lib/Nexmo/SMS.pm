package Nexmo::SMS;

use warnings;
use strict;

use Nexmo::SMS::BinaryMessage;
use Nexmo::SMS::TextMessage;
use Nexmo::SMS::WAPPushMessage;

use Nexmo::SMS::GetBalance;

# ABSTRACT: Module for the Nexmo SMS API!

our $VERSION = '0.09';


=head1 SYNOPSIS

This module simplifies sending SMS through the Nexmo API.


    use Nexmo::SMS;

    my $nexmo = Nexmo::SMS->new(
        server   => 'https://rest.nexmo.com/sms/json',
        username => 'testuser1',
        password => 'testpasswd2',
    );
    
    my $sms = $nexmo->sms(
        text     => 'This is a test',
        from     => 'Test02',
        to       => '452312432',
    ) or die $nexmo->errstr;
    
    my $response = $sms->send || die $sms->errstr;
    
    if ( $response->is_success ) {
        print "SMS was sent...\n";
    }

=head1 METHODS

=head2 new

create a new object

    my $foo = Nexmo::SMS->new(
        server   => 'https://rest.nexmo.com/sms/json',
        username => 'testuser1',
        password => 'testpasswd2',
    );

Those parameters are optional and they are used as defaults for the message objects

=cut

my @attrs = qw(server username password);;

for my $attr ( @attrs ) {
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

    $param{server} ||= 'https://rest.nexmo.com/sms/json';
    
    for my $attr ( @attrs ) {
        if ( exists $param{$attr} ) {
            $self->$attr( $param{$attr} );
        }
    }
    
    return $self;
}

=head2 sms

Create a new message object or returns C<undef>.

    my $sms = $nexmo->sms(
        text     => 'This is a test',
        from     => 'Test02',
        to       => '452312432',
    ) or die $nexmo->errstr;

Send a binary message

    my $binary = $nexmo->sms(
        type     => 'binary',
        udh      => '06050415811581',   # hex encoded udh
        body     => '0011223344556677', # hex encoded body
        from     => 'Test02',
        to       => '452312432',
    ) or die $nexmo->errstr;

=cut

sub sms {
    my ($self,%param) = @_;
    
    my %types = (
        text    => 'Nexmo::SMS::TextMessage',
        unicode => 'Nexmo::SMS::TextMessage',
        binary  => 'Nexmo::SMS::BinaryMessage',
        wappush => 'Nexmo::SMS::WAPPushMessage',
    );
    
    my $requested_type = $param{type};
    if ( exists $param{type} and !$types{$requested_type} ) {
        $self->errstr("Type $requested_type not supported (yet)!");
        return;
    }
        
    my $type   = $requested_type || 'text';
    my $module = $types{$type};

    $param{type} = $type if $type ne 'text';
    
    # check for needed params
    my $sub_name  = 'check_needed_params';
    my $check_sub = $module->can( $sub_name );
    if ( !$check_sub ) {
        $self->errstr("$module does not know about sub $sub_name");
        return;
    }
    
    $param{server}   ||= $self->server;
    $param{username} ||= $self->username;
    $param{password} ||= $self->password;
    
    my $params_not_ok = $module->$sub_name( %param );
    if ( $params_not_ok ) {
        $self->errstr("Check params $params_not_ok");
        return;
    }
    
    # create new message
    my $message = $module->new( %param );
    
    # return message 
    return $message;
}

=head2 errstr

return the "last" error as string.

    print $nexmo->errstr;

=cut

sub errstr {
    my ($self,$message) = @_;
    
    $self->{__errstr__} = $message if @_ == 2;
    return $self->{__errstr__};
}

=head2 get_balance

  my $balance = $nexmo->get_balance;

=cut

sub get_balance {
    my ($self,%param) = @_;

    $param{server}   ||= $self->server;
    $param{username} ||= $self->username;
    $param{password} ||= $self->password;

    my $balance = Nexmo::SMS::GetBalance->new(
        %param,
    );
    
    return $balance->get_balance;
}

=head2 get_pricing

Not implemented yet...

=cut

sub get_pricing {
    warn "not implemented yet\n";
    return;
}

=head1 Attributes

These attributes are available for C<Nexmo::SMS::TextMessage> objects. For each
attribute there is a getter/setter:

  $nexmo->server( 'servername' );
  my $server = $nexmo->server;

=over 4

=item * password

=item * server

=item * username

=back

=head1 ACKNOWLEDGEMENTS

Jui-Nan Lin added support for Unicode messages, thanks!
(see https://github.com/reneeb/perl-Nexmo-SMS/pull/1/files)

=cut

1; # End of Nexmo::SMS

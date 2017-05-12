package Polycom::App::Push;
use strict;
use warnings;
use LWP::UserAgent;
use base qw(Class::Accessor);

our $VERSION = 0.04;

###################
# Basic Accessors
###################
Polycom::App::Push->mk_accessors(qw(address username password));

###################
# Constructors
###################
sub new
{
    my ($class, %args) = @_;

    my $self = {
        address   => $args{address},
        username  => $args{username},
        password  => $args{password},
        ua        => LWP::UserAgent->new,
    };

    if (!defined $self->{address} || $self->{address} eq '')
    {
        warn "No 'address' attribute specified";
    }

    return bless $self, $class;
}

###################
# Public Methods
###################
sub push_message
{
    my ($self, @messages) = @_;

    # Push all of the messages to the phone
    my $messagesSent = 0;
    foreach my $msg (@messages)
    {
        my $priority = (defined $msg->{priority} && lc($msg->{priority}) eq 'critical') ? 'critical' : 'normal';
        my $content_type;

        # Generate the XML message to send to the phone
        my $xml = '<PolycomIPPhone>';
        if (defined $msg->{url})
        {
            $xml .= qq(<URL priority="$priority">$msg->{url}</URL>);
            $content_type = 'application/x-com-polycom-spipx';
        }
        elsif (defined $msg->{data})
        {
            $xml .= qq(<Data priority="$priority">$msg->{data}</Data>);
            $content_type = 'application/xhtml+xml';
        }
        elsif (defined $msg->{uri_data})
        {
            $xml .= qq(<Data priority="$priority">$msg->{uri_data}</Data>);
            $content_type = 'application/x-com-polycom-spipx';
        }
        $xml .= '</PolycomIPPhone>';

        # Verify that at least one of the required url, data, or uri_data parameters are specified
        if (!defined $content_type)
        {
            die 'Exactly one of url, data, or uri_data must be specified';
        }

        # Configure the user agent to communicate with the phone
        $self->{ua}->credentials($self->{address} . ':80', 'PUSH Authentication', $self->{username}, $self->{password});

        # Send the push request to the phone
        my $response = $self->{ua}->post(
            'http://' . $self->{address} . '/push',
            'Content-Type' => $content_type,
            Content        => $xml,
        );

        if ($response->is_success)
        {
            $messagesSent++;
        }
        else
        {
            print "Unable to send push request to http://$self->{address}/push. The response from the phone was:\n"
                . $response->as_string;
        }
    }

    return $messagesSent;
}

=head1 NAME

Polycom::App::Push - Module for sending push requests to Polycom's SoundPoint IP and VVX series VoIP phones

=head1 SYNOPSIS

  use Polycom::App::Push;

  my $phone = Polycom::App::Push->new(address => '172.23.8.100', username => 'Bob', password => '1234');

  # Send a simple XHTML message to a Polycom phone that will pop-up on the screen
  $phone->push_message({priority => 'normal', data => '<h1>Fire drill at 2:00pm!</h1>'});

  # Request that the phone show the specified web page, relative to the URL specified in the "apps.push.serverRootURL" configuration parameter
  $phone->push_message({priority => 'critical', url => '/announcement.xhtml'});

  # Request that the phone execute the specified internal URI, or prompt the user to dial the specified "tel:" or "sip:" URI
  $phone->push_message({priority => 'critical', uri_data => 'sip:172.23.8.100'});

=head1 DESCRIPTION

The C<Polycom::App::Push> class is for writing web applications for Polycom's SoundPoint IP and VVX series VoIP phones. It provides a mechanism to push messages to a phone for display to the user.

Note that to use the C<push_message> method, the phone must be configured with the following parameters, where the values of each parameters should be customized based on your requirements:

   <apps
     apps.push.messageType="5"
     apps.push.serverRootURL="http://192.168.1.11"
     apps.push.username="Polycom"
     apps.push.password="456" />

The value of the 'C<apps.push.messageType>' parameter is very important, because it determines how the phone will filter incoming push messages based on their 'C<priority>' attributes. The allowable values for the 'C<apps.push.messageType>' parameter are: 

   0 - Don't show any push messages
   1 - Show messages with 'priority="normal"'
   2 - Show messages with 'priority="important"'
   3 - Show messages with 'priority="high"'
   4 - Show messages with 'priority="critical"'
   5 - Show all messages, regardless of their 'priority' value

The 'C<apps.push.serverRootURL>' parameter is used as the base URL for the relative URL passed to 'C<push_message>' method in its 'C<url>' parameter.

The 'C<apps.push.username>' and 'C<apps.push.password>' parameters must match the 'C<username>' and 'C<password>' parameters passed to the 'C<push_message>' method.

=head1 CONSTRUCTOR

=head2 new ( %fields )

  use Polycom::App::Push;
  my $phone = Polycom::App::Push->new(address => '172.23.8.100', username => 'Polycom', password => '456');

Returns a newly created C<Polycom::App> object. The following parameters are required:

  address   - the IP address of the phone.
  username  - the user name configured on the phone with the "apps.push.username" parameter.
  password  - the password configured on the phone with the "apps.push.password" parameter.

=head1 ACCESSORS

=head2 address

  my $ip_address = $phone->address
  $phone->address('172.23.8.100');  # Set the address to "172.23.8.100"

=head2 username

  my $username = $phone->username;
  $phone->username('Bob');  # Set the username to 'Bob'

=head2 password

  my $password = $phone->password;
  $phone->password('1234');  # Set the password to '1234'

=head1 METHODS

=head2 push_message

  if (!$phone->push_message({priority => "critical", url => "/announcements/happy_birthday.xhtml"});)
  {
      print "Failed to send push message\n";
  }

This method can be used to send a push request to a Polycom IP phone that will trigger it to display the supplied message or URL in its web browser. The following parameters are supported:

  priority  - the priority of the message (either "critical" or "normal"). If not specified, "normal" is assumed.
  url       - the URL to display on the phone, relative to the "apps.push.serverRootURL" configuration parameter.
  data      - a URI-escaped HTML document to display on the phone.
  uri_data  - an internal URI to execute, or a "sip:" or "tel:" URI to prompt the user to dial 

Note that either C<url> or C<data> must be specified, but not both. Returns C<1> if the message was sent successfully, or C<0> otherwise.

=head1 SEE ALSO

I<Developer's Guide SoundPoint IP / SoundStation IP> - L<http://support.polycom.com/global/documents/support/setup_maintenance/products/voice/Web_Application_Developers_Guide_SIP_3_1.pdf>

I<Polycom(R) UC Software Administrator's Guide> - L<http://support.polycom.com/global/documents/support/setup_maintenance/products/voice/spip_ssip_vvx_Admin_Guide_UCS_v4_0_0.pdf>

C<Polycom::App::URI> - A module that can be used to generate XHTML documents for displaying custom softkeys and hyperlinks using internal URIs for Polycom phones.

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Zachary Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

'Together. Great things happen.';

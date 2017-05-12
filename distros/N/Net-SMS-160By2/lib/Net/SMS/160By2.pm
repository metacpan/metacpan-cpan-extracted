package Net::SMS::160By2;

no warnings;
use strict;

# Load this to handle exceptions nicely
use Carp;
use Data::Dumper;

# Load this to make HTTP Requests
use WWW::Mechanize;
use HTML::Form;
use POSIX qw/strftime/;

=head1 NAME

Net::SMS::160By2 - Send SMS using your 160By2 account!

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

our $BASE_URL           = 'http://www.160by2.com';
our $LOGIN_URL          = $BASE_URL . '/re-login';
our $SENDSMS_URL        = $BASE_URL . '/SendSMS';
our $SENDSMS_SUBMIT_URL = $BASE_URL . '/SendSMSDec19';
my $mech;

=head1 SYNOPSIS

This module provides a wrapper around 160By2.com to send an SMS to any mobile number in 

India, Kuwait, UAE, Saudi, Singapore, Philippines & Malaysia at present.

you can use this as follows.

    use Net::SMS::160By2;

    my $obj = Net::SMS::160By2->new(); # or Net::SMS::160By2->new({debug => 1, verbose => 1});
    $obj->login($username, $password);
   
    # Send SMS to one mobile number 
    # country code is optional in mobile number
    my ($msg1, $to1) = ('Test Msg', 1111111111);
    $obj->send_sms($msg1, $to1);

    # Send SMSes to Many mobile numbers
    my ($msg1, $to1, $msg2, $to2) = ('Test Msg 1', 2222222222, 'Test Msg 2', 3333333333);
    my @array = ( 
      [ $msg2, $to2 ], 
      [ $msg3, $to3 ],
      # include as many as your want
    );

    $obj->send_sms_multiple(\@array);

    # logout from 160by2.com
    $obj->logout();

    # send additional params will print WWW::Mechanize detailed request and
    # responses

Thats it!
    
=head1 SUBROUTINES/METHODS

=head2 new

This is constructor method.

input: username, password

A new object will be created with username, password attributes.

You can send additional params in a hash ref as 3rd parameter.

at present only debug option is handled in additional params.

output: Net::SMS::160By2 object

=cut

sub new {
    my $class = shift;

    # read username and password
    my $options = shift;
    $options = {} unless ref($options) eq 'HASH';

    # debug mean both debug and verbose
    # verbose means only verbose
    $options->{verbose} = $options->{debug} if $options->{debug};

    # return blessed object
    my $self = bless {
        'username'   => undef,
        'password'   => undef,
        'session_id' => undef,
        %{$options}
    }, $class;
    return $self;
}

=head2 login

Login to www.160By2.com

=cut

sub login {
    my ( $self, $username, $password ) = @_;

    # Throw error in case of no username or password
    confess("No username provided") unless ($username);
    confess("No password provided") unless ($password);

    $self->{username} = $username;
    $self->{password} = $password;

    # create mechanize object
    $mech = WWW::Mechanize->new( autocheck => 1 );
    $self->logger( 'DEBUG', 'Created WWW::Mechanize successfully.' )
      if $self->{debug};

    #if ( $self->{debug} ) {
    #    $mech->add_handler( "request_send",  sub { shift->dump; return } );
    #    $mech->add_handler( "response_done", sub { shift->dump; return } );
    #}
    $mech->agent_alias('Windows Mozilla');

    # Login with given credentials
    $self->logger( 'INFO',
        "Logging into $BASE_URL using $self->{username}, $self->{password}" )
      if $self->{verbose};
    $mech->post( $LOGIN_URL,
        { username => $self->{username}, password => $self->{password} } );

    # Verify login success/failed
    my $content = $mech->content();
    $self->logger( 'DEBUG', "Response received for Login request: \n$content" )
      if $self->{debug};
    my ($prefix) = ( $content =~
          m/window\.location=['"](?:Main(?:\.action)?)\?(.*?)['"]/gi );
    my ($session_id) = ( $prefix =~ /id=(.*)$/gi );
    $self->logger( 'ERROR',
"No session details found in received Response for Login request. So treating this as Login failure."
    ) if ( $self->{verbose} && !$session_id );
    confess "Login to 160by2.com failed." unless $session_id;

    $self->{session_id} = $session_id;
}

=head2 logout

Logout from 160By2.com

=cut

sub logout {
    my ($self) = @_;
    $self->logger( 'ERROR', "No Session found to logout" )
      if ( $self->{verbose} && !$self->{session_id} );
    confess "No Session found to logout" unless ( $self->{session_id} );
    my $logout_url = $BASE_URL . '/Logout';
    $mech->get($logout_url);
}

=head2 send_sms

This method is used to send an SMS to any mobile number.
input : message, to

where message contains the information you want to send.
      to is the recipient mobile number
      
=cut

sub send_sms {
    my ( $self, $msg, $to ) = @_;
    confess 'Please send Message, mobile number as arguements to send_sms'
      unless ( $msg || $to );

    # Check user session exists
    confess "No Session details found. Please login first to send SMS"
      unless ( $self->{session_id} );

    # format inputs
    $self->logger( 'INFO', "Formatting message, mobile number" )
      if $self->{verbose};
    ( $msg, $to ) = $self->_format_input( $msg, $to );

    # sendsms from 160by2
    $self->logger( 'INFO', "Sending Message '$msg' to Mobile '$to'" )
      if $self->{verbose};
    $self->_send_one( $msg, $to );

}

=head2 send_sms_multiple

This method is used to send an SMS to many mobile numbers.
input : $ARRAY_REF [ [$msg1, $to1], [$msg2, $to2], [$msg3, $to3], etc.. ]

where message contains the information you want to send.
      to is the recipient mobile number
      
=cut

sub send_sms_multiple {
    my ( $self, $persons ) = @_;

    confess
'Please send an array reference, ex. [ [$msg1, $mob1], [$msg2, $mob2], [$msg3, $mob3], and soon.. ] as an arguement to send_sms_multiple'
      unless ref($persons) eq 'ARRAY';

    # Check user session exists
    confess "No Session details found. Please login to send SMS"
      unless ( $self->{session_id} );

    foreach my $person (@$persons) {

        # format inputs
        my ( $msg, $to ) = @$person;
        confess("Message or mobile number are missing") unless ( $msg || $to );

        $self->logger( 'INFO', "Formatting message, mobile number" )
          if $self->{verbose};
        ( $msg, $to ) = $self->_format_input(@$person);

        # sendsms from 160by2
        $self->logger( 'INFO', "Sending Message '$msg' to Mobile '$to'" )
          if $self->{verbose};
        $self->_send_one( $msg, $to );
    }

}

=head2 _format_input

This will format message and mobile number

=cut

sub _format_input {
    my ( $self, $msg, $to ) = @_;

    # trim spaces
    $msg =~ s/^\s+|\s+$//;
    $to  =~ s/^\s+|\s+$//;

    # cleanup mobile number
    # remove non digits
    $to =~ s/\D//g;

    # prepend country code if not present
    unless ( length($to) == 10 ) {
        $to .= '91' . $to;
    }
    return ( $msg, $to );
}

sub _send_one {
    my ( $self, $message, $mobile ) = @_;

    # Try to go to Home Page
    my $sendsms_url = $SENDSMS_URL . '?id=' . $self->{session_id};
    $self->logger( 'INFO', "Getting SMS Form using URL $sendsms_url" )
      if $self->{verbose};
    $mech->get($sendsms_url);

    my $response = $mech->response();
    $self->logger( 'INFO',
        "Checking SMS Form really exists in received Response" )
      if $self->{verbose};
    my @forms = HTML::Form->parse($response);

    my ($sendsms_form) = grep {
             ( $_->attr('name') =~ /frm_sendsms/i )
          or ( $_->attr('id')   =~ /frm_sendsms/i )
          or ( $_->attr('id')   =~ /send\-sms\-form/i )
    } @forms;
    die "Unable to find Send SMS Form\n" unless $sendsms_form;
    $self->logger( 'INFO', "Found Send SMS form in response." )
      if $self->{verbose};

    my @names = $sendsms_form->param;
    my %params;
    my $action;

    foreach my $name (@names) {
        my $input = $sendsms_form->find_input($name);
        if (
               $input
            && $input->type eq 'text'
            && (   $input->name =~ /mobile/i
                || $input->id =~ /mobile/i
                || $input->{placeholder} =~ /Mobile (Number)?/i )
          )
        {
            $params{$name} = $mobile;
        }

        # Find message textarea element
        elsif (
               $input
            && $input->type eq 'textarea'
            && (   $input->name =~ /sendSMSMsg/i
                || $input->id =~ /sendSMSMsg/i
                || $input->{placeholder} =~ /(Enter your)?\s*message/i )
          )
        {
            $params{$name} = $message;
        }

        # Find form action attribute
        elsif ($input
            && $input->type eq 'hidden'
            && ( $input->name =~ /fkapps/i || $input->id =~ /fkapps/i ) )
        {
            $action = $BASE_URL . '/' . $input->value;
            $params{$name} = $input->value;
        }
        elsif ( $name eq 'hid_exists' ) {
            $params{$name} = 'no';
        }
        elsif ( $name eq 'maxwellapps' ) {
            $params{$name} = $self->{session_id};
        }
        elsif ( $name eq 'ulCategories' ) {
            $params{$name} = 32;
        }
        elsif ( $name eq 'reminderDate' ) {
            $params{$name} = strftime( "%m-%d-%Y", localtime );
        }
        else {
            $params{$name} = $input->value;
        }
    }
    $action = $SENDSMS_SUBMIT_URL unless $action;
    $self->logger( 'DEBUG',
        "Posting Data " . Dumper( \%params ) . " to URL $action" )
      if $self->{debug};
    $mech->post( $action, \%params );
    my $content = $mech->content();
    $self->logger( 'DEBUG', "Response for Send SMS Form Post : " . $content )
      if $self->{debug};
    if ( $content =~ /You have reached 160by2 Usage/gsmi ) {
        $self->logger( 'ERROR',
'160By2 Usage Limit for your account reached today. Please use a different Account to send more or wait till tomorrow!'
        );
    }
}

=head2 logger

Log info for debugging purpose

=cut

sub logger {
    my ( $self, $state, $msg ) = @_;
    print STDOUT "$state: $msg\n";
}

=head1 AUTHOR

Mohan Prasad Gutta, C<< <mohanprasadgutta at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-sms-160by2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMS-160By2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMS::160By2


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMS-160By2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SMS-160By2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SMS-160By2>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SMS-160By2/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Mohan Prasad Gutta.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Net::SMS::160By2

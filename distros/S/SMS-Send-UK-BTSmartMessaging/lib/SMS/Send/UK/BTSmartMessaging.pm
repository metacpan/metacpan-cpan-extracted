package SMS::Send::UK::BTSmartMessaging;

use warnings;
use strict;
use Carp;

=head1 NAME

SMS::Send::UK::BTSmartMessaging

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

=head1 SYNOPSIS

    # Instantiate a sender object
    my $sender = SMS::Send->new(
        'UK::BTSmartMessaging',
        _login    => 'username',
        _password => 'password',
    );

    # Send a message
    my $sent = $sender->send_sms(
        text => 'This is my message, must be <= 160 characters',
        to   => '0000000000' # In the format: 447312345679
    );

=head1 DESCRIPTION

L<SMS::Send::UK::BTSmartMessaging> is a L<SMS::Send> driver that provides
SMS message sending via the BT Smart Messaging Tailored powered by Soprano
HTTP API

=head2 CAVEATS

You need a BT Smart Messaging Tailored powered by Soprano account in order
to use this driver

=head1 METHODS

=cut

use base 'SMS::Send::Driver';
use LWP::UserAgent();
use MIME::Base64;

=head2 new

    # Instantiate a sender object
    my $sender = SMS::Send->new(
        'UK::BTSmartMessaging',
        _login    => 'username',
        _password => 'password',
    );

The C<new> constructor accepts three parameters, all of which are required:

The return value is a C<SMS::Send::UK::BTSmartMessaging> object.

=over 4

=item 'UK::BTSmartMessaging'

The parameter identifying the driver name

=item _login

The C<_login> parameter as supplied by BT

=item _password

The C<_password> parameter as supplied by BT

=back

=cut

sub new {
    my $class = shift;
    my %params = @_;

    # Ensure we've been passed the parameters we're expecting
    my @expected = ( '_login', '_password' );
    foreach my $expect(@expected) {
        if (!exists $params{$expect}) {
            croak join(', ', @expected) . ' parameters must be supplied';
        }
    }

    # Instantiate the object
    my $self = bless {
        login    => $params{'_login'},
        password => $params{'_password'},
        base_url => 'https://tailored.bt.com/cgphttp/servlet/sendmsg'
    }, $class;

    return $self;
}

=head2 clean_to

    # Examine a passed phone number and attempt to return the number
    # in an international format, croak of a conversion is not possible
    my $intl_number = clean_to($source_number);

The C<clean_to> method accepts a single required parameter:

The return value is the number in international format

=over 4

=item source_number

A string containing the number to be cleaned

=back

=cut

sub clean_number {
    my $source_number = shift;

    # The number may already be in the format we want
    if ($source_number =~ /^44(?!4)/) {
        return $source_number;
    }
    # Strip any leading +
    elsif ($source_number =~ /^\+44/) {
        $source_number =~ s/^\+//;
        return $source_number;
    }
    # Replace a leading 0 with 44
    elsif ($source_number =~ /^0/) {
        $source_number =~ s/^0/44/;
        return $source_number;
    }
    # We can't do anything with this number
    else {
        croak 'Unrecognised number format';
    }
}

=head2 send_sms

    # Send a message
    my $sent = $sender->send_sms(
        text => 'This is my message, must be <= 160 characters',
        to   => '0000000000' # In the format: 447312345679
    );

The C<send_sms> method accepts two parameters, both of which are required:

The return value is a 0 or 1 representing false or true, indicating whether
the send was successful.

=over 4

=item text

A string of text representing the message, limited to 160 characters

=item to

A numeric string representing the phone number of the recipient, in a valid
international format (i.e. country code followed by the number)

=back

=cut

sub send_sms {
    my $self = shift;
    my %params = @_;

    # Ensure we've been passed the parameters we're expecting
    my @expected = ('text', 'to');
    foreach my $expect(@expected) {
        if (!exists $params{$expect}) {
            croak join(', ', @expected) . ' parameters must be supplied';
        }
    }

    my $ua = LWP::UserAgent->new;
    my $destination = clean_number($params{to});
    my $text = $params{text};

    # Add our authorisation credentials
    my $credentials = encode_base64($self->{'login'} . ':' . $self->{'password'});
    $ua->default_header('Authorization' => "Basic $credentials");
    # Send the request
    my $response = $ua->post(
        $self->{'base_url'},
        { destination => $destination, text => $text }
    );

    # Check the send succeded
    if (!$response->is_success()) {
        croak('API request failed: ' . $response->status_line());
        return 0;
    }

    return 1;
}

=head1 AUTHOR

Andrew Isherwood C<< <andrew.isherwood at ptfs-europe.com> >>

=head1 BUGS

Please report any bugs or features to C<andrew.isherwood at ptfs-europe.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc SMS::Send::UK::BTSmartMessaging

=head1 COPYRIGHT & LICENSE

Copyright (C) 2018 PTFS Europe L<https://www.ptfs-europe.com/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself
 
Additionally, you are again reminded that this software comes with
no warranty of any kind, including but not limited to the implied
warranty of merchantability.
  
ANY use my result in charges on your BT Smart Messaging bill, and you should
use this software with care. The author takes no responsibility for
any such charges accrued.

=head1 ACKNOWLEDGEMENTS

Many thanks to the authors of the following modules that served as
inspiration for this one:

=over 4

=item SMS::Send::US::TMobile


=item SMS::Send::US::Ipipi


=item SMS::Send::UK::Kapow

=back

=cut

1; # End of SMS::Send::UK::BTSmartMessaging


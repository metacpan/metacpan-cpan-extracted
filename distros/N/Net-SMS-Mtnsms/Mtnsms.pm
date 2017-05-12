package Net::SMS::Mtnsms;

$VERSION = '0.003';

use strict;

#------------------------------------------------------------------------------
#
# Standard pragmas
#
#------------------------------------------------------------------------------

require Net::SMS::Web;

#------------------------------------------------------------------------------
#
# POD
#
#------------------------------------------------------------------------------

=head1 NAME

Net::SMS::Mtnsms - a module to send SMS messages using the Mtnsms web2sms
gateway (L<http://www.mtnsms.com/>).

=head1 SYNOPSIS

    my $sms = Net::SMS::Mtnsms->new(
        autotruncate => 1,
        username => 'yourname',
        password => 'yourpassword',
        recipient => 07713123456,
        signature => 'a test',
        message => 'a test message',
    );

    $sms->verbose( 1 );
    $sms->message( 'a different message' );
    print "sending message to mobile number ", $sms->recipient();

    $sms->send_sms();

=head1 DESCRIPTION

A perl module to send SMS messages, using the Mtnsms web2sms gateway. This
module will only work with mobile phone numbers that have been registered with
Mtnsms (L<http://www.mtnsms/>) and uses form submission to a URL that may be
subject to change.

There is a maximum length for SMS signature + message (160 for Mtnsms). If the
sum of signature and message lengths exceed this, the behaviour of the
Net::SMS::Mtnsms objects depends on the value of the 'autotruncate' argument to
the constructor. If this is a true value, then the signature / message will be
truncated to 123 characters. If false, the object will throw an exception
(croak).

=cut

#------------------------------------------------------------------------------
#
# Package globals
#
#------------------------------------------------------------------------------

use vars qw(
    @ISA
    $BASE_URL 
    $LOGIN_URL
    $SEND_URL 
    $LOGOUT_URL
    %REQUIRED_KEYS 
    %LEGAL_KEYS 
    $MAX_CHARS
);

@ISA = qw( Net::SMS::Web );

$BASE_URL = 'http://www.mtnsms.com';

$LOGIN_URL = "/session.asp";
$SEND_URL = "/sms/xsms.asp";
$LOGOUT_URL  = "/logout.asp";

%REQUIRED_KEYS = (
    username => 1,
    password => 1,
    recipient => 1,
    message => 1,
);

%LEGAL_KEYS = (
    username => 1,
    password => 1,
    recipient => 1,
    signature => 1,
    message => 1,
    verbose => 1,
);

$MAX_CHARS = 123;

#------------------------------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------------------------------

=head1 CONSTRUCTOR

The constructor for Net::SMS::Mtnsms takes the following arguments as hash
values (see L<"SYNOPSIS">):

=head2 autotruncate (OPTIONAL)

Mtnsms has a upper limit on the length of the subject + message (123). If
autotruncate is true, subject and message are truncated to 123 if the sum of
their lengths exceeds 160. The heuristic for this is simply to treat subject
and message as a string and truncate it (i.e. if length(subject) >= 123 then
message is truncated to 0. Thanks to Mark Zealey <mark@itsolve.co.uk> for this
suggestion. The default for this is false.

=head2 username (REQUIRED)

The Mtnsms username for the user (assuming that the user is already registered
at L<http://www.mtnsms.com/>.

=head2 password (REQUIRED)

The Mtnsms password for the user (assuming that the user is already registered
at L<http://www.mtnsms.com/>.

=head2 recipient (REQUIRED)

Mobile number for the intended SMS recipient.

=head2 subject (REQUIRED)

SMS message subject.

=head2 message (REQUIRED)

SMS message body.

=head2 verbose (OPTIONAL)

If true, various soothing messages are sent to STDERR. Defaults to false.

=cut

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->_init( @_ );
    return $self;
}

#------------------------------------------------------------------------------
#
# AUTOLOAD - to set / get object attributes
#
#------------------------------------------------------------------------------

=head1 AUTOLOAD

All of the constructor arguments can be got / set using accessor methods. E.g.:

        $old_message = $self->message;
        $self->message( $new_message );

=cut

sub AUTOLOAD
{
    my $self = shift;
    my $value = shift;

    use vars qw( $AUTOLOAD );
    my $key = $AUTOLOAD;
    $key =~ s/.*:://;
    return if $key eq 'DESTROY';
    die ref($self), ": unknown method $AUTOLOAD\n" 
        unless $LEGAL_KEYS{ $key }
    ;
    if ( defined( $value ) )
    {
        $self->{$key} = $value;
    }
    return $self->{$key};
}

=head1 METHODS

=head2 send_sms

This method is invoked to actually send the SMS message that corresponds to the
constructor arguments.

=cut

sub send_sms
{
    my $self = shift;

    $self->action( Net::SMS::Web::Action->new(
        url => $BASE_URL . $LOGIN_URL, 
        params => {
            username => $self->{username},
            password => $self->{password},
        },
        method  => 'POST',
    ) );
    $self->action( Net::SMS::Web::Action->new(
        url => $BASE_URL . $SEND_URL,
        params => {
            smsToNumbers    => $self->{recipient},
            smsMessage      => $self->{message},
            smsSig          => defined $self->{signature},
            smsSigDyna      => $self->{signature},
        }
    ) );
    $self->action( Net::SMS::Web::Action->new(
        url => $BASE_URL . $LOGOUT_URL,
    ) );
}

sub _check_length
{
    my $self = shift;
    $self->{message_length} = 0;
    if ( $self->{autotruncate} )
    {
        # Chop the message down the the correct length. Also supports subjects
        # > $MAX_CHARS, but I think it's a bit stupid to send one, anyway ...
        # - Mark Zealey
        $self->{subject} = substr $self->{subject}, 0, $MAX_CHARS;
        $self->{message} = 
            substr $self->{message}, 0, $MAX_CHARS - length $self->{subject}
        ;
        $self->{message_length} += length $self->{$_} for qw/subject message/;
    }
    else
    {
        $self->{message_length} = 
            length( $self->{subject} ) + length( $self->{message} )
        ;
        if ( $self->{message_length} > $MAX_CHARS )
        {
            die ref($self), 
                ": total message length (subject + message)  is too long ",
                "(> $MAX_CHARS)\n"
            ;
        }
    }
}

sub _init
{
    my $self = shift;
    my %keys = @_;

    for ( keys %REQUIRED_KEYS )
    {
        die ref($self), ": $_ field is required\n" unless $keys{$_};
    }
    for ( keys %keys )
    {
        $self->{$_} = $keys{$_};
    }
    $self->_check_length();
}

#------------------------------------------------------------------------------
#
# More POD ...
#
#------------------------------------------------------------------------------

=head1 ACKNOWLEGEMENTS

Many thanks to P-A-N-D-O-R [pandor@compclub.sk] for access to a script he wrote
for submitting SMS messages via mtnsms.

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;

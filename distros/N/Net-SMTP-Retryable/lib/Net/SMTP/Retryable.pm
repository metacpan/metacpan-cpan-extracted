#
# Net::SMTP::Retryable - Wrapper for Net::SMTP which supports retries
#
# $Id: Retryable.pm,v 1.6 2005/07/04 20:00:29 mprewitt Exp $
# $Source: /home/cvs/chelsea/netsmtp-retryable/lib/Net/SMTP/Retryable.pm,v $
# $Locker:  $
#

#---------------------------------------------------------------------

=head1 NAME

B<Net::SMTP::Retryable> - Net::SMTP wrapper

=head1 SYNOPSIS

    use Net::SMTP::Retryable;

    %options = (
            connectretries => 2,
            sendretries => 5,
            retryfactor => .25
            );

    $smtp = Net::SMTP->new($mailhost, %options);
    $smtp = Net::SMTP->new([ $mailhost1, $mailhost2, ...], %options);

    $smtp->SendMail(mail=>$from, to=>$to, data=>$body);

    $smtp->mail($from);
    $smtp->to($to);
    $smtp->data($body);

=head1 DESCRIPTION

Net::SMTP offers some automatic redundancy by allowing you to specify
multiple hosts.  On connection, a connection will be tried to each
host until one succeeds.  However, if you loose your connection,
it is up to you to reconnect and resend your message.  This leads to
code which has reconnection and retries and usually ends up as a mess.

This class adds retry and reconnect logic to Net::SMTP commands 
The following Net::SMTP commands are patched to offer retry logic:

    $smtp->mail()
    $smtp->send()
    $smtp->send_or_mail()
    $smtp->send_and_mail()
    $smtp->mail()
    $smtp->to()
    $smtp->cc()
    $smtp->bcc()
    $smtp->recipient()
    $smtp->data()

If any of the above commands fail, the connection to the server
will be reset and all commands in the current mail transaction
will be replayed.

This also works with other mail packages which use Net::SMTP as 
a transport like MIME::Entity.

=head1 NOTES

This is an alpha version and there are a few things which will 
undoubtedly change.  First, the default retry numbers are up
for discussion and will probably change.  Second, the retry
logic is very simple and needs to be given a bit of thought.

I'd like this to really be a subclass of Net::SMTP. Right now,
it Net::SMTP::Retryable delegates to Net::SMTP.  In order to
subclass, I'd have to build a few more methods instead of using
the AUTOLOADer and figure out how to handle getting a new
Net::SMTP object on retries.  The former is just a matter of
typing, the later is not so simple.

=head1 DEPENDENCIES

L<Net::SMTP>
L<Time::HiRes>
L<Log::Log4perl> if you have it. Configurable with the Net.SMTP.Retryable logger.

=head1 AUTHOR

Marc Prewitt < mprewitt at the domain flatiron in the dot org tld >

=head1 SEE ALSO

L<Net::SMTP>

=head1 PUBLIC METHODS

=cut
#---------------------------------------------------------------------

$VERSION = '0.0.2';

use strict;
#use warnings;

package Net::SMTP::Retryable;

use Net::SMTP;
use Scalar::Util 'refaddr';
use Time::HiRes;

# We're an inside-out object.  See "Perl Best Practices", Conway.
# These are each object's attributes.

my %mailhosts;
my %retryfactor;
my %sendretries;
my %connectretries;
my %savedcommands;
my %smtp;
my %opts;
my $net_smtp_new;
BEGIN {
    $net_smtp_new = \&Net::SMTP::new;
}

my $LOG;
BEGIN {
    eval {
        use Log::Log4perl;
        $LOG = Log::Log4perl->get_logger(__PACKAGE__);
    };
    $LOG = Net::SMTP::Retryable::SimpleLog->new(Net::SMTP::Retryable::SimpleLog::FATAL()) 
        if length $@;
}

# 
# Create methods for commands we want to be retryable
#
foreach my $method (qw( mail send send_and_mail send_or_mail to cc bcc recipient )) {
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        return $self->cmd_with_retry( $method, @_ );
    }
}

#
# Send the mail with retry/reconnect logic
#
sub data {
    my $self = shift;
    my $smtp = $smtp{refaddr $self};
    my $retry = 0;
    my $result;
    while ( !($result = $smtp->data( @_ )) && $retry++ <= $sendretries{refaddr $self} ) {
        $LOG->warn("error in 'data': " . $smtp->message . " code: " .  $smtp->code);
        $smtp->reset();    # ?? can't be called after data sent
        $smtp->quit();
        $LOG->warn("Reconnecting to mailhost");
        my $error;
        last unless $self->_ReconnectToMailHost();
    };

    $self->_Reset();

    return $result if $result;
    $LOG->warn( $smtp->message );
    return;
}

sub dataend {
    my $self = shift;

    $self->_Reset();

    return $smtp{refaddr $self}->dataend( @_ );
}

#
# _ConnectToMailHost
#
# Attempt to connect to $self->{mailhosts}.  Return
# 1 on success, undef on failure.
#
sub _ConnectToMailHost {
    my $self = shift;

    my $error;

    foreach my $mailhost ( @{ $mailhosts{refaddr $self} } ) {
        my $connects = 1;
        do {
            return 1
              if $smtp{refaddr $self} = $net_smtp_new->( 'Net::SMTP', $mailhost, %{ $opts{refaddr $self} } );
            $error = "SMTP could not connect to $mailhost.";
            $LOG->warn($error);
            Time::HiRes::sleep($retryfactor{refaddr $self} * $connects);
        } while ( $connects++ < $connectretries{refaddr $self} );
    }
    $LOG->warn($error);
    return;
}

#
# _ReConnectToMailHost
#
# Reconnect to the mail host and replay any commands up to the point
# that the connection failed.
#
sub _ReconnectToMailHost {
    my $self = shift;
    $self->_ConnectToMailHost() || return;
    $self->SendMail(%{$savedcommands{refaddr $self}});
}

#
# _Reset()
#
# Removes any saved commands from this object.
#
sub _Reset {
    my $self = shift;

    $savedcommands{refaddr $self} = undef;
    return 1;
}

#
# $smtp->cmd_with_retry($cmd, @args)
#
# Save the arguments for later replay and run the command
# retrying up to $smtp->{opts}->{sendretries}
#
sub cmd_with_retry {
    my $self = shift;
    my $method = shift;

    $savedcommands{refaddr $self}->{$method} = [ @_ ];  # save the args in case we need to retry later

    my $smtp = $smtp{refaddr $self};
    my $result;
    my $connects;

    $LOG->debug( "Calling: $method" );
    while ( !($result = $smtp->$method(@_)) && $connects++ <= $sendretries{refaddr $self} )
    {
        $LOG->warn( "error in '$method' for @_: " . $smtp->message . " code: "
          . $smtp->code );
        $smtp->reset();
        $smtp->quit();

        Time::HiRes::sleep($retryfactor{refaddr $self} * $connects);

        $LOG->warn("Reconnecting to mailhost");
        return undef unless $self->_ReconnectToMailHost();
    }

    if ($result) {
        return $result;
    } else {
        $smtp->reset();
        $smtp->quit();
        $LOG->warn( $smtp->message );
        return; 
    }
}

=head2 SendMail

This is a short-cut method for sending a mail in one command.

    $smtp->SendMail(
            mail=>$from, send=>$from, send_or_mail=>$from, send_and_mail=>$from # FROM methods
            to=>$to, cc=>$cc, bcc=>$bcc, recipient=>$recipient,                 # TO methods
            data=>$data                                                         # BODY
        ) || warn "Mail failed";

Sends an email using the Net::SMTP mail/send/send_or_mail/send_and_mail, 
to/cc/bcc/recipient, data methods.
One B<FROM> and one B<TO> arguments are required.
The values of the arguments can be scalars or array refs.  Use an array ref if you
need to send additional parameters or multiple parameters to the underlying
Net::SMTP method.  

Returns undef if any of the methods fails otherwise returns the return
value of the last method executed.

=cut
sub SendMail {
    my $self = shift;
    my %opts = @_;

    my @ordered_options = qw( mail send send_or_mail send_and_mail to cc bcc recipient data );
    my $return;
    foreach my $method ( @ordered_options ) {
        if (exists $opts{$method}) {
            $return = $self->$method( ref($opts{$method}) eq 'ARRAY' ? @{$opts{$method}} : $opts{$method} ) ||
                return;
        }
    }

    return $return;
}

=head2 get_smtp

    $net_smtp = $net_smtp_retryable->get_smtp();

Returns the underlying smtp object.

=cut
sub get_smtp {
    return $smtp{refaddr $_[0]};
}

#
# Cleanup attributes for the destroyed object to prevent
# memory leaks.
#
sub DESTROY {
    my $self = shift;
    delete $mailhosts{refaddr $self};
    delete $retryfactor{refaddr $self};
    delete $sendretries{refaddr $self};
    delete $connectretries{refaddr $self};
    delete $smtp{refaddr $self};
    delete $opts{refaddr $self};
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return $smtp{refaddr $self}->$method(@_);
}

package Net::SMTP;

use Scalar::Util 'refaddr';

my $LOG;
BEGIN {
    eval {
        use Log::Log4perl;
        $LOG = Log::Log4perl->get_logger(__PACKAGE__);
    };
    $LOG = Net::SMTP::Retryable::SimpleLog->new(Net::SMTP::Retryable::SimpleLog::FATAL()) 
        if length $@;
}


use constant DEFAULT_CONNECT_RETRIES => 0;
use constant DEFAULT_RESEND_RETRIES => 0;
use constant DEFAULT_RETRY_FACTOR => 1;

#---------------------------------------------------------------------

=head2 new

    $smtp = Net::SMTP::Retryable->new( $mailhost, %options );

    $smtp = Net::SMTP::Retryable->new( \@mailhosts, %options );
B<PARAMETERS:> 

    $mailhost - Outgoing SMTP host to connect to or array of hosts
    to connect to

    %options  - Optional parameters:
        connectretries => $number of times to retry a connection (default=0)
        sendretries => $number of times to retry a send attempt (default=0)
        retryfactor => number of seconds to pause between each 
        reconnect attempt.  Number can be less than 1, number
        is doubled on each successive reconnect attempt. (default=1)

B<RETURN VALUES:> Reference to instantiated object.

=cut


sub new {
    my $type     = shift;
    my $mailhost = shift;
    my %opts     = @_;
    my $self     = \do {my $anon_scalar};
    bless $self => 'Net::SMTP::Retryable';

    if ( ref($mailhost) eq 'ARRAY' ) {
        $mailhosts{refaddr $self} = $mailhost;
    }
    elsif ( ref($mailhost) ) {
        $LOG->error("Non array ref reference passed to new as first arg.");
        return;
    }
    else {
        $mailhosts{refaddr $self} = [$mailhost];
    }

    $retryfactor{refaddr $self} = $opts{retryfactor} || DEFAULT_RETRY_FACTOR;
    $sendretries{refaddr $self} = $opts{sendretries} || DEFAULT_RESEND_RETRIES;
    $connectretries{refaddr $self} = $opts{connectretries} || DEFAULT_CONNECT_RETRIES;

    # save the rest of the options to send to Net::SMTP->new
    delete $opts{retryfactor};
    delete $opts{sendretries};
    delete $opts{connectretries};
    $opts{refaddr $self} = \%opts;

    $self->_ConnectToMailHost() || return;

    return $self;
}

#---------------------------------------------------------------------
# A simple logging package that looks/works like log4perl
#
package Net::SMTP::Retryable::SimpleLog;

use constant FATAL => 0;
use constant ERROR => 1;
use constant WARN  => 2;
use constant INFO  => 3;
use constant DEBUG => 4;

my $logger = bless {} => __PACKAGE__;
my $level = FATAL;

sub new {
    my $type = shift;
    $level = shift || $level;
    return $logger;
}

sub fatal {
    return unless $level >= FATAL;
    my $self = shift;
    print STDERR @_, "\n";
}

sub error {
    return unless $level >= ERROR;
    my $self = shift;
    print STDERR @_, "\n";
}

sub warn {
    return unless $level >= WARN;
    my $self = shift;
    print STDERR @_, "\n";
}

sub info {
    return unless $level >= INFO;
    my $self = shift;
    print STDERR @_, "\n";
}

sub debug {
    return unless $level >= DEBUG;
    my $self = shift;
    print STDERR @_, "\n";
}

1;

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

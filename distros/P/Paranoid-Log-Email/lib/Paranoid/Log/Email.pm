# Paranoid::Log::Email -- Log Facility Email for paranoid programs
#
# (c) 2005 - 2015, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Log/Email.pm, 2.00 2016/05/13 19:49:51 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Log::Email;

use strict;
use warnings;
use vars qw($VERSION);
use Paranoid;
use Paranoid::Debug qw(:all);
use Net::SMTP;
use Net::Domain qw(hostfqdn);

($VERSION) = ( q$Revision: 2.00 $ =~ /(\d+(?:\.\d+)+)/sm );

use constant SMTP_DELAY => 30;

my @tlevels = qw(debug informational notice warning critical alert emergency);

#####################################################################
#
# Module code follows
#
#####################################################################

sub init () {

    # Purpose:  Exists purely for compliance.
    # Returns:  Boolean
    # Usage:    init();

    return 1;
}

sub addLogger {

    # Purpose:  Exists purely for compliance.
    # Returns:  Boolean
    # Usage:    startLogger();

    my %record = @_;
    my $rv     = 1;

    # Validate required options
    unless ( exists $record{options}{mailhost} ) {
        Paranoid::ERROR = pdebug( 'failed to declare a mailhost', PDLEVEL1 );
        $rv = 0;
    }
    unless ( exists $record{options}{recipient} ) {
        Paranoid::ERROR = pdebug( 'failed to declare a recipient', PDLEVEL1 );
        $rv = 0;
    }

    return $rv;
}

sub delLogger {

    # Purpose:  Exists purely for compliance.
    # Returns:  Boolean
    # Usage:    stopLogger();

    return 1;
}

sub logMsg {

    # Purpose:  Mails the passed message to the named recipient
    # Returns:  True (1) if successful, False (0) if not
    # Usage:    log($msgtime, $severity, $message, $name, $facility, $level,
    #               $scope);
    # Usage:    log($msgtime, $severity, $message, $name, $facility, $level,
    #               $scope, $mailhost);
    # Usage:    log($msgtime, $severity, $message, $name, $facility, $level,
    #               $scope, $mailhost, $recipient);
    # Usage:    log($msgtime, $severity, $message, $name, $facility, $level,
    #               $scope, $mailhost, $recipient, $sender);
    # Usage:    log($msgtime, $severity, $message, $name, $facility, $level,
    #               $scope, $mailhost, $recipient, $sender, $subject);

    my %record = @_;
    my $rv     = 0;
    my ( $sender, $subject );
    my ( $smtp, $hostname, $data );

    pdebug( 'entering w/%s', PDLEVEL1, %record );
    pIn();

    if ( defined $record{message} ) {

        # Get the system hostname
        $hostname = hostfqdn();

        # Make sure something is set for the sender
        $sender =
            exists $record{options}{sender}
            ? $record{options}{sender}
            : "$ENV{USER}\@$hostname";

        # Make sure something is set for the subject
        $subject =
            exists $record{options}{subject}
            ? $record{options}{subject}
            : "ALERT from $ENV{USER}\@$hostname";

        # Compose the data block
        $data = << "__EOF__";
To:      $record{options}{recipient}
From:    $sender
Subject: $subject

This alert was sent out from $hostname by $ENV{USER} because of a log event which met the $tlevels[$record{severity}] level.  The message of this event is as follows:

$record{message}

__EOF__

        pdebug(
            'sending to %s via %s',
            PDLEVEL2,
            $record{options}{recipient},
            $record{options}{mailhost} );

        # Try to open an SMTP connection
        if ($smtp = Net::SMTP->new(
                $record{options}{mailhost},
                Timeout => SMTP_DELAY
            )
            ) {

            # Start the transaction
            if ( $smtp->mail($sender) ) {

                # Send to recipient
                Paranoid::ERROR = pdebug( 'server rejected recipient: %s',
                    PDLEVEL1, $record{options}{recipient} )
                    unless $smtp->to( $record{options}{recipient} );

                # Send the message
                $rv = $smtp->data($data);

                # Log the error
            } else {
                Paranoid::ERROR =
                    pdebug( 'server rejected sender: %s', PDLEVEL1, $sender );
                $rv = 0;
            }

            # Close the connection
            $smtp->quit;

        } else {

            # Failed to connect to the server!
            Paranoid::ERROR = pdebug( 'couldn\'t connect to server : %s',
                PDLEVEL1, $record{options}{mailhost} );
            $rv = 0;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::Log::Email - Log Facility Email

=head1 VERSION

$Id: lib/Paranoid/Log/Email.pm, 2.00 2016/05/13 19:49:51 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Log;
  
  startLogger('crit-msg', 'Email', PL_CRIT, PL_GE, 
    { mailhost  => $mailhost, recipient => $recipient,
      sender    => $sender,   subject   => $subject });

=head1 DESCRIPTION

This module implements an e-mail transport for messages sent to the logger.
It supports one or more recipients as well as overriding the sender address
and subject line.  It also supports connecting to a remote mail server.

B<mailhost> and B<recipient> are the only mandatory options.

=head1 OPTIONS

The options recognized for use in the options hash are as follows:

    Option      Value       Description
    -----------------------------------------------------
    mailhost    string      Hostname of mail server
    recipient   string      E-mail address of recipient
    sender      string      E-mail address of sender
    subject     string      Subject line to use

=head1 SUBROUTINES/METHODS

B<NOTE>:  Given that this module is not intended to be used directly nothing
is exported.

=head2 init

=head2 addLogger

=head2 delLogger

=head2 logMsg

=head1 DEPENDENCIES

=over

=item o

L<Net::SMTP>

=item o

L<Net::Domain>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=back

=head1 SEE ALSO

=over

=item o

L<Paranoid::Log>

=back

=head1 BUGS AND LIMITATIONS

No format checking is done for any of the mail options.  The mandatory options
are checked only for existence upon addition of a new logger.

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2015, Arthur Corliss (corliss@digitalmages.com)


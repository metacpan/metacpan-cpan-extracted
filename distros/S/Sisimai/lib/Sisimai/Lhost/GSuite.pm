package Sisimai::Lhost::GSuite;
use parent 'Sisimai::Lhost';
use v5.26;
use strict;
use warnings;

sub description { 'Google Workspace: https://workspace.google.com/' }
sub inquire {
    # Detect an error from Google Workspace (Transfer from the Google Workspace to the destination host)
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [undef]         failed to decode or the arguments are missing
    # @since v4.21.0
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless rindex($mhead->{'from'}, '<mailer-daemon@googlemail.com>') > -1;
    return undef unless index($mhead->{'subject'}, 'Delivery Status Notification') > -1;
    return undef unless $mhead->{'x-gm-message-state'};

    state $indicators = __PACKAGE__->INDICATORS;
    state $boundaries = ['Content-Type: message/rfc822', 'Content-Type: text/rfc822-headers'];
    state $markingsof = {
        'message' => ['** '],
        'error'   => ['The response was:', 'The response from the remote server was:'],
    };
    state $messagesof = {
        'userunknown'  => ["because the address couldn't be found. Check for typos or unnecessary spaces and try again."],
        'notaccept'    => ['Null MX'],
        'networkerror' => [' had no relevant answers.', ' responded with code NXDOMAIN'],
    };

    my $fieldtable = Sisimai::RFC1894->FIELDTABLE;
    my $permessage = {};    # (Hash) Store values of each Per-Message field
    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailparts = Sisimai::RFC5322->part($mbody, $boundaries);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $endoferror = 0;     # (Integer) Flag for a blank line after error messages
    my $emptylines = 0;     # (Integer) The number of empty lines
    my $anotherset = {      # (Hash) Another error information
        'diagnosis' => '',
    };
    my $v = undef;

    for my $e ( split("\n", $emailparts->[0]) ) {
        # Read error messages and delivery status lines from the head of the email to the previous
        # line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if grep { index($e, $_) == 0 } $markingsof->{'message'}->@*;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};

        if( my $f = Sisimai::RFC1894->match($e) ) {
            # $e matched with any field defined in RFC3464
            next unless my $o = Sisimai::RFC1894->field($e);
            $v = $dscontents->[-1];

            if( $o->[-1] eq 'addr' ) {
                # Final-Recipient: rfc822; kijitora@example.jp
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                if( $o->[0] eq 'final-recipient' ) {
                    # Final-Recipient: rfc822; kijitora@example.jp
                    if( $v->{'recipient'} ) {
                        # There are multiple recipient addresses in the message body.
                        push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                        $v = $dscontents->[-1];
                    }
                    $v->{'recipient'} = $o->[2];
                    $recipients++;

                } else {
                    # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                    $v->{'alias'} = $o->[2];
                }
            } elsif( $o->[-1] eq 'code' ) {
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                $v->{'spec'} = $o->[1];
                $v->{'diagnosis'} = $o->[2];

            } else {
                # Other DSN fields defined in RFC3464
                next unless exists $fieldtable->{ $o->[0] };
                $v->{ $fieldtable->{ $o->[0] } } = $o->[2];

                if( $fieldtable->{ $o->[0] } eq 'lhost' ) {
                    # Do not set an email address as a hostname in "lhost" value
                    $v->{'lhost'} = '' if index($v->{'lhost'}, '@');
                }

                next unless $f == 1;
                $permessage->{ $fieldtable->{ $o->[0] } } = $o->[2];
            }
        } else {
            # The line does not begin with a DSN field defined in RFC3464
            if( ! $endoferror && $v->{'diagnosis'} ) {
                # Append error messages continued from the previous line
                $endoferror ||= 1 if $e eq '';
                next if $endoferror;
                $v->{'diagnosis'} .= $e;

            } elsif( grep { index($e, $_) == 0 } $markingsof->{'error'}->@* ) {
                # The response from the remote server was:
                $anotherset->{'diagnosis'} .= ' '.$e;

            } else {
                # ** Address not found **
                #
                # Your message wasn't delivered to * because the address couldn't be found.
                # Check for typos or unnecessary spaces and try again.
                #
                # The response from the remote server was:
                # 550 #5.1.0 Address rejected.
                next if index($e, 'Content-Type:') == 0;
                if( $anotherset->{'diagnosis'} ) {
                    # Continued error messages from the previous line like "550 #5.1.0 Address rejected."
                    next if $emptylines > 5;
                    unless( length $e ) {
                        # Count and next()
                        $emptylines += 1;
                        next;
                    }
                    $anotherset->{'diagnosis'} .= ' '.$e

                } else {
                    # ** Address not found **
                    #
                    # Your message wasn't delivered to * because the address couldn't be found.
                    # Check for typos or unnecessary spaces and try again.
                    next unless grep { index($e, $_) == 0 } $markingsof->{'message'}->@*;
                    $anotherset->{'diagnosis'} = $e;
                }
            }
        } # End of message/delivery-status
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{ $_ } ||= $permessage->{ $_ } || '' for keys %$permessage;

        if( exists $anotherset->{'diagnosis'} && $anotherset->{'diagnosis'} ) {
            # Copy alternative error message
            $e->{'diagnosis'} ||= $anotherset->{'diagnosis'};
            if( index($e->{'diagnosis'}, ' ') < 0 && int($e->{'diagnosis'}) > 0 ) {
                # Override the value of diagnostic code message
                $e->{'diagnosis'} = $anotherset->{'diagnosis'};

            } else {
                # More detailed error message is in "$anotherset"
                my $as = undef; # status
                my $ar = undef; # replycode

                if( $e->{'status'} eq '' || $e->{'status'} eq '5.0.0' || $e->{'status'} eq '4.0.0' ) {
                    # Check the value of D.S.N. in $anotherset
                    $as = Sisimai::SMTP::Status->find($anotherset->{'diagnosis'}) || '';
                    if( length($as) > 0 && substr($as, -4, 4) ne '.0.0' ) {
                        # The D.S.N. is neither an empty nor *.0.0
                        $e->{'status'} = $as;
                    }
                }

                if( $e->{'replycode'} eq '' || $e->{'replycode'} eq '500' || $e->{'replycode'} eq '400' ) {
                    # Check the value of SMTP reply code in $anotherset
                    $ar = Sisimai::SMTP::Reply->find($anotherset->{'diagnosis'}) || '';
                    if( length($ar) > 0 && substr($ar, -2, 2) ne '00' ) {
                        # The SMTP reply code is neither an empty nor *00
                        $e->{'replycode'} = $ar;
                    }
                }

                if( $as || $ar && ( length($anotherset->{'diagnosis'}) > length($e->{'diagnosis'}) ) ) {
                    # Update the error message in $e->{'diagnosis'}
                    $e->{'diagnosis'} = $anotherset->{'diagnosis'};
                }
            }
        }
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});

        for my $q ( keys %$messagesof ) {
            # Guess an reason of the bounce
            next unless grep { index($e->{'diagnosis'}, $_) > -1 } $messagesof->{ $q }->@*;
            $e->{'reason'} = $q;
            last;
        }
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailparts->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::GSuite - bounce mail decoder class for Google Workspace L<https://workspace.google.com/>

=head1 SYNOPSIS

    use Sisimai::Lhost::GSuite;

=head1 DESCRIPTION

C<Sisimai::Lhost::GSuite> decodes a bounce email which created by Google Workspace L<https://workspace.google.com/>.
Methods in the module are called from only C<Sisimai::Message>.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::GSuite->description;

=head2 C<B<inquire(I<header data>, I<reference to body string>)>>

C<inquire()> method decodes a bounced email and return results as a array reference.
See C<Sisimai::Message> for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2017-2024 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut


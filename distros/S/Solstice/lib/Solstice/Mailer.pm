package Solstice::Mailer;


# $Id: $

=head1 NAME

Solstice::Mailer - Manage a queue of Solstice::Emails

=head1 SYNOPSIS

  use Solstice::Mailer;

  my $mailer = Solstice::Mailer->new();

  $mailer->enqueue($solstice_email);

  #or, for efficient and fair handling of large mailings:
  $mailer->enqueueList($solstice_list_object_full_of_solstice_emails);

  #to send the email queued up, probably done via a cron script
  $mailer->runQueue();

  #also, as a convienience, you may call "enqueue" on a Solstice::Email object.
  #This is equivalent to creating a mailer and adding the email yourself
  $solstice_email->enqueue();

=head1 DESCRIPTION

The mailer manages a queue of emails.  When runQueue is called emails are 
sent to the SMTP server specified in the solstice_config.xml, throttled by 
the mail send delay specified in solstice_config.xml.

=cut

use 5.006_000;
use strict;
use warnings;

use Solstice::Configure;
use Solstice::DateTime;
use Solstice::Database;
use Digest::MD5;
use Mail::Sender;

use Time::HiRes qw( sleep );

use constant TRUE   => 1;
use constant FALSE  => 0;

use constant MAX_EMAILS_WITHOUT_RECHECK => 100;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Constructs a new Solstice::Mailer.

=cut

sub new {
    my $obj = shift;
    my $self = bless {}, ref $obj || $obj;

    my $config = Solstice::Configure->new();

    $self->{_default_smtp} = $config->getSMTPServer();
    $self->{_mailname} = $config->getSMTPMailname();

    return $self;
}

sub enqueue {
    my $self = shift;
    my $mail = shift;

    return FALSE unless $mail;

    if(Solstice::Configure->new()->getSMTPUseQueue() eq 'never'){
        return $mail->send();
    }

    my @values = $self->_getMailValues($mail) or return FALSE;

    return $self->_writeToQueue(\@values, '(?,?,?,?,?,?,?,?,?)');
}

sub enqueueList {
    my $self = shift;
    my $list = shift;

    return unless $list;

    if(Solstice::Configure->new()->getSMTPUseQueue() eq 'never'){
        my $iterator = $list->iterator;
        while( my $mail = $iterator->next() ){
            $mail->send();
        }
        return TRUE;
    }

    my $batch_id = $self->_getBatchID();

    my @values;
    my @placeholders;
    my $iterator = $list->iterator;
    while( my $mail = $iterator->next() ){
        push @values, $self->_getMailValues($mail, $batch_id) or return FALSE;
        push @placeholders, '(?,?,?,?,?,?,?,?,?)';
    }
    my $placeholder_string = join(',', @placeholders);

    return $self->_writeToQueue(\@values, $placeholder_string);
}


sub runQueue {
    my $self = shift;

    my $db = Solstice::Database->new();
    my $db_name = Solstice::Configure->new()->getDBName();
    my $delay = Solstice::Configure->new()->getSMTPMessageWait();

    while (my $message_ids = $self->_getMessagesToSend()){

        my @values;
        my @placeholders;
        for my $message_id (@$message_ids){
            push @values, $message_id;
            push @placeholders, '?';
        }
        my $placeholder = join (',', @placeholders);

        $db->readQuery("SELECT * FROM $db_name.MailQueue WHERE message_id IN($placeholder)", @values);

        my $log_service = Solstice::LogService->new();

        my $sender = Mail::Sender->new({
                keepconnection  => TRUE,
                smtp            => $self->getSMTPServer(), 
                client          => $self->getMailName(),
            });

        die 'Couldn\'t open SMTP connection: '. $Mail::Sender::Error."\n" if ! ref $sender;


        while( my $row = $db->fetchRow() ){

            my $error = '';
            
            #do not try to send email if we do not know where it is going
            next unless $row->{'recipient'};

            $sender->OpenMultipart({
                    to          => $row->{'recipient'},
                    from        => $row->{'sender'},
                    cc          => $row->{'cc'},
                    bcc         => $row->{'bcc'},
                    subject     => $row->{'subject'},
                    multipart   => 'mixed',
                });
            $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};

            $sender->Part({
                    ctype       => 'multipart/alternative'
                });
            $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};

            $sender->Part({
                    ctype       => 'text/plain', 
                    disposition => 'NONE', 
                    msg         => $row->{'text_body'}."\n"
                });
            $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};

            if($row->{'html_body'}){
                $sender->Part({
                        ctype       => 'text/html', 
                        disposition => 'NONE', 
                        msg         => $row->{'html_body'}."\n"
                    });
                $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};

            }
            $sender->EndPart("multipart/alternative");
            $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};

            $sender->Close();
            $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};


            warn "Mailing from queue failed: $error\n" if $error;

            my $content;
            if($error){
                $content = 'To: '.$row->{'recipient'}. ', CC: '.$row->{'cc'}.', BCC: '.$row->{'bcc'}.', From: '.$row->{'sender'}.", FAIL: $error";
            }else{
                $content = 'To: '.$row->{'recipient'}. ', CC: '.$row->{'cc'}.', BCC: '.$row->{'bcc'}.', From: '.$row->{'sender'}.", SUCCESS";
            }

            Solstice::LogService->new()->log({
                    log_file    => 'queue_mail_log',
                    content     => $content,
                    username    => '-',
                    model_id    => $row->{'unique_id'}
                });

            #now using Time::HiRes to sleep for a possibly non-integer ammount of time
            sleep($delay);
        }
        $sender->Close(TRUE);

        $db->writeQuery("DELETE FROM $db_name.MailQueue WHERE message_id IN($placeholder)", @values);
    }
    return TRUE;
}

sub _getMessagesToSend {
    my $self = shift;

    my $db = Solstice::Database->new();
    my $db_name = Solstice::Configure->new()->getDBName();

    #select all the message id and batch info 
    $db->readQuery("SELECT message_id, batch_id FROM $db_name.MailQueue");

    return FALSE unless $db->rowCount();

    my %batches;
    while( my $row = $db->fetchRow() ){
        push @{$batches{$row->{'batch_id'}}}, $row->{'message_id'};
    }

    #take one message from each queue or the configured minimum if
    #there are fewer queues than that
    my @messages;
    my $count = 0;
    while( $count < MAX_EMAILS_WITHOUT_RECHECK  ){

        for my $batch_id (keys %batches){
            if(@{$batches{$batch_id}}){
                push @messages, shift @{$batches{$batch_id}};
                delete $batches{$batch_id} unless scalar @{$batches{$batch_id}};
                $count ++;
            }
        }
        last unless scalar(keys(%batches));
    }
    return \@messages;
}


sub _getMailValues {
    my $self = shift;
    my $mail = shift;
    my $batch_id = shift;

    # Start by getting the content we want to send...
    my $from        = $mail->getFrom();
    my @to          = $mail->getTo();
    my @cc          = $mail->getCC();
    my @bcc         = $mail->getBCC();
    my $subject     = $mail->getSubject();
    my $text_body   = $mail->getPlainTextBody();
    my $html_body   = $mail->getHTMLBody();
    my $msg_id      = $mail->getMessageID();

    if ($#to < 0 and $#cc < 0 and $#bcc < 0) {
        return FALSE;
    }

    #cleanup data to prevent accidental/deliberate header overruns
    for my $value (@to, @cc, @bcc, $from, $subject){
        $value =~ s/\n//g;
    }


    my $to = join(', ', @to);
    my $cc = join(', ', @cc);
    my $bcc = join(', ', @bcc);

    $batch_id = $self->_getBatchID() unless $batch_id; #if we're passed one, use it

    return ($batch_id, $to, $cc, $bcc, $subject, $text_body, $html_body, $from, $msg_id);
}

sub _writeToQueue {
    my $self = shift;
    my $values_ref = shift;
    my $placeholder_string = shift;

    my $db = Solstice::Database->new();
    my $db_name = Solstice::Configure->new()->getDBName();

    $db->writeQuery("INSERT INTO $db_name.MailQueue 
        (batch_id, recipient, cc, bcc, subject, text_body, html_body, sender, unique_id) values $placeholder_string",
        @$values_ref
    );

    return TRUE;
}

sub _getBatchID {
    return Digest::MD5::md5_hex( time().{}.rand().$$ );
}


=item getMailName()

Returns the smtp server we will be using.

=cut

sub getMailName {
    my $self = shift;
    return $self->{'_mailname'};
}

=item getSMTPServer()

Returns the smtp server we will be using.

=cut

sub getSMTPServer {
    my $self = shift;
    return $self->{_smtp_server} || $self->{_default_smtp};
}

1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $

=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut

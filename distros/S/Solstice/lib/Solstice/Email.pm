package Solstice::Email;

# $Id: Email.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::Email - Send email with a resonable amount of ease.

=head1 SYNOPSIS

  use Solstice::Email;

  my $mailer = Solstice::Email->new();

  $mailer->from('From Address <sender@example.com>');
  $mailer->to(@email_addresses);
  $mailer->cc(@email_addresses);
  $mailer->bcc(@email_addresses);

  $mailer->subject('Subject!');

  $mailer->plainTextBody('Plain text version');
  $mailer->htmlBody('<b>HTML version!</b>');

  # This will make it so an image can be embedded in the HTML.
  # To reference the image in the HTML, use the something like the 
  # following:
  # <img src="cid:happy_user.png" />
  $mailer->attachMedia( content_type => 'image/png',
                        id           => 'happy_user.png',
                        path         => '/path/to/happy_user.png',
                        );

  $mailer->send();

  # For internal use, and perhaps some testing...
  my $server  = $mailer->getSMTPServer();
  my $from    = $mailer->getFrom();
  my @to      = $mailer->getTo();
  my @cc      = $mailer->getCC();
  my @bcc     = $mailer->getBCC();
  my $subject = $mailer->getSubject();
  my $text    = $mailer->getPlainTextBody();
  my $html    = $mailer->getHTMLBody();
  my @media   = $mailer->getAttachedMedia();

=head1 DESCRIPTION

This module was designed to make it easy to send HTML email, in a way that older mail clients would be able to read.  It is designed to supercede the old Email module, which seems like it was written at a point when people still needed convincing that object encapsulation was a good idea. 

=cut

use 5.006_000;
use strict;
use warnings;

use Solstice::Configure;
use Solstice::DateTime;
use Solstice::Mailer;
use Solstice::LogService;

use Mail::Sender;

use constant TRUE   => 1;
use constant FALSE  => 0;

use constant NET_SMTP => '/Net/SMTP.pm';

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Constructs a new Solstice::Email.

=cut

sub new {
    my $obj = shift;
    my $self = bless {}, ref $obj || $obj;

    $self->{'_message_id'} = Digest::MD5::md5_hex(rand().$$.time);

    return $self;
}

sub getMessageID {
    my $self = shift;
    return $self->{'_message_id'};
}

=item getMailName()

Returns the smtp server we will be using.

=cut

sub getMailName {
    my $self = shift;
    return Solstice::Configure->new()->getSMTPMailname();
}

=item getSMTPServer()

Returns the smtp server we will be using.

=cut

sub getSMTPServer {
    my $self = shift;
    return Solstice::Configure->new()->getSMTPServer();
}

=item from('from address')

Set the sender.

=cut

sub from {
    my $self = shift;
    $self->{_from} = shift;
}

=item getFrom()

Returns the sender.

=cut

sub getFrom {
    my $self = shift;
    return $self->{_from} || '';
}

=item to(@addresses)

Set an array of recipients.

=cut

sub to {
    my $self = shift;
    $self->{_to} = \@_;
}

=item getTo()

Returns an array of address.

=cut

sub getTo {
    my $self = shift;
    if (defined $self->{_to}) {
        return @{$self->{_to}};
    }
    return ();
}

=item cc(@addresses)

Set an array of recipients.

=cut

sub cc {
    my $self = shift;
    $self->{_cc} = \@_;
}

=item getCC()

Returns an array of addresses.

=cut

sub getCC {
    my $self = shift;
    if (defined $self->{_cc}) {
        return @{$self->{_cc}};
    }
    return ();
}

=item bcc(@addresses)

Set an array of recipients.

=cut

sub bcc {
    my $self = shift;
    $self->{_bcc} = \@_;
}

=item getBCC()

Returns an array of addresses.

=cut

sub getBCC {
    my $self = shift;
    if (defined $self->{_bcc}) {
        return @{$self->{_bcc}};
    }
    return ();
}

=item subject('subject')

Subject of the email.

=cut

sub subject {
    my $self = shift;
    $self->{_subject} = shift;
}

=item getSubject()

Returns the subject of the email.

=cut

sub getSubject {
    my $self = shift;
    return $self->{_subject} || '';
}

=item plainTextBody('text')

A version of the email for older clients.

=cut

sub plainTextBody {
    my $self = shift;
    $self->{_plain_text_body} = shift;
}

=item getPlainTextBody()

Returns the plain text version of the message.

=cut

sub getPlainTextBody {
    my $self = shift;
    return $self->{_plain_text_body} || '';
}

=item htmlBody('html')

A version of the email for shiny new clients.

=cut

sub htmlBody {
    my $self = shift;
    $self->{_html_body} = shift;
}

=item getHTMLBody()

Returns the HTML version of the message.

=cut

sub getHTMLBody {
    my $self = shift;
    return $self->{_html_body};
}

=item attachMedia( content_type => 'image/type',
                   id           => 'file_name.img',
                   path         => '/path/to/file_name.img',
                 )

Add an image to the email.

=cut

sub attachMedia {
    my $self = shift;
    my %input = @_;

    warn "Attached media is not currently sent in email!!!";

    if (!defined $self->{_attached_media}) {
        $self->{_attached_media} = [];
    }
    push @{$self->{_attached_media}}, { 
        content_type => $input{content_type},
        id => $input{id},
        path => $input{path},
    };
}

=item getAttachedMedia()

Returns an array of all media attached to this message.

=cut

sub getAttachedMedia {
    my $self = shift;
    if (defined $self->{_attached_media}) {
        return @{$self->{_attached_media}};
    }
    return ();
}

=item enqueue

Places the mail in the mail queue

=cut

sub enqueue {
    my $self = shift;

    my $mailer = Solstice::Mailer->new();
    return $mailer->enqueue($self);
}

=item send()

Sends off the email.

=cut

sub send {
    my $self = shift;

    if(Solstice::Configure->new()->getSMTPUseQueue() eq 'always'){
        my $mailer = Solstice::Mailer->new();
        return $mailer->enqueue($self);
    }

    # Start by getting the content we want to send...
    my $from        = $self->getFrom();
    my @to          = $self->getTo();
    my @cc          = $self->getCC();
    my @bcc         = $self->getBCC();
    my $subject     = $self->getSubject();
    my $text_body   = $self->getPlainTextBody();
    my $html_body   = $self->getHTMLBody();

    if ($#to < 0 and $#cc < 0 and $#bcc < 0) {
        return FALSE;
    }

    #cleanup data to prevent accidental/deliberate header overruns
    for my $value (@to, @cc, @bcc, $from, $subject){
        $value =~ s/[\n\r]//g; 
    }

    my $error = '';

    my $sender = Mail::Sender->new({
            smtp => $self->getSMTPServer(), 
            client => $self->getMailName(),
        });

    die 'Couldn\'t open SMTP connection: '. $Mail::Sender::Error."\n" if ! ref $sender;

    $sender->OpenMultipart({
            to          => \@to,
            from        => $from,
            cc          => \@cc,
            bcc         => \@bcc,
            subject     => $subject,
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
            msg         => $text_body."\n"
        });
    $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};

    if($html_body){
        $sender->Part({
                ctype       => 'text/html', 
                disposition => 'NONE', 
                msg         => $html_body."\n"
            });
        $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};
    }

    $sender->EndPart("multipart/alternative");
    $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};

    $sender->Close();
    $error .= $Mail::Sender::Error. ' ' if $sender->{'error'};

    warn 'Mailing failed from '. join(' ', caller()). ": $error\n" if $error;

    my $to = join(', ', @to);
    my $cc = join(', ', @cc);
    my $bcc = join(', ', @bcc);

    my $content;
    if($error){
        $content = "To: $to, CC: $cc, BCC: $bcc, From: $from, FAIL: $error";
    }else{
        $content = "To: $to, CC: $cc, BCC: $bcc, From: $from, SUCCESS";
    }

    Solstice::LogService->new()->log({
            log_file    => 'direct_mail_log',
            content     => $content,
            username    => '-',
            model_id    => $self->getMessageID(),
        });

    return TRUE;
}



#    # Prep our SMTP object...
#
#    # I don't know why this format works, but the original (see below) returns 
#    # an undef object... I'm guessing in some version change they changed what
#    # they considered to be valid constructors, and didn't bother to warn when 
#    # you used an older method?
#    my $smtp = Net::SMTP->new($self->getSMTPServer(), Hello => $self->getMailName());
#    #XXX: Here's the original version...We should investigate further
#    #my $smtp = Net::SMTP->new(Host => $self->getSMTPServer(), Hello => $self->getMailName());
#
#
#    if($smtp){
#        $smtp->mail($from);
#
#        # We have these so that mail clients will do a more pleasant display of 
#        # the names/addresses of everyone involved.
#        #
#        # Net::SMTP doesn't send to, from, cc or bcc headers, which in addition to 
#        # making things look bad, makes us more likely to be marked as spam.
#        my ($to_string, $cc_string, $bcc_string);
#        if ($#to >= 0) {
#            $smtp->to(@to);
#            $to_string = join(',', @to);
#        }
#        if ($#cc >= 0) {
#            $smtp->cc(@cc);
#            $cc_string = join(',', @cc);
#        }
#        if ($#bcc >= 0) { 
#            $smtp->bcc(@bcc);
#            $bcc_string = join(',', @bcc);
#        }
#
#        $smtp->data();
#        $smtp->datasend("From: $from\n");
#        if (defined $to_string) {
#            $smtp->datasend("To: $to_string\n");
#        }
#        if (defined $cc_string) {
#            $smtp->datasend("CC: $cc_string\n");
#        }
#        if (defined $bcc_string) {
#            $smtp->datasend("BCC: $bcc_string\n");
#        }
#    
#        $smtp->datasend("Subject: $subject\n");
#        $smtp->datasend($body);
#        $smtp->dataend();
#
#    }else{
#        warn "Unable to create SMTP connection!  Please check your SMTP settings in solstice_config.xml\n";
#    }
#
#
#    return TRUE;
#}

1;
__END__

=back

=head2 Modules Used

L<Solstice::Configure|Solstice::Configure>,
L<MIME::Lite|MIME::Lite>,
L<Net::SMTP|Net::SMTP>.

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

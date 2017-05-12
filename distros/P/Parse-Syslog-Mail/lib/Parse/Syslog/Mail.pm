package Parse::Syslog::Mail;
use strict;
use warnings;
use Carp;
use Parse::Syslog;

{
    no strict;
    $VERSION = '0.17';
}

=head1 NAME

Parse::Syslog::Mail - Parse mailer logs from syslog

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

    use Parse::Syslog::Mail;

    my $maillog = Parse::Syslog::Mail->new('/var/log/syslog');
    
    while(my $log = $maillog->next) {
	# do something with $log
        # ...
    }

=head1 DESCRIPTION

As its names implies, C<Parse::Syslog::Mail> presents a simple interface 
to gather mail information from a syslog file. It uses C<Parse::Syslog> for 
reading the syslog, and offer the same simple interface. Currently supported 
log formats are: Sendmail, Postfix, Qmail.


=head1 METHODS

=over 4

=item B<new()>

Creates and returns a new C<Parse::Syslog::Mail> object. 
A file path or a C<File::Tail> object is expected as first argument. 
Options can follow as a hash. Most are the same as for C<< Parse::Syslog->new() >>. 

B<Options>

=over 4

=item *

C<type> - Format of the syslog stream. Can be one of C<"syslog"> (traditional
syslog format) or C<"metalog"> (Metalog format).

=item *

C<year> - Syslog files usually do store the time of the event without 
year. With this option you can specify the start-year of this log. If 
not specified, it will be set to the current year.

=item *

C<GMT> - If this option is set, the time in the syslog will be converted 
assuming it is GMT time instead of local time.

=item *

C<repeat> - C<Parse::Syslog> will by default repeat xx times events that 
are followed by messages like C<"last message repeated xx times">. If you 
set this option to false, it won't do that.

=item *

C<locale> - Specifies an additional locale name or the array of locale 
names for the parsing of log files with national characters.

=item *

C<allow_future> - If true will allow for timestamps in the future. 
Otherwise timestamps of one day in the future and more will not be returned 
(as a safety measure against wrong configurations, bogus C<year> arguments, 
etc.)

=back

B<Example>

    my $syslog = new Parse::Syslog::Mail '/var/log/syslog', allow_future => 1;

=cut

sub new {
    my $self = {
        syslog => undef, 
    };
    my $class = ref $_[0] ? ref shift : shift;
    bless $self, $class;

    my $file = shift;
    my %args = @_;

    croak "fatal: Expected an argument" unless defined $file;

    $self->{syslog} = eval { Parse::Syslog->new($file, %args) } or do {
        $@ =~ s/ at .*$//;
        croak "fatal: Can't create new Parse::Syslog object: $@";
    };

    return $self
}

=item B<next()>

Returns the next line of the syslog as a hashref, or C<undef> when there 
is no more lines. The hashref contains at least the following keys: 

=over 4

=item *

C<host> - hostname of the machine.

=item *

C<program> - name of the program. 

=item *

C<timestamp> - Unix timestamp for the event.

=item *

C<id> - Local transient mail identifier. 

=item *

C<text> - text description.

=back

Other available keys:

=over 4

=item *

C<from> - Email address of the sender.

=item *

C<to> - Email addresses of the recipients, coma-separated.

=item *

C<msgid> - Message ID.

=item *

C<relay> - MTA host used for relaying the mail.

=item *

C<status> - Status of the transaction.

=item *

C<delivery_type> - I<(Qmail only)> type of the delivery: C<"local"> or C<"remote">.

=item *

C<delivery_id> - I<(Qmail only)> id number of the delivery.

=back

B<Example>

    while(my $log = $syslog->next) {
        # do something with $log
    }

=cut

sub next {
    my $self = shift;
    my %mail = ();
    my @fields = qw(host program timestamp text);
    my %delivery2id = ();  # used to map delivery id with msg id (Qmail)

    LINE: {
        my $log = $self->{syslog}->next;
        return undef unless defined $log;
        @mail{@fields} = @$log{@fields};
        my $text = $log->{text};

        # Sendmail & Postfix format parsing ------------------------------------
        if ($log->{program} =~ /^(?:sendmail|sm-mta|postfix)/) {
            redo LINE if $text =~ /^(?:NOQUEUE|STARTTLS|TLS:)/;
            redo LINE if $text =~ /prescan: (?:token too long|too many tokens|null leading token) *$/;
            redo LINE if $text =~ /possible SMTP attack/;

            $text =~ s/^(\w+): *// and my $id = $1;         # gather the MTA transient id
            redo LINE unless $id;

            redo LINE if $text =~ /^\s*(?:[<-]--|[Mm]ilter|SYSERR)/;   # we don't treat these

            $text =~ s/^(\w+): *clone:/clone=$1/;           # handle clone messages
            $text =~ s/stat=/status=/;                      # renaming 'stat' field to 'status'
            $text =~ s/message-id=/msgid=/;                 # renaming 'message-id' field to 'msgid' (Postfix)
            $text =~ s/^\s*([^=]+)\s*$/status=$1/;          # format other status messages

            # format other status messages (2)
            if ($text =~ s/^\s*([^=]+)\s*;\s*/status=$1, /) {
                $text =~ s/(\S+)\s+([\w-]+)=/$1, $2=/g;
            }

            $text =~ s/collect: /collect=/;                 # treat collect messages as field identifiers
            $text =~ s/(\S+),\s+([\w-]+)=/$1\t$2=/g;        # replace fields seperator with tab character

            %mail = (%mail, map {
                    s/,$//;  s/^ +//;  s/ +$//; # cleaning spaces
                    s/^\s+([\w-]+=)/$1/;        # cleaning up field names
                    split /=/, $_, 2            # no more than 2 elements
                 } split /\t/, $text);

            if (exists $mail{ruleset} and exists $mail{arg1}) {
                $mail{ruleset} eq 'check_mail'  and $mail{from}  = $mail{arg1};
                $mail{ruleset} eq 'check_rcpt'  and $mail{to}    = $mail{arg1};
                $mail{ruleset} eq 'check_relay' and $mail{relay} = $mail{arg1};

                unless (exists $mail{status}) {
                    $mail{reject}     and $mail{status} = "reject: $mail{reject}";
                    $mail{quarantine} and $mail{status} = "quarantine: $mail{quarantine}";
                }
            }

            $mail{id} = $id;

        # Courier ESMTP -------------------------------------------------------
        } elsif ($log->{program} =~ /^courier/) {
            redo LINE if $text =~ /^(?:NOQUEUE|STARTTLS|TLS:)/;

            $text =~ s/,status: /,status=/;     # treat status as a field
            $text =~ s/,(\w+)=/\t$1=/g;         # replace fields separator with tab character

            %mail = (%mail, map { split /=/, $_, 2 } split /\t/, $text);

        # Qmail format parsing -------------------------------------------------
        } elsif ($log->{program} =~ /^qmail/) {
            $text =~ s/^(\d+\.\d+) // and $mail{qmail_timestamp} = $1;   # Qmail timestamp
            # use Time::TAI64 to parse that timestamp?
            redo LINE if $text =~ /^(?:status|bounce|warning)/;

            # record 'new' and 'end' events in the status
            $text =~ s/^(new|end) msg (\d+)$// 
                and $mail{status} = "$1 message" and $mail{id} = $2 and last;

            # record 'triple bounce' events in the status
            $text =~ s/^(triple bounce: discarding bounce)\/(\d+)$// 
                and $mail{status} = $1 and $mail{id} = $2 and last;

            # mail id and its size
            $text =~ s/^info msg (\d+): bytes (\d+) from (<[^>]*>) // 
                and $mail{id} = $1 and $mail{size} = $2 and $mail{from} = $3;
            
            # begining of the delivery
            $text =~ s/^(starting delivery (\d+)): msg (\d+) to (local|remote) (.+)$// 
                and $mail{status} = $1 and $mail{id} = $3 and $delivery2id{$2} = $3 
                and $mail{delivery_id} = $2 and $mail{delivery_type} = $4 and $mail{to} = $5;

            $text =~ s/^delivery (\d+): +// 
                and $mail{delivery_id} = $1 and $mail{id} = $delivery2id{$1} || '';
            
            # status of the delivery
            $text =~ s/^(success|deferral|failure): +(\S+)// 
                and $mail{status} = "$1: $2" and $mail{status} =~ tr/_/ /;

            # in case of missing MTA transient id, generate one
            $mail{id} ||= 'psm' . time;

        # Exim format parsing --------------------------------------------------
        } elsif ($log->{program} =~ /^exim/) {
            # format seems to be DATE TIME TID DIR ADDRESS ?
            # where DIR is
            #   => for outgoing email, recipient follows in <>
            #   <= for incoming email
            #   == for informational message
            #   s= for ???
            # 
            # possible errors/warnings:
            #   cancelled by system filter:

        } else {
            redo LINE
        }
    }

    return \%mail
}

=back


=head1 DIAGNOSTICS

=over 4

=item C<Can't create new %s object: %s>

B<(F)> Occurs in C<new()>. As the message says, we were unable to create 
a new object of the given class. The rest of the error may give more information. 

=item C<Expected an argument>

B<(F)> You tried to call C<new()> with no argument. 

=back

=head1 SEE ALSO

L<Parse::Syslog>

I<Inspecter /var/log/mail.log avec Parse::Syslog::Mail>, by Philippe Bruhat, 
published in GNU/Linux Magazine France #92, March 2007

=head1 TODO

Add support for other mailer daemons (Exim, Courier, Qpsmtpd). 
Send me logs or, even better, patches, if you want support for your 
favorite mailer daemon. 

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni C<< E<lt>sebastien (at) aperghis.netE<gt> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-parse-syslog-mail (at) rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Syslog-Mail>. 
I will be notified, and then you'll automatically be notified 
of progress on your bug as I make changes.

=head1 CAVEATS

Most probably the same as C<Parse::Syslog>, see L<Parse::Syslog/"BUGS">

=head1 COPYRIGHT & LICENSE

Copyright 2005, 2006, 2007, 2008 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Parse::Syslog::Mail

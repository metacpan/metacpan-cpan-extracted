package SyslogScan::SendmailLine;

use SyslogScan::SyslogEntry;

$VERSION = 0.21;
sub Version { $VERSION };
@ISA = qw( SyslogScan::SyslogEntry );

use SyslogScan::SendmailLineTrans;

use strict;

# parseContent method:  parses a sendmail message.  Puts message
# ID (if any) into $self{"messageID"}, and calls parseFrom() or
# parseTo() methods if the message is a "From:" or "To:" line.

sub parseContent
{
    my ($self) = shift;

    # check that we have the tag
    die "no tag found in sendmail line $$self{content}" unless
	defined $$self{tag};

    # parse content lines like:

    # WAA18677: to=foo, blahblahblah...
    # WAA18678: from=bar, blahblahblah...
    # NAC24788: clone NAA24787, owner=foo-owner

    # Other sendmail messages are legal but currently
    # unsupported by SendmailLine.pm.

    my ($id, $attrListString) = split ' ', $$self{"content"}, 2;

    # return now unless an ID exists
    return unless $id =~ s/:$//;

    # we have a transaction with a message ID

    $$self{"messageID"} = $id;
    $$self{"attrListString"} = $attrListString;
    bless ($self, "SyslogScan::SendmailLineTrans");
    $self -> SyslogScan::SendmailLineTrans::parseContent;
}    

1;
    
__END__

=head1 NAME

SyslogScan::SendmailLine -- Enhances basic SyslogEntry parsing by
understanding sendmail to/from message syntax.

=head1 DESCRIPTION

Suppose I run a 'new SyslogEntry' command and read in the following line:

Jun 13 01:32:26 satellife sendmail[23498]: WAA18677:
to=bar@foo.org,baz@foo.org, delay=03:50:20, mailer=smtp,
relay=relay.ulthar.com [128.206.5.3],
stat=Sent (May, have (embedded, commas))

If I have not loaded in SendmailLine, then 'new SyslogEntry' will return
an 'UnsupportedEntry' object looking like this:

 month => Jun,
 day => 13,
 time => 01:32:26,
 machine => satellife,
 executable => sendmail,
 tag => 23498,
 content => WAA18677: to=bar@foo.org,baz@foo.org, delay=03:50:20, ...

On the other hand, if I have a 'use SyslogScan::SendmailLine' command
before my call to 'new SyslogEntry', then I will a 'SendmailLine'
object with all of the above parameters, plus the following additional
parameters:

 messageID => WAA18677
 toList => ( bar@foo.org, baz@foo.org )
 attrHash => ( to => "bar@foo.org,baz@foo.org",
 	     delay => "03:50:20",
 	     mailer => "smtp",
 	     relay => "relay.ulthar.com [128.206.5.3]",
 	     stat => "Sent (May, have (embedded, commas))"
 	     )

Also well-supported is the 'From' line:	     

Jun 13 01:34:54 satellife sendmail[26035]: BAA26035: from=<bar!baz!foo>,
size=7000, class=0, pri=37000, nrcpts=1,
msgid=<199606130634.BAA26035@satellife.healthnet.org>,
proto=SMTP, relay=uth.bar.com [155.247.14.2]

will produce a SendmailLine object with the additional attributes of

 messageID => BAA26035
 attrHash => ( from => "<bar!baz!foo>",
 	     size => "7000",
 	     class => "0",
 	     pri => "37000"
 	     nrcpts => "1",
 	     msgid => "<199606130634.BAA26035@satellife.healthnet.org>",
 	     proto => "SMTP",
 	     relay => "uth.bar.com [155.247.14.2]"
 	     )

Other types of lines are legal, but are not currently very thorougly
parsed, and therefore return somewhat minimal SendmailLine objects.

Jun 13 13:05:35 satellife sendmail[19620]: NAA19606: NAA19620:
return to sender: unknown mailer error 2

will return a SendmailLine object with the usual SyslogEntry attributes,
plus the single additional attribute of

messageID => NAA19606

while lines like the following produce SendmailLine objects with no
additional SendmailLine-specific attributes:

Jun 13 03:00:05 satellife sendmail[26611]: alias database
/var/yp/nis.healthnet.org/mail.aliases rebuilt by root

Note this is a subclass for SyslogScan::SyslogEntry which handles
certain types of logfile lines.  See the documentation for SyslogEntry
for further details of how SyslogEntry subclassing works.

Also, see the SyslogScan::SendmailLineFrom and
SyslogScan::SendmailLineTo modules for examples of returned
SendmailLine objects.

=head1 AUTHOR and COPYRIGHT

The author (Rolf Harold Nelson) can currently be e-mailed as
rolf@usa.healthnet.org.

This code is Copyright (C) SatelLife, Inc. 1996.  All rights reserved.
This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

In no event shall SatelLife be liable to any party for direct,
indirect, special, incidental, or consequential damages arising out of
the use of this software and its documentation (including, but not
limited to, lost profits) even if the authors have been advised of the
possibility of such damage.

=head1 SEE ALSO

L<SyslogScan::SyslogEntry>, L<SyslogScan::SendmailLineFrom>,
L<SyslogScan::SendmailLineTo>

package SyslogScan::SendmailLineFrom;

$VERSION = 0.20;
sub Version { $VERSION };

use SyslogScan::SendmailUtil;

@ISA = qw ( SyslogScan::SendmailLineTrans );
use strict;

# parses a 'From:' line, checks that $self{"attrHash"} table
# has From-specific attributes like "size"
sub parseContent
{
    my ($self) = @_;
    
    # sanity-check that the required "size" attribute was filled in
    # with a legal number
    my $attrHashRef = $$self{"attrHash"};
    if ($$attrHashRef{"size"} !~ /^\-?\d+$/)
    {
	die("No legal size field in %$attrHashRef");
    }
    $$attrHashRef{"size"} = 0 if $$attrHashRef{"size"} < 0;

    $$attrHashRef{"from"} =
	&SyslogScan::SendmailUtil::canonAddress($$attrHashRef{"from"});

    return;
}

__END__

=head1 NAME

SyslogScan::SendmailLineFrom -- encapsulates a 'From:' line in a syslog file

=head1 DESCRIPTION

Here is a sample SendmailLineFrom object.

If 'new SyslogScan::SendmailLineEntry' reads in a line like

Jun 13 02:34:54 satellife sendmail[26035]: BAA26035: from=<HELP-NET@BAR.TEMPLE.EDU>, size=7000, class=0, pri=37000, nrcpts=1, msgid=<199606130634.BAA26035@satellife.healthnet.org>, proto=SMTP, relay=vm.temple.edu [155.247.14.2]

then it will return a SyslogScan::SendmailLineFrom object like this:

 # generic SyslogScan::SyslogEntry stuff
 day => 13,
 executable => 'sendmail',
 machine => 'satellife',
 month => 'Jun',
 tag => 26035,
 time => '02:34:54',
 content => 'BAA26035: from=<HELP-NET@BAR.TEMPLE.EDU>, size=7000, class=0, pri=37000, nrcpts=1, msgid=<199606130634.BAA26035@satellife.healthnet.org>, proto=SMTP, relay=vm.temple.edu [155.247.14.2]',

 # sendMailLineFrom-specific stuff
 messageID => 'BAA26035',
 attrHash => {
 	 'class' => 0,
          'from' => 'help-net@bar.temple.edu',
          'msgid' => '<199606130634.BAA26035@satellife.healthnet.org>',
          'nrcpts' => 1,
          'pri' => 37000,
          'proto' => 'SMTP',
          'relay' => 'vm.temple.edu [155.247.14.2]',
          'size' => 7000
 	 }

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

L<SyslogScan::SendmailLine>

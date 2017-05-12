# SendmailUtil.pm:  exports utilities for use with syslog
#   sendmail parsing.

package SyslogScan::SendmailUtil;

$VERSION = 0.20;

sub Version { $VERSION };

use SyslogScan::SyslogEntry;
use SyslogScan::SendmailLine;
use strict;

# getNextMailTransfer: given a filehandle, gets the next SyslogEntry
# which is also a SendmailLineTrans
sub getNextMailTransfer
{
    my $fh = shift;

    my ($pLogLine, $lineClass);
    while ($pLogLine = new SyslogScan::SyslogEntry $fh)
    {
	my $executable = $$pLogLine{'executable'};
	next unless ($executable eq 'sendmail');

	$lineClass = ref $pLogLine;

	# do not tolerate errors in sendmail module except
	# for unbalanced parens and i/o errors
	if ($lineClass =~ /BotchedEntry/)
	{
	    next if $$pLogLine{errorString} =~ /unbalanced paren/;
	    next if $$pLogLine{suspectIOError};
	    die "parsing error:  $$pLogLine{'errorString'}";
	}

        die "sanity check of class failed for $lineClass"
	    unless ($lineClass =~ /^SyslogScan::SendmailLine/);

	last if (($lineClass =~ /From/) || ($lineClass =~ /To/)
		 || ($lineClass =~ /Clone/));
    }
    return $pLogLine;   # either a Transfer, or undefined at EOF
}

sub canonAddress
{
    my $address = shift;

    $address =~ s/^\<(.+)\>$/$1/;
    $address =~ tr/A-Z/a-z/;
    $address =~ /[\!\@]/ or $address .= '@localhost';
    $address;
}

1;

__END__

=head1 NAME

SendmailUtil.pm -- utilities for sendmail packages.

=head1 SYNOPSIS

  use SyslogScan::SendmailUtil;

  open(FH,"/var/log/syslog");
  my $transfer;
  while ($transfer = SyslogScan::SendmailUtil::getNextMailTranfer(\*FH))
  {
     # process the tranfer
  }

=head1 DESCRIPTION

getNextMailTransfer queries a filehandle pointing to a syslog for the
next line which is a sendmail 'To:', 'From:', and 'Clone:' lines, and
returns a SyslogScan::SendmailLineFrom, SyslogScan::SendmailLineTo, or
SyslogScan::SendmailLineClone object.

=head1 canonAddress() routine

The canonAddress() routine modifies the address of the Sendmail
routines to be all-lowercase, remove enclosing brackets, and append
'@localhost' to local addresses.  Modifying this routine will change
how SyslogScan canonicalizes.

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

L<SyslogScan::SendmailLineFrom>, L<SyslogScan::SendmailLineTo>,
L<SyslogScan::SyslogEntry>

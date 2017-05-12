package SyslogScan::SendmailLineTo;

$VERSION = 0.20;
sub Version { $VERSION };

@ISA = qw ( SyslogScan::SendmailLineTrans );
use strict;

# checks that the line in $self{"attrHash"} table
# has To-specific attribute of "stat"; creates "@toList"
# array insides attrHash
sub parseContent
{
    my ($self) = @_;

    # sanity-check that status field was filled in
    my $attrHashRef = $$self{attrHash};
    if (! defined($$attrHashRef{"stat"}))
    {
	print STDERR "No status field in attrHash for id $$self{messageID}\n"
	    unless $::gbQuiet;
    }

    # break recipients into a list of individual recipients
    my(@toList) = split(',', $$attrHashRef{"to"});

    grep($_ = &SyslogScan::SendmailUtil::canonAddress($_),@toList);

    # TODO: move this over to the $toHash
    $$self{"toList"} = \@toList;
    return;
}

__END__

=head1 NAME

SyslogScan::SendmailLineTo -- encapsulates a 'To:' line in a syslog file

=head1 DESCRIPTION

Here is a sample SendmailLineTo object.

If 'new SyslogScan::SendmailLineEntry' reads in a line like

Jun 13 01:50:48 satellife sendmail[23498]: WAA18677: to=mbe527@time.nums.nwu.edu,jsm341@anima.nums.nwu.edu, delay=03:52:42, mailer=smtp, relay=anima.nums.nwu.edu. [165.124.50.10], stat=Sent (AA097917369 Message accepted for delivery)

then it will return a SyslogScan::SendmailLineTo object like this:

 # generic SyslogScan::SyslogEntry stuff
 day => 13,
 executable => 'sendmail',
 machine => 'satellife',
 messageID => 'WAA18677',
 month => 'Jun',
 tag => 23498,
 content => 'WAA18677: to=mbe527@time.nums.nwu.edu,jsm341@anima.nums.nwu.edu, delay=03:52:42, mailer=smtp, relay=anima.nums.nwu.edu. [165.124.50.10], stat=Sent (AA097917369 Message accepted for delivery)',

 # sendMailLineTo-specific stuff
 messageID => 'WAA18677'
 toList => (mbe527@time.nums.nwu.edu, jsm341@anima.nums.nwu.edu)
 attrHash => (
          'delay' => '03:52:42',
          'mailer' => 'smtp',
          'relay' => 'anima.nums.nwu.edu. [165.124.50.10]',
          'stat' => 'Sent (AA097917369 Message accepted for delivery)',
          'to' => 'mbe527@time.nums.nwu.edu,jsm341@anima.nums.nwu.edu'
 	 )

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

L<SyslogScan::SendmailLineTo>

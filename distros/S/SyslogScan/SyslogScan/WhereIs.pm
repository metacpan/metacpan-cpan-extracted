package SyslogScan::WhereIs;

$VERSION = 0.20;
sub Version { $VERSION };

use strict;

sub guess
{
    my $type = shift;
    my $conf = shift || "/etc/syslog.conf";

    open (CONF,$conf) or die "cannot open $conf: $!";
    my @aConfig = <CONF>;  #slurp in entire file

    my $facility;
    my $line;
    LINE: foreach $line (@aConfig)
    {
	chomp($line);
	next if ($line =~ /^\#/);

	my $pattern;
	foreach $pattern (qw( mail\.info mail\.=info mail\.debug mail\.\*
			    \*\.info \*\.=info \*\.debug \*\.\* ))
	{
	    if ($line =~ /$pattern[^\t\n]*\s+(.+)/)
	    {
		my $candidate = $1;
		next unless $candidate =~ /\//;
		next if $candidate =~ /^\/dev\//;  #ignore console messages
		$facility = $candidate;
		last LINE;
	    }
	}
    }

    defined($facility) or die "could not find local sendmail system log";
    return $facility;
}

1;

__END__

=head1 NAME

SyslogScan::WhereIs::guess -- return full path of syslog file where
mail messages are logged

=head1 SYNOPSIS

    my $syslogPath =
        new SyslogScan::Whereis::guess("/etc/syslog.conf");

=head1 DESCRIPTION

Scans a syslog configuration file to try to figure out where
"mail.info" messages are sent.  Default configuration file is
"/etc/syslog.conf".

Returns undef if the syslog file cannot be determined.

=head1 BUGS

It might have been more elegant to return an array of syslog files;
this would, as a bonus, permit multiple syslogs to be returned if mail
messages go to more than one place.

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

L<SyslogScan::DeliveryIterator>

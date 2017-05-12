# SyslogEntry: generic line in a syslog program.

package SyslogScan;

$VERSION = 0.31;
sub Version { $VERSION };


package SyslogScan::SyslogEntry;

use SyslogScan::ParseDate;

$VERSION = 0.31;
sub Version { $VERSION };

use SyslogScan::UnsupportedEntry;
use Carp;
use strict;

# to handle 'last message repeated n times' lines
my %gLastLineByHost;
my $gLineToRepeat;
my $gFinalMonth;
my $gFinalDay;
my $gFinalTime;
my $gRepeatCount = 0;

my %gTable = 
    (
# examples:
#     'cli'         =>   'SyslogScan::AnnexEntry',
#     'slip'        =>   'SyslogScan::AnnexEntry',
#     'telnet_cmd'  =>   'SyslogScan::AnnexEntry',
#     'ppp'         =>   'SyslogScan::AnnexEntry',
#     'rlogin_rdr'  =>   'SyslogScan::AnnexEntry',
     );

my $pIsSubclass = sub {
    my($superclass,$possibleSubclass) = @_;
    my(@superclassList);
    
    die "illegal subclass (has whitespace)" if
	$possibleSubclass =~ /\s/;
    @superclassList = eval '@' . "$possibleSubclass" . "::ISA";
    return 't' if (grep (($superclass eq $_), @superclassList));
    '';
};

sub new
{
    my $staticType = shift;
    my $SYSLOG = shift;

    defined $SYSLOG or croak("syslog not defined");

    my ($self, $className, $line);

    # check if we are repeating ourselves
    if ($gRepeatCount)
    {
	$line = $gLineToRepeat;
    }
    else
    {
	# read the next syslog line
	no strict 'refs';
	defined($line = <$SYSLOG>) || return undef;  # at EOF
	use strict 'refs';
	if (chop($line) ne "\n")
	{
	    warn "Discarding final line which was not newline-terminated.\n";
	    print STDERR "  (consider using 'tail -f syslog')\n";
	    return undef;
	}
    }
    
    # parse a line like: 'Jun 13 02:32:27 satellife mydaemon[25994]: foo'
    my ($month,$day,$time,$machine,$rest) =
	split ' ', $line, 5;

    # check for 'last line repeated n times' message
    if ($rest =~ /^last message repeated (\d+) time/)
    {
	$gRepeatCount and
	    die "repetition of 'last message repeated' line!?";
	$gRepeatCount = $1;
	$gLineToRepeat = $gLastLineByHost{$machine};
	($gFinalMonth, $gFinalDay, $gFinalTime) = ($month, $day, $time);
	$gRepeatCount ||
	    die "repetition of length 0!?";
	return SyslogScan::SyslogEntry -> new($SYSLOG);
    }

    if ($gRepeatCount)
    {
	if ($gRepeatCount == 1)  # on last repetition
	{
	    ($month, $day, $time) = ($gFinalMonth, $gFinalDay, $gFinalTime);
	}
	else
	{
	    ($month, $day, $time) = ();  # cannot precisely know time
	}
	$gRepeatCount--;
    }

    $gLastLineByHost{$machine} = $line;
	
    my ($executable,$tag,$content) =
	$rest =~ /^([^\:\[\]]+)(\[\d+\])?\: (.*)/;
    $tag =~ s/\[(.+)\]/$1/ if defined $tag;

    if (! defined $executable)
    {
	$rest and
	    print STDERR "executable not defined in line: $line\n"
		unless $::gbQuiet;
    }

    # fill in my 'self' array
    $self = {
	"content" => $content,
	"month" => $month,
	"day" => $day,
	"time" => $time,
	"machine" => $machine,
	"executable" => $executable,
	"tag" => $tag,
	"raw" => $line
	};

    if (defined $time)
    {
	my $date = "$month $day $time";
	$self->{"unix_time"} = SyslogScan::ParseDate::parseDate($date);
    }

    # check for possible i/o error
    if ($line =~ m^I/O error^ and $` !~ /\bstat=/)
    {
	print STDERR "may be syslog I/O error in line:\n  $line\n"
	    unless $::gbQuiet;
	$$self{suspectIOError} = 1;
    }

    # Make first letter of program capital, and change . to _,
    # so the module to handle 'in.identd' is named "In_identdLine.pm"

    my $oldChar = substr($executable,0,1);
    substr($executable,0,1) =~ tr/a-z/A-Z/;
    my $handlerClass = "SyslogScan::" . $executable . "Line";
    $handlerClass =~ s/[\. ]/_/g;
    substr($executable,0,1) = $oldChar;

    # If the module to handle this program has been "use"'d,
    # then subclass our object and call its parseContent() method.
    if (&$pIsSubclass("SyslogScan::SyslogEntry",$handlerClass))
    {
	bless($self,$handlerClass);
    }
    elsif (defined ($gTable{$executable}))
    {
	bless($self,$gTable{$executable});
    }
    else
    {
	# this line is not supported by a handler class
	bless($self,"SyslogScan::UnsupportedEntry");
    }

    # TODO: get rid of 'type' in favor of checking ref
    eval
    {
	$self -> parseContent;
    };

    if ($@ ne "")
    {
	# provide "escape hatches" so a module can halt the
	# entire program execution if it really needs to
	if (($@ =~ /SYSLOGMODULEFATAL/) ||
	    defined $$self{"ERRORS ARE FATAL"})
	{
	    die "fatal module error: $@" ;
	}
	
	# catch non-fatal errors so flawed module does not break others
	my ($brokenHandler) = ref $self;
	bless ($self, "SyslogScan::BotchedEntry");
	$$self{"brokenHandler"} = $brokenHandler;
	$$self{"errorString"} = $@;
	print STDERR "SyslogEntry.pm caught $brokenHandler module error: \n" .
	    "  $@\n" .
	    "  returning BotchedEntry object\n";
    }

    $self;
}

sub parseContent
{
    my ($self) = @_;
    die "class ", ref($self), " did not override parseContent!\n";
}

# access methods

sub content    { return ( (my $self = shift)->{"content"});}
sub raw        { return ( (my $self = shift)->{"raw"});}
sub month      { return ( (my $self = shift)->{"month"});}
sub day        { return ( (my $self = shift)->{"day"});}
sub time       { return ( (my $self = shift)->{"time"});}
sub machine    { return ( (my $self = shift)->{"machine"});}
sub executable { return ( (my $self = shift)->{"executable"});}
sub tag        { return ( (my $self = shift)->{"tag"});}
sub unix_time  { return ( (my $self = shift)->{"unix_time"});}

1;

__END__

=head1 NAME

SyslogScan::SyslogEntry -- parses generic lines in syslog files.

=head1 SYNOPSIS

    use SyslogScan::SyslogEntry;

    open(FH,"/var/log/syslog");

    my $entry;

    # reads from filehandle $fh and returns an object
    # of a subclass of SyslogEntry.
    while ($entry = new SyslogScan::SyslogEntry (\*FH))
    {
	# process $entry
    }

=head1 DESCRIPTION

All Syslog object share these data structures: month, day, time,
machine, executable, tag (optional), content.

For example, if a syslog line looks like:

Jun 13 02:32:27 satellife in.identd[25994]: connect from mail.missouri.edu

then the line returned by 'new SyslogEntry' will return a
SyslogEntry-derived object with at least this set of parameters:

 month => Jun,
 day => 13,
 time => 02:32:27,
 machine => satellife,
 executable => in.identd,
 tag => 25994,
 content => connect from mail.missouri.edu,
 unix_time => 834633147,
 raw => Jun 13 02:32:27 satellife in.identd[25994]: connect from mail.missouri.edu

Since the executable is 'in.identd', SyslogEntry.pm will look for a
class called "SyslogScan::In_identdLine" derived from SyslogEntry, and
attempt to call that class's parseContent method.  If no such
In_identdLine class is in use, then the returned object is of the
default "SyslogScan::UnsupportedEntry" class.

If the In_identdLine class throws a die() exception, SyslogEntry.pm
will catch the die() and return a "SyslogScan::BotchedEntry" object
containing the exception in "$errorString" and the failed handler in
"brokenHandler".

"new SyslogEntry" returns the undefined value if at EOF.

=head1 BUGS

In retrospect, this model of passing control to subclasses based on
the name of the controlling program doesn't work exceptionally
elegantly in perl.  I would probably do it more conventionally if I
had it to do over again.

=head1 AUTHOR and COPYRIGHT

The author (Rolf Harold Nelson) can currently be e-mailed as
rolf@usa.healthnet.org.

Thanks to Allen S. Rout for his code contributions.

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

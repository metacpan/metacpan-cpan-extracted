package PBS::Logs;

=head1 NAME

PBS::Logs - general parser for PBS log files

=head1 SYNOPSIS

See the sections below:

  use PBS::Logs;

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item The PBS Pro 5.4 Administrator Guide

=item PBS::Logs::Acct

=item PBS::Logs::Event

=back

=head1 AUTHOR

Dr R K Owen, E<lt>rkowen@nersc.govE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 The Regents of the University of California

This library is free software; you can redistribute it
and/or modify it under the terms of the GNU Lesser General
Public License as published by the Free Software Foundation;
either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
the GNU Lesser General Public License for more details,
which can be found at:

	http://www.gnu.org/copyleft/lesser.html
or	http://www.opensource.org/licenses/lgpl-license.php

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Time::Local;

our @ISA = qw();

our $VERSION = '0.05';

my $debug = 0;

my $datetime_regex = '(\d{2})/(\d{2})/(\d{4}) (\d{2}):(\d{2}):(\d{2})';

BEGIN {
	my @fields = qw{input type};
	# construct read-only accessor functions here - no need for AUTOLOAD
	foreach my $f (@fields) {
		my $code = "package ".__PACKAGE__.";\n"
.qq{sub $f {
	my \$self = shift;
	carp __PACKAGE__."->$f \$self (".join(',',\@_).")\n"
		if (\$debug || \$self->{'-debug'});
	\$self->{'$f'};
	}
};
	eval $code;
	}
}

# Preloaded methods go here.

=head1 new('file_name')

=head1 new(\@array_ref)

=head1 new(\*FILE_HANDLE)

Create a PBS::Logs object.
It takes only one argument which is either a filename, array reference,
or a FILE glob reference.

Pass a PBS log file name to read:

 my $pl = new PBS::Logs('/var/spool/PBS/server_logs/20050512');

Slurp the file into an array and pass the array reference

 open PL, '/var/spool/PBS/server_logs/20050512' 
   || die "can not open log";
 my @pl = <PL>;
 my $pl = new PBS::Logs(\@pl);

Or finally, pass a FILEHANDLE glob.  This can be useful if creating a filter.

 my $pl = new PBS::Logs(\*STDIN);

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
		'-debug'	=> 0,
		'-lastline'	=> undef,
		'-start'	=> undef,
		'-end'		=> undef,
		'input'		=> undef,
		'line'		=> 0,
		'type'		=> undef,
	};
	carp __PACKAGE__.": creating $self\n"
		if ($debug || $self->{'-debug'});
	my $x = shift;
	if (ref $x eq "ARRAY") {	# slurped ARRAY
		$self->{'input'} = $x;
		$self->{'type'} = 'ARRAY';
	} elsif (ref $x eq "GLOB") {	# FILEHANDLE
		$self->{'input'} = $x;
		$self->{'type'} = 'FILTER';
	} elsif (! ref $x) {		# filename
		open PBSIN, $x
			or croak __PACKAGE__.": new - can not open '$x'";
		$self->{'input'} = \*PBSIN;
		$self->{'type'} = 'FILE';
	} else {
		croak __PACKAGE__
		.": new - must pass either filename, array reference, "
		."or filehandle glob ... not ".ref($x)." '$x'";
	}
	bless ($self, $class);
	return $self;
}

sub DESTROY {
	my $self = shift;
	carp __PACKAGE__.": destroying $self\n"
		if ($debug || $self->{'-debug'});
	close $self->{'input'} if ref $self->{'input'} eq "GLOB";
}

sub END {
	carp __PACKAGE__.": ending\n"
		if ($debug);
}

=head1 debug([enable])

Debugging can be enabled for the entire class by calling
C<PBS::Logs::debug(1)>.

Or debugging can be enabled for a single object with
C<$obj-E<gt>debug(1)>.

To disable debugging just set to 0.

Calling either form with no argument will just cause
the current value to be returned.

=cut

sub debug {
	my $self = shift;
	if (index(ref($self), __PACKAGE__) == 0) {	# just myself
		@_	? $self->{'-debug'} = shift
			: $self->{'-debug'};
	} else {				# whole class
		defined($self)	? $debug = $self
				: $debug;
	}
}

=head1 line()

Return the "log line number" that will be read next (zero based),
and returns -1 when at the "end of file".  (Remember the "file"
could have been slurped into an array.)

=cut

sub line {
	my $self = shift;
	carp __PACKAGE__." : line $self (".join(',',@_).")\n"
		if ($debug || $self->{'-debug'});
	return undef if ! defined $self->{'line'};
	# the line count is always high by one since we must pre-read a line
	$self->{'line'} > 0 ? $self->{'line'} - 1 : $self->{'line'};
}

=head1 current()

Return the "current" concatenated PBS record that has been read and that
meets the selection criterion.  Remember, though, that actuall PBS logs can
have a record that is spread across multiple lines.
New records begin with a date/time-stamp.
This gives the entire record as one line.

=cut

sub current {
	my $self = shift;
	carp __PACKAGE__." : current $self (".join(',',@_).")\n"
		if ($debug || $self->{'-debug'});
	return undef if ! defined $self->{'current'};
	$self->{'current'};
}

=head1 start()

Begin reading at the start of the log, if not a filter.

=cut

sub start {
	my $self = shift;
	carp __PACKAGE__.": start $self(".join(',',@_).")\n"
		if ($debug || $self->{'-debug'});
	if ($self->{'type'} eq "FILE") {
		seek $self->{'input'}, 0, 0
		or croak __PACKAGE__.": start - can not seek on file";
	}
	$self->{'-lastline'}	= undef;
	$self->{'line'} = 0 if ($self->{'type'} ne 'FILTER');
	$self->{'current'}	= undef;
}

=head1 end()

End reading of the log and close it out, if not a filter.
Sets all the internal values to undef.

=cut

sub end {
	my $self = shift;
	carp __PACKAGE__.": end $self(".join(',',@_).")\n"
		if ($debug || $self->{'-debug'});
	if ($self->{'type'} eq "FILE") {
		close $self->{'input'};
	}
	$self->{'-lastline'}	= undef;
	$self->{'-start'}	= undef;
	$self->{'-end'}		= undef;
	$self->{'input'}	= undef;
	$self->{'line'}		= undef;
	$self->{'current'}	= undef;
	$self->{'type'}		= undef;
}

#=head1 getline()
#
#Get the next text line from the log returning a string
# (stripped of trailing \n's).
#This method is used internally only, and should not be called directly
#
#=cut

sub getline {
	my $self = shift;
	carp __PACKAGE__.": getline $self(".join(',',@_).")\n"
		if ($debug || $self->{'-debug'});

	my $l = undef;
	if ($self->{'type'} eq 'ARRAY') {
		$l = $self->{'input'}->[$self->{'line'}]
			if scalar @{$self->{'input'}} > $self->{'line'}
			&& $self->{'line'} != -1;
	} else {
		$l = readline $self->{'input'}
			if not eof($self->{'input'});
	}

	if (defined $l) {
		chomp $l;
		$self->{'line'}++;
	} else  {		# reached EOF
		$self->{'line'} = -1;
		$self->{'current'} = undef;
	}
	$l;						# return array ref
}

#=head1 getdata()
#
#Get the next data batch from the log returning an array reference
#of elements.
#This method is used internally only, and should not be called directly
#
#=cut

sub getdata {
	my $self = shift;
	carp __PACKAGE__.": getdata $self(".join(',',@_).")\n"
		if ($debug || $self->{'-debug'});

	my ($a,$l,$line) = (undef,undef,$self->{'-lastline'});

	$line = $self->getline() if ! defined $line;

	while ($l = $self->getline()) {
		last if ! defined $l;
		if ($l =~ /^$datetime_regex/) {
			$self->{'-lastline'} = $l;
			last;
		} else {		# a continuation record
			$line .= " $l";
		}
	}
	$self->{'-lastline'} = undef if ! defined $l;

	if (defined $line) {
		$a = [split(';',$line)];
		$self->{'current'} = $line;
	} else {
		$self->{'current'} = undef;
	}

	$a;						# return array ref
}

=head1 get()

Get the next entry from the log and return as an array reference
if in an scalar context, else return a list if called otherwise.

 $a = $pl->get();      # returns array reference
 @a = $pl->get();      # returns array

However, at the end of the log the array reference context will return undef
and the array context will return an empty list ();

=cut

sub get {
	my $self = shift;
	carp __PACKAGE__.": get $self(".join(',',@_).")\n"
		if ($debug || $self->{'-debug'});

	if ($self->{'line'} == -1) {	# nothing to do at EOF
		$self->{'current'} = undef;
		return () if (wantarray);
		return undef;
	}

#	my ($a,$l,$line) = (undef,undef,$self->{'-lastline'});
	my $a;
	while ($a = $self->getdata()) {
		my $dt = $self->datetime($a->[0]);
		next	if defined($self->{'-start'})
			&& ($dt < $self->{'-start'});
		next	if defined($self->{'-end'})
			&& ($dt > $self->{'-end'});
		last;
	}

	return if ! defined wantarray;			# just read log line
	return (defined $a ? @$a : ()) if (wantarray);	# return array
	$a;						# return array ref
}

=head1 datetime($datetime)

Parse the PBS date-time string and return the number of seconds
since the epoch if in a scalar context (UTC time),
or return a 6-element array similar to the gmtime() or localtime()
functions with
 (0:$sec, 1:$min, 2:$hour, 3:$mday, 4:$mon, 5:$year)
where $mon is in the range 0..11 and $year is a 4-digit year.

 $dt = '02/01/2005 18:48:10';
 $a = $pl->datetime($dt);      # returns seconds since January 1, 1970 UTC
 @a = $pl->datetime($dt);      # returns array

=cut

sub datetime {
	my $self = shift;
	carp __PACKAGE__.": datetime $self(".join(',',@_).")\n"
		if ($debug || $self->{'-debug'});

	my $dt = shift;
	carp __PACKAGE__.": datetime : received an undefined value"
		if ! defined $dt;

	my @dt = $dt =~ /$datetime_regex/;

	if (wantarray) {
		# rewrite in proper order
		return ($dt[5],$dt[4],$dt[3],$dt[1],$dt[0]-1,$dt[2]);
	} else {
		return timegm($dt[5],$dt[4],$dt[3],$dt[1],$dt[0]-1,$dt[2]);
	}
}

=head1 filter_datetime([start,end])

Sets or reads the datetime filter for the get() method.

get() will only retrieve lines that have a datetime between
"start" and "end" inclusive.

Either one can be 'none' to signify that no filtering will be
performed with respect to that time endpoint.  No filtering is
essentially ('none','none').  Or just do not call this method.

The start or end value can be given either in the PBS datetime
format ( DD/MM/YYYY HH:MM:SS ) or in seconds from the epoch.

It will return '1' if successful, else undef if some warning occurs.

If no arguments are given then the method will return an array
(start,end) where the values are in seconds since the epoch.

=cut

sub filter_datetime {
	my $self = shift;
	carp __PACKAGE__.": filter_datetime $self(".join(',',@_).")\n"
		if ($debug || $self->{'-debug'});

	my ($st,$et) = @_;

	return ($self->{'-start'}, $self->{'-end'})
		if (! defined $st);

	if (! defined $et) {
		carp __PACKAGE__
			.": filter_datetime : received an undefined value";
		return undef;
	}

	if ($st eq 'none') {
		$self->{'-start'} = undef;
	} elsif ($st =~ /^\d+$/) {
		$self->{'-start'} = $st;
	} elsif ($st =~ /^$datetime_regex$/) {
		$self->{'-start'} = $self->datetime($st);
	} else {
		carp __PACKAGE__.": filter_datetime : bad start value = '"
			.$st."'";
		return undef;
	}

	if ($et eq 'none') {
		$self->{'-end'} = undef;
	} elsif ($et =~ /^\d+$/) {
		$self->{'-end'} = $et;
	} elsif ($et =~ /^$datetime_regex$/) {
		$self->{'-end'} = $self->datetime($et);
	} else {
		carp __PACKAGE__.": filter_datetime : bad end value = '"
			.$et."'";
		return undef;
	}
	1;
}

1;
__END__

package PBS::Logs::Acct;

=head1 NAME

PBS::Logs::Acct - parses the PBS accounting log files
and inherits from PBS::Logs.

=head1 SYNOPSIS

See the sections below:

  use PBS::Logs::Acct;

The only non-inheritable function is the class level debug()

  PBS::Logs::Acct::debug()

You must use

  PBS::Logs::debug()

to read or set global debugging.
However, the instance version works just fine:

  $pl->debug()

Other than that
PBS::Logs::Acct inherits all the methods that are available from
PBS::Logs, plus adds the methods listed below.

=head1 DESCRIPTION

=head2 EXPORT

Can export message_hash() and message_hash_dump()

=head1 SEE ALSO

=over

=item PBS::Logs

=item PBS::Logs::Event

=item The PBS Pro 5.4 Administrator Guide

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
use PBS::Logs;
use Exporter;

our @ISA = qw(Exporter PBS::Logs);

our @EXPORT_OK = qw{message_hash message_hash_dump};

our $VERSION = $PBS::Logs::VERSION;

our %num2keys = (
	0	=> 'datetime',
	1	=> 'record_type',
	2	=> 'id',
	3	=> 'message'
);

our %keys;
$keys{$num2keys{$_}}=$_ for (keys %num2keys);

our %record_type = (
	'A'	=> 'job aborted by server',
	'B'	=> 'resource reservation period begin',
	'C'	=> 'job checkpointed and held',
	'D'	=> 'job deleted by request',
	'E'	=> 'job ended',
	'F'	=> 'resource reservation period finish',
	'K'	=> 'removal of resource reservation by sheduler or server',
	'k'	=> 'removal of resource reservation by client',
	'Q'	=> 'job queued',
	'R'	=> 'job rerun',
	'S'	=> 'job execution started',
	'T'	=> 'job restarted from checkpoint',
	'U'	=> 'unconfirmed resource reservation created by server',
	'Y'	=> 'confirmed resource reservation created by scheduler',
);

our %record_message_fields = (
	'B'	=> [
qw{owner name account queue ctime start end duration nodes
authorized_users authorized_groups authorized_hosts resource_list.}],
	'E'	=> [
qw{user group account jobname queue resvname resvID resvjobID
ctime qtime etime start exec_host Resource_List. session
alt_id end Exit_status Resources_used.}],
	'S'	=> [
qw{user group jobname queue
ctime qtime etime start exec_host Resource_List. session}],
);

# Preloaded methods go here.

=head1 new

Create a PBS::Logs::Acct object.
It takes only one argument which is either a filename, array reference,
or a FILE glob reference.

See PBS::Logs::new for examples and specifics.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	carp __PACKAGE__.": creating $self\n"
		if ($SUPER::debug || $self->{'-debug'});
	$self->{'-records'} = undef;
	bless ($self, $class);
	return $self;
}

=head1 get()

Get the next accounting log entry.  Extends PBS::Logs::get()
by filtering based on record_types.  See PBS::Logs::Acct::filter_records()
below for more info on this filtering, and PBS::Logs::get() for
info on return values.

=cut

sub get {
	my $self = shift;
	carp __PACKAGE__.": get $self(".join(',',@_).")\n"
		if ($SUPER::debug || $self->{'-debug'});

	my $a;
	while ($a = $self->SUPER::get()) {
		if (defined $self->{'-records'}) {
			last if exists
	$self->{'-records'}->{$a->[$keys{'record_type'}]};
		} else {
			last;
		}
	}

	return if ! defined wantarray;			# just read log entry
	return (defined $a ? @$a : ()) if (wantarray);	# return array
	$a;						# return array ref
}

=head1 Special Arrays

The following special associative arrays (hashes)
are provided by this package, which may be useful for
translating between arrays returned by the get() method
to/from hashes returned by the get_hash() method, or for
selecting a subset of the log entry.

=head2 %PBS::Logs::Acct::num2keys

Relates array position (number) to the keys (or field
descriptions) of a get_hash() generated hash.

  %num2keys = (
        0       => 'datetime',
        1       => 'record_type',
        2       => 'id',
        3       => 'message'
  );

=head2 %PBS::Logs::Acct::keys

Relates keys (field descriptions) as used by the get_hash() method
to array positions (number) as returned from the get() method.
Essentially, just the inverse of %PBS::Logs::Acct::num2keys above.

=head2 %PBS::Logs::Acct::record_type

Describes the record types, which are keys to this hash array.

  %record_type = (
        'A'     => 'job aborted by server',
        'B'     => 'resource reservation period begin',
        'C'     => 'job checkpointed and held',
        'D'     => 'job deleted by request',
        'E'     => 'job ended',
        'F'     => 'resource reservation period finish',
        'K'     => 'removal of resource reservation by sheduler or server',
        'k'     => 'removal of resource reservation by client',
        'Q'     => 'job queued',
        'R'     => 'job rerun',
        'S'     => 'job execution started',
        'T'     => 'job restarted from checkpoint',
        'U'     => 'unconfirmed resource reservation created by server',
        'Y'     => 'confirmed resource reservation created by scheduler',
  );

=head1 get_hash()

Like the PBS::Logs::Acct::get() method; however, instead of returning an
array reference, it (obviously) returns a hash
where the keys are the same keys as given by %PBS::Logs::Acct::keys .

The accounting log entry looks like this with respect to the keys:

  datetime;record_type;id;message

where the message field can have several key=value pairs depending on
the record_type and all the new-lines have been replaced with spaces.

If in a scalar mode it will return a hash reference else it
returns a hash.

=cut

sub get_hash {
	my $self = shift;
	carp __PACKAGE__.": get_hashref $self(".join(',',@_).")\n"
		if ($SUPER::debug || $self->{'-debug'});

	my $a = $self->get();

	if (! defined $a) {
		return ()	if (wantarray);
		return undef;
	}
	my $h = {};

	$h->{$_} = $a->[$keys{$_}] for (keys %keys);

	return if ! defined wantarray;			# just read log line
	return (defined $h ? %$h : ()) if (wantarray);	# return hash
	$h;						# return hash ref
}

=head1 filter_records(\@array_reference_list_of_record_types)

=head1 filter_records(@array_list_of_record_types)

Sets or reads the record_type filter for the get() method.

get() or get_hash() will only retrieve lines that have a record_type
in the list given.

Sending an empty array reference will clear the record_type filtering.

It will return '1' if successful, else undef if some warning occurs.

If no arguments are given then the method will return an array
of record_types filtered.

=cut

sub filter_records {
	my $self = shift;
	carp __PACKAGE__.": filter_records $self(".join(',',@_).")\n"
		if ($SUPER::debug || $self->{'-debug'});

	my @f;
	if (! defined $_[0]) {
		return (sort keys %{$self->{'-records'}})
			if defined $self->{'-records'};
		return ();
	} elsif (ref $_[0] eq "ARRAY") {
		@f = (@{$_[0]});
	} else {
		@f = @_;
	}
	if (! scalar @f) {
		$self->{'-records'} = undef;
	} else {
		# create hash
		$self->{'-records'} = {};
		$self->{'-records'}->{$_} = 1 for (sort @f);
	}

	1;
}

=head1 message_hash($message_text)

Parses an accounting log message and returns an associative array (hash)
containing the key/value pairs.  And for certain fields, such as:
Resource_List and resources_used, the value is another hash array
containing the resource key and value.
Can be called either as a method of an instantiated
object, or as a class function.

An example of the message text with resources_used dotted field:

  ...
  resources_used.cpupercent=0 resources_used.cput=00:00:00
  resources_used.mem=2880kb resources_used.ncpus=4
  resources_used.vmem=6848kb resources_used.walltime=00:00:00
  ...

Results in a hash array of:

  ...
  resources_used => {
     cpupercent => 0,
     cput => 00:00:00,
     mem => 2880kb,
     ncpus => 4,
     vmem => 6848kb,
     walltime => 00:00:00
  }, ...

=cut

sub message_hash {
	my $self = shift;
	if (ref $self eq __PACKAGE__) {
		carp __PACKAGE__.": message_hash $self(".join(',',@_).")\n"
			if ($SUPER::debug || $self->{'-debug'});
	} else {	# called directly as function
		unshift @_, $self;
		$self = undef;
		carp __PACKAGE__.":: message_hash(".join(',',@_).")\n"
			if ($SUPER::debug);
	}
	my $m = shift;

	my @m;
	my ($text,$quote) = (undef,undef);

	# Handle any key=value where the value may be ' or " delimited
	# (which are the only two delimiters recognized).
	# Since we are splitting on any whitespace ... this will have
	# the effect that all whitespace gets replaced by spaces (' ').
	foreach (split /\s/, $m) {
		if (defined $quote && /(.*)$quote$/) {
			# end of quoted block
			push @m, "$text $1";
			$text = undef;
			$quote = undef;
		} elsif (defined $quote && /^$/) {
			# some type of whitespace (replace with space)
			$text .= ' ';
		} elsif (defined $quote) {
			$text .= $_;
		} elsif (/^([^=]+)=(['"])(.*)\2$/) {
			push @m, "$1=$3";
		} elsif (/^([^=]+)=(['"])(.*)$/) {
			$text = "$1=$3";
			$quote = $2;
		} else {
			push @m, $_;
			$text = undef;
			$quote = undef;
		}
	}

	my $h = {};

	for (@m) {
		my ($k,$v) = m/^([^=]*)=*(.*)$/;
		if ($k =~ /\./) {
			my ($kk,$vv) = split('\.',$k);
			$h->{$kk} = {}	if ! exists $h->{$kk};
			$h->{$kk}->{$vv} = $v;
		} else {
			$h->{$k} = $v;
		}
	}
	return $h;
}

=head1 message_hash_dump($message_hash)

Takes the hash returned by message_hash() and recursively
dumps the keys and values into a string suitable for viewing
or evaluation.  Can be called either as a method of an instantiated
object, or as a class function.

Example of evaluating the output:

  my $m = PBS::Logs::Acct::message_hash($some_message);
  my $t = PBS::Logs::Acct::message_hash_dump($m);
  my $x;
  eval "\$x = $t";	# $x is now a HASH reference, equivalent to $m

=cut

sub message_hash_dump {
	my $self = shift;
	if (ref $self eq "HASH") {	# called directly as function
		unshift @_, $self;
		$self = undef;
		carp __PACKAGE__.":: message_hash_dump(".join(',',@_).")\n"
			if ($SUPER::debug);
	} else {
		carp __PACKAGE__.": message_hash_dump $self(".join(',',@_).")\n"
			if ($SUPER::debug || $self->{'-debug'});
	}
	my $h = shift;
	my $level = shift;
	$level = 0 if ! defined $level;

	my $text = ("    " x $level)."{\n";

	foreach my $k (sort {lc($a) cmp lc($b);} keys %$h) {
		if (ref $h->{$k} eq "HASH") {
			$text .= ("    " x $level)."'".$k."' => \n";
			if (defined $self) {
				$text .= 
				$self->message_hash_dump($h->{$k}, $level + 1);
			} else {
				$text .= 
				&message_hash_dump($h->{$k}, $level + 1);
			}
		} else {
			$text .= ("    " x $level)."'".$k."' => '".
				$h->{$k}."',\n";
		}
	}
	$text .= ("    " x $level)."}".($level?",":"")."\n";
	$text;
}

1;
__END__

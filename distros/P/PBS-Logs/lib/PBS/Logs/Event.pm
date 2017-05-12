package PBS::Logs::Event;

=head1 NAME

PBS::Logs::Event - parses the PBS event log files
and inherits from PBS::Logs.

=head1 SYNOPSIS

See the sections below:

  use PBS::Logs::Event;

The only non-inheritable function is the class level debug()

  PBS::Logs::Event::debug()

You must use

  PBS::Logs::debug()

to read or set global debugging.
However, the instance version works just fine:

  $pl->debug()

Other than that
PBS::Logs::Event inherits all the methods that are available from
PBS::Logs, plus adds the methods listed below.

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item PBS::Logs

=item PBS::Logs::Acct

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

our @ISA = qw(PBS::Logs);

our $VERSION = $PBS::Logs::VERSION;

# Preloaded methods go here.

=head1 new

Create a PBS::Logs::Event object.
It takes only one argument which is either a filename, array reference,
or a FILE glob reference.

See PBS::Logs::new for examples and specifics.

=cut

our %num2keys = (
	0	=> 'datetime',
	1	=> 'event_code',
	2	=> 'server_name',
	3	=> 'object_type',
	4	=> 'object_name',
	5	=> 'message'
);

our %keys;
$keys{$num2keys{$_}}=$_ for (keys %num2keys);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	carp __PACKAGE__.": creating $self\n"
		if ($SUPER::debug || $self->{'-debug'});
	bless ($self, $class);
	return $self;
}

=head1 get_hash()

Like the PBS::Logs::Event::get() method; however, instead of returning an
array reference, it (obviously) returns a hash
where the keys are the same keys as given by %PBS::Logs::Event::keys .

The event log entry looks like this with respect to the keys:
  datetime;event_code;server_name;object_type;object_name;message

If in a scalar mode it will return a hash reference else it
returns a hash.

=head1 Special Arrays

The following special associative arrays (hashes)
are provided by this package, which may be useful for
translating between arrays returned by the get() method
to/from hashes returned by the get_hash() method, or for
selecting a subset of the log entry.

=head2 %PBS::Logs::Event::num2keys

Relates array position (number) to the keys (or field
descriptions) of a get_hash() generated hash.

  %num2keys = (
        0       => 'datetime',
        1       => 'event_code',
        2       => 'server_name',
        3       => 'object_type',
        4       => 'object_name',
        5       => 'message'
  );

=head2 %PBS::Logs::Event::keys

Relates keys (field descriptions) as used by the get_hash() method
to array positions (number) as returned from the get() method.
Essentially, just the inverse of %PBS::Logs::Event::num2keys above.

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

1;
__END__

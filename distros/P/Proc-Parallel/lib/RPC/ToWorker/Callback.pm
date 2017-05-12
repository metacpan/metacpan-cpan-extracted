
package RPC::ToWorker::Callback;

use strict;
use warnings;
require Exporter;
use Storable qw(freeze thaw);

our @EXPORT = qw(master_call);
our @ISA = qw(Exporter);

our $master;

sub master_call
{
	my ($packages, $func, $with, @args) = @_;

	local($0) = $0;

	$0 =~ s/: RUNNING/: making RPC call on master to $func/g;

	my $pkgs = ref($packages)
		? $packages
		: [ split(' ', $packages) ];
	$with = ref($with)
		? $with
		: [ split(' ', $with) ];

	my $args = freeze(\@args);
	printf $master "DATA %d CALL %s with %s after loading %s\n%s", length($args), $func, "@$with", "@$pkgs", $args
		or die "print to master: $!";

	die if $func =~ /\s/;
	die unless $func =~ /\S/;

	my $ds =<$master>;
	die unless $ds =~ /^DATA (\d+) DONE_RESPONSE\n/;
	my $amt = $1;
	my $buf = '';
	while (length($buf) < $amt) {
		read($master, $buf, $amt - length($buf), length($buf)) or die;
	}
	my $ret = thaw($buf);
	return @$ret;
}

1;

__END__

=head1 SYNOPSIS

 use RPC::ToWorker::Callback;

 @return_values = master_call('Some::Packages To::Preload', 'remote_function_name', 'remote local data keys', @data);

=head1 DESCRIPTION

Make a remote call to a function on the master node from a 
slave process started with L<RPC::ToWorker>.

This module is used in the worker, not the master.

The slaves are running sychronously, but the master is asychronous so
this is a blocking call on the slave.  Use this sparingly since the slave
will have to wait.

The calling parameters are:

=over

=item 1

B<String or List>.
A reference to a list or a 
a space-separated list of modules to load on the master.

=item 2

B<String>.
The name of the function to invoke on the master.

=item 3

B<String or List>.
A reference to a list or a 
A reference to a list or a 
A space-separated list of keys from the optional C<local_data> parameter to the
original C<do_remote_job> call that invoked the work process.   The keys and values corresponding
to these keys till be appended to the list of arguments to the function.

=item remainder

B<anything>.
Arguments to the function to invoke.

=back

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.
Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.


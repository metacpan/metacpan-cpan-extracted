package ORLite::Profile;

=pod

=head1 NAME

ORLite::Profile - Experimental Aspect-Oriented Profiler for ORLite

=head1 SYNOPSIS

  # Load your ORLite database
  use My::ORLiteDB;
  
  # Load the profiler
  use ORLite::Profile;
  
  # Stimulate the load you want to profile here.
  # When the program exists, the profiling data
  # will ne printed to STDERR.

=head1 DESCRIPTION

B<ORLite::Profile> is an experimental profiler for L<ORLite>. It currently
serves as an experimental test-bed for more wide-scoped DBI profiling and
monitoring modules.

It weaves L<Aspect>-based profiling logic into the DBI layer,
below the ORLite logic itself.

At the present time, the main purpose of this module is to
examine the aggregate total time spent in the connect, prepare,
and execute tasks.

I hope to expand this in the future to capture more interesting
types of data.

=head1 Using This Module

This module has no interface and takes no options.

You just load it after your L<ORLite>-based class is loaded, and
then generate some test load.

When the program exits, the profing information is written to STDERR.

=cut

use 5.008;
use strict;
use warnings;
use Aspect;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

aspect Profiler => call qr/^DBI::(?:connect|db::prepare|db::do|db::select|st::execute|st::fetch)/;

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/Public/Dist/Display.html?Name=ORLite-Profile>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<ORLite::Mirror>, L<ORLite::Migrate>

=head1 COPYRIGHT

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

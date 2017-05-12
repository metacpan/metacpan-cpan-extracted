# -*- perl -*-
#
# Test::AutoBuild::Repository::CVS by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2002-2004 Daniel Berrange <dan@berrange.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id$

=pod

=head1 NAME

Test::AutoBuild::Repository::CVS - A repository for CVS

=head1 SYNOPSIS

  use Test::AutoBuild::Repository::CVS


=head1 DESCRIPTION

This module provides access to source within a CVS repository.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository::CVS;

use strict;
use warnings;
use POSIX qw(strftime);
use Log::Log4perl;

use base qw(Test::AutoBuild::Repository);


sub export {
    my $self = shift;
    my $runtime = shift;
    my $src = shift;
    my $dst = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my $branch;
    if ($src =~ /(.*):((?:\w|-)+)$/) {
	$branch = $2;
	$src = $1;
    }

    if ($branch &&
	$branch eq "HEAD") {
	$log->warn("Illegal tag HEAD - only branch tags are allowed");
	$branch = undef;
    }

    my $date = strftime("%d %b %Y %H:%M:%S +0000", gmtime $runtime->timestamp);

    my $cmd = -e $dst ?
	($branch ?
	 ['cvs', '-q', 'update', '-D', $date, '-r', $branch, '-PdC'] :
	 ['cvs', '-q', 'update', '-D', $date, '-APdC']) :
	 ($branch ?
	  ['cvs', '-q', 'checkout', '-D', $date, '-d', $dst, '-r', $branch, '-P', $src] :
	  ['cvs', '-q', 'checkout', '-D', $date, '-d', $dst, '-P', $src]);

    $log->debug("About to run " . join(" ", @{$cmd}));
    my ($output, $errors) = $self->_run($cmd, -e $dst ? $dst : undef, $logfile);

    # Crude change checking - any line which doesn't
    # look like a directrory traversal message treated
    # as indicating a change
    my $changed = 0;
    if ($output) {
	foreach (split /\n/, $output) {
	    next if /^cvs server:/;
	    next if /^\s*\?/;
	    $changed = 1;
	}
    }
    return $changed;
}



1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002-2004 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Repository>

=cut

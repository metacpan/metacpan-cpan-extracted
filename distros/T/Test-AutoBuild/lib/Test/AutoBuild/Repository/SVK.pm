# -*- perl -*-
#
# Test::AutoBuild::Repository::SVK by Daniel Berrange
#
# Copyright (C) 2004 Daniel Berrange
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

Test::AutoBuild::Repository::SVK - A repository for SVK (Distributed Subversion)

=head1 SYNOPSIS

  use Test::AutoBuild::Repository::SVK


=head1 DESCRIPTION

This module provides a repository implementation for the
SVK revision control system, a distributed implementation
of Subversion. It will automatically import remote repositories
it uses into a local repository with a name matching the
module name. It has full support for detecting updates to
an existing checkout.

=head1 CONFIGURATION

Example configuration entry for SVK module looks like

  svk = {
    label = SVK
    module = Test::AutoBuild::Repository::SVK
  }


A module's paths entries either contain the full path
of the remote repository in which case it will be
imported into a local repository with the same name
as the module. If the two arg form is used, the second
arg will be used as a subdirectory of the module


 myapp = {
    label = CCM Core
    paths = (
      http://svn.example.org/svn/trunk
      http://svn.example.org/other/trunk -> other
    )
    repository = svk
    group = Software
 }

In this example, the following commands will be run
to process the module

   svk import //myapp http://svn.example.org/svn/trunk
   svk sync //myapp

   svk import //myapp/other http://svn.example.org/other/trunk
   svk sync //myapp/other

   svk checkout //myapp myapp
   svk chcekout //myapp/other myapp/other



=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository::SVK;

use strict;
use warnings;
use Carp qw(confess);

use base qw(Test::AutoBuild::Repository);


=item my $repository = Test::AutoBuild::Repository::SVK->new(  );

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    bless $self, $class;

    return $self;
}


sub export {
    my $self = shift;
    my $runtime = shift;
    my $src = shift;
    my $dst = shift;
    my $logfile = shift;

    my $changed = 0;

    $self->_run(["svk", "mirror", "//$dst", $src], undef, $logfile);
    $self->_run(["svk", "sync", "//$dst"], undef, $logfile);

    if (-d $dst) {
	my $output = $self->_run(["svk", "up", $dst], undef, $logfile);
	if (!($output =~ /^\s*$/)) {
	    $changed = 1;
	}
    } else {
	$self->_run(["svk", "checkout", "//$dst",$dst], undef, $logfile);
	$changed = 1;
    }

    return $changed;
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange

=head1 COPYRIGHT

Copyright (C) 2004 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Repository>

=cut

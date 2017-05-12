# -*- perl -*-
#
# Test::AutoBuild::ArchiveManager::Memory
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2004-2005 Dennis Gregorovice, Daniel Berrange
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

Test::AutoBuild::ArchiveManager::Memory - In memory based archive manager

=head1 SYNOPSIS

  use Test::AutoBuild::ArchiveManager::Memory;

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::ArchiveManager::Memory;

use base qw(Test::AutoBuild::ArchiveManager);
use warnings;
use strict;
use Log::Log4perl;
use Test::AutoBuild::Archive::Memory;

sub init {
    my $self = shift;
    my %params = @_;

    $self->SUPER::init(@_);

    $self->{archives} = {};
}

sub create_archive {
    my $self = shift;
    my $key = shift;

    $self->{archives}->{$key} = Test::AutoBuild::Archive::Memory->new(key => $key);
}

sub get_current_archive {
    my $self = shift;
    my $runtime = shift;

    my $key = $runtime->build_counter;

    return $self->{archives}->{$key};
}


sub list_archives {
    my $self = shift;

    return sort { $a->key cmp $b->key } values %{$self->{archives}};
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004-2005 Dennis Gregorovic, Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>

=cut

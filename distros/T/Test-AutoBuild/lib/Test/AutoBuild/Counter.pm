# -*- perl -*-
#
# Test::AutoBuild::Counter
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2005 Daniel Berrange
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

Test::AutoBuild::Counter - The base class for an AutoBuild stage

=head1 SYNOPSIS

  use Test::AutoBuild::Counter;

  my $counter = Test::AutoBuild::Counter->new(options => \%options);

  # Retrieve the current counter
  $counter->value();

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Counter;

use warnings;
use strict;
use Log::Log4perl;

=item my $stage = Test::AutoBuild::Counter->new(options => %options);

Creates a new counter, with the options parameter providing in any
sub-class specific configuration options.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my %params = @_;

    $self->{options} = exists $params{options} ? $params{options} : {};

    bless $self, $class;

    return $self;
}


=item $value = $counter->option($name[, $newvalue]);

Retrieves the subclass specific configuration
option specified by the C<$name> parameter. If the
C<$newvalue> parameter is supplied, then the configuration
option is updated.

=cut

sub option {
   my $self = shift;
   my $name = shift;

   $self->{options}->{$name} = shift if @_;

   return $self->{options}->{$name};
}


=item $counter->generate($runtime);

This method should be implemented by subclasses to the logic
required to generate the next build counter.

=cut

sub generate {
    my $self = shift;
    my $runtime = shift;

    die "class " . ref($self) . " forgot to implement the generate method";
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>

=cut

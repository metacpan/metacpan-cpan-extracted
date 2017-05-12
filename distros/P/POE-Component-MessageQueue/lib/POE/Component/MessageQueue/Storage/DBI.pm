#
# Copyright 2007-2010 David Snopek <dsnopek@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package POE::Component::MessageQueue::Storage::DBI;
use Moose;
extends qw(POE::Component::MessageQueue::Storage::Generic);

has '+package' => ( 
	default => 'POE::Component::MessageQueue::Storage::Generic::DBI',
);

around new => sub {
	my ($original, $class) = (shift, shift);
	my @args;
	if (ref($_[0]) eq 'HASH') {
		@args = %{$_[0]};
	} else {
		@args = @_;
	}
	$original->($class, @args, options => \@args);
};

sub BUILD {
	my ($self) = @_;
	# Forces early termination if we cannot connect to db.
	eval 'require ' . $self->package;
	$self->package->new(@{$self->options});
}

1;

__END__

=pod

=head1 NAME

POE::Component::MessageQueue::Storage::DBI -- A storage engine that uses L<DBI>

=head1 SYNOPSIS

  use POE;
  use POE::Component::MessageQueue;
  use POE::Component::MessageQueue::Storage::DBI;
  use strict;

  # For mysql:
  my $DB_DSN      = 'DBI:mysql:database=perl_mq';
  my $DB_USERNAME = 'perl_mq';
  my $DB_PASSWORD = 'perl_mq';
  my $DB_OPTIONS  = undef;

  POE::Component::MessageQueue->new({
    storage => POE::Component::MessageQueue::Storage::DBI->new({
      dsn      => $DB_DSN,
      username => $DB_USERNAME,
      password => $DB_PASSWORD,
      options  => $DB_OPTIONS
    })
  });

  POE::Kernel->run();
  exit;

=head1 DESCRIPTION

A storage engine that uses L<DBI>.  All messages stored with this backend are
persisted.

Performance is increased greatly by wrapping this engine in 
L<POE::Component::MessageQueue::Storage::Throttled> at the expense of being slower
to persist messages.

This module is really just L<POE::Component::MessageQueue::Storage::Generic> with
L<POE::Component::MessageQueue::Storage::Generic::DBI>.  See the documentation for
those modules for more information (primarily
L<POE::Component::MessageQueue::Storage::Generic::DBI>).

=head1 CONSTRUCTOR PARAMETERS

=over 2

=item dsn => SCALAR

=item username => SCALAR

=item password => SCALAR

=item options => SCALAR

=item mq_id => SCALAR

=back

=head1 SEE ALSO

L<POE::Component::MessageQueue>,
L<POE::Component::MessageQueue::Storage>,
L<DBI>

I<Other storage engines:>

L<POE::Component::MessageQueue::Storage::Memory>,
L<POE::Component::MessageQueue::Storage::BigMemory>,
L<POE::Component::MessageQueue::Storage::FileSystem>,
L<POE::Component::MessageQueue::Storage::Generic>,
L<POE::Component::MessageQueue::Storage::Generic::DBI>,
L<POE::Component::MessageQueue::Storage::Throttled>,
L<POE::Component::MessageQueue::Storage::Complex>,
L<POE::Component::MessageQueue::Storage::Default>

=cut


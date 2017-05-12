# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Pod-MinimumVersion.

# Pod-MinimumVersion is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Pod-MinimumVersion is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.


package Pod::MinimumVersion::Report;
use 5.004;
use strict;
use overload '""' => \&as_string;

use vars '$VERSION';
$VERSION = 50;

sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}

# not sure about this ...
sub as_string {
  my ($self) = @_;
  return "$self->{'filename'}:$self->{'linenum'}: $self->{'version'} due to $self->{'why'}";
}

1;
__END__

=for stopwords Ryde Pod-MinimumVersion

=head1 NAME

Pod::MinimumVersion::Report - report object from Pod::MinimumVersion

=head1 DESCRIPTION

See C<Pod::MinimumVersion/REPORT OBJECTS>.

=head1 SEE ALSO

L<Pod::MinimumVersion>

=head1 HOME PAGE

http://user42.tuxfamily.org/pod-minimumversion/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011 Kevin Ryde

Pod-MinimumVersion is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Pod-MinimumVersion is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.

=cut

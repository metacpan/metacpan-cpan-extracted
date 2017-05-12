package PDLx::Role::RestrictedPDL;

use strictures 2;

use Carp;
use PDL::Core ':Internal';
use overload;

our $VERSION = '0.03';

my $_cant_mutate;

BEGIN {
    $_cant_mutate = sub { croak "restricted piddle: cannot mutate" };
}


use Moo::Role;

use overload
    map { $_ => $_cant_mutate }
    grep { $_ =~ /=$/ }
    map { split( ' ', $_ ) } @{overload::ops}{ 'assign', 'mutators', 'binary' };

sub is_inplace { 0; }
sub set_inplace { goto $_cant_mutate unless @_ > 0 && $_[1] == 0 }

*inplace = $_cant_mutate;

1;


__END__


=pod

=head1 NAME

PDLx::Role::RestrictedPDL -- restrict write access to a PDL object as much as possible

=head1 SYNOPSIS

  package MyPDL;

  use Moo;

  with 'PDLx::Role::RestrictedPDL';


=head1 DESCRIPTION

This role overloads assignment operators and the
L<< B<is_inplace>|PDL::Core/inplace >>,
L<< B<is_inplace>|PDL::Core/is_inplace >>,
and
L<< B<set_inplace>|PDL::Core/set_inplace >>,
methods to attempt to prevent mutation of a piddle.

=head1 BUGS AND LIMITATIONS

B<< This does I<not> provide a readonly PDL! >>  Currently that's impossible.
It tries to make common operations croak, but cannot handle corner cases.

Please report any bugs or feature requests to
C<bug-pdlx-mask@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-Mask>.


=head1 VERSION

Version 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 The Smithsonian Astrophysical Observatory

PDLx::Mask is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>

=cut

=begin fakeout_pod_coverage

=head3 inplace

=head3 is_inplace

=head3 PDL

=head3 set_inplace

=end fakeout_pod_coverage

package Siebel::Srvrmgr::Types;

use warnings;
use strict;
use Moose::Util::TypeConstraints 2.0402;
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::Types - definition of types restrictions for Siebel::Srvrmgr

=head1 SYNOPSIS

	use Siebel::Srvrmgr::Types;

=head1 DESCRIPTION

This module defines types restrictions for L<Siebel::Srvrmgr> classes usage based on L<Moose::Util::TypeConstraints>.

=head1 EXPORTS

Nothing. Just use the module is enough to have types restrictions definitions.

=cut

=head2 NotNullStr

A subtype of 'Str' but do not accept undefined or empty strings.

=cut

subtype 'NotNullStr', as 'Str',
  where { ( defined($_) ) and ( $_ ne '' ) },
  message { 'This attribute value must be a defined, non-empty string' };

=head2 Chr

A subtype of 'Str' but for a single character only.

=cut

subtype 'Chr', as 'Str',
  where { ( defined($_) ) and ( $_ ne '' ) and ( length($_) == 1 ) },
  message { 'This attribute value must be a defined, non-empty string with a single character' };

=head2 OutputTabularType

A subtype of 'Str' that must be defined and equal to "fixed" or "delimited".

=cut

subtype 'OutputTabularType', as 'Str', 
	where { ( ( defined($_) ) and ( ( $_ eq 'fixed' ) or ( $_ eq 'delimited' ) ) ) }, 
	message { 'This attribute value must be a defined, non-empty string equal "fixed" or "delimited"' };

=head2 CheckCompsComp

Definition of type for instances of L<Siebel::Srvrmgr::Daemon::Action::Check::Component> class.

=cut

role_type 'CheckCompsComp',
  { role => 'Siebel::Srvrmgr::Daemon::Action::Check::Component' };

no Moose::Util::TypeConstraints;

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;

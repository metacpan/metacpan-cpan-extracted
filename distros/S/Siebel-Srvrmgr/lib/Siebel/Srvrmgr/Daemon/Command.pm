package Siebel::Srvrmgr::Daemon::Command;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Command - daemon command class

=head1 SYNOPSIS

	my $action = Siebel::Srvrmgr::Daemon::Command->new(
	    {
            command => 'list comps',
            action  => 'Siebel::Srvrmgr::Daemon::Action', 
			params => ['parameter1', 'parameter2']
        }
	);


=head1 DESCRIPTION

This class represents a single command that will be executed by a L<Siebel::Srvrmgr::Daemon> instance.

A command in this context is made of a srvrmgr command, an action to be executed after the commands output is received (the name of a subclass of 
L<Siebel::Srvrmgr::Daemon::Action>) and an optional parameter in the form of an array reference for the action class being used.

=cut

use Moose 2.0401;
use MooseX::FollowPBP 0.05;
use namespace::autoclean 0.13;
our $VERSION = '0.29'; # VERSION

=pod

=head1 ATTRIBUTES

All attributes are read-only and cannot be modified after a class instance is created.

=head2 command

The command attribute holds a string that will be submitted to the srvrmgr program. Beware that any string is acceptable but any correct output expected
depends on passing valid commands to the srvrmgr prompt. This attribute is required.

=cut

has command => ( isa => 'Str', is => 'ro', required => 1 );

=pod

=head2 action

The action parameter expects a string with the name of a subclass of L<Siebel::Srvrmgr::Daemon::Action> class. If one is used, then only the name of the subclass can be
used (for example, 'Foobar' will produce an instance of a 'Siebel::Srvrmgr::Daemon::Action' subclass, if it exists). If another class is used, then the complete name
of the class must be used.

Beware that the class passed as parameter must be able to deal with the srvrmgr output and do something with it.

This attribute is obligatory.

=cut

has action => ( isa => 'Str', is => 'ro', required => 1 );

=pod

=head2 params

The params parameter expects an array reference with any arbitrary number of parameters to the used by the subclass of L<Siebel::Srvrmgr::Daemon::Action> given as value for
the action parameter.

Since this parameter is optional, if some value is passed by a subclass that does not expects a parameter, nothing will be processed.

=cut

has params =>
  ( isa => 'ArrayRef', is => 'ro', required => 0, default => sub { [] } );

=pod

=head1 METHODS

All methods available is for retrieving the parameters values by using the methodology proposed by L<MooseX::FollowPBP>. Use "get_<attribute>" to retrieve the desired
value.

=cut

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<MooseX::FollowPBP>

=item *

L<Siebel::Srvrmgr::Daemon> command attribute description.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
1;

package Siebel::Srvrmgr::Daemon::ActionFactory;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::ActionFactory - abstract factory to create Action subclasses

=head1 SYNOPSIS

	my $action = Siebel::Srvrmgr::Daemon::ActionFactory->create(
		$class,
		{
			parser => Siebel::Srvrmgr::ListParser->new(),
			params => \@params
		}
	);


=head1 DESCRIPTION

This is a abstract factory used to instatiate Action classes. It is used primarily by L<Siebel::Srvrmgr::Daemon> class
to define the Action objects to process generated output.

=cut

use warnings;
use strict;
use MooseX::AbstractFactory 0.004000;
our $VERSION = '0.29'; # VERSION

=pod

=head1 METHODS

=head2 create

Expects as parameter the name of the class that needs to be instantiated followed by any required parameters for the class to 
instantiate a new object. It returns the instantiated object, if possible, otherwise it will raise an exception.

If a single string (without double semicolon separators) is given as the class name, ActionFactory will understand that it will
have to expand it to a full Action subclass name available from this distribution. For example, if a "LoadPrefences" is given it
will be expanded to "Siebel::Srvrmgr::Daemon::Action::LoadPreferences" and try to instantiate such object.

If a full class name (with double semicolon separators) is given, the factory will try to instantiate that object and return it. That should
make possible to create objects from classes outside the distribution directory.

=cut

implementation_class_via sub {

    my $classname = shift;

    if ( $classname =~ /\:{2}/ ) {

        return $classname;

    }
    else {

        return 'Siebel::Srvrmgr::Daemon::Action::' . $classname;

    }

};

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<MooseX::AbstractFactory>

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

1;

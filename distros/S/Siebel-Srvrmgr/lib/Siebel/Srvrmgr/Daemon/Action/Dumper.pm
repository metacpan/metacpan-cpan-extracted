package Siebel::Srvrmgr::Daemon::Action::Dumper;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::Dumper - subclass for Siebel::Srvrmgr::Daemon::Action to dump buffer content

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::Daemon::Action> for an example.

=head1 DESCRIPTION

This is a subclass of L<Siebel::Srvrmgr::Daemon::Action> that will dump a buffer content (array reference) passed
as parameter to the it's C<do> method.

This class uses L<Data::Dumper> them to print the buffer content to C<STDOUT>.

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Data::Dumper;

extends 'Siebel::Srvrmgr::Daemon::Action';
our $VERSION = '0.29'; # VERSION

=head1 METHODS

=head2 do_parsed

It will print the content of the parsed tree to C<STDOUT> by using L<Data::Dumper> C<Dump> function.

This functions always returns true.

=cut

override 'do_parsed' => sub {

    my $self = shift;
    my $item = shift;

    print Dumper($item);

    return 1;

};

=pod

=head1 SEE ALSO

L<Siebel::Srvrmgr::Daemon::Action>

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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

__PACKAGE__->meta->make_immutable;

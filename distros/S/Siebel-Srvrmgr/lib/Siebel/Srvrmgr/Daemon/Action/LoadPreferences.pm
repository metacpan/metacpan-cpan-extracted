package Siebel::Srvrmgr::Daemon::Action::LoadPreferences;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::LoadPreferences - dummy subclass of Siebel::Srvrmgr::Daemon::Action to allow execution of load preferences command

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Daemon::Action::LoadPreferences;
    my $action = Siebel::Srvrmgr::Daemon::Action::LoadPreferences->new(parser => Siebel::Srvrmgr::ListParser->new());
    $action->do(\@output);

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;

extends 'Siebel::Srvrmgr::Daemon::Action';
our $VERSION = '0.29'; # VERSION

=head1 DESCRIPTION

The only usage for this class is to allow execution of C<load preferences> command by a L<Siebel::Srvrmgr::Daemon> object, allowing the execution
and parsing of the output of the command to be executed in the regular cycle of processing.

Executing C<load preferences> is particullary useful for setting the correct columns and sizing of output of commands like C<list comp>.

=head1 METHODS

=head2 do_parsed

It checks if the given object as parameter is a L<Siebel::Srvrmgr::ListParser::Output::LoadPreferences> object and then returning true, otherwise
returns false.

=cut

override 'do_parsed' => sub {
    my ($self, $item) = @_;

    if ( blessed($item) eq $self->get_exp_output() ) {
        return 1;
    }
    else {
        return 0;
    }

};

override _build_exp_output => sub {
    return 'Siebel::Srvrmgr::ListParser::Output::LoadPreferences';
};

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Daemon>

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<Siebel::Srvrmgr::ListParser::Output::LoadPreferences>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;

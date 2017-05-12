package Siebel::Srvrmgr::Daemon::Action::ListSessions;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::ListSessions - subclass of Siebel::Srvrmgr::Daemon::Action to recover sessions information

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::Daemon::Action> for an example.

=head1 DESCRIPTION

This is a subclass of L<Siebel::Srvrmgr::Daemon::Action> that will recover sessions information as documented in the C<do_parsed> method.

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr;
use Siebel::Srvrmgr::Daemon::ActionStash;

extends 'Siebel::Srvrmgr::Daemon::Action';
our $VERSION = '0.29'; # VERSION

=head1 METHODS

=head2 do_parsed

This method is overrided from parent class.

The method will recover the sessions as the iterator returned from the C<get_sessions> method from the L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions> instance created by the parser and
stash it in the L<Siebel::Srvrmgr::Daemon::ActionStash> available.

Expects as parameters:

=over

=item 1.

a L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions> instance

=item 2.

A string identifying the Siebel servername which sessions is expected to be in the first parameter

=back 

This method will returne true in the case the object received as parameter C<isa> L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions> or false otherwise.

=cut

override 'do_parsed' => sub {

    my $self = shift;
    my $obj  = shift;
    my $servername = $self->get_params()->[0];

    if ( $obj->isa( $self->get_exp_output() ) ) { 
    
        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
        $stash->push_stash( $obj->get_sessions($servername) );
        
        return 1;

    }
    else {

        return 0;

    }

};

override '_build_exp_output' => sub {

    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions';

};

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<Siebel::Srvrmgr::Daemon::ActionStash>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions>

=back

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

package Siebel::Srvrmgr::Daemon::Cleanup;

use warnings;
use strict;
use Siebel::Srvrmgr;
use Moose::Role;
our $VERSION = '0.29'; # VERSION

=head1 NAME

Siebel::Srvrmgr::Daemon::Cleanup - Moose roles for Siebel::Srvrmgr::Daemon subclasses cleanup

=head1 DESCRIPTION

This Moose role provides cleanup "hidden" methods for subclasses of L<Siebel::Srvrmgr::Daemon> to execute
their own cleanup of temporary files when they're done.

=cut

sub _del_file {
    my ( $self, $filename ) = @_;
    my $logger = Siebel::Srvrmgr->gimme_logger( blessed($self) );

    if ( defined($filename) ) {

        if ( -e $filename ) {
            my $ret = unlink $filename;

            if ($ret) {
                return 1;
            }
            else {
                $logger->warn("Could not remove $filename: $!");
                return 0;
            }

        }
        else {
            $logger->warn("File $filename does not exists");
            return 0;
        }
    }

}

sub _del_input_file {
    my $self = shift;
    return $self->_del_file( $self->get_input_file() );
}

sub _del_output_file {
    my $self = shift;
    return $self->_del_file( $self->get_output_file() );
}

=pod

=head1 SEE ALSO

=over

=item *

L<Moose::Role>

=item *

L<Siebel::Srvrmgr::Daemon>

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

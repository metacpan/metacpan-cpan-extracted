package Siebel::Srvrmgr::Daemon::Offline;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Offline - subclass that reads srvrmgr output from a file

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Daemon::Offline;
    my $daemon = Siebel::Srvrmgr::Daemon::Offline->new(
        {
            output_file => File::Spec->catfile('some', 'location', 'to', 'srvrmgr', 'output', 'file'), 
            field_delimiter => $field_delimiter;
        }
    );
    $daemon->run();


=head1 DESCRIPTION

This is a subclass of L<Siebel::Srvrmgr::Daemon> used to execute the C<srvrmgr> program in batch mode.

This class also uses the L<Siebel::Srvrmgr::Daemon::Cleanup> role.

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionFactory;
use Carp qw(longmess);
use File::Temp 0.2304 qw(:POSIX);
use Data::Dumper;
use Siebel::Srvrmgr;
use File::BOM 0.14 qw(:all);
use Try::Tiny 0.27;

our $VERSION = '0.29'; # VERSION

extends 'Siebel::Srvrmgr::Daemon';
with 'Siebel::Srvrmgr::Daemon::Cleanup';

=pod

=head1 ATTRIBUTES

=head2 output_file

A string representing the full pathname to the file that contains all output from srvrmgr program to be parsed.

Required during object creation, this is a read-write attribute.

=cut

has output_file => (
    isa      => 'Str',
    is       => 'rw',
    reader   => 'get_output_file',
    writer   => '_set_output_file',
    required => 1
);

=head2 field_delimiter

An optional, read-write parameter during object creation.

If the file defined by C<output_file> has fields separated by a delimiter, you must set this attribute or output parsing will fail.

If setup, expects a single character.

=cut

has field_delimiter => ( is => 'rw', isa => 'Chr', reader => 'get_field_del', writer => 'set_field_del' );

=head2 run

This method completely overrides the parent's L<Siebel::Srvrmgr::Daemon> method.

It will then parse the file defined in the C<output_file> attribute, executing any action defined during object creation.

=cut

override 'run' => sub {
    my ( $self ) = @_;
    my $logger = Siebel::Srvrmgr->gimme_logger( blessed($self) );
    $logger->info('Starting run method');
    my $parser = $self->create_parser($self->get_field_del);
    my $in;

    try {
        open_bom( $in, $self->get_output_file(), ':utf8' );
    }
    catch {
        $logger->logdie(
            'Cannot read ' . $self->get_output_file() . ': ' . $_ );
    };

# :TODO:22-09-2014 01:32:45:: this might be dangerous if the output is too large
    my @input_buffer = <$in>;
    close($in);

    if ( scalar(@input_buffer) >= 1 ) {
        $self->_check_error( \@input_buffer, 0 );
        $self->normalize_eol( \@input_buffer );

# since we should have all output, we parse everything first to call each action after
        $parser->parse( \@input_buffer );

        if ( $parser->has_tree() ) {
            my $total = $self->cmds_vs_tree( $parser->count_parsed() );

            if ( $logger->is_debug() ) {
                $logger->debug( 'Total number of parsed items = '
                      . $parser->count_parsed() );
            }

            $logger->logdie(
'Number of parsed nodes is different from the number of submitted commands'
            ) unless ( defined($total) );

            my $parsed_ref = $parser->get_parsed_tree();
            $parser->clear_parsed_tree();

            for ( my $i = 0 ; $i < $total ; $i++ ) {
                my $cmd    = ( @{ $self->get_commands() } )[$i];
                my $action = Siebel::Srvrmgr::Daemon::ActionFactory->create(
                    $cmd->get_action(),
                    {
                        parser => $parser,
                        params => $cmd->get_params()
                    }
                );
                $action->do_parsed( $parsed_ref->[$i] );
            }

        }
        else {
            $logger->logdie('Parser did not have a parsed tree after parsing');
        }

    }
    else {
        $logger->debug('buffer is empty');
    }

    $logger->info('Exiting run sub');
    return 1;
};

override _my_cleanup => sub {
    my $self = shift;
    return $self->_del_output_file();
};

=pod

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::Daemon::Command>

=item *

L<Siebel::Srvrmgr::Daemon::ActionFactory>

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<Siebel::Srvrmgr::Regexes>

=item *

L<POSIX>

=item *

L<Siebel::Srvrmgr::Daemon::Command>

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


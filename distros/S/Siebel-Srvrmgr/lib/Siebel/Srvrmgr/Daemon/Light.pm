package Siebel::Srvrmgr::Daemon::Light;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Light - subclass for running commmands with srvrmgr in batch mode

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Daemon::Light;

    my $daemon = Siebel::Srvrmgr::Daemon::Light->new(
        {
            time_zone   => 'America/Sao_Paulo',
            connection => $my_connection, 
			commands    => [
			        Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'load preferences',
                        action  => 'LoadPreferences'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp type',
                        action  => 'ListCompTypes',
                        params  => [$comp_types_file]
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp',
                        action  => 'ListComps',
                        params  => [$comps_file]
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp def',
                        action  => 'ListCompDef',
                        params  => [$comps_defs_file]
                    )
                ]
        }
    );
    $daemon->run;


=head1 DESCRIPTION

This is a subclass of L<Siebel::Srvrmgr::Daemon> used to execute the C<srvrmgr> program in batch mode. For a better understanding of what batch mode means, 
check out srvrmgr documentation.

This class is recomended for cases where it is not necessary to run several commmands through srvrmgr in a short period of time because in batch mode it will
connect to the Siebel Gateway, execute the commands configured and exit, avoiding keeping a connection opened for a long time. For UNIX-like OS, this class
would be a good choice for using with Inetd and Xinetd daemons.

This class is also highly recommended for OS plataforms like Microsoft Windows where IPC is not reliable enough, since this class uses C<system> instead of
L<IPC::Open3>.

Since version 0.21, this class does not overrides anymore the parent class method C<shift_command>. Some attention is required is this matter, since a instance of
Siebel::Srvrmgr::Daemon::Light will not maintain configuration previously loaded with C<load preferences> command. Be sure to maintain this command everytime you invoke
C<run> available in the C<commands> attribute.

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionFactory;
use Siebel::Srvrmgr::Daemon::Command;
use Carp qw(longmess);
use File::Temp 0.2304 qw(:POSIX);
use Data::Dumper;
use Siebel::Srvrmgr;
use File::BOM 0.14 qw(:all);
use Siebel::Srvrmgr::IPC qw(check_system);
use Try::Tiny 0.27;
our $VERSION = '0.29'; # VERSION

extends 'Siebel::Srvrmgr::Daemon';
with 'Siebel::Srvrmgr::Daemon::Cleanup';
with 'Siebel::Srvrmgr::Daemon::Connection';

=pod

=head1 ATTRIBUTES

=head2 output_file

A string that represents the "/o" command line parameter of srvrmgr. It is defined internally, so it is read-only.

=cut

has output_file => (
    isa    => 'Str',
    is     => 'ro',
    reader => 'get_output_file',
    writer => '_set_output_file'
);

=pod

=head2 input_file

A string that represents the "/i" command line parameter of srvrmgr. It is defined internally, so it is read-only.

=cut

has input_file => (
    isa    => 'Str',
    is     => 'ro',
    reader => 'get_input_file',
    writer => '_set_input_file'
);

=pod

=head1 METHODS

=head2 get_output_file

Returns the content of the C<output_file> attribute.

=head2 get_input_file

Returns the content of the C<input_file> attribute.

=head2 run

This method will try to connect to a Siebel Enterprise through C<srvrmgr> connection to submit the commands and respective actions defined during object creation.

Those operations will be executed in the sequence define until all were executed once.

Beware that Siebel::Srvrmgr::Daemon uses a B<single instance> of a L<Siebel::Srvrmgr::ListParser> class to process the parsing requests, so it is not possible
to execute L<Siebel::Srvrmgr::Daemon::Command> instances in parallel.

=cut

override 'run' => sub {
    my ( $self ) = @_;
    super();
    my $logger = Siebel::Srvrmgr->gimme_logger( blessed($self) );
    $logger->info('Starting run method');
    my $parser     = $self->create_parser( $self->get_conn->get_field_del );
    my $params_ref = $self->get_conn->get_params_pass;
    $self->_define_params($params_ref);

    if ( $logger->is_debug() ) {
        $logger->debug( 'Calling system with the following parameters: '
              . Dumper($params_ref) );
        $logger->debug(
            'Commands to be execute are: ' . Dumper( $self->get_commands() ) );
    }

    my $ret_code = system( @{$params_ref} );
    $self->_check_system( ${^CHILD_ERROR_NATIVE}, $ret_code, $? );
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

# since everything is read from a file, there is not way to identify if is a error from the file handler,
# so we will "turn off" warning checking
        $self->_check_error( \@input_buffer, 0 );
        $self->normalize_eol( \@input_buffer );

# since we should have all output, we parse everything first to call each action after
        $parser->parse( \@input_buffer );

        if ( $parser->has_tree() ) {
            my $total = $self->cmds_vs_tree( $parser->count_parsed() );

            if ( $logger->is_debug() ) {
                $logger->debug( 'Total number of parsed items = '
                      . $parser->count_parsed() );
                $logger->debug( 'Total number of submitted commands = '
                      . scalar( @{ $self->get_commands() } ) );
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

    $self->_set_child_runs( $self->get_child_runs() + 1 );
    $logger->debug( 'child_runs = ' . $self->get_child_runs() )
      if ( $logger->is_debug() );
    $logger->info('Exiting run sub');
    return 1;
};

override _my_cleanup => sub {
    my $self = shift;
    return $self->_del_input_file() && $self->_del_output_file();
};

override _setup_commands => sub {
    my $self = shift;
    super();
    my ( $fh, $input_file ) = tmpnam();

    foreach my $cmd ( @{ $self->get_commands() } ) {
        print $fh $cmd->get_command(), "\n";
    }

    close($fh);
    $self->_set_input_file($input_file);
};

override _define_params => sub {
    my ( $self, $params_ref ) = @_;
    super();
    $self->_set_output_file( scalar( tmpnam() ) );
    push(
        @{$params_ref},
        '/b', '/i', $self->get_input_file(),
        '/o', $self->get_output_file()
    );
    return $params_ref;
};

# :TODO:18-10-2013:arfreitas: this should be done by IPC.pm module?
sub _manual_check {
    my ( $self, $ret_code, $error_code ) = @_;
    my $logger = Siebel::Srvrmgr->gimme_logger( blessed($self) );

    if ( $ret_code == 0 ) {
        $logger->info(
            'Child process terminate successfully with return code = 0');
    }
    else {
        $logger->logdie( 'system failed to execute srvrmgr: ' . $error_code );
    }

}

sub _check_system {
    my ( $self, $child_error, $ret_code, $error_code ) = @_;

    my $logger = Siebel::Srvrmgr->gimme_logger( blessed($self) );
    my ( $message, $is_error ) = check_system($child_error);

    unless ( ( defined($message) ) and ( defined($is_error) ) ) {
        $self->_manual_check( $ret_code, $error_code );
    }
    else {

        if ( defined($is_error) ) {

            if ($is_error) {
                $logger->logdie($message);
            }
            else {
                $logger->info($message);
            }

        }
        else {
            $logger->info( $message . "Error code is $error_code" );
        }

    }

}

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


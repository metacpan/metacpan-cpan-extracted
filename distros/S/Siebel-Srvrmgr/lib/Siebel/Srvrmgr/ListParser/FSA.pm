package Siebel::Srvrmgr::ListParser::FSA;

use warnings;
use strict;
use Siebel::Srvrmgr;
use Siebel::Srvrmgr::Regexes qw(SRVRMGR_PROMPT prompt_slices);

use parent 'FSA::Rules';

our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::FSA - the FSA::Rules class specification for Siebel::Srvrmgr::ListParser

=head1 SYNOPSIS

	use FSA::Rules;
	my $fsa = Siebel::Srvrmgr::ListParser::FSA->get_fsa();
    # do something with $fsa

    # for getting a diagram exported in your currently directory with a onliner
    perl -MSiebel::Srvrmgr::ListParser::FSA -e "Siebel::Srvrmgr::ListParser::FSA->export_diagram"

=head1 DESCRIPTION

Siebel::Srvrmgr::ListParser::FSA subclasses the state machine implemented by L<FSA::Rules>, which is used by L<Siebel::Srvrmgr::ListParser> class.

This class also have a L<Log::Log4perl> instance built in.

=head1 EXPORTS

Nothing.

=head1 METHODS

=head2 export_diagram

Creates a PNG file with the state machine diagram in the current directory where the method was invoked.

=cut

sub export_diagram {

    my $fsa = get_fsa();

    my $graph = $fsa->graph( layout => 'neato', overlap => 'false' );
    $graph->as_png('pretty.png');

    return 1;

}

=pod

=head2 new

Returns the state machine object defined for usage with a L<Siebel::Srvrmgr::ListParser> instance.

Expects as parameter a hash table reference containing all the commands alias as keys and their respective regular expressions to detect
state change as values. See L<Siebel::Srvrmgr::ListParser::OutputFactory> C<get_mapping> method for details.

=cut

sub new {

    my $class   = shift;
    my $map_ref = shift;

    my $logger =
      Siebel::Srvrmgr->gimme_logger('Siebel::Srvrmgr::ListParser::FSA');

    $logger->logdie('the output type mapping reference received is not valid')
      unless ( ( defined($map_ref) ) and ( ref($map_ref) eq 'HASH' ) );

    my %params = (
        done => sub {

            my $self = shift;

            my $curr_line = shift( @{ $self->{data} } );

            if ( defined($curr_line) ) {

                if ( defined( $self->notes('last_command') )
                    and ( $self->notes('last_command') eq 'exit' ) )
                {

                    return 1;

                }
                else {

                    $self->{curr_line} = $curr_line;
                    return 0;

                }

            }
            else {    # no more lines to process

                return 1;

            }

        }
    );

    my $self = $class->SUPER::new(
        \%params,
        no_data => {
            do => sub {

                my $logger =
                  Siebel::Srvrmgr->gimme_logger('Siebel::Srvrmgr::ListParser');

                if ( $logger->is_debug() ) {

                    $logger->debug('Searching for useful data');

                }

            },
            rules => [
                greetings => sub {

                    my $state = shift;

                    my $line = $state->machine()->{curr_line};

                    if ( defined($line) ) {

                        return ( $line =~ $map_ref->{greetings} );

                    }
                    else {

                        return 0;

                    }

                },
                command_submission => sub {

                    my $state = shift;
                    my $line  = $state->machine()->{curr_line};

                    if ( defined($line) ) {

                        return ( $line =~ SRVRMGR_PROMPT );

                    }
                    else {

                        return 0;

                    }

                },
            ],
            message => 'Line read'

        },
        greetings => {
            label    => 'greetings message from srvrmgr',
            on_enter => sub {

                my $state = shift;
                $state->notes( is_cmd_changed     => 0 );
                $state->notes( is_data_wanted     => 1 );
                $state->notes( 'create_greetings' => 1 )
                  unless ( $state->notes('greetings_created') );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    my $line  = $state->machine()->{curr_line};
                    return ( $line =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        end => {
            do => sub {

                my $logger =
                  Siebel::Srvrmgr->gimme_logger('Siebel::Srvrmgr::ListParser');
                $logger->debug('Enterprise says bye-bye');

            },
            rules => [
                no_data => sub {
                    return 1;
                }
            ],
            message => 'EOF'
        },
        list_comp => {
            label    => 'parses output from a list comp command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        list_comp_types => {
            label    => 'parses output from a list comp types command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        list_params => {
            label    => 'parses output from a list params command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        list_comp_def => {
            label    => 'parses output from a list comp def command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        list_tasks => {
            label    => 'parses output from a list tasks command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        list_procs => {
            label    => 'parses output from a list procs command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        list_servers => {
            label    => 'parses output from a list servers command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        list_sessions => {
            label    => 'parses output from a list sessions command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        set_delimiter => {
            label    => 'parses output (?) from set delimiter command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        load_preferences => {
            label    => 'parses output from a load preferences command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->machine->{curr_line} =~ SRVRMGR_PROMPT );

                },
            ],
            message => 'prompt found'
        },
        command_submission => {
            do => sub {

                my $state = shift;

                my $logger =
                  Siebel::Srvrmgr->gimme_logger('Siebel::Srvrmgr::ListParser');
                if ( $logger->is_debug() ) {

                    my $line = $state->notes('line');
                    $logger->debug( 'command_submission got [' . $line . ']' )
                      if ( defined($line) );

                }

                $state->notes( found_prompt => 1 );
                my ( $server, $cmd ) =
                  prompt_slices( $state->machine->{curr_line} );

                if ( ( defined($cmd) ) and ( $cmd ne '' ) ) {
                    $logger->debug("last_command set with '$cmd'")
                      if $logger->is_debug();
                    $state->notes( last_command   => $cmd );
                    $state->notes( is_cmd_changed => 1 );
                }
                else {

                    if ( $logger->is_debug() ) {
                        $logger->debug('got prompt, but no command submitted');
                    }

                    $state->notes( last_command   => '' );
                    $state->notes( is_cmd_changed => 1 );
                }

            },
            rules => [
                set_delimiter => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~
                        $map_ref->{set_delimiter} )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_comp => sub {

                    my $state = shift;

                    if (
                        $state->notes('last_command') =~ $map_ref->{list_comp} )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_comp_types => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~
                        $map_ref->{list_comp_types} )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_params => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~
                        $map_ref->{list_params} )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_tasks => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~
                        $map_ref->{list_tasks} )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_procs => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~
                        $map_ref->{list_procs} )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_servers => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~
                        $map_ref->{list_servers} )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_sessions => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~
                        $map_ref->{list_sessions} )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_comp_def => sub {
                    my $state = shift;

                    if ( $state->notes('last_command') =~
                        $map_ref->{list_comp_def} )
                    {
                        return 1;
                    }
                    else {
                        return 0;
                    }
                },
                load_preferences => sub {
                    my $state = shift;

                    if ( $state->notes('last_command') =~
                        $map_ref->{load_preferences} )
                    {
                        return 1;
                    }
                    else {
                        return 0;
                    }
                },
                no_data => sub {
                    my $state = shift;

                    if ( $state->notes('last_command') eq '' ) {
                        return 1;
                    }
                    else {
                        return 0;
                    }

                },

                # add other possibilities here of list commands
            ],
            message => 'command submitted'
        }
    );

    $self->{data}      = undef;
    $self->{curr_line} = undef;
    return $self;
}

=head2 set_data

Set the array reference of the data to be parsed by this object.

=cut

sub set_data {
    my $self = shift;
    $self->{data} = shift;
}

=head2 get_curr_line

Returns a string, the current line being processed by this object.

=cut

sub get_curr_line {

    return shift->{curr_line};

}

1;

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<FSA::Rules>

=back

=head1 CAVEATS

This class has some problems, most due the API of L<FSA::Rules>: since the state machine is a group of references to subroutines, it holds references
to L<Siebel::Srvrmgr::ListParser>, which basically causes circular references between the two classes.

There is some workaround to the caused memory leaks due this configuration, but in future releases L<FSA::Rules> may be replaced to something else.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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

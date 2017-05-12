package Siebel::Srvrmgr::ListParser;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser - state model parser to idenfity which output type was read

=head1 SYNOPSIS

    use Siebel::Srvrmgr::ListParser;
    my $parser = Siebel::Srvrmgr::ListParser->new({ prompt_regex => $some_prompt });

=cut

use Moose;
use Siebel::Srvrmgr::ListParser::OutputFactory;
use Siebel::Srvrmgr::ListParser::Buffer;
use Siebel::Srvrmgr;
use Siebel::Srvrmgr::ListParser::FSA;
use namespace::autoclean 0.13;
use Carp;
use Siebel::Srvrmgr::Types;
use String::BOM 0.3 qw(string_has_bom strip_bom_from_string);

our $VERSION = '0.29'; # VERSION

=pod

=head1 DESCRIPTION

Siebel::Srvrmgr::ListParser is a state machine parser created to parse output of "list" commands executed through C<srvrmgr> program.

The parser can identify different types of commands and their outputs from a buffer given as parameter to the module. For each 
type of output identified an L<Siebel::Srvrmgr::ListParser::Buffer> object will be created, identifying which type of command
was executed and the raw information from it.

At the end of information read from the buffer, this class will call L<Siebel::Srvrmgr::ListParser::OutputFactory> to create
specific L<Siebel::Srvrmgr::ListParser::Output> objects based on the identified type of Buffer object. Each of this objects will
parse the raw output and populate attributes based on this information. After this is easier to obtain the information from
those subclasses of L<Siebel::Srvrmgr::ListParser::Output>.

Siebel::Srvrmgr::ListParser expects to receive output from C<srvrmgr> program in an specific format and is able to idenfity a
limited number of commands and their outputs, raising an exception when those types cannot be identified. See subclasses
of L<Siebel::Srvrmgr::ListParser::Output> to see which classes/types are available.

Logging of this class can be enabled by using L<Siebel::Srvrmgr> logging feature.

=head2 Features

Currently, this class can parse the output of the following Siebel Server Manager commands:

=over

=item *

load preferences

=item *

list comp

=item *

list compdef

=item *

list comp type

=item *

list params

=item *

list server

=item *

list session

=item *

list task

=back

Also the initial text after connecting to Server Manager can be parsed.

=head1 ATTRIBUTES

=head2 parsed_tree

An array reference of parsed data. Each index should be a reference to another data extructure, most probably an hash 
reference, with parsed data related from one line read from output of C<srvrmgr> program.

This is an read-only attribute.

=cut

has 'parsed_tree' => (
    is     => 'ro',
    isa    => 'ArrayRef',
    reader => 'get_parsed_tree',
    writer => '_set_parsed_tree'
);

=pod

=head2 has_tree

A boolean value that identifies if the ListParser object has a parsed tree or not.

=cut

has 'has_tree' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    writer  => '_set_has_tree',
    reader  => 'has_tree'
);

=pod

=head2 last_command

A string with the last command identified by the parser. It is used for several things, including changes in the state model machine.

This is a read-only attribute.

=cut

has 'last_command' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_last_command',
    writer  => 'set_last_command',
    default => '',
    trigger => \&_toggle_cmd_changed
);

=pod

=head2 is_cmd_changed

A boolean value that identified when the last_command attribute has been changed (i.e another command was identified by the parser).

=cut

has 'is_cmd_changed' => ( isa => 'Bool', is => 'rw', default => 0 );

=pod

=head2 buffer

An array reference with each one of the indexes being a C<Siebel::Srvrmgr::ListParser::Buffer> object.

=cut

has 'buffer' => (
    is      => 'rw',
    isa     => 'ArrayRef[Siebel::Srvrmgr::ListParser::Buffer]',
    reader  => 'get_buffer',
    writer  => '_set_buffer',
    default => sub { return [] }
);

=pod

=head2 enterprise

A reference to a L<Siebel::Srvrmgr::ListParser::Output::Greetings>. It is defined during initial parsing (can be available or not).

This object has some details about the enterprise connected. Check the related Pod for more information.

=cut

has 'enterprise' => (
    is     => 'ro',
    isa    => 'Siebel::Srvrmgr::ListParser::Output::Enterprise',
    reader => 'get_enterprise',
    writer => '_set_enterprise'
);

=pod

=head2 fsa

=cut

has 'fsa' => (
    is     => 'ro',
    isa    => 'Siebel::Srvrmgr::ListParser::FSA',
    reader => 'get_fsa',
    writer => '_set_fsa',
);

=pod

=head2 clear_raw

=cut

has clear_raw => (
    is      => 'rw',
    isa     => 'Bool',
    reader  => 'clear_raw',
    writer  => 'set_clear_raw',
    default => 1
);

has field_delimiter => ( is => 'ro', isa => 'Chr', reader => 'get_field_del' );

=pod

=head1 METHODS

=head2 is_cmd_changed

Sets the boolean attribute with the same name. If no parameter is given, returns the value stored in the C<is_cmd_changed> attribute. If a parameter is given, 
expects to received true (1) or false (0), otherwise it will return an exception.

=head2 get_parsed_tree

Returns the parsed_tree attribute.

=head2 get_prompt_regex

Returns the regular expression reference from the prompt_regex attribute.

=head2 set_prompt_regex

Sets the prompt_regex attribute. Expects an regular expression reference as parameter.

=head2 get_hello_regex

Returns the regular expression reference from the hello_regex attribute.

=head2 set_hello_regex

Sets the hello_regex attribute. Expects an regular expression reference as parameter.

=head2 get_last_command

Returns an string of the last command read by the parser.

=head2 has_tree

Returns a boolean value (1 for true, 0 for false) if the parser has or not a parsed tree.

=head2 set_last_command

Set the last command found in the parser received data. It also triggers that the command has changed (see method is_cmd_changed).

=cut

sub _toggle_cmd_changed {
    my ( $self, $new_value, $old_value ) = @_;
    $self->is_cmd_changed(1);
}

=pod

=head2 BUILD

Automatically defines the state machine object based on L<Siebel::Srvrmgr::ListParser::FSA>.

=cut

sub BUILD {
    my $self     = shift;
    my $copy_ref = Siebel::Srvrmgr::ListParser::OutputFactory->get_mapping();

    foreach my $cmd_alias ( keys( %{$copy_ref} ) ) {
        my $regex = $copy_ref->{$cmd_alias}->[1];
        $copy_ref->{$cmd_alias} = $regex;
    }

    $self->_set_fsa( Siebel::Srvrmgr::ListParser::FSA->new($copy_ref) );
}

=pod

=head2 set_buffer

Sets the buffer attribute, inserting new C<Siebel::Srvrmgr::ListParser::Buffer> objects into the array reference as necessary.

Expects an instance of a L<FSA::State> class as parameter (obligatory parameter).

=cut

sub set_buffer {
    my ( $self, $type, $line ) = @_;
    my $logger = Siebel::Srvrmgr->gimme_logger( blessed($self) );

    if ( defined($line) ) {
        my $buffer_ref = $self->get_buffer();

        # already has something, get the last one
        if ( scalar( @{$buffer_ref} ) >= 1 ) {
            $logger->debug('I already have data buffered');
            my $last_buffer = $buffer_ref->[ $#{$buffer_ref} ];
            $logger->debug(
                'Command is the same, appending data to last buffer');

            if ( $last_buffer->get_type() eq $type ) {

                if ( $line ne '' ) {
                    $last_buffer->set_content($line);
                }
                else {
                    $logger->debug(
'Ignoring first blank line right after command submission'
                    );
                }

            }
            else {

                if ( $logger->is_fatal() ) {

                    $logger->fatal(
                        'Command has not changed but type of output has (got '
                          . $type
                          . ' instead of '
                          . $last_buffer->get_type()
                          . '). Data was ignored' );

                }

            }

        }
        else {
            $logger->fatal(
'buffer is still uninitialized even though _create_buffer should already taken care of it'
            );
        }

    }
    else {
        $logger->warn('Undefined content from state received');
    }

}

# adds a new buffer to the buffer attribute
sub _create_buffer {
    my ( $self, $type ) = @_;
    my $logger = Siebel::Srvrmgr->gimme_logger( blessed($self) );

    if ( Siebel::Srvrmgr::ListParser::OutputFactory->can_create($type) ) {
        my $buffer = Siebel::Srvrmgr::ListParser::Buffer->new(
            {
                type     => $type,
                cmd_line => $self->get_last_command()
            }
        );
        push( @{ $self->get_buffer() }, $buffer );

        if ( $logger->is_debug ) {
            $logger->debug("Created buffer for $type output");
        }

    }
    else {
        $logger->fatal(
"Siebel::Srvrmgr::ListParser::OutputFactory cannot create instances of $type type"
        );
    }
}

=pod

=head2 clear_buffer

Removes the array reference from the buffer attribute and associates a new one with an empty array. This should be used for cleanup purpouses or attemp to free memory.

=cut

sub clear_buffer {
    my $self = shift;
    $self->_set_buffer( [] );
}

=pod

=head2 count_parsed

Returns an integer with the total number of objects available in the parsed_tree attribute.

=cut

sub count_parsed {
    my $self = shift;
    return scalar( @{ $self->get_parsed_tree() } );
}

=pod

=head2 clear_parsed_tree

Removes the reference on parsed_tree attribute. Also, sets has_tree attribute to false.

=cut

sub clear_parsed_tree {
    my $self = shift;
    $self->_set_has_tree(0);
    $self->_set_parsed_tree( [] );
}

=pod

=head2 set_parsed_tree

Sets the parsed_tree attribute, adding references as necessary. Also sets the has_tree attribute to true.

This method should not be called directly unless you know what you're doing. See C<append_output> method.

=cut

sub set_parsed_tree {
    my ( $self, $output ) = @_;

    if ( $self->has_tree() ) {
        my $old_parsed_tree = $self->get_parsed_tree();
        push( @{$old_parsed_tree}, $output );
        $self->_set_parsed_tree($old_parsed_tree);
    }
    else {
        $self->_set_parsed_tree( [$output] );
    }

    $self->_set_has_tree(1);
}

=pod

=head2 append_output

Appends an object to an existing parsed tree.

Can use an optional parameter as L<Siebel::Srvrmgr::ListParser::Buffer> instance, othewise it will use the returned value from C<get_buffer> method.

It uses L<Siebel::Srvrmgr::ListParser::OutputFactory> to create the proper 
L<Siebel::Srvrmgr::ListParser::Output> object based on the L<Siebel::Srvrmgr::ListParser::Buffer> type.

If the item received as parameter is a L<Siebel::Srvrmgr::ListParser::Output::Greetings> instance, it will be assigned to the C<enterprise>
attribute instead of being added to the C<parsed_tree> attribute.

=cut

sub append_output {
    my ( $self, $buffer ) = @_;

    if ( defined($buffer) ) {
        my $output = Siebel::Srvrmgr::ListParser::OutputFactory->build(
            $buffer->get_type(),
            {
                data_type => $buffer->get_type(),
                raw_data  => $buffer->get_content(),
                cmd_line  => $buffer->get_cmd_line()
            },
            $self->get_field_del()
        );

        if ( $output->isa('Siebel::Srvrmgr::ListParser::Output::Enterprise') ) {
            $self->_set_enterprise($output);
        }
        else {
            $self->set_parsed_tree($output);
        }

    }
    else {
# :WORKAROUND:21/08/2013 16:29:35:: not very elegant, but should speed up thing for avoid calling method resolution multiple times

        my $buffer_ref = $self->get_buffer();

        foreach my $buffer ( @{$buffer_ref} ) {
            my $output = Siebel::Srvrmgr::ListParser::OutputFactory->build(
                $buffer->get_type(),
                {
                    data_type => $buffer->get_type(),
                    raw_data  => $buffer->get_content,
                    cmd_line  => $buffer->get_cmd_line()
                },
                $self->get_field_del()
            );

            if (
                $output->isa('Siebel::Srvrmgr::ListParser::Output::Enterprise')
              )
            {
                $self->_set_enterprise($output);
            }
            else {
                $self->set_parsed_tree($output);
            }

        }

    }

    return 1;

}

=pod

=head2 parse

Parses one or more commands output executed through C<srvrmgr> program.

Expects as parameter an array reference with the output of C<srvrmgr>, including the command executed. The array references indexes values should be rid off any
EOL character.

It will create an L<FSA::Rules> object to parse the given array reference, calling C<append_output> method for each L<Siebel::Srvrmgr::ListParser::Buffer> object
found.

This method will raise an exception if a given output cannot be identified by the parser.

=cut

sub parse {
    my ( $self, $data_ref ) = @_;
    my $logger = Siebel::Srvrmgr->gimme_logger( blessed($self) );
    $logger->logdie('Received an invalid buffer as parameter')
      unless ( ( defined($data_ref) )
        and ( ref($data_ref) eq 'ARRAY' )
        and ( scalar( @{$data_ref} ) > 0 ) );

    if ( string_has_bom( $data_ref->[0] ) ) {
        $data_ref->[0] = strip_bom_from_string( $data_ref->[0] );
    }

    $self->get_fsa->set_data($data_ref);
    $self->get_fsa->start() unless ( $self->get_fsa()->curr_state() );
    $data_ref = undef;
    my $found_prompt = 0;
    my $prev_state_name;

    do {

        my $state = $self->get_fsa->try_switch();

        if ( defined($state) ) {
            $prev_state_name = $state->name;
            my $curr_msg = $self->get_fsa()->get_curr_line();
            $found_prompt = $state->notes('found_prompt');

# :TODO:03-10-2013:arfreitas: find a way to keep circular references between the two objects to avoid
# checking state change everytime with is_cmd_changed

          SWITCH: {

# :WORKAROUND:03-10-2013:arfreitas: command_submission defines is_cmd_changed but it is not a
# Siebel::Srvrmgr::ListParser::Output subclass, so it's not worth to create a buffer object for it and discard later.
# Anyway, is expected that after a command is submitted, the next message is the output from it and it needs
# a buffer to be stored
                if ( $self->get_fsa->prev_state()->name() eq
                    'command_submission' )
                {

                    $self->_create_buffer( $state->name() );
                    last SWITCH;
                }

                if ( $state->notes('is_cmd_changed') ) {

                    $logger->debug( 'calling set_last_command with ['
                          . $state->notes('last_command')
                          . ']' )
                      if ( $logger->is_debug() );

                    $self->set_last_command( $state->notes('last_command') );
                    last SWITCH;

                }

                if ( $state->notes('create_greetings') ) {

                    $self->_create_buffer( $state->name );
                    $state->notes( create_greetings  => 0 );
                    $state->notes( greetings_created => 1 );
                    last SWITCH;

                }

            }

            if ( $state->notes('is_data_wanted') ) {

                $logger->debug( 'calling set_buffer with ['
                      . $state->name() . '], ['
                      . $curr_msg
                      . ']' )
                  if ( $logger->is_debug() );
                $self->set_buffer( $state->name(), $curr_msg );

            }

        }
        else {    # state hasn't changed, but let's keep getting other lines

            $self->set_buffer( $prev_state_name,
                $self->get_fsa()->get_curr_line() );

        }

    } until ( $self->get_fsa->done() );

    $self->append_output();
    $self->get_fsa->reset();

# :WORKAROUND:21/06/2013 20:36:08:: if parse method is called twice, without calling clear_buffer, the buffer will be reused
# and the returned data will be invalid due removal of the last three lines by Siebel::Srvrmgr::ListParser::Output->parse
# This should help with memory utilization too
    $self->clear_buffer();

    confess
      'Received an invalid buffer to process: could not find the command prompt'
      unless ($found_prompt);

    return 1;

}

=head2 DEMOLISH

Due issues with memory leak and garbage collection, DEMOLISH was implemented to call additional methods from the API to clean buffer and parsed tree
data.

=cut

sub DEMOLISH {
    my $self = shift;
    $self->{fsa} = undef;
    $self->clear_buffer();
    $self->clear_parsed_tree();
}

=pod

=head1 CAVEATS

Checkout the POD for the L<Siebel::Srvrmgr::ListParser::Output> objects to see details about which kind of output is expected if you're getting errors from the parser. There 
are details regarding how the settings of srvrmgr are expect for output of list commands.

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<FSA::Rules>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Siebel::Srvrmgr::ListParser::OutputFactory>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Greetings>

=item *

L<Siebel::Srvrmgr::ListParser::Buffer>

=item *

L<Siebel::Srvrmgr::Regexes>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

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

1;

package Siebel::Srvrmgr::Daemon::Condition;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Condition - object that checks which conditions should keep a Siebel::Srvrmgr::Daemon running

=head1 SYNOPSIS

    my $condition = Siebel::Srvrmgr::Daemon::Condition->new(
        {
			total_commands => 10
        }
    );

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
our $VERSION = '0.29'; # VERSION

=pod

=head1 DESCRIPTION

Siebel::Srvrmgr::Daemon::Condition class has one function: define if the L<Siebel::Srvrmgr::Daemon> object instance should continue it's loop execution or stop.

There are several checkings that are carried (for example, if the loop must be infinite or if the stack of commands is finished) and the object of this class
will return true (1) or false (0) depending on the context.

Since this class was used exclusively to control de loop of execution, it does not make much sense to use it outside of L<Siebel::Srvrmgr::Daemon> class.

There are more status that this class will keep, please check the attributes and methods.

=head1 ATTRIBUTES

=head2 max_cmd_idx

Maximum command index. This is an integer attribute that identifies the last command from the commands stack (of L<Siebel::Srvrmgr::Daemon>).

It's automatically set to C<total_commands> - 1 right after object creation.

=cut

has max_cmd_idx =>
  ( isa => 'Int', is => 'ro', required => 0, builder => '_set_max', lazy => 1 );

=pod

=head2 total_commands

This is an integer that tells the total amount of commands available for execution. This class will keep track of the executed commands and the result
of it will be part of the definition of the result returned from the method C<check> and restart, if necessary, the stack of commands to be executed.

This attribute is required during object creation.

=cut

has total_commands =>
  ( isa => 'Int', is => 'ro', required => 1, writer => '_set_total_commands' );

=pod

=head2 cmd_counter

An integer that keeps tracking of the current command being executed, always starting from zero.

This attribute has a default value of zero.

=cut

has cmd_counter => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
    writer   => '_set_cmd_counter',
    reader   => 'get_cmd_counter',
    default  => 0
);

=pod

=head2 output_used

An boolean that identifies if the last executed command output was used or not.

=cut

has output_used => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
    reader  => 'is_output_used',
    writer  => '_set_output_used'
);

=pod

=head2 cmd_sent

An boolean that identifies if the current command to be executed was truly submitted to C<srvrmgr> program or not.

=cut

has cmd_sent => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
    reader  => 'is_cmd_sent',
    writer  => 'set_cmd_sent'
);

=pod

=head1 METHODS

=head2 get_cmd_counter

Returns the content of the attribute C<cmd_counter> as an integer.

=head2 is_output_used

Returns a true or false based on the content of C<output_used> attribute.

=head2 set_output_used

Sets the C<output_used> attribute. Expects a 1 (true) or 0 (false) value as parameter.

If the parameter is true then the attribute C<cmd_sent> will be set to false (a new command will need to be submitted).

=cut

sub set_output_used {

    my $self  = shift;
    my $value = shift;

    $self->_set_output_used($value);

    if ($value) {

# if there is a single command to execute, there is no reason to reset the cmd_sent attribute
        $self->set_cmd_sent(0) unless ( $self->max_cmd_idx() == 0 );

    }

}

=pod

=head2 is_cmd_sent

Returns a true or false based on the content of C<cmd_sent> attribute.

=head2 set_cmd_sent

Sets the attribute C<cmd_sent>. Expects true (1) or false (0) as value.

=head2 max_cmd_idx

Returns an integer based on the content of C<max_cmd_idx> attribute.

=head2 reduce_total_cmd

This method subtracts one from the C<total_cmd> attribute.

=cut

sub reduce_total_cmd {

    my $self = shift;

    $self->_set_total_commands( $self->total_commands() - 1 );

}

sub _set_max {

    my $self = shift;

    if ( $self->total_commands() >= 1 ) {

        $self->{max_cmd_idx} = $self->total_commands() - 1;

    }
    else {

        warn "total_commands has zero commands?";

    }

}

=pod

=head2 check

This method will check various conditions and depending on them will return true (1) or false (0).

The conditions that are taken in consideration:

=over 3

=item *

The execution loop is infinite or not.

=item *

There is more items to execute from the commands/actions stack.

=item *

The output from a previous executed command was used or not.

=back

=cut

sub check {

    my $self = shift;

    if ( ( $self->get_cmd_counter() == $self->max_cmd_idx() )
        and $self->is_output_used() )
    {

        return 0;

    }
    elsif ( $self->total_commands() > 0 ) {

        # if at least one command to execute
        if ( $self->total_commands() == 1 ) {

            $self->reduce_total_cmd();
            return 1;

            # or there are more commands to execute
        }
        elsif ( ( $self->total_commands() > 1 )
            and ( $self->get_cmd_counter() <= ( $self->max_cmd_idx() ) ) )
        {

            return 1;

        }
        else {

            return 0;

        }

    }
    else {

        return 0;

    }

}

=pod

=head2 add_cmd_counter

Increments by one the C<cmd_counter> attribute, if possible.

It will check if the C<cmd_counter> after incrementing will not pass the C<max_cmd_idx> attribute. In this case, the method will
not change C<cmd_counter> value and will raise an exception.

=cut

sub add_cmd_counter {

    my $self = shift;

    if ( ( $self->get_cmd_counter() + 1 ) <= ( $self->max_cmd_idx() ) ) {

        $self->_set_cmd_counter( $self->get_cmd_counter() + 1 );

    }
    else {

        die "Can't increment counter because maximum index of command is "
          . $self->max_cmd_idx() . "\n";

    }

}

=pod

=head2 can_increment

This method checks if the C<cmd_counter> can be increment or not, returning true (1) or false (0) depending
on the conditions evaluated.

=cut

sub can_increment {

    my $self = shift;

    if (    ( $self->is_output_used() )
        and ( ( $self->get_cmd_counter() + 1 ) <= $self->max_cmd_idx() ) )
    {

        return 1;

    }
    else {

        return 0;

    }

}

=pod

=head2 is_last_cmd

This method returns true (1) if the C<cmd_counter> holds the last command index from the command stack, otherwise it
returns false.

=cut

sub is_last_cmd {

    my $self = shift;

    if ( $self->get_cmd_counter() == $self->max_cmd_idx() ) {

        if ( ( $self->max_cmd_idx() == 1 ) and ( not( $self->is_cmd_sent() ) ) )
        {

            return 1;

        }
        elsif ( $self->is_output_used() ) {

            return 1;

        }
        else {

            return 0;

        }

    }
    else {

        return 0;

    }

}

=pod

=head2 reset_cmd_counter

Resets the C<cmd_counter> attributing setting it to zero. This is useful specially if the loop of execution is infinite (thus the command stack must be restarted).

=cut

sub reset_cmd_counter {

    my $self = shift;

    $self->_set_cmd_counter(0);

    return 1;

}

=pod

=head1 CAVEATS

This class is becoming more and more complex due the several conditions that need to be evaluated for defining if the L<Siebel::Srvrmgr::Daemon> should still
execute the C<run> method or not. This probably should be replaced by a state machine.

=head1 SEE ALSO

=over

=item *

L<Moose>

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

__PACKAGE__->meta->make_immutable;

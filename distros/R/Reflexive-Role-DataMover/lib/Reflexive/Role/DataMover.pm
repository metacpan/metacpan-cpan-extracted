package Reflexive::Role::DataMover;
{
  $Reflexive::Role::DataMover::VERSION = '1.122130';
}

#ABSTRACT: Provides a composable behavior for moving data between Reflex::Streams

use Reflex::Role;
use MooseX::Types::Moose(':all');





attribute_parameter input   => "input";


attribute_parameter output  => "output";


callback_parameter cb_input_data    => qw/ on input data /;


callback_parameter cb_input_error   => qw/ on input error /;


callback_parameter cb_input_close   => qw/ on input close /;


callback_parameter cb_input_stop    => qw/ on input stop /;


callback_parameter cb_output_error  => qw/ on output error /;


callback_parameter cb_output_data   => qw/ on output data /;



method_parameter ev_input_error  => qw/ _ input error /;


method_parameter ev_output_data  => qw/ _ output data /;


method_parameter ev_output_error => qw/ _ output error /;


method_parameter method_clear_input     => qw/ clear input _/;


method_parameter method_clear_output    => qw/ clear output _/;



parameter internal_flush_method =>
(
    isa => Str,
    default => '_do_handle_flush',
);

role
{
    use Reflex::Callbacks(':all');
    use MooseX::Types::Structured(':all');
    use MooseX::Params::Validate;
    use namespace::autoclean;

    with 'Reflex::Role::Collectible';
    my $p = shift;





    requires
    (
        $p->input,
        $p->output,
        $p->method_clear_input,
        $p->method_clear_output,
    );




    make_terminal_emitter $p->cb_input_error => $p->ev_input_error;



    make_terminal_emitter $p->cb_output_error => $p->ev_output_error;



    make_emitter $p->cb_output_data => $p->ev_output_data;

    method BUILD => sub { };


    after BUILD => sub
    {
        my ($self) = @_;

        $self->watch
        (
            $self->${\$p->input},
            (
                'data'      => cb_method($self, $p->cb_input_data),
                'closed'    => cb_method($self, $p->cb_input_close),
                'stopped'   => cb_method($self, $p->cb_input_stop),
                'error'     => cb_method($self, $p->cb_input_error),
            )
        );

        $self->watch
        (
            $self->${\$p->output},
            (
                'error'     => cb_method($self, $p->cb_output_error),
            )
        );

        $self->watch
        (
            $self,
            (
                $p->ev_output_data => cb_method($self, $p->cb_output_data),
                'stopped' => cb_method($self, '_clean_up'),
            )
        );
    };


    method ${\$p->cb_input_close} => sub
    {
        my $self = shift;
        $self->${\$p->input}->stop();
    };


    method ${\$p->cb_input_stop} => sub
    {
        my $self = shift;
        $self->ignore($self->${\$p->input});
        $self->${\$p->method_clear_input}();
        $self->done_writing();
    };


    method ${\$p->cb_input_data} => sub
    {
        my ($self, $data) = pos_validated_list
        (
            \@_,
            { does => 'Reflexive::Role::DataMover' },
            { isa => 'Reflex::Event' },
        );

        $self->${\$p->cb_output_data}($data);
    };


    method ${\$p->cb_output_data} => sub
    {
        my ($self, $args) = pos_validated_list
        (
            \@_,
            { does => 'Reflexive::Role::DataMover' },
            { isa => 'Reflex::Event::Octets' },
        );

        $self->${\$p->output}->put($args->octets)
    };


    method done_writing => sub
    {
        my $self = shift;
        1 while $self->${\$p->output}->${\$p->internal_flush_method}();
        $self->ignore($self->${\$p->output});
        $self->${\$p->method_clear_output}();
        $self->stopped();
    };


    method _clean_up => sub
    {
        my $self = shift;
        $self->ignore($self);
    };
};

1;


=pod

=head1 NAME

Reflexive::Role::DataMover - Provides a composable behavior for moving data between Reflex::Streams

=head1 VERSION

version 1.122130

=head1 SYNOPSIS

    package MyDataMover;
    use Moose;

    extends 'Reflex::Base';

    foreach my $attr (qw/input output/)
    {
        has $attr =>
        (
            is => 'ro',
            does => 'Reflex::Role::Streaming',
            clearer => 'clear_'.$attr,
            predicate => 'has_'.$attr,
        );
    }

    with 'Reflexive::Role::DataMover';

=head1 DESCRIPTION

Reflexive::Role::DataMover is a composable behavior that provides functionality
for streaming data between two Reflex::Streams. It is a parameterized role, so
there is tons of configurability available, but the defaults should be sane
enough to avoid using most of it. See L</ROLE_PARAMTERS> for details.

Essentially what this role does is upon BUILD it watches the events out of each
of the handles. This kickstarts reading from the "input" handle. on_input_data
is setup to respond to the "data" event. This in turn emits a "output_data"
event which is watched internally, to then put() the data into the other
stream. When the input stream reached EOF, all of the clean up happens which
includes manually flushing the output handle to make sure everything is written
out. Then all of the events are ignored, the streams cleared, and the instance
implodes allowing the Collection container to reap it (if it is stored inside
one).

This role consumes the Collectible role and so emits a stopped event when
everything is said and done.

=head1 ROLE_PARAMETERS

=head2 input

    default: input

input contains the name of the attribute holding the input stream

=head2 output

    default: output

output contains the name of the attribute holding the output stream

=head2 cb_input_data

    default: on_input_data

cb_input_data contains the name of the callback intended to handle the data
event emitted from the input handle.

=head2 cb_input_error

    default: on_input_error

cb_input_error contains the name of the callback intended to handle the error
event emitted from the input handle.

=head2 cb_input_close

    default: on_input_close

cb_input_close contains the name of the callback intended to handle the closed
event emitted from the input handle.

=head2 cb_input_stop

    default: on_input_stop

cb_input_stop contains the name of the callback intended to handle the stopped
event emitted from the input handle.

=head2 cb_output_error

    default: on_output_error

cb_output_error contaouts the name of the callback outtended to handle the error
event emitted from the output handle.

=head2 cb_output_data

    default: on_output_data

cb_output_data contaouts the name of the callback outtended to handle the data
event emitted when writing data to the output handle.

=head2 ev_input_error

    default: input_error

ev_input_error contains the actual name of the event emitted from the input
stream on error.

=head2 ev_output_data

    default: output_data

ev_output_data contains the actual name of the event emitted when writing data
to the output stream.

=head2 ev_output_error

    default: output_error

ev_output_error contains the actual name of the event emitted from the output
stream on error.

=head2 method_clear_input

    default: clear_input

method_clear_input contains the name of the clearer method on the input stream
attribute.

=head2 method_clear_output

    default: clear_output

method_clear_output contains the name of the clearer method on the output stream
attribute.

=head2 internal_flush_method

    default: _do_handle_flush

internal_flush_method contains the method name of the flush mechanism on the
output stream. If a default Reflex::Stream is used, there shouldn't be a need
to change this.

=head1 ROLE_REQUIRES

=head2 input

This role requires an attribute named "input" by default.

=head2 output

This role requires an attribute named "output" by default.

=head2 clear_input

This role requires a method named "clear_input" by default that will clear
the input attribute when called

=head2 clear_output

This role requires a method named "clear_output" by default that will clear
the output attribute when called

=head1 PROTECTED_METHODS

=head2 on_input_error

on_input_error merely re-emits error events from the input stream

=head2 on_output_error

on_output_error merely re-emits error events from the output stream

=head2 output_data

output_data is simple method that merely calls emit for the output_data event
along with whatever arguments are provided

=head2 on_input_close

on_input_close handles the closed event from the input handle. It merely calls
the stop() method of the input stream.

=head2 on_input_stop

on_input_stop handles the stopped event from the input handle. It ignores
further events from the input handle, clears the attribute then calls
done_writing()

=head2 on_input_data

on_input_data handles the data event from the input handle. It calls
output_data to emit the output_data event with the argument passed in.

=head2 on_output_data

on_output_data handles the data event emitted from the role. It calls put()
on the output stream with the argument passed in.

=head2 done_writing

done_writing is called when the input stream reaches EOF. It ensures that all
remaining data is flushed on the output stream using the internal flush method
of the output stream. Further events are then ignored from the output handle, 
and the output attribute is cleared. Finally, stopped() is called to emit the
stopped event.

=head1 PRIVATE_METHODS

=head2 BUILD

BUILD is advised to setup all of the appropriate watchers on the input and
output streams, and also upon itself after other BUILD process have occurred.

=head2 _clean_up

_clean_up handles the stopped event from the role. It simply ignores further
events from itself.

=head1 EMITTED_EVENTS

=head2 input_error

If there is an error event emitted from the input stream, it will be re-emitted
without alteration. Errors are /not/ handled by this role.

=head2 output_error

If there is an error event emitted from the output stream, it will be re-emitted
without alteration. Errors are /not/ handled by this role.

=head2 output_data

When data is processed by the input data callback, this event is emitted with
the data gained.

=head1 NOTES

This role doesn't provide the attributes that store the input and output
handles, but instead provides configurable parameters so that you can add them
and name them whatever you want.

To achieve the manual flush, encapsulation is broken on the output stream. This
shouldn't be an issue so long as a Reflex::Stream is used. If you build your
own Stream object using Reflex::Role::Streaming, fair warning is given that it
had better use the defaults or else things might not go very smoothly.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

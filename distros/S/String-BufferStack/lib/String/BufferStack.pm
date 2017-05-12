package String::BufferStack;

use strict;
use warnings;
use Carp;

our $VERSION; $VERSION = "1.16";

=head1 NAME

String::BufferStack - Nested buffers for templating systems

=head1 SYNOPSIS

  my $stack = String::BufferStack->new;
  $stack->push( filter => sub {return uc shift} );
  $stack->append("content");
  $stack->flush_output;

=head1 DESCRIPTION

C<String::BufferStack> provides a framework for storing nested
buffers.  By default, all of the buffers flow directly to the output
method, but individual levels of the stack can apply filters, or store
their output in a scalar reference.

=head1 METHODS

=head2 new PARAMHASH

Creates a new buffer stack and returns it.  Possible arguments include:

=over

=item prealoc

Preallocate this many bytes in the output buffer.  This can reduce
reallocations, and thus speed up appends.

=item out_method

The method to call when output trickles down to the bottom-most buffer
and is flushed via L<flush_output>.  The default C<out_method> prints
the content to C<STDOUT>.  This method will always be called with
non-undef, non-zero length content.

=item use_length

Calculate length of each buffer as it is built.  This imposes a
significant runtime cost, so should be avoided if at all possible.
Defaults to off.

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $output = " "x($args{prealloc} || 0);
    $output = '';
    return bless {
        stack => [],
        top => undef,
        output => \$output,
        out_method => $args{out_method} || sub { print STDOUT @_ },
        pre_appends => {},
        use_length => $args{use_length},
    }, $class;
}

=head2 push PARAMHASH

Pushes a new frame onto the buffer stack.  By default, the output from
this new frame connects to the input of the previous frame.  There are
a number of possible options:

=over

=item buffer

A string reference, into which the output from this stack frame will
appear.  By default, this is the input buffer of the previous frame.

=item private

If a true value is passed for C<private>, it creates a private string
reference, and uses that as the buffer -- this is purely for
convenience.  That is, the following blocks are equivilent:

  my $buffer = "";
  $stack->push( buffer => \$buffer );
  # ...
  $stack->pop;
  print $buffer;

  $stack->push( private => 1 );
  # ...
  print $stack->pop;

=item pre_append

A callback, which will be called with a reference to the
C<String::BufferStack> object, and the arguments to append, whenever
this stack frame has anything appended to the input buffer, directly
or indirectly.

Within the context of the pre-append callback, L</append>,
L</direct_append>, and L</set_pre_append> function on the frame the
pre-append is attached to, not the topmost trame.  Using L</append>
within the pre-append callback is not suggested; use
L</direct_append> instead.  L</set_pre_append> can be used to alter or
remove the pre-append callback itself -- this is not uncommon, in
the case where the first append is the only one which needs be watched
for, for instance.

=item filter

A callback, used to process data which is appended to the stack frame.
By default, filters are lazy, being called only when a frame is
popped.  They can be forced at any time by calling L</flush_filters>,
however.

=back

=cut

sub push {
    my $self = shift;
    my $frame = {
        buffer => $self->{top} ? $self->{top}{pre_filter} : $self->{output},
        @_
    };
    my $filter = "";
    my $buffer = "";
    $frame->{buffer} = \$buffer if delete $frame->{private};
    $frame->{length} = (defined ${$frame->{buffer}}) ? CORE::length(${$frame->{buffer}}) : 0
        if $self->{use_length} or $frame->{use_length};
    $frame->{pre_filter} = $frame->{filter} ? \$filter : $frame->{buffer};
    $self->{top} = $frame;
    local $self->{local_frame} = $frame;
    $self->set_pre_append(delete $frame->{pre_append}) if defined $frame->{pre_append};
    CORE::push(@{$self->{stack}}, $frame);
}

=head2 depth

Returns the current depth of the stack.  This starts at 0, when no
frames have been pushed, and increases by one for each frame pushed.

=cut

sub depth {
    my $self = shift;
    return scalar @{$self->{stack}};
}

=head2 append STRING [, STRING, ...]

Appends the given strings to the input side of the topmost buffer.
This will call all pre-append hooks attached to it, as well.  Note
that if the frame has a filter, the filter will not immediately run,
but will be delayed until the frame is L</pop>'d, or L</flush_filters>
is called.

When called with no frames on the stack, appends the stringins
directly to the L</output_buffer>.

=cut

sub append {
    my $self = shift;
    my $frame = $self->{local_frame} || $self->{top};
    if ($frame) {
        my $ref = $frame->{pre_filter};
        if (exists $self->{pre_appends}{$frame->{buffer}} and not $frame->{filter}) {
            # This is an append to the output buffer, signal all pre_append hooks for it
            for my $frame (@{$self->{pre_appends}{$frame->{buffer}}}) {
                die unless $frame->{pre_append};
                local $self->{local_frame} = $frame;
                $frame->{pre_append}->($self, @_);
            }
        }
        for (@_) {
            $$ref .= $_ if defined;
        }
    } else {
        my $ref = $self->{output};
        for (@_) {
            $$ref .= $_ if defined;
        }
    }
}

=head2 direct_append STRING [, STRING, ...]

Similar to L</append>, but appends the strings to the output side of
the frame, skipping pre-append callbacks and filters.

When called with no frames on the stack, appends the strings
directly to the L</output_buffer>.

=cut

sub direct_append {
    my $self = shift;
    my $frame = $self->{local_frame} || $self->{top};
    my $ref = $frame ? $frame->{buffer} : $self->{output};
    for (@_) {
        $$ref .= $_ if defined;
    }
}

=head2 pop

Removes the topmost frame on the stack, flushing the topmost filters
in the process.  Returns the output buffer of the frame -- note that
this may not contain only strings appended in the current frame, but
also those from before, as a speed optimization.  That is:

   $stack->append("one");
   $stack->push;
   $stack->append(" two");
   $stack->pop;   # returns "one two"

This operation is a no-op if there are no frames on the stack.

=cut

sub pop {
    my $self = shift;
    return unless $self->{top};
    $self->filter;
    my $frame = CORE::pop(@{$self->{stack}});
    local $self->{local_frame} = $frame;
    $self->set_pre_append(undef);
    $self->{top} = @{$self->{stack}} ? $self->{stack}[-1] : undef;
    return ${$frame->{buffer}};
}

=head2 set_pre_append CALLBACK

Alters the pre-append callback on the topmost frame.  The callback
will be called before text is appended to the input buffer of the
frame, and will be passed the C<String::BufferStack> and the arguments
to L</append>.

=cut

sub set_pre_append {
    my $self = shift;
    my $hook = shift;
    my $frame = $self->{local_frame} || $self->{top};
    return unless $frame;
    if ($hook and not $frame->{pre_append}) {
        CORE::push(@{$self->{pre_appends}{$frame->{buffer}}}, $frame);
    } elsif (not $hook and $frame->{pre_append}) {
        $self->{pre_appends}{ $frame->{buffer} }
            = [ grep { $_ ne $frame } @{ $self->{pre_appends}{ $frame->{buffer} } } ];
        delete $self->{pre_appends}{ $frame->{buffer} }
            unless @{ $self->{pre_appends}{ $frame->{buffer} } };
    }
    $frame->{pre_append} = $hook;
}

=head2 set_filter FILTER

Alters the filter on the topmost frame.  Doing this flushes the
filters on the topmost frame.

=cut

sub set_filter {
    my $self = shift;
    my $filter = shift;
    return unless $self->{top};
    $self->filter;
    if (defined $self->{top}{filter} and not defined $filter) {
        # Removing a filter, flush, then in = out
        $self->{top}{pre_filter} = $self->{top}{buffer};
    } elsif (not defined $self->{top}{filter} and defined $filter) {
        # Adding a filter, add a pre_filter stage
        my $pre_filter = "";
        $self->{top}{pre_filter} = \$pre_filter;
    }
    $self->{top}{filter} = $filter;
}

=head2 filter

Filters the topmost stack frame, if it has outstanding unfiltered
data.  This will propagate content to lower frames, possibly calling
their pre-append hooks.

=cut

sub filter {
    my $self = shift;
    my $frame = shift || $self->{top};
    return unless $frame and $frame->{filter} and CORE::length(${$frame->{pre_filter}});

    # We remove the input before we shell out to the filter, so we
    # don't get into infinite loops.
    my $input = ${$frame->{pre_filter}};
    ${$frame->{pre_filter}} = '';
    my $output = $frame->{filter}->($input);
    if (exists $self->{pre_appends}{$frame->{buffer}}) {
        for my $frame (@{$self->{pre_appends}{$frame->{buffer}}}) {
            local $self->{local_frame} = $frame;
            $frame->{pre_append}->($self, $output);
        }
    }
    ${$frame->{buffer}} .= $output;
}

=head2 flush

If there are no frames on the stack, calls L</flush_output>.
Otherwise, calls L</flush_filters>.

=cut

sub flush {
    my $self = shift;
    # Flushing with no stack flushes the output
    return $self->flush_output unless $self->depth;
    # Otherwise it just flushes the filters
    $self->flush_filters;
}

=head2 flush_filters

Flushes all filters.  This does not flush output from the output
buffer; see L</flush_output>.

=cut

sub flush_filters {
    my $self = shift;
    # Push content through filters -- reverse so the top one is first
    for my $frame (reverse @{$self->{stack}}) {
        $self->filter($frame);
    }
}

=head2 buffer

Returns the contents of the output buffer of the topmost frame; if
there are no frames, returns the output buffer.

=cut

sub buffer {
    my $self = shift;
    return $self->{top} ? ${$self->{top}{buffer}} : ${$self->{output}};
}

=head2 buffer_ref

Returns a reference to the output buffer of the topmost frame; if
there are no frames, returns a reference to the output buffer.  Note
that adjusting this skips pre-append and filter hooks.

=cut

sub buffer_ref {
    my $self = shift;
    return $self->{top} ? $self->{top}{buffer} : $self->{output};
}

=head2 length

If C<use_length> was enabled in the buffer stack's constructor,
returns the number of characters appended to the current frame; if
there are no frames, returns the length of the output buffer.

If C<use_length> was not enabled, warns and returns 0.

=cut

sub length {
    my $self = shift;
    carp("String::BufferStack object didn't enable use_length") and return 0
        unless $self->{use_length} or ($self->{top} and $self->{top}{use_length});
    return $self->{top} ? CORE::length(${$self->{top}{buffer}}) - $self->{top}{length} : CORE::length(${$self->{output}});
}


=head2 flush_output

Flushes all filters using L</flush_filters>, then flushes output from
the output buffer, using the configured L</out_method>.

=cut

sub flush_output {
    my $self = shift;
    $self->flush_filters;

    # Look at what we have at the end
    return unless CORE::length(${$self->{output}});
    $self->{out_method}->(${$self->{output}});
    ${$self->{output}} = "";
    return "";
}

=head2 output_buffer

Returns the pending output buffer, which sits below all existing
frames.

=cut

sub output_buffer {
    my $self = shift;
    return ${$self->{output}};
}

=head2 output_buffer_ref

Returns a reference to the pending output buffer, allowing you to
modify it.

=cut

sub output_buffer_ref {
    my $self = shift;
    return $self->{output};
}

=head2 clear

Clears I<all> buffers in the stack, including the output buffer.

=cut

sub clear {
    my $self = shift;
    ${$self->{output}} = "";
    ${$_->{pre_filter}} = ${$_->{buffer}} = "" for @{$self->{stack}};
    return "";
}

=head2 clear_top

Clears the topmost buffer in the stack; if there are no frames on the
stack, clears the output buffer.

=cut

sub clear_top {
    my $self = shift;
    if ($self->{top}) {
        ${$self->{top}{pre_filter}} = ${$self->{top}{buffer}} = "";
    } else {
        ${$self->{output}} = "";
    }
    return "";
}

=head2 out_method [CALLBACK]

Gets or sets the output method callback, which is given content from
the pending output buffer, which sits below all frames.

=cut

sub out_method {
    my $self = shift;
    $self->{out_method} = shift if @_;
    return $self->{out_method};
}

=head1 SEE ALSO

Many concepts were originally taken from L<HTML::Mason>'s internal
buffer stack.

=head1 AUTHORS

Alex Vandiver C<< alexmv@bestpractical.com >>

=head1 LICENSE

Copyright 2008-2009, Best Practical Solutions.

This package is distributed under the same terms as Perl itself.

=cut


1;

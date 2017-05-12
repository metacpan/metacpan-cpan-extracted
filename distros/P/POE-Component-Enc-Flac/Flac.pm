#   FLAC encoding component for POE
#   Copyright (c) 2004 Steve James. All rights reserved.
#
#   This library is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself.
#

package POE::Component::Enc::Flac;

use 5.008;
use strict;
use warnings;
use Carp;
use POE qw(Wheel::Run Filter::Line Driver::SysRW);

our $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

# Create a new encoder object
sub new {
    my $class = shift;
    my $opts  = shift;

    my $self = bless({}, $class);

    my %opts = !defined($opts) ? () : ref($opts) ? %$opts : ($opts, @_);
    %$self = (%$self, %opts);

    $self->{compression} ||= 5;   # Default compression level
    $self->{priority}    ||= 0;   # No priority delta by default

    $self->{parent}    ||= 'main';    # Default parent
    $self->{status}    ||= 'status';  # Default events
    $self->{error}     ||= 'error';
    $self->{done}      ||= 'done';
    $self->{warning}   ||= 'warning';

    return $self;
}


# Start an encoder.
sub enc {
    my $self = shift;
    my $opts = shift;

    my %opts = !defined($opts) ? () : ref($opts) ? %$opts : ($opts, @_);
    %$self = (%$self, %opts);

    croak "No input file specified" unless $self->{input};

    # Output filename is derived from input, unless specified
    unless ($self->{output}) {
        ($self->{output} = $self->{input}) =~ s/(.*)\.(.*)$/$1.flac/;
    }

    # For posting events to the parent session. Always passes $self as
    # the first event argument.
    sub post_parent {
        my $kernel = shift;
        my $self   = shift;
        my $event  = shift;

        $kernel->post($self->{parent}, $event, $self, @_)
            or carp "Failed to post to '$self->{parent}': $!";
    }

    POE::Session->create(
        inline_states => {
            _start => sub {
                my ($heap, $kernel, $self) = @_[HEAP, KERNEL, ARG0];

                $kernel->sig(CHLD => "child"); # We must handle SIGCHLD

                $heap->{self} = $self;

                my @args;   # List of arguments for encoder

                push @args, '--output-name="' . $self->{output} .'"';

                push @args, '-' . $self->{compression}
                    if $self->{compression};

                # The comment parameter is a list of tag-value pairs.
                # Each list element must be passed to the encoder as a
                # separate --tag argument.
                if ($self->{comment}) {
                    foreach (@{$self->{comment}}) {
                        push @args, '--tag="' . $_ .'"'
                    }
                }

                # Finally, the input file
                push @args, $self->{input};

                $heap->{wheel} = POE::Wheel::Run->new(
                    Program     => 'flac',
                    ProgramArgs => \@args,
                    Priority    => $self->{priority},
                    StdioFilter => POE::Filter::Line->new(),
                    Conduit     => 'pty',
                    StdoutEvent => 'wheel_stdout',
                    CloseEvent  => 'wheel_done',
                    ErrorEvent  => 'wheel_error',
                );
            },

            _stop => sub {
            },

            close => sub {
                delete $_[HEAP]->{wheel};
            },

            # Handle CHLD signal. Stop the wheel if the exited child is ours.
            child => sub {
                my ($kernel, $heap, $signame, $child_pid, $exit_code)
                    = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];

                if ($heap->{wheel} && $heap->{wheel}->PID() == $child_pid) {
                    delete $heap->{wheel};

                    # If we got en exit code, the child died unexpectedly,
                    # so create a wheel-error event. otherwise the child exited
                    # normally, so create a wheel-done event.
                    if ($exit_code) {
                        $kernel->yield('wheel_error', $exit_code);
                    } else {
                        $kernel->yield('wheel_done');
                    }
                }
            },

            wheel_stdout => sub {
                my ($kernel, $heap) = @_[KERNEL, HEAP];
                my $self = $heap->{self};
                $_ = $_[ARG0];

                if (m{^ERROR: (.*)}i) {
                    # An error message has been emitted by the encoder.
                    # Remember the message for later
                    $self->{message} = $1;
                } elsif (m{^WARNING: (.*)}i) {
                    # A warning message has been emitted by the encoder.
                    # Post the warning message to the parent
                    post_parent($kernel, $self, $self->{warning},
                                $self->{input},
                                $self->{output},
                                $1
                                );
                    return;
                } elsif (m{
                    \S+:\s+                 # input file name
                    (\d+)%\s+complete,      # Percentage completion
                    \s+ratio=([0-9.]+)      # Current compression ratio
                    }x) {
                    # We have a progress message from the compressor
                    # Post the percentage and ratio to the parent.
                    my ($percent, $ratio) = ($1, $2);

                    post_parent($kernel, $self, $self->{status},
                                $self->{input},
                                $self->{output},
                                $percent, $ratio
                    );
                } elsif (m{
                    \S+:\s+                 # input file name
                    wrote\s+(\d+)\s+bytes,  # Percentage completion
                    \s+ratio=([0-9.]+)      # Compression ratio
                    }x) {
                    # We have a completion message from the compressor
                    # Post the percentage and ratio to the parent.
                    my ($size, $ratio) = ($1, $2);

                    post_parent($kernel, $self, $self->{status},
                                $self->{input},
                                $self->{output},
                                100, $ratio
                    );
                }
            },

            wheel_error => sub {
                my ($kernel, $heap) = @_[KERNEL, HEAP];
                my $self = $heap->{self};

                post_parent($kernel, $self, $self->{error},
                    $self->{input},
                    $self->{output},
                    $_[ARG0],
                    $self->{message} || ''
                );

                # Remove output file: might be incomplete
                $_ = $self->{output}; unlink if ($_ && -f);
            },

            wheel_done => sub {
                my ($kernel, $heap) = @_[KERNEL, HEAP];
                my $self = $heap->{self};

                # Delete the input file if instructed
                unlink $self->{input} if $self->{delete};

                post_parent($kernel, $self, $self->{done},
                    $self->{input},
                    $self->{output}
                );
            },
        },
        args => [$self]
    );
}

1;
__END__


=head1 NAME

POE::Component::Enc::Flac - POE component to wrap FLAC encoder F<flac>

=head1 SYNOPSIS

  use POE qw(Component::Enc::Flac);

  $encoder1 = POE::Component::Enc::Flac->new();
  $encoder1->enc(input => "/tmp/track03.wav");

  $encoder2 = POE::Component::Enc::Flac->new(
    parent      => 'mainSession',
    priority    => 10,
    compression => 'best',
    status      => 'flacStatus',
    error       => 'flacEerror',
    warning     => 'flacWarning',
    done        => 'flacDone',
    );
  $encoder2->enc(
    input       => "/tmp/track02.wav",
    output      => "/tmp/02.flac",
    tracknumber => 'Track 2',
    comment     => [
                    'title=Birdhouse in your Soul',
                    'artist=They Might be Giants',
                    'date=1990',
                    'origin=CD',
                   ]
    );

  POE::Kernel->run();

=head1 ABSTRACT

POE is a multitasking framework for Perl. FLAC stands for Free Lossless
Audio Codec and 'flac' is an encoder for this standard. This module wraps
'flac' into the POE framework, simplifying its use in, for example, a CD music
ripper and encoder application. It provides an object oriented interface.

To use this module, you will need the POE framework (See http://poe.perl.org/)
and you will need to install the flac tool (See http://flac.sourceforge.net/).

=head1 DESCRIPTION

This POE component encodes wav audio files into FLAC format.
It's merely a wrapper for the F<flac> program.

=head1 METHODS

The module provides an object oriented interface as follows.


=head2 new

Used to create an encoder instance.
The following parameters are available. All of these are optional.

=over 12

=item priority

This is the delta priority for the encoder relative to the caller, default is C<0>.
A positive value lowers the encoder's priority.
See POE::Wheel:Run(3pm) and nice(1).

=item parent

Names the session to which events are posted. By default this
is C<main>.

=item compression

Sets the encoding compression level to the given value, between 0 (least) and 8 (most). You can also specify 'fast' and 'best' which are synonymous to 0 and
8 respectively. If unspecified, the default compression level is C<5>.

=item status

=item error

=item warning

=item done

These parameters specify the events that are posted to the main session.
By default the events are C<status>, C<error>, C<warning> and C<done> respectively.

=back


=head2 enc

Encodes the given file, naming the result with a C<.flac> extension.
The only mandatory parameter is the name of the file to encode.

=over 12

=item input

The input file to be encoded. This must be a F<.wav> file.

=item output

The output file to encode to. This will be a F<.flac> file. This parameter
is optional, and if unspecied the output file name will be formed by replacing the extension of the input file name with F<.flac>.

=item delete

A true value for this parameter indicates that the original input
file should be deleted after encoding.

=item comment

Use this parameter to pass Vorbis comments to the encoder.

For the comment parameter, the encoder expects tag-value pairs separated with
an equals sign (C<'tag=value'>). Multiple pairs can be specified because this
parameter is a list. Note that this parameter must always be passed as a list even if it has only one element. This parameter is optional.

=back


=head1 EVENTS

Events are passed to the session specified to the C<new()> method
to indicate progress, completion, warnings and errors. These events are described below, with their default names; alternative names may be specified when calling C<new()>.

The first argument (C<ARG0>) passed with these events is always the instance of the encoder as returned by C<new()>. ARG1 and ARG2 are always the input and output file names respectively.


=head2 status

Sent during encoding to indicate progress. ARG3 is the percentage of completion so far (integer number 0 to 100), and ARG4 is the current compression ratio (real number, three decimal places).

=head2 warning

Sent when the encoder emits a warning.
ARG3 is the warning message.

=head2 error

Sent in the event of an error from the encoder. ARG3 is the error code from the encoder and ARG4 is the error message if provided, otherwise ''.

=head2 done

This event is sent upon completion of encoding.


=head1 SEE ALSO

Vorbis Tools oggenc(1),
L<POE::Component::Enc::Ogg>,
L<POE::Component::Enc::Mp3>,
L<POE::Component::CD::Detect>,
L<POE::Component::CD::Rip>.

http://www.ambrosia.plus.com/perl/modules/POE-Component-Enc-Flac/

=head1 AUTHOR

Steve James E<lt>steATcpanDOTorgE<gt>

=head1 DATE

$Date: 2004/04/25 22:01:19 $

=head1 VERSION

$Revision: 1.1 $

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 Steve James

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

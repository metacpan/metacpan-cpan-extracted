#   Ogg Vorbis encoding component for POE
#   Copyright (c) 2004 Steve James. All rights reserved.
#
#   This library is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself.
#

package POE::Component::Enc::Ogg;

use 5.008;
use strict;
use warnings;
use Carp;
use POE qw(Wheel::Run Filter::Line Driver::SysRW);

our $VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

# Create a new encoder object
sub new {
    my $class = shift;
    my $opts  = shift;

    my $self = bless({}, $class);

    my %opts = !defined($opts) ? () : ref($opts) ? %$opts : ($opts, @_);
    %$self = (%$self, %opts);

    $self->{quality}   ||= 3;   # Default quality level of 3
    $self->{priority}  ||= 0;   # No priority delta by default

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

    croak "Input file does not exist: '$self->{input}'"
      unless (-f $self->{input});

    $self->{input} =~ /(.*)\.(.*)$/;
    my ($path, $ext) = ($1, $2);

    croak "Input file extension must be 'wav' or 'flac': I have '$ext'"
      unless ($ext eq 'wav' || $ext eq 'flac');

    # Output filename is derived from input, unless specified
    unless ($self->{output}) {
        $self->{output} = "$path.ogg";
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

                push @args, '--album="'   . $self->{album} .'"'
                    if $self->{album};

                push @args, '--genre="'   . $self->{genre} .'"'
                    if $self->{genre};

                push @args, '--title="'   . $self->{title} .'"'
                    if $self->{title};

                push @args, '--date="'    . $self->{date} .'"'
                    if $self->{date};

                push @args, '--artist="'  . $self->{artist} .'"'
                    if $self->{artist};

                push @args, '--output="'  . $self->{output} .'"';

                push @args, '--quality="' . $self->{quality} .'"'
                    if $self->{quality};

                push @args, '--tracknum="'. $self->{tracknumber}.'"'
                    if $self->{tracknumber};

                # The comment parameter is a list of tag-value pairs.
                # Each list element must be passed to the encoder as a
                # separate --comment argument.
                if ($self->{comment}) {
                    foreach (@{$self->{comment}}) {
                        push @args, '--comment="' . $_ .'"'
                    }
                }

                # Name of the encoder program we will use
                my $encoder = 'oggenc';

                # We might need to use a decoder front-end pipe
                my $decoder = '';

                # If the input is in flac format, use a flac decoder
                # front-end, and pipe it to the encoder.
                # Otherwise pass the input file name direct to the encoder
                if ($ext eq 'flac') {
                    $decoder = "flac --decode --silent --stdout $self->{input} |";
                    push @args, '-';
                } else {
                    push @args, $self->{input};
                }

                $heap->{wheel} = POE::Wheel::Run->new(
                    Program     => $decoder.$encoder,
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
                } elsif (m{^
                    \s+ \[ \s+ ([0-9.]+) % \s* \]
                    \s+ \[ \s+ (\d+) m (\d+) s \s+ remaining \s* \]
                    }x) {
                    # We have a progress message from the encoder
                    # Post the percentage and number of remaining seconds
                    # to the parent.
                    my ($percent, $seconds) = ($1, $2 * 60 + $3);

                    post_parent($kernel, $self, $self->{status},
                                $self->{input},
                                $self->{output},
                                $percent, $seconds
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

POE::Component::Enc::Ogg - POE component to wrap Ogg Vorbis encoder F<oggenc>

=head1 SYNOPSIS

  use POE qw(Component::Enc::Ogg);

  $encoder1 = POE::Component::Enc::Ogg->new();
  $encoder1->enc(input => "/tmp/track03.wav");

  $encoder2 = POE::Component::Enc::Ogg->new(
    parent    => 'MainSession',
    priority  => 10,
    quality   => 6,
    status    => 'oggStatus',
    error     => 'oggError',
    warning   => 'oggWarning',
    done      => 'oggDone',
    album     => 'Flood',
    genre     => 'Alternative'
    );
  $encoder2->enc(
    artist      => 'They Might be Giants',
    title       => 'Birdhouse in your Soul',
    input       => "/tmp/track02.wav",
    output      => "/tmp/02.ogg",
    tracknumber => 'Track 2',
    date        => '1990',
    comment     => ['origin=CD', 'loudness=medium']
    );

  POE::Kernel->run();

=head1 ABSTRACT

POE is a multitasking framework for Perl. Ogg Vorbis is an open standard for compressed
audio and F<oggenc> is an encoder for this standard. This module
wraps F<oggenc> into the POE framework, simplifying its use in, for example,
a CD music ripper and encoder application.

=head1 DESCRIPTION

This POE component encodes wav and flac audio files into Ogg Vorbis format.
It's merely a wrapper for the F<oggenc> program. For flac files, the flac(1)
program is also required.

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

=item quality

Sets the encoding quality to the given value, between -1 (low) and 10 (high).
If unspecified, the default quality level is C<3>.
Fractional quality levels such as 2.5 are permitted.

=item status

=item error

=item warning

=item done

These parameters specify the events that are posted to the main session.
By default the events are C<status>, C<error>, C<warning> and C<done> respectively.

=item album

=item genre

These parameters are used to pass information to the encoder.

=back


=head2 enc

Encodes the given file, naming the result with a C<.ogg> extension.
The only mandatory parameter is the name of the file to encode.

=over 12

=item input

The input file to be encoded. This must be a F<.wav> file or a F<.flac> file.

=item output

The output file to encode to. This will be a F<.ogg> file. This parameter
is optional, and if unspecied the output file name will be formed by replacing the extension of the input file name with F<.ogg>.

=item delete

A true value for this parameter indicates that the original input
file should be deleted after encoding.

=item tracknumber

=item title

=item artist

=item date

These parameters are used to pass information to the encoder. They all all optional.

=item comment

For the comment parameter, the encoder expects tag-value pairs separated with
an equals sign (C<'tag=value'>). Multiple pairs can be specified because this
parameter is a list. Note that this parameter must always be passed as a list even if it has only one element. This parameter is optional.

You can use this parameter as a generic way to specify all the specific parameters listed
above (i.e. album, genre, tracknumber, title, artist & date), and you can name
your own tags. For example, the following two statements are
equivalent.

  $encoder2->enc(
    input       => "/tmp/track02.wav"),
    artist      => 'They Might be Giants',
    title       => 'Birdhouse in your Soul',
    comment     => ['source=CD'],   # my non-'standard' tag
    );

  $encoder2->enc(
    input       => "/tmp/track02.wav"),
    comment     => [
                    'artist=They Might be Giants',
                    'title=Birdhouse in your Soul',
                    'source=CD',    # my non-'standard' tag
                   ],
    );

=back


=head1 EVENTS

Events are passed to the session specified to the C<new()> method
to indicate progress, completion, warnings and errors. These events are described below, with their default names; alternative names may be specified when calling C<new()>.

The first argument (C<ARG0>) passed with these events is always the instance of the encoder as returned by C<new()>. ARG1 and ARG2 are always the input and output file names respectively.


=head2 status

Sent during encoding to indicate progress. ARG3 is the percentage of completion so far, and ARG4 is the estimated number of seconds remaining to completion.

=head2 warning

Sent when the encoder emits a warning.
ARG3 is the warning message.

=head2 error

Sent in the event of an error from the encoder. ARG3 is the error code from the encoder and ARG4 is the error message if provided, otherwise ''.

=head2 done

This event is sent upon completion of encoding.


=head1 SEE ALSO

Vorbis Tools oggenc(1),
L<POE::Component::Enc::Flac>,
L<POE::Component::Enc::Mp3>,
L<POE::Component::CD::Detect>,
L<POE::Component::CD::Rip>.

http://www.ambrosia.plus.com/perl/modules/POE-Component-Enc-Ogg/

=head1 AUTHOR

Steve James E<lt>steATcpanDOTorgE<gt>

This module was inspired by Erick Calder's POE::Component::Enc::Mp3

=head1 DATE

$Date: 2004/05/31 08:10:55 $

=head1 VERSION

$Revision: 1.5 $

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 Steve James

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

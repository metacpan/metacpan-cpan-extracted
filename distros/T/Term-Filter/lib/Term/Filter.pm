package Term::Filter;
BEGIN {
  $Term::Filter::AUTHORITY = 'cpan:DOY';
}
{
  $Term::Filter::VERSION = '0.03';
}
use Moose::Role;
# ABSTRACT: Run an interactive terminal session, filtering the input and output

use IO::Pty::Easy ();
use IO::Select ();
use Moose::Util::TypeConstraints 'subtype', 'as', 'where', 'message';
use Scope::Guard ();
use Term::ReadKey ();


subtype     'Term::Filter::TtyFileHandle',
    as      'FileHandle',
    where   { -t $_ },
    message { "Term::Filter requires input and output filehandles to be attached to a terminal" };


has input => (
    is      => 'ro',
    isa     => 'Term::Filter::TtyFileHandle',
    lazy    => 1,
    builder => '_build_input',
);

sub _build_input { \*STDIN }


has output => (
    is      => 'ro',
    isa     => 'Term::Filter::TtyFileHandle',
    lazy    => 1,
    builder => '_build_output',
);

sub _build_output { \*STDOUT }




has input_handles => (
    traits   => ['Array'],
    isa      => 'ArrayRef[FileHandle]',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_input_handles',
    writer   => '_set_input_handles',
    handles  => {
        input_handles       => 'elements',
        add_input_handle    => 'push',
        _grep_input_handles => 'grep',
    },
    trigger  => sub {
        my $self = shift;
        $self->_clear_select;
    },
);

sub _build_input_handles {
    my $self = shift;
    [ $self->input, $self->pty ]
}

sub remove_input_handle {
    my $self = shift;
    my ($fh) = @_;
    $self->_set_input_handles(
        [ $self->_grep_input_handles(sub { $_ != $fh }) ]
    );
}


has pty => (
    is      => 'ro',
    isa     => 'IO::Pty::Easy',
    lazy    => 1,
    builder => '_build_pty',
);

sub _build_pty { IO::Pty::Easy->new(raw => 0) }

has _select => (
    is      => 'ro',
    isa     => 'IO::Select',
    lazy    => 1,
    builder => '_build_select',
    clearer => '_clear_select',
);

sub _build_select {
    my $self = shift;
    return IO::Select->new($self->input_handles);
}

has _raw_mode => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
    init_arg => undef,
    trigger  => sub {
        my $self = shift;
        my ($val) = @_;
        if ($val) {
            Term::ReadKey::ReadMode(5, $self->input);
        }
        else {
            Term::ReadKey::ReadMode(0, $self->input);
        }
    },
);


sub run {
    my $self = shift;
    my @cmd = @_;

    my $guard = $self->_setup(@cmd);

    LOOP: while (1) {
        my ($r, undef, $e) = IO::Select->select(
            $self->_select, undef, $self->_select,
        );

        for my $fh (@$e) {
            $self->read_error($fh);
        }

        for my $fh (@$r) {
            if ($fh == $self->input) {
                my $got = $self->_read_from_handle($self->input, "STDIN");
                last LOOP unless defined $got;

                $got = $self->munge_input($got);

                # XXX should i select here, or buffer, to make sure this
                # doesn't block?
                syswrite $self->pty, $got;
            }
            elsif ($fh == $self->pty) {
                my $got = $self->_read_from_handle($self->pty, "pty");
                last LOOP unless defined $got;

                $got = $self->munge_output($got);

                # XXX should i select here, or buffer, to make sure this
                # doesn't block?
                syswrite $self->output, $got;
            }
            else {
                $self->read($fh);
            }
        }
    }
}

sub _setup {
    my $self = shift;
    my (@cmd) = @_;

    Carp::croak("Must be run attached to a tty")
        unless -t $self->input && -t $self->output;

    $self->pty->spawn(@cmd) || Carp::croak("Couldn't spawn @cmd: $!");

    $self->_raw_mode(1);

    my $prev_winch = $SIG{WINCH};
    $SIG{WINCH} = sub {
        $self->pty->slave->clone_winsize_from($self->input);

        $self->pty->kill('WINCH', 1);

        $self->winch;

        $prev_winch->();
    };

    my $setup_called;
    my $guard = Scope::Guard->new(sub {
        $SIG{WINCH} = $prev_winch;
        $self->_raw_mode(0);
        $self->cleanup if $setup_called;
    });

    $self->setup(@cmd);
    $setup_called = 1;

    return $guard;
}

sub _read_from_handle {
    my $self = shift;
    my ($handle, $name) = @_;

    my $buf;
    sysread $handle, $buf, 4096;
    if (!defined $buf || length $buf == 0) {
        Carp::croak("Error reading from $name: $!")
            unless defined $buf;
        return;
    }

    return $buf;
}


sub setup        { }
sub cleanup      { }
sub munge_input  { $_[1] }
sub munge_output { $_[1] }
sub read         { }
sub read_error   { }
sub winch        { }

no Moose::Role;
no Moose::Util::TypeConstraints;


1;

__END__
=pod

=head1 NAME

Term::Filter - Run an interactive terminal session, filtering the input and output

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  package My::Term::Filter;
  use Moose;
  with 'Term::Filter';

  sub munge_input {
      my $self = shift;
      my ($got) = @_;
      $got =~ s/\ce/E-  Elbereth\n/g;
      $got;
  }

  sub munge_output {
      my $self = shift;
      my ($got) = @_;
      $got =~ s/(Elbereth)/\e[35m$1\e[m/g;
      $got;
  }

  My::Term::Filter->new->run('nethack');

=head1 DESCRIPTION

This module is a L<Moose role|Moose::Role> which implements running a program
in a pty while being able to filter the data that goes into and out of it. This
can be used to alter the inputs and outputs of a terminal based program (as in
the L</SYNOPSIS>), or to intercept the data going in or out to record it or
rebroadcast it (L<App::Ttyrec> or L<App::Termcast>, for instance).

This role is intended to be consumed by a class which implements its callbacks
as methods; for a simpler callback-based API, you may want to use
L<Term::Filter::Callback> instead.

=head1 ATTRIBUTES

=head2 input

The input filehandle to attach to the pty's input. Defaults to STDIN.

=head2 output

The output filehandle to attach the pty's output to. Defaults to STDOUT.

=head2 pty

The L<IO::Pty::Easy> object that the subprocess will be run under. Defaults to
a newly created instance.

=head1 METHODS

=head2 input_handles

Returns the filehandles which will be monitored for reading. This list defaults
to C<input> and C<pty>.

=head2 add_input_handle($fh)

Add an input handle to monitor for reading. After calling this method, the
C<read> callback will be called with C<$fh> as an argument whenever data is
available to be read from C<$fh>.

=head2 remove_input_handle($fh)

Remove C<$fh> from the list of input handles being watched for reading.

=head2 run(@cmd)

Run the command specified by C<@cmd>, as though via C<system>. The callbacks
that have been defined will be called at the appropriate times, to allow for
manipulating the data that is sent or received.

=head1 CALLBACKS

The following methods may be defined to interact with the subprocess:

=over 4

=item setup

Called when the process has just been started. The parameters to C<run> are
passed to this callback.

=item cleanup

Called when the process terminates. Will not be called if C<setup> is never run
(for instance, if the process fails to start).

=item munge_input

Called whenever there is new data coming from the C<input> handle, before it is
passed to the pty. Must return the data to send to the pty (and the default
implementation does this), but can do other things with the data as well.

=item munge_output

Called whenever the process running on the pty has produced new data, before it
is passed to the C<output> handle. Must return the data to send to the
C<output> handle (and the default implementation does this), but can do other
things with the data as well.

=item read

Called when a filehandle other than C<input> or C<pty> has data available (so
will never be called unless you call C<add_input_handle> to register your
handle with the event loop). Receives the handle with data available as its
only argument.

=item read_error

Called when an exception state is detected in any handle in C<input_handles>
(including the default ones). Receives the handle with the exception state as
its only argument.

=item winch

Called whenever the parent process receives a C<SIGWINCH> signal, after it
propagates that signal to the subprocess. C<SIGWINCH> is sent to a process
running on a terminal whenever the dimensions of that terminal change. This
callback can be used to update any other handles watching the subprocess about
the new terminal size.

=back

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-term-filter at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-Filter>.

=head1 SEE ALSO

L<IO::Pty::Easy>

L<App::Termcast>

L<App::Ttyrec>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Term::Filter

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Term-Filter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Term-Filter>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-Filter>

=item * Search CPAN

L<http://search.cpan.org/dist/Term-Filter>

=back

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


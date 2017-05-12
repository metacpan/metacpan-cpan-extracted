#ABSTRACT: Moo role for issuing commands, with debug support, and signal handling

#pod =head1 SYNOPSIS
#pod
#pod This role provides the ability to capture system calls, and to execute system calls.
#pod
#pod Features
#pod
#pod =for :list
#pod * Prints output in realtime, in debug mode
#pod * Handles signals, and kills via signal if configured too.
#pod * Uses Log::Any for logging.  If in debug mode, will log output of commands, and execution line
#pod * Command line option
#pod
#pod     package Moo_Package;
#pod     use Moo;
#pod     use MooX::Options; # required before with statement
#pod     with qw(MooX::Ipc::Cmd);
#pod
#pod     has '+_cmd_kill' => (default=>1); # override default
#pod     sub run {
#pod         my $self=shift
#pod         $self->_system(['cmd']);
#pod         my @result=$self->_capture(['results']);
#pod     }
#pod     1;
#pod
#pod     package main
#pod     use Log::Any::Adapter('Stdout');  #setup Log::Any::Adapter;
#pod     my $app=Moo_Package->new_with_options(_cmd_kill=>0); #command line processing
#pod     my $app=Moo_Package->new(_cmd_kill=>0); #no command line processing
#pod     1;
#pod
#pod =cut

package MooX::Ipc::Cmd;
use Moo::Role;
use MooX::Options;
use Config qw();
use Types::Standard qw(Optional Dict slurpy Object ArrayRef Str);
use Type::Params qw(compile);

# use List::Util qw(any);
use POSIX qw(WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG);
with('MooX::Log::Any');
use feature qw(state);
use IPC::Run3;
use MooX::Ipc::Cmd::Exception;
use List::Util 1.33;
use namespace::autoclean;



use constant UNDEFINED_POSIX_RE => qr{not (?:defined|a valid) POSIX macro|not implemented on this architecture};

has _cmd_signal_from_number => (
                                is            => 'lazy',
                                default       => sub {return [split(' ', $Config::Config{sig_name})]},
                                documentation => 'Posix signal number'
                               );


#pod =attribute _cmd_kill
#pod
#pod If set to 1 will send the propgate signal when cmd exits due to signal.
#pod
#pod Reader: _cmd_kill
#pod
#pod Default: 1
#pod
#pod =cut

has _cmd_kill => (
                  is            => 'ro',
                  default       => 0,
                  documentation => 'If set to 1 will send the propogate signal when cmd exits due to signal.'
                 );

#pod =attribute mock
#pod
#pod Mocks the cmd, does not run
#pod
#pod Reader: mock 
#pod
#pod Default: 0
#pod
#pod Command line option, via MooX::Options
#pod
#pod =cut

option mock => (
                is            => 'ro',
                default       => 0,
                documentation => 'Mocks the cmd, does not run'
               );

#pod =method _system(\@cmd', /%opts);
#pod
#pod Runs a command like system call, with the output silently dropped, unless in log::any debug level
#pod
#pod =for :list
#pod = Params:
#pod  $cmd : arrayref of the command to send to the shell
#pod  %opts
#pod    valid_exit => [0] - exits to not throw exception, defaults to 0
#pod = Returns:
#pod exit code
#pod = Exception
#pod Throws an error when case dies, will also log error using log::any category _cmd
#pod
#pod =cut

sub _system
{
    state $check= compile(Object, ArrayRef [Str], slurpy Dict [valid_exit=>Optional[ArrayRef]]);
    my ($self, $cmd,$opt) = $check->(@_);

    $self->logger('_cmd')->debug('Executing ' . join(' ', @$cmd));
    return 0 if ($self->mock);

    my $stderr=[];

    if (scalar @{$cmd} == 1)
    {
        run3($cmd->[0], \undef,
             sub {$self->_cmd_stdout($_)},
             sub {$self->_cmd_stderr($stderr, undef, $_)},
             {return_if_system_error => 1},
            );
    }
    else
    {
        run3($cmd, \undef,
             sub {$self->_cmd_stdout($_);},
             sub {$self->_cmd_stderr($stderr, undef, $_);},
             {return_if_system_error => 1},
            );
    }

    my $error = $?;
    $self->_check_error($error, $cmd, $stderr,$opt);
    return $error;
}

#pod =method _capture(\@cmd',\%opts);
#pod
#pod Runs a command like qx call.  Will display cmd executed 
#pod
#pod =begin :list
#pod
#pod = Params:
#pod  $cmd: arrayref of the command to send to the shell
#pod  %opts:
#pod     valid_exit => [0] - exits to not throw exception, defaults to 0
#pod
#pod = Returns:
#pod combined stderr stdout
#pod = Exception
#pod Throws an MooX::Ipc::Cmd::Exception error
#pod
#pod =end :list
#pod
#pod =cut

sub _capture
{
    state $check= compile(Object, ArrayRef [Str],slurpy Dict [valid_exit=>Optional[ArrayRef]]);
    my ($self, $cmd,$opt) = $check->(@_);
    $self->logger('_cmd')->debug('Executing ' . join(' ', @$cmd));

    return 0 if ($self->mock);

    my $output = [];
    my $stderr = [];
    if (scalar @$cmd == 1)
    {
        run3($cmd->[0], \undef,
             sub {$self->_cmd_stdout($_, $output);},
             sub {$self->_cmd_stderr($stderr, $output, $_);},
             {return_if_system_error => 1});
    }
    else
    {
        run3($cmd, \undef,
             sub {$self->_cmd_stdout($_, $output);},
             sub {$self->_cmd_stderr($stderr, $output, $_);},
             {return_if_system_error => 1},
            );
    }
    my $exit_status = $?;

        $self->_check_error($exit_status, $cmd, $stderr) unless 
    (defined $opt->{valid_exit} && $opt->{valid_exit}==1);
    if (defined $output)
    {
        if (wantarray)
        {
            return @$output;
        }
        else
        {
            return $output;
        }
    }
    else {return}
}

sub _cmd_stdout
{
    my $self = shift;
    my ($line, $output) = @_;
    if (defined $output)
    {
        push(@$output, $line);
    }
    chomp $line;
    $self->logger('_cmd')->debug($line);
}

#sub routine to push output to the stderr and global output variables
# ignores lfs batch system concurrent spew
sub _cmd_stderr
{
    my $self   = shift;
    my $stderr = shift;
    my $output = shift;
    my $line   = $_;      # output from cmd

    return if ($line =~ / Batch system concurrent query limit exceeded/);    # ignores lfs spew
    push(@$output, $line) if (defined $output);
    chomp $line;
    push(@$stderr, $line);
    if ($self->logger('_cmd')->is_debug)
    {
        $self->logger('_cmd')->debug($line);
    }
}

#most of _check_error stolen from IPC::Simple
sub _check_error
{
    my $self = shift;
    my ($child_error, $cmd, $stderr,$opt) = @_;
    if (! exists $opt->{valid_exit})
    {
        $opt->{valid_exit}=[0];
    }

    if ($child_error == -1)
    {
        my $opt = {
                   cmd         => $cmd,
                   exit_status => $child_error,
                   stderr      => [$!],
                  };
        $opt->{stderr} = $stderr if (defined $stderr);
        MooX::Ipc::Cmd::Exception->throw($opt);
    }
    if (WIFSIGNALED($child_error))    # check to see if child error
    {
        my $signal_no = WTERMSIG($child_error);

        #kill with signal if told to
        if ($self->_cmd_kill)
        {
            kill $signal_no;
        }

        my $signal_name = $self->_cmd_signal_from_number->[$signal_no] || "UNKNOWN";

        my $opt = {
                   cmd         => $cmd,
                   exit_status => $child_error,
                   signal      => $signal_name,
                  };
        $opt->{stderr} = $stderr if (defined $stderr);
        MooX::Ipc::Cmd::Exception->throw($opt);
    }
    elsif (!List::Util::any {$_ eq $child_error} @{$opt->{valid_exit}})
    {
        my $opt = {
                   cmd         => $cmd,
                   exit_status => $child_error >> 8,    # get the real exit status if no signal
                  };
        $opt->{stderr} = $stderr if (defined $stderr);
        MooX::Ipc::Cmd::Exception->throw($opt);
    }
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Ipc::Cmd - Moo role for issuing commands, with debug support, and signal handling

=head1 VERSION

version 1.2.1

=head1 SYNOPSIS

This role provides the ability to capture system calls, and to execute system calls.

Features

=over 4

=item *

Prints output in realtime, in debug mode

=item *

Handles signals, and kills via signal if configured too.

=item *

Uses Log::Any for logging.  If in debug mode, will log output of commands, and execution line

=item *

Command line option

=back

    package Moo_Package;
    use Moo;
    use MooX::Options; # required before with statement
    with qw(MooX::Ipc::Cmd);

    has '+_cmd_kill' => (default=>1); # override default
    sub run {
        my $self=shift
        $self->_system(['cmd']);
        my @result=$self->_capture(['results']);
    }
    1;

    package main
    use Log::Any::Adapter('Stdout');  #setup Log::Any::Adapter;
    my $app=Moo_Package->new_with_options(_cmd_kill=>0); #command line processing
    my $app=Moo_Package->new(_cmd_kill=>0); #no command line processing
    1;

=head1 ATTRIBUTES

=head2 _cmd_kill

If set to 1 will send the propgate signal when cmd exits due to signal.

Reader: _cmd_kill

Default: 1

=head2 mock

Mocks the cmd, does not run

Reader: mock 

Default: 0

Command line option, via MooX::Options

=head1 METHODS

=head2 _system(\@cmd', /%opts);

Runs a command like system call, with the output silently dropped, unless in log::any debug level

=over 4

=item Params:

 $cmd : arrayref of the command to send to the shell
 %opts
   valid_exit => [0] - exits to not throw exception, defaults to 0

=item Returns:

exit code

=item Exception

Throws an error when case dies, will also log error using log::any category _cmd

=back

=head2 _capture(\@cmd',\%opts);

Runs a command like qx call.  Will display cmd executed 

=over 4

=item Params:

 $cmd: arrayref of the command to send to the shell
 %opts:
    valid_exit => [0] - exits to not throw exception, defaults to 0

=item Returns:

combined stderr stdout

=item Exception

Throws an MooX::Ipc::Cmd::Exception error

=back

=head1 AUTHOR

Eddie Ash <eddie+cpan@ashfamily.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Edward Ash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

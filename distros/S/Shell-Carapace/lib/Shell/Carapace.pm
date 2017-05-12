package Shell::Carapace;
use Moo;

our $VERSION = "0.22";

=head1 NAME

Shell::Carapace - Simple realtime output for ssh and shell commands

=head1 SYNOPSIS

    use Shell::Carapace::Local;

    # A callback is required.  It can be used to log commands, output, errors
    my $shell_callback = sub {
        my ($category, $message, $host) = @_;
        print "  $host $message\n"  if $category =~ /output/ && $message;
        print "Running $message\n"  if $category eq 'command';
        print "ERROR: cmd failed\n" if $category eq 'error';
    };

    my $shell = Shell::Carapace->shell(callback => $callback);
    $shell->run(@cmd); # throws an exception if @cmd fails

    my $ssh  = Shell::Carapace->ssh(
        callback    => $callback,    # required
        host        => $hostname,    # required
        ssh_options => $ssh_options, # a hash for Net::OpenSSH
    );
    $ssh->run(@cmd); # throws an exception if @cmd fails

=head1 DESCRIPTION

Ever run a script that takes 30 minutes to run and have to wait
30 minutes to see the output?  This module solve that problem.

Shell::Carapace is a small wrapper around IPC::Open3::Simple and Net::OpenSSH.
It provides a callback so you can easily log or process cmd output in realtime.  

=head1 METHODS

=head2 shell(%options)

Creates and returns a Shell::Carapace::Shell object.  All parameters are
optional except 'callback'.  The following parameters are accepted:

   callback    : Required.  A coderef which is executed in realtime as output

=head2 ssh(%options)

Creates and returns a Shell::Carapace::SSH object.  All parameters are optional
except 'callback'.  The following parameters are accepted:

   callback    : Required.  A coderef which is executed in realtime as output
                 is emitted from the command.
   host        : Required.  A string like 'localhost' or 'user@hostname' which
                 is passed to Net::OpenSSH.  Net::OpenSSH defaults the username
                 to the current user.
   ssh_options : A hash which is passed to Net::OpenSSH.

=head2 $shell->run(@cmd)

Execute the command locally via IPC::Open3::Simple.  Calls the callback in
realtime for each line of output emitted from the command.

=head2 $ssh->run(@cmd)

Execute the command on a remote host via Net::OpenSSH.  Calls the callback in
realtime for each line of output emitted from the command.

=cut

sub shell {
    my ($class, %args) = @_;
    require Shell::Carapace::Shell;
    return Shell::Carapace::Shell->new(%args);
}

sub ssh {
    my ($class, %args) = @_;
    require Shell::Carapace::SSH;
    return Shell::Carapace::SSH->new(%args);
}

=head1 ABOUT THE NAME

Carapace: n. A protective, shell-like covering likened to that of a turtle or crustacean

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

1;

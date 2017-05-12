[![Build Status](https://travis-ci.org/kablamo/p5-shell-carapace.svg?branch=master)](https://travis-ci.org/kablamo/p5-shell-carapace) [![Coverage Status](https://img.shields.io/coveralls/kablamo/p5-shell-carapace/master.svg)](https://coveralls.io/r/kablamo/p5-shell-carapace?branch=master)
# NAME

Shell::Carapace - Simple realtime output for ssh and shell commands

# SYNOPSIS

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

# DESCRIPTION

Ever run a script that takes 30 minutes to run and have to wait
30 minutes to see the output?  This module solve that problem.

Shell::Carapace is a small wrapper around IPC::Open3::Simple and Net::OpenSSH.
It provides a callback so you can easily log or process cmd output in realtime.  

# METHODS

## shell(%options)

Creates and returns a Shell::Carapace::Shell object.  All parameters are
optional except 'callback'.  The following parameters are accepted:

    callback    : Required.  A coderef which is executed in realtime as output

## ssh(%options)

Creates and returns a Shell::Carapace::SSH object.  All parameters are optional
except 'callback'.  The following parameters are accepted:

    callback    : Required.  A coderef which is executed in realtime as output
                  is emitted from the command.
    host        : Required.  A string like 'localhost' or 'user@hostname' which
                  is passed to Net::OpenSSH.  Net::OpenSSH defaults the username
                  to the current user.
    ssh_options : A hash which is passed to Net::OpenSSH.

## $shell->run(@cmd)

Execute the command locally via IPC::Open3::Simple.  Calls the callback in
realtime for each line of output emitted from the command.

## $ssh->run(@cmd)

Execute the command on a remote host via Net::OpenSSH.  Calls the callback in
realtime for each line of output emitted from the command.

# ABOUT THE NAME

Carapace: n. A protective, shell-like covering likened to that of a turtle or crustacean

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>

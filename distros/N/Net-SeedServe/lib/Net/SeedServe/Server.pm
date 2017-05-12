package Net::SeedServe::Server;

use strict;
use warnings;

use Net::SeedServe;
use IO::All;
use Time::HiRes qw(usleep);

=head1 NAME

Net::SeedServe::Server - Perl module for implementing a seed server.

=head1 DESCRIPTION

None yet. Consult the code, and the examples in the tests directory.

=head1 METHODS

=head2 $obj = Net::SeedServe::Server->new(status_file => $status_filename);

Initialises a new object with the status filename.

=cut

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self = shift;
    my %args = (@_);
    $self->{'status_file'} = $args{'status_file'} or
        die "Unknown status file!";

    return 0;
}

=head2 $server->start()

Starts the server on a port starting from port 3,000. Returns a hash ref
containing the port.

=cut

sub start
{
    my $self = shift;
    my $status_file = $self->{'status_file'};

    for(my $port = 3000; ; $port++)
    {
        unlink($status_file);
        my $fork_pid = fork();
        if (!defined($fork_pid))
        {
            die "Fork was not successful!";
        }
        if (! $fork_pid)
        {
            # The child will start the service.
            my $server =
                Net::SeedServe->new(
                    'status_file' => $status_file,
                    'port' => $port,
                );

            eval
            {
                $server->loop();
            };
            if ($@)
            {
                exit(-1);
            }
        }
        else
        {
            # The parent will try to find the child's status
            my $text;

            while (! ( defined($text) and $text =~ /\n\z/) )
            {
                while (! -f $status_file)
                {
                    usleep(5000);
                }
                usleep(5000);
                $text = io()->file($status_file)->getline();
            }
            if ($text eq "Status:Success\tPort:$port\tPID:$fork_pid\n")
            {
                # The game is on - the service is running and everything's OK.
                $self->{'port'} = $port;
                $self->{'server_pid'} = $fork_pid;
                return +{ 'port' => $port };
            }
            else
            {
                waitpid($fork_pid, 0);
            }
        }
    }
}

=head2 $server->connect(status_file => $status_filename)

Connects to an existing Server whose status file is $status_filename.

=cut

sub connect
{
    my $self = shift;

    my $status_file = $self->{'status_file'};

    my $text = io()->file($status_file)->getline();

    if ($text !~ /^Status:Success\tPort:(\d+)\tPID:(\d+)$/)
    {
        die "Invalid status file.";
    }

    my $port = $1;
    $self->{'server_pid'} = $2;
    # TODO ?
    # Add sanity checks.

    $self->{'port'} = $port;

    return { 'port' => $port, };
}

=head2 $server->stop()

Stops the service by killing the listening process.

=cut

sub stop
{
    my $self = shift;

    my $pid = $self->{'server_pid'};
    kill("TERM", $pid);

    waitpid($pid, 0);
}

sub _ok_transact
{
    my $self = shift;
    my $msg = shift;
    my $port = $self->{'port'};
    my $conn = io("localhost:$port");
    $conn->print("$msg\n");
    my $response = $conn->getline();
    if ($response eq "OK\n")
    {
        return 0;
    }
    else
    {
        die "Invalid response - $response.";
    }
}

=head2 $server->clear();

Sends a clear transaction that clears the seeds of the seed server.

=cut

sub clear
{
    my $self = shift;
    return $self->_ok_transact("CLEAR");
}

=head2 $server->enqueue(\@seeds);

Enqueues several seeds in the server to be served next.

=cut

sub enqueue
{
    my $self = shift;
    my $seeds = shift;
    if (grep { $_ !~ /^\d+$/ } @$seeds)
    {
        die "Invalid seed.";
    }
    return $self->_ok_transact("ENQUEUE " . join("", map { "$_," } @$seeds));
}

1;

__END__

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Shlomi Fish

This library is free software, you can redistribute and/or modify and/or
use it under the terms of the MIT X11 license.

=cut


package Net::SeedServe;

use 5.008;
use strict;
use warnings;

use IO::Socket::INET;
use IO::All;

our $VERSION = '0.2.7';

sub new
{
    my $class = shift;
    my $self = +{};
    bless $self, $class;
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self = shift;

    my %args = (@_);

    my $port = $args{'port'} or
        die "Port not specified!";

    $self->{'port'} = $port;

    $self->{'status_file'} = $args{'status_file'} or
        die "Success file not specified";

    return 0;
}

sub _update_status_file
{
    my $self = shift;
    my $string = shift;

    io()->file($self->{'status_file'})->print("$string\n");
}

sub loop
{
    my $self = shift;

    my $serving_socket;

    $serving_socket =
        IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => 'localhost',
            LocalPort => $self->{'port'},
            Proto     => 'tcp'
        );
    if (!defined($serving_socket))
    {
        $self->_update_status_file("Status:Error");
        die $@;
    }

    $self->_update_status_file(
        "Status:Success\tPort:" . $self->{'port'} . "\tPID:$$"
        );

    my @queue;
    my $next_seed;

    my $clear = sub {
        @queue = ();
        $next_seed = 1;
    };

    $clear->();

    while (my $conn = $serving_socket->accept())
    {
        my $request = $conn->getline();
        my $response;
        if ($request =~ /^FETCH/)
        {
            my $seed;
            if ($seed = shift(@queue))
            {
                $response = $seed;
                $next_seed = $seed+1;
            }
            else
            {
                $response = $next_seed++;
            }
        }
        elsif ($request =~ /^CLEAR/)
        {
            $clear->();
            $response = "OK";
        }
        elsif ($request =~ /^ENQUEUE ((?:\d+,)+)/)
        {
            my $nums = $1;
            $nums =~ s{,$}{};
            push @queue, split(/,/, $nums);
            $response = "OK";
        }
        else
        {
            $response = "ERROR";
        }
        $conn->print("$response\n");
    }
}

1;
__END__

=head1 NAME

Net::SeedServe - Perl module for implementing a seed server.

=head1 DESCRIPTION

Do not use this module directly - use Net::SeedServe::Server instead.

Consult the documentation of L<Net::SeedServe::Server>.

=head1 METHODS

=head2 $server = Net::SeedServe->new(port => $port, status_file => $status_filename)

Constructs a new seed server object on a certain port with a certain status
file.

=head2 $server->loop();

Starts a loop.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Shlomi Fish

This library is free software, you can redistribute and/or modify and/or
use it under the terms of the MIT X11 license.

=cut


package Net::Ostrich;
{
  $Net::Ostrich::VERSION = '0.01';
}
use Moose;

# ABSTRACT: Perl interface to Ostrich

use JSON::XS qw(decode_json);
use LWP::UserAgent;

has 'client' => (
    is => 'rw',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        return LWP::UserAgent->new;
    } 
);


has 'host' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'path' => (
    is => 'rw',
    isa => 'Str',
    default => '/'
);


has 'port' => (
    is => 'rw',
    isa => 'Int',
    required => 1
);


sub gc {
    my ($self) = @_;
    
    my $ua = $self->client;
    my $resp = $ua->get('http://' . $self->host . ':' . $self->port . $self->path . 'gc.json');
    unless($resp->is_success) {
        die("Failed to connect to ostrich: ".$resp->status_line);
    }
    
    return decode_json($resp->decoded_content);
}


sub ping {
    my ($self) = @_;
    
    my $ua = $self->client;
    my $resp = $ua->get('http://' . $self->host . ':' . $self->port . $self->path . 'ping.json');
    unless($resp->is_success) {
        die("Failed to connect to ostrich: ".$resp->status_line);
    }
    
    return decode_json($resp->decoded_content);
}


sub quiesce {
    my ($self) = @_;
    
    my $ua = $self->client;
    my $resp = $ua->get('http://' . $self->host . ':' . $self->port . $self->path . 'quiesce.json');
    unless($resp->is_success) {
        die("Failed to connect to ostrich: ".$resp->status_line);
    }
    
    return decode_json($resp->decoded_content);
}


sub reload {
    my ($self) = @_;
    
    my $ua = $self->client;
    my $resp = $ua->get('http://' . $self->host . ':' . $self->port . $self->path . 'reload.json');
    unless($resp->is_success) {
        die("Failed to connect to ostrich: ".$resp->status_line);
    }
    
    return decode_json($resp->decoded_content);
}


sub shutdown {
    my ($self) = @_;
    
    my $ua = $self->client;
    my $resp = $ua->get('http://' . $self->host . ':' . $self->port . $self->path . 'shutdown.json');
    unless($resp->is_success) {
        die("Failed to connect to ostrich: ".$resp->status_line);
    }
    
    return decode_json($resp->decoded_content);
}


sub stats {
    my ($self) = @_;
    
    my $ua = $self->client;
    my $resp = $ua->get('http://' . $self->host . ':' . $self->port . $self->path . 'stats.json');
    unless($resp->is_success) {
        die("Failed to connect to ostrich: ".$resp->status_line);
    }
    
    return decode_json($resp->decoded_content);
}


sub threads {
    my ($self) = @_;
    
    my $ua = $self->client;
    my $resp = $ua->get('http://' . $self->host . ':' . $self->port . $self->path . 'threads.json');
    unless($resp->is_success) {
        die("Failed to connect to ostrich: ".$resp->status_line);
    }
    
    return decode_json($resp->decoded_content);
}

1;

__END__
=pod

=head1 NAME

Net::Ostrich - Perl interface to Ostrich

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $no = Net::Ostrich->new(host => '172.16.49.130', port => 2223);

    my $stats = $no->stats;
    
    my $pong = $no->ping;

=head1 DESCRIPTION

Net::Ostrich is a perl interface to L<ostrich|https://github.com/twitter/ostrich>'s
administrative web service.

=head1 ATTRIBUTES

=head2 client

The L<LWP::UserAgent> client used by Net::Ostrich.  Provided in case you need
to change any settings, such as the proxy.

=head2 host

The hostname to which we'll be connecting to talk to Ostrich

=head2 path

The path where Ostrich resides.  Defaults to '/'.  This will be appended
after the port, so it's important that it begin and end with a /.

=head2 port

The port on which we'll be contacting Ostrich

=head1 METHODS

=head2 gc

Force a garbage collection cycle.

=head2 ping

Ping the server.

=head2 quiesce

Close any listening sockets, stop accepting new connections, and shutdown the
server as soon as the last client connection is done.

=head2 reload

Reload the server config file for any services that support it (most do not).

=head2 shutdown

Immediately shutdown the server.

=head2 stats

Fetch stats.  Grabs them as JSON and returns the decoded JSON structure.

=head2 threads

Fetch thread information.  Grabs them as JSON and returns the decoded JSON structure.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


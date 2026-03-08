package Net::Async::MCP::Transport::Stdio;
# ABSTRACT: Stdio MCP transport via subprocess JSON-RPC
our $VERSION = '0.002';
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future;
use JSON::MaybeXS;
use Carp qw( croak );


sub _init {
  my ( $self, $params ) = @_;
  $self->{command} = delete $params->{command}
    or croak "command is required";
  $self->{pending} = {};
  $self->{next_id} = 0;
  $self->{buffer}  = '';
  $self->{closed}  = 0;
  $self->{json}    = JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1);
  $self->SUPER::_init($params);
}

sub configure {
  my ( $self, %params ) = @_;
  if (exists $params{command}) {
    $self->{command} = delete $params{command};
  }
  $self->SUPER::configure(%params);
}

sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);

  require IO::Async::Process;

  my $process = IO::Async::Process->new(
    command => $self->{command},
    stdin   => { via => 'pipe_write' },
    stdout  => {
      on_read => sub {
        my ( $stream, $buffref, $eof ) = @_;
        $self->_on_stdout_read($buffref, $eof);
        return 0;
      },
    },
    stderr => {
      on_read => sub {
        my ( $stream, $buffref, $eof ) = @_;
        $$buffref = '';
        return 0;
      },
    },
    on_finish => sub {
      my ( $proc, $exitcode ) = @_;
      $self->_on_finish($exitcode);
    },
  );

  $self->{process} = $process;
  $self->add_child($process);
}

sub send_request {
  my ( $self, $method, $params ) = @_;

  if ($self->{closed}) {
    return Future->fail("MCP server process has exited");
  }

  my $id = ++$self->{next_id};
  my $request = {
    jsonrpc => '2.0',
    id      => $id,
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  my $json_line = $self->{json}->encode($request) . "\n";
  $self->{process}->stdin->write($json_line);

  my $future = $self->loop->new_future;
  $self->{pending}{$id} = $future;
  return $future;
}


sub send_notification {
  my ( $self, $method, $params ) = @_;

  if ($self->{closed}) {
    return Future->fail("MCP server process has exited");
  }

  my $request = {
    jsonrpc => '2.0',
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  my $json_line = $self->{json}->encode($request) . "\n";
  $self->{process}->stdin->write($json_line);

  return Future->done;
}


sub close {
  my ( $self ) = @_;
  return Future->done if $self->{closed};

  $self->{closed} = 1;

  if ($self->{process} && $self->{process}->is_running) {
    my $future = $self->loop->new_future;
    $self->{close_future} = $future;
    $self->{process}->kill('TERM');
    return $future;
  }

  return Future->done;
}


sub _on_stdout_read {
  my ( $self, $buffref, $eof ) = @_;
  $self->{buffer} .= $$buffref;
  $$buffref = '';

  while ($self->{buffer} =~ s/^(.*?)\n//) {
    my $line = $1;
    $line =~ s/\r$//;
    next if $line eq '';

    my $response = eval { $self->{json}->decode($line) };
    next unless $response && ref $response eq 'HASH';

    my $id = $response->{id};
    next unless defined $id;

    my $future = delete $self->{pending}{$id};
    next unless $future;

    if (my $err = $response->{error}) {
      $future->fail("MCP error $err->{code}: $err->{message}");
    }
    else {
      $future->done($response->{result});
    }
  }
}

sub _on_finish {
  my ( $self, $exitcode ) = @_;
  $self->{closed} = 1;

  for my $id (keys %{$self->{pending}}) {
    my $future = delete $self->{pending}{$id};
    $future->fail("MCP server process exited (code $exitcode)")
      if $future && !$future->is_ready;
  }

  if ($self->{close_future} && !$self->{close_future}->is_ready) {
    $self->{close_future}->done;
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Transport::Stdio - Stdio MCP transport via subprocess JSON-RPC

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # Usually created automatically by Net::Async::MCP
    use IO::Async::Loop;
    use Net::Async::MCP;

    my $loop = IO::Async::Loop->new;
    my $mcp = Net::Async::MCP->new(
        command => ['npx', '@anthropic/mcp-server-web-search'],
    );
    $loop->add($mcp);

=head1 DESCRIPTION

L<Net::Async::MCP::Transport::Stdio> communicates with an external MCP server
process via stdin/stdout using newline-delimited JSON-RPC 2.0. The subprocess
is managed as an L<IO::Async::Process> child notifier.

This transport works with any MCP server that supports the stdio transport,
regardless of implementation language (Perl, Node.js, Python, Go, etc.).

Requests are matched to responses by their JSON-RPC C<id> field. Each pending
request is represented by a L<Future> that resolves when the matching response
arrives. If the subprocess exits unexpectedly, all pending futures are failed
with an error message including the exit code.

This transport is selected automatically by L<Net::Async::MCP> when constructed
with a C<command> argument.

=head2 send_request

    my $future = $transport->send_request($method, \%params);

Encodes a JSON-RPC request and writes it as a newline-terminated JSON line to
the subprocess stdin. Returns a L<Future> that resolves to the C<result> value
when the matching response is read from stdout, or fails with an error if the
server returns a JSON-RPC error or the process exits.

Fails immediately if the subprocess has already exited.

=head2 send_notification

    my $future = $transport->send_notification($method, \%params);

Encodes a JSON-RPC notification (no C<id> field, no response expected) and
writes it to the subprocess stdin. Returns an immediately resolved L<Future>.

Fails immediately if the subprocess has already exited.

=head2 close

    my $future = $transport->close;

Sends SIGTERM to the subprocess and returns a L<Future> that resolves when
the process exits. If the process has already exited, returns an immediately
resolved L<Future>.

=head1 SEE ALSO

=over 4

=item * L<Net::Async::MCP> - Main client module that uses this transport

=item * L<Net::Async::MCP::Transport::InProcess> - Alternative transport for in-process Perl servers

=item * L<IO::Async::Process> - Subprocess management used internally

=item * L<IO::Async::Notifier> - Base class

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

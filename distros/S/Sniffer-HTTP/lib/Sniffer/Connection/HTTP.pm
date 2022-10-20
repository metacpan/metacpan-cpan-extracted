package Sniffer::Connection::HTTP;
use strict;
use Sniffer::Connection;
use HTTP::Request;
use HTTP::Response;

=head1 NAME

Sniffer::Connection::HTTP - Callbacks for a HTTP connection

=head1 SYNOPSIS

You shouldn't use this directly but via L<Sniffer::HTTP>
which encapsulates most of this.

  my $sniffer = Sniffer::Connection::HTTP->new(
    callbacks => {
      request  => sub { my ($req,$conn) = @_; print $req->uri,"\n" if $req },
      response => sub { my ($res,$req,$conn) = @_; print $res->code,"\n" },
    }
  );

  # retrieve TCP packet in $tcp, for example via Net::Pcap
  my $tcp = sniff_tcp_packet;

  $sniffer->handle_packet($tcp);

=cut

use parent 'Class::Accessor';

our $VERSION = '0.27';

my @callbacks = qw(request response closed log);
__PACKAGE__->mk_accessors(qw(tcp_connection sent_buffer recv_buffer _response _response_chunk_size _response_len _request prev_request),
                          @callbacks);

sub new {
  my ($class,%args) = @_;

  my $packet = delete $args{tcp};

  # Set up dummy callbacks as the default
  for (@callbacks) { $args{$_} ||= sub {}; };

  for (qw(sent_buffer recv_buffer)) {
    $args{$_} ||= \(my $buffer);
  };

  my $tcp_log = delete $args{tcp_log} || sub {};

  my $self = $class->SUPER::new(\%args);
  $self->tcp_connection(Sniffer::Connection->new(
    tcp           => $packet,
    sent_data     => sub { $self->sent_data(@_) },
    received_data => sub { $self->received_data(@_) },
    closed        => sub {},
    teardown      => sub { $self->closed->($self) },
    log           => $tcp_log,
  ));

  $self;
};

sub sent_data {
  my ($self,$data,$conn) = @_;
  $self->flush_received;
  ${$self->{sent_buffer}} .= $data;
  $self->flush_sent;
};

sub received_data {
  my ($self,$data,$conn) = @_;
  $self->flush_sent;
  ${$self->{recv_buffer}} .= $data;
  #warn $data;
  $self->flush_received;
};

sub extract_chunksize {
  my ($self,$buffer) = @_;
  my $chunksize;
  #$self->log->("---Extracting from\n$$buffer\n---");
  if (! ($$buffer =~ s!^\s*([a-f0-9]+)[ \t]*\r\n!!si)) {
    $self->log->("Extracting chunked size failed.");
    #$self->log->($$buffer);
    (my $copy = $$buffer) =~ s!\n!\\n\n!gs;
    $copy =~ s!\r!\\r!gs;
    $self->log->($copy);
  } else {
    $chunksize = hex $1;
    #$self->log->(sprintf "Found chunked size %s (%s remaining)\n", $chunksize, length $$buffer);
    #$self->log->(length $$buffer);
    $self->_response_chunk_size($chunksize);
  };
  #$self->log->("---Buffer is now\n$$buffer\n---");
  return $chunksize
};

sub flush_received {
  my ($self) = @_;
  my $buffer = $self->recv_buffer;
  #$self->log->($$buffer);
  while ($$buffer) {
    if (! (my $res = $self->_response)) {
      # We need to find something that looks like a valid HTTP request in our stream
      if (not $$buffer =~ s!.*^(HTTP/\d\..*? [12345]\d\d\b)!$1!m) {
        # Need to discard-and-sync
        $$buffer = "";
        #$self->recv_buffer(undef);
        return;
      };

      if (! ($$buffer =~ s!^(.*?\r?\n\r?\n)!!sm)) {
        # need more data before header is complete
        $self->log->("Need more header data");
        #$self->recv_buffer($buffer);
        return;
      };

      my $h = $1;
      $res = HTTP::Response->parse($h);
      $self->_response($res);

      my $len = $res->header('Content-Length');

      $self->_response_len( $len );
    };

    my $res = $self->_response;
    my $len = $self->_response_len;
    my $chunksize = $self->_response_chunk_size;

    my $te = lc ($res->header('Transfer-Encoding') || '');
    if ($te and $te eq 'chunked') {
      if (! defined $chunksize) {
        $chunksize = $self->extract_chunksize($buffer);
      };

      if (defined $chunksize) {
        #$self->log->("Chunked size: $chunksize\n");
        #$self->log->("Got buffer of size " + length $$buffer);

        while (defined $chunksize and length $$buffer >= $chunksize) {
          #$self->log->("Got chunk of size $chunksize");
          #$self->log->(">>$$buffer<<");
          $self->_response->add_content(substr($$buffer,0,$chunksize));
          #$self->log->(substr($$buffer,0,$chunksize));
          $$buffer = substr($$buffer,$chunksize);
          $$buffer =~ s!^\r\n!!;
          #$self->log->(sprintf "Remaining are %s bytes ($$buffer)", length $$buffer);

          $self->_response_chunk_size(undef);
          if ($chunksize == 0) {
            $self->log->("Got chunksize 0, reporting response");
            $self->report_response($res);
            #$$buffer =~ s!^\r\n!!;

            if ($$buffer eq '') {
              return;
            };
          } elsif (length $$buffer) {
            # Get next chunksize, if available
            $chunksize = $self->extract_chunksize($buffer);
            #$self->log->("Next size is $chunksize");
          } else {
            # We've read/received exactly the chunk.
          };

          return
            if ! defined $chunksize;
        };
      };
      return
    };

    # Non-chunked handling:
    if (defined $len and length $$buffer < $len) {
      # need more data before header is complete
      $self->log->(sprintf "Need more response body data (%0.0f%%)\r", 100 * ((length $$buffer) / $len))
        if $len;
      return;
    };

    if (defined $len and $len == 0) {
      # can only flush at closing of connection
      $self->log->("Would need to collect whole buffer in connection (unimplemented, taking what I've got)" );
      $len = length $$buffer;
    };

    $self->report_response_buffer($buffer,$len);
  };
};

sub report_response_buffer {
  my ($self,$buffer,$len) = @_;
  my $res = $self->_response;

  $len = length $$buffer
    if (! defined $len);

  $res->content(substr($$buffer,0,$len));
  $self->log->("Response header and content are ready ($len bytes)");

  $$buffer = substr($$buffer,$len);
  if (length $$buffer) {
    $self->log->("Leftover data: $$buffer");
  };
  $self->report_response($res);
};

sub report_response {
  my ($self,$res) = @_;
  $self->response->($res,$self->prev_request,$self);
  $self->_response(undef);
  $self->_response_len(undef);
};

sub flush_sent {
  my ($self) = @_;
  my $buffer = $self->sent_buffer;
  while ($$buffer) {
    if (! (my $req = $self->_request)) {
      # We need to find something that looks like a valid HTTP request in our stream
      $$buffer =~ s!.*^(GET|POST)!$1!m;

      if (! ($$buffer =~ s!^(.*?\r?\n\r?\n)!!sm)) {
        # need more data before header is complete
        $self->log->("Need more header data");
        #$self->sent_buffer($buffer);
        return;
      };

      # Consider prepending the hostname in front of
      # the URI for nicer equivalence with HTTP::Proxy?

      $self->log->("Got header");
      my $h = $1;
      $req = HTTP::Request->parse($h);

      my $host;
      # should be the IP address of some TCP packet if we don't find the header ...
      if ($req->header('Host')) {
        $host = $req->header('Host');
      } else {
        warn "Missing Host: header. Don't know how to determine hostname";
        $host = "???"
      };
      $req->uri->scheme('http');
      $req->uri->host($host);
      #$req->uri->port(80); # fix from TCP packet!

      $self->_request($req);
    };

    my $req = $self->_request;
    my $len = $req->header('Content-Length') || 0; # length $$buffer; # not clean

    if (length $$buffer < $len) {
      # need more data before header is complete
      return;
    };

    $self->_request->content(substr($$buffer,0,$len));
    $self->log->("Request header and content are ready ($len bytes)");

    $self->request->($req,$self);

    $$buffer = substr($$buffer,$len);

    # Tie request and response together in a better way than serial request->response->request ...
    $self->prev_request($req);
    $self->_request(undef);
  };
};

# Delegate some methods
sub handle_packet { my $self = shift;$self->tcp_connection->handle_packet(@_); };
sub flow { my $self = shift; return $self->tcp_connection->flow(@_);};
sub last_activity { my $self = shift; $self->tcp_connection->last_activity(@_) }

1;

=head1 TODO

=over 4

=item *

Think about pipelined connections. These are not easily massaged into the
request/response scheme. Well, maybe they are, with a bit of hidden
logic here.

=item *

Every response accumulates all data in memory instead of
giving the user the partial response so it can be written
to disk. This should maybe later be improved.

=back

=head1 BUGS

The whole module suite has almost no tests.

If you experience problems, I<please> supply me with a complete,
relevant packet dump as the included C<dump-raw.pl> creates. Even
better, supply me with (failing) tests.

=head1 AUTHOR

Max Maischein (corion@cpan.org)

=head1 COPYRIGHT

Copyright (C) 2005-2021 Max Maischein.  All Rights Reserved.

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

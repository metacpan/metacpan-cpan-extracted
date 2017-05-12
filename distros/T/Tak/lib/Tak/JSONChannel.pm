package Tak::JSONChannel;

use JSON::PP qw(encode_json decode_json);
use IO::Handle;
use Scalar::Util qw(weaken);
use Log::Contextual qw(:log);
use Moo;

has read_fh => (is => 'ro', required => 1);
has write_fh => (is => 'ro', required => 1);

has _read_buf => (is => 'ro', default => sub { my $x = ''; \$x });

sub BUILD { shift->write_fh->autoflush(1); }

sub read_messages {
  my ($self, $cb) = @_;
  my $rb = $self->_read_buf;
  if (sysread($self->read_fh, $$rb, 1024, length($$rb)) > 0) {
    while ($$rb =~ s/^(.*)\n//) {
      my $line = $1;
      log_trace { "Received $line" };
      if (my $unpacked = $self->_unpack_line($line)) {
        $cb->(@$unpacked);
      }
    }
  } else {
    log_trace { "Closing" };
    $cb->('close', 'channel');
  }
}

sub _unpack_line {
  my ($self, $line) = @_;
  my $data = eval { decode_json($line) };
  unless ($data) {
    $self->write_message(mistake => invalid_json => $@||'No data and no exception');
    return;
  }
  unless (ref($data) eq 'ARRAY') {
    $self->write_message(mistake => message_format => "Not an ARRAY");
    return;
  }
  unless (@$data > 0) {
    $self->write_message(mistake => message_format => "Empty request array");
    return;
  }
  $data;
}

sub write_message {
  my ($self, @msg) = @_;
  my $json = eval { encode_json(\@msg) };
  unless ($json) {
    $self->_raw_write_message(
      encode_json(
        [ failure => invalid_message => $@||'No data and no exception' ]
      )
    );
    return;
  }
  log_trace { "Sending: $json" };
  $self->_raw_write_message($json);
}

sub _raw_write_message {
  my ($self, $raw) = @_;
#warn "Sending: ${raw}\n";
  print { $self->write_fh } $raw."\n"
    or log_error { "Error writing: $!" };
}

1;

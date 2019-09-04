package Protocol::Redis::Faster;

use strict;
use warnings;
use Carp ();

use parent 'Protocol::Redis';

our $VERSION = '0.003';

my %simple_types = ('+' => 1, '-' => 1, ':' => 1);

sub encode {
  my $self = shift;

  my $encoded = '';
  while (@_) {
    my $message = shift;

    # Order optimized for client encoding;
    # client commands are sent as arrays of bulk strings

    # Bulk strings
    if ($message->{type} eq '$') {
      if (defined $message->{data}) {
        $encoded .= '$' . length($message->{data}) . "\r\n" . $message->{data} . "\r\n";
      }
      else {
        $encoded .= '$-1' . "\r\n";
      }
    }

    # Arrays
    elsif ($message->{type} eq '*') {
      if (defined $message->{data}) {
        $encoded .= '*' . scalar(@{$message->{data}}) . "\r\n";
        unshift @_, @{$message->{data}};
      }
      else {
        $encoded .= '*-1' . "\r\n";
      }
    }

    # Simple strings, errors, and integers
    elsif (exists $simple_types{$message->{type}}) {
      $encoded .= $message->{type} . $message->{data} . "\r\n";
    }

    # Invalid type
    else {
      Carp::croak(qq/Unknown message type $message->{type}/);
    }
  }

  return $encoded;
}

sub get_message { shift @{$_[0]{_messages}} }

sub on_message {
  my ($self, $cb) = @_;
  $self->{_on_message_cb} = $cb;
}

sub parse {
  my ($self, $input) = @_;
  $self->{_buf} .= $input;

  my $buf = \$self->{_buf};

  CHUNK:
  while (length $$buf) {

    # Look for message type and get the actual data,
    # length of the bulk string or the size of the array
    if (!$self->{_curr}{type}) {
      my $pos = index $$buf, "\r\n";
      return if $pos < 0; # Wait for more data

      $self->{_curr}{type} = substr $$buf, 0, 1;
      $self->{_curr}{len}  = substr $$buf, 1, $pos - 1;
      substr $$buf, 0, $pos + 2, ''; # Remove type + length/data + \r\n
    }

    # Order optimized for client decoding;
    # large array replies usually contain bulk strings

    # Bulk strings
    if ($self->{_curr}{type} eq '$') {
      if ($self->{_curr}{len} == -1) {
        $self->{_curr}{data} = undef;
      }
      elsif (length($$buf) - 2 < $self->{_curr}{len}) {
        return; # Wait for more data
      }
      else {
        $self->{_curr}{data} = substr $$buf, 0, $self->{_curr}{len}, '';
        substr $$buf, 0, 2, ''; # Remove \r\n
      }
    }

    # Simple strings, errors, and integers
    elsif (exists $simple_types{$self->{_curr}{type}}) {
      $self->{_curr}{data} = delete $self->{_curr}{len};
    }

    # Arrays
    elsif ($self->{_curr}{type} eq '*') {
      $self->{_curr}{data} = $self->{_curr}{len} < 0 ? undef : [];

      # Fill the array with data
      if ($self->{_curr}{len} > 0) {
        $self->{_curr} = {parent => $self->{_curr}};
        next CHUNK;
      }
    }

    # Invalid input
    else {
      Carp::croak(qq/Unexpected input "$self->{_curr}{type}"/);
    }

    # Fill parent array with data
    while (my $parent = delete $self->{_curr}{parent}) {
      delete $self->{_curr}{len};
      push @{$parent->{data}}, $self->{_curr};

      if (@{$parent->{data}} < $parent->{len}) {
        $self->{_curr} = {parent => $parent};
        next CHUNK;
      }
      else {
        $self->{_curr} = $parent;
      }
    }

    # Emit a complete message
    delete $self->{_curr}{len};
    if (defined $self->{_on_message_cb}) {
      $self->{_on_message_cb}->($self, delete $self->{_curr});
    } else {
      push @{$self->{_messages}}, delete $self->{_curr};
    }
  }
}

1;

=head1 NAME

Protocol::Redis::Faster - Optimized pure-perl Redis protocol parser/encoder

=head1 SYNOPSIS

  use Protocol::Redis::Faster;
  my $redis = Protocol::Redis::Faster->new(api => 1) or die "API v1 not supported";

  $redis->parse("+foo\r\n");

  # get parsed message
  my $message = $redis->get_message;
  print "parsed message: ", $message->{data}, "\n";

  # asynchronous parsing interface
  $redis->on_message(sub {
      my ($redis, $message) = @_;
      print "parsed message: ", $message->{data}, "\n";
  });

  # parse pipelined message
  $redis->parse("+bar\r\n-error\r\n");

  # create message
  print "Get key message:\n",
    $redis->encode({type => '*', data => [
       {type => '$', data => 'string'},
       {type => '+', data => 'OK'}
  ]});

=head1 DESCRIPTION

This module implements the L<Protocol::Redis> API with more optimized pure-perl
internals. See L<Protocol::Redis> for usage documentation.

This is a low level parsing module, if you are looking to use Redis in Perl,
try L<Redis>, L<Redis::hiredis>, or L<Mojo::Redis>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHORS

Dan Book <dbook@cpan.org>

Jan Henning Thorsen <jhthorsen@cpan.org>

=head1 CREDITS

Thanks to Sergey Zasenko <undef@cpan.org> for the original L<Protocol::Redis>
and defining the API.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book, Jan Henning Thorsen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Protocol::Redis>

package Net::Graphite;
use strict;
use warnings;
use Errno qw(EINTR);
use Carp qw/confess/;
use IO::Socket::INET;
use Scalar::Util qw/reftype/;

$Net::Graphite::VERSION = '0.17';

our $TEST = 0;   # if true, don't send anything to graphite

sub new {
    my $class = shift;
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    return bless {
        host                 => '127.0.0.1',
        port                 => 2003,
        fire_and_forget      => 0,
        return_connect_error => 0,
        proto                => 'tcp',
        timeout              => 1,
        # path
        # transformer
        %args,
        # _socket
    }, $class;
}

sub send {
    my $self = shift;
    my $value;
    $value = shift if @_ % 2;   # single value passed in
    my %args = @_;

    my $plaintext;
    if ($args{data}) {
        my $xform = $args{transformer} || $self->transformer;
        if ($xform) {
            $plaintext = $xform->($args{data});
        }
        else {
            if (ref $args{data}) {
                my $reftype = reftype $args{data};

                # default transformers
                if ($reftype eq 'HASH') {
                    # hash structure from Yves
                    my $start_path = $args{path} ? $args{path} : $self->path;
                    foreach my $epoch (sort {$a <=> $b} keys %{ $args{data} }) {
                        _fill_lines_for_epoch(\$plaintext, $epoch, $args{data}{$epoch}, $start_path);
                    }
                }
                # TODO - not sure what structure is most useful;
                # an aref of [$path, $value, $epoch] seems a bit trivial?
                # elsif ($reftype eq 'ARRAY') {
                #
                # }
                # TODO
                # elsif ($reftype eq 'CODE') {
                #     my $iter = $args{data};
                #     while (my $text = $iter->()) {
                #         $plaintext .= $text;
                #     }
                # }
                # how about sth of DBI? XML? maybe not
                else {
                    confess "Arg 'data' passed to send method is a ref but has no plaintext transformer";
                }
            }
            else {
                # this obsoletes plaintext; just pass 'data' without a transformer
                $plaintext = $args{data};
            }
        }
    }
    else {
        $value   = $args{value} unless defined $value;
        my $path = $args{path} || $self->path;
        my $time = $args{time} || time;

        $plaintext = "$path $value $time\n";
    }

    $self->trace($plaintext) if $self->{trace};

    unless ($Net::Graphite::TEST) {
        if ($self->connect()) {
            my $buf = $plaintext;
            while (length($buf)) {
                my $res = $self->{_socket}->send($buf);
                if (not defined $res) {
                    next if $! == EINTR;
                    last; # not sure what to do here
                }

                last unless $res; # should never happen
                substr($buf, 0, $res, '');
            }
        }
        # I didn't close the socket!
    }

    return $plaintext;
}

sub _fill_lines_for_epoch {
    # note: $in_out_str_ref is a reference to a string,
    # not so much for performance but as an accumulator in this recursive function
    my ($in_out_str_ref, $epoch, $hash, $path) = @_;

    # still in the "branches"
    if (ref $hash) {
        foreach my $key (sort keys %$hash) {
            my $value = $hash->{$key};
            _fill_lines_for_epoch($in_out_str_ref, $epoch, $value, "$path.$key");
        }
    }
    # reached the "leaf" value
    else {
        $$in_out_str_ref .= "$path $hash $epoch\n";
    }
}

sub connect {
    my $self = shift;
    return $self->{_socket}
      if $self->{_socket} && $self->{_socket}->connected;

    $self->{_socket} = IO::Socket::INET->new(
        PeerHost => $self->{host},
        PeerPort => $self->{port},
        Proto    => $self->{proto},
        Timeout  => $self->{timeout},
    );

    unless ($self->{_socket}) {
        if ($self->{return_connect_error}) {
            # This is probably only used if you call $graphite->connect before ->send
            # in order to check if there is a connection;
            # otherwise, it'll just "forget" (without even "firing").
            return;
        }
        elsif (not $self->{fire_and_forget}) {
            confess "Error creating socket: $!";
        }
    }
    return $self->{_socket};
}

# if you need to close/flush for some reason
sub close {
    my $self = shift;
    return unless my $socket = delete $self->{_socket};
    $socket->close();
}

sub trace {
    my (undef, $val_line) = @_;
    print STDERR $val_line;
}

### mutators
sub path {
    my ($self, $path) = @_;
    $self->{path} = $path if defined $path;
    return $self->{path};
}
sub transformer {
    my ($self, $xform) = @_;
    $self->{transformer} = $xform if defined $xform;
    return $self->{transformer};
}

1;
__END__

=pod

=head1 NAME

Net::Graphite - Interface to Graphite

=head1 SYNOPSIS

  use Net::Graphite;
  my $graphite = Net::Graphite->new(
      # except for host, these hopefully have reasonable defaults, so are optional
      host                  => '127.0.0.1',
      port                  => 2003,
      trace                 => 0,                # if true, copy what's sent to STDERR
      proto                 => 'tcp',            # can be 'udp'
      timeout               => 1,                # timeout of socket connect in seconds
      fire_and_forget       => 0,                # if true, ignore sending errors
      return_connect_error  => 0,                # if true, forward connect error to caller

      path                  => 'foo.bar.baz', # optional, use when sending single values
  );

  # to check for connection error (when return_connect_error => 1) do:
  die "connection error: $!" unless $graphite->connect;

  # send a single value,
  # need to set path in the call to new
  # or call $graphite->path('some.path') beforehand
  $graphite->send(6);        # default time is "now"

 -OR-

  # send a metric with named parameters
  $graphite->send(
      path => 'foo.bar.baz',
      value => 6,
      time => time(),        # time defaults to "now"
  );

 -OR-

  # send text with one line per metric, following the plaintext protocol
  $graphite->send(data => $string_with_one_line_per_metric);

 -OR-

  # send a data structure,
  # here using the default transformer for Hash of Hash: epoch => key => key .... => value
  $graphite->send(path => 'foo', data => $hash);

  # example of hash structure:
  1234567890 => {
      bar => {
          db1 => 3,
          db2 => 7,
          db3 => 2,
          ....
      },
      baz => 42,
  },
  would be:
  foo.bar.db1 = 3
  foo.bar.db2 = 7
  foo.bar.db3 = 2
  foo.baz = 42

 -OR-

  # send a data structure, providing your own plaintext transformer
  # (the callback's only arg is the data structure, return a text string one metric on each line)
  $graphite->send(data => $whatever, transformer => \&make_whatever_into_plaintext);

=head1 DESCRIPTION

Interface to Graphite which doesn't depend on AnyEvent.

=head1 INSTANCE METHODS

=head2 close

Explicitly close the socket to the graphite server.
Not normally needed,
because the socket will close when the $graphite object goes out of scope.

=head2 connect

Get an open a socket to the graphite server, either the currently connected one
or, if not already connected, a new one.
Not normally needed.

=head2 path

Set the default path (corresponds to 'path' argument to new),
for use when sending single values.

=head2 send

Normally all you need to use. See the SYNOPSIS. (FIXME)

=head2 transformer

If you pass a 'data' argument to send,
use this coderef to transform from the data structure to plaintext.
The coderef receives the data structure as its only parameter.
There are default transformers for certain reftypes.

=head1 SEE ALSO

AnyEvent::Graphite

L<http://graphite.readthedocs.org/>

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

=cut

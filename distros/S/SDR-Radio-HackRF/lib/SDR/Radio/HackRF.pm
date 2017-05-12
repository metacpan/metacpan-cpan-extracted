package SDR::Radio::HackRF;

our $VERSION = '0.100';

require XSLoader;
XSLoader::load('SDR::Radio::HackRF', $VERSION);

use common::sense;
use AnyEvent;
use AnyEvent::Util;


sub new {
  my ($class, %args) = @_;

  my $self = {};
  bless $self, $class;

  $self->{ctx} = new_context();
  $self->{state} = 'IDLE';

  ($self->{perl_side_signalling_fh}, $self->{c_side_signalling_fh}) = AnyEvent::Util::portable_socketpair();

  die "couldn't create signalling socketpair: $!" if !$self->{perl_side_signalling_fh};

  _set_signalling_fd($self->{ctx}, fileno($self->{c_side_signalling_fh}));

  ## always turn amp off -- keep off as much as possible so it doesn't accidentally fry
  _set_amp_enable($self->{ctx}, 0);

  if (!$args{dont_handle_sigint}) {
    $SIG{INT} = sub {
      $self->stop;
      exit;
    };
  }

  return $self;
}


sub tx {
  my ($self, $cb) = @_;

  die "already in $self->{state} state" if $self->{state} ne 'IDLE';
  $self->{state} = 'TX';

  $self->{pipe_watcher} = AE::io $self->{perl_side_signalling_fh}, 0, sub {
    sysread $self->{perl_side_signalling_fh}, my $junk, 1; ## FIXME: non-blocking

    my $buffer_size = _get_buffer_size($self->{ctx});

    my $bytes = $cb->($buffer_size);

    if (!defined $bytes) {
      $self->stop;
      return;
    }

    _copy_to_buffer($self->{ctx}, $$bytes);

    syswrite $self->{perl_side_signalling_fh}, "\x00";
  };

  _start_tx($self->{ctx});
}

sub rx {
  my ($self, $cb) = @_;

  die "already in $self->{state} state" if $self->{state} ne 'IDLE';
  $self->{state} = 'RX';

  $self->{pipe_watcher} = AE::io $self->{perl_side_signalling_fh}, 0, sub {
    sysread $self->{perl_side_signalling_fh}, my $junk, 1; ## FIXME: non-blocking

    my $buffer = _copy_from_buffer($self->{ctx});

    $cb->($buffer);

    syswrite $self->{perl_side_signalling_fh}, "\x00";
  };

  _start_rx($self->{ctx});
}



sub frequency {
  my ($self, $freq) = @_;

  die "getter not implemented yet" if !defined $freq;

  _set_freq($self->{ctx}, $freq);
}

sub sample_rate {
  my ($self, $sample_rate) = @_;

  die "getter not implemented yet" if !defined $sample_rate;

  _set_sample_rate($self->{ctx}, $sample_rate);
}

sub amp_enable {
  my ($self, $amp_enable) = @_;

  die "getter not implemented yet" if !defined $amp_enable;

  $amp_enable = $amp_enable ? 1 : 0;

  _set_amp_enable($self->{ctx}, $amp_enable);
}



sub stop {
  my ($self) = @_;

  if ($self->{state} eq 'TX') {
    $self->_stop_callback();
    _stop_tx($self->{ctx});
  } elsif ($self->{state} eq 'RX') {
    $self->_stop_callback();
    _stop_rx($self->{ctx});
  } else {
    warn "called stop but in state '$self->{state}'";
  }
}


sub _stop_callback {
  my ($self) = @_;

  _set_terminate_callback_flag($self->{ctx});

  $self->{state} = 'TERM';

  syswrite $self->{perl_side_signalling_fh}, "\x00";

  $self->{pipe_watcher} = AE::io $self->{perl_side_signalling_fh}, 0, sub {
    sysread $self->{perl_side_signalling_fh}, my $junk, 1; ## FIXME: non-blocking

    delete $self->{pipe_watcher};
    delete $self->{state};
  };
}



sub run {
  my ($self) = @_;

  $self->{cv} = AE::cv;

  $self->{cv}->recv;
}



1;



__END__

=encoding utf-8

=head1 NAME

SDR::Radio::HackRF - Control HackRF software defined radio

=head1 SYNOPSIS

TX:

    my $radio = SDR::Radio::HackRF->new;

    $radio->frequency(35_000_000);
    $radio->sample_rate(8_000_000);

    $radio->tx(sub {
        my $block_size = shift;

        my $output = "\x00" x $block_size;

        return \$output;
    });

    $radio->run;

RX:

    my $radio = SDR::Radio::HackRF->new;

    $radio->frequency(35_000_000);
    $radio->sample_rate(8_000_000);

    $radio->rx(sub {
        ## Process data in $_[0]
    });

    $radio->run;

=head1 DESCRIPTION

This is the L<SDR> driver for L<HackRF|http://greatscottgadgets.com/hackrf/> devices.

Although you can use it by itself, see the L<SDR> docs for more generic usage.

In order to install this module you will need C<libhackrf> installed. On Ubuntu/Debian you can run:

    sudo apt-get install libhackrf-dev

NOTE: This module creates background threads so you should not fork after creating C<SDR::Radio::HackRF> objects.

=head1 SEE ALSO

L<SDR-Radio-HackRF github repo|https://github.com/hoytech/SDR-Radio-HackRF>

L<SDR> - The main module, includes examples

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2015 Doug Hoyte.

This module is licensed under the same terms as perl itself.

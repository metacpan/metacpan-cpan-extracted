package SDR;

use common::sense;

our $VERSION = '0.100';

use Symbol;



our $known_radio_capabilities = {
  tx => [qw{ HackRF }],
  rx => [qw{ HackRF RTLSDR }],
};


sub radio {
  my ($class, %args) = @_;

  my $can = $args{can} || 'rx'; ## FIXME: support requesting multiple capabilities as an array ref

  my $possible_radios = $known_radio_capabilities->{$can};

  my @errors;
  my $radio;

  foreach my $radio_name (@$possible_radios) {
    my $module = "SDR::Radio::$radio_name";

    eval "require $module";
    if ($@) {
      push @errors, "$module -- not installed";
      next;
    }

    $radio = eval {
      no strict "refs";
      return qualify("new", $module)->($module, %{ $args{args} });
    };

    if ($@) {
      push @errors, "$module -- $@";
      next;
    }

    last;
  }

  return $radio if $radio;

  die "Unable to find any suitable radio:\n\n" . join("\n", @errors) . "\nPlease install one of the above modules.\n";
}



sub audio_sink {
  my ($class, %args) = @_;

  my $audio_sink;
  my @errors;

  my $sample_rate = $args{sample_rate};
  die "need sample_rate" if !defined $sample_rate;

  my $format = $args{format};
  die "unsupported format: $format" if $format ne 'float'; ## FIXME

  eval {
    open($audio_sink,
         '|-:raw',
         qw{ pacat --stream-name fmrecv --format float32le --channels 1 --latency-msec 10 },
                   '--rate' => $sample_rate,
        ) || die "failed to run pacat: $!";
  };

  if ($@) {
    push @errors, "pulse audio: $@";
  } else {
    return $audio_sink;
  }

  eval {
    open($audio_sink,
         '|-:raw',
         qw{ play -t raw -e float -b 32 -c 1 -q },
         '-r' => $sample_rate,
         '-',
        ) || die "failed to run play: $!";
  };

  if ($@) {
    push @errors, "SoX: $@";
  } else {
    return $audio_sink;
  }

  die "Unable to run any suitable audio sink:\n\n" . join("\n", @errors);
}





1;



__END__


=encoding utf-8

=head1 NAME

SDR - Software-Defined Radio

=head1 SYNOPSIS

    use SDR;

    my $radio = SDR->radio(can => 'rx');

    $radio->frequency(104_500_000);
    $radio->sample_rate(2_000_000);

    $radio->rx(sub {
      ## process IQ samples in $_[0]
    });

    $radio->run;

=head1 DESCRIPTION

This is the parent module and primary interface for the SDR system of perl modules.

SDR stands for Software-Defined Radio. It is a technology where raw radio samples are created and decoded purely in software -- kind of like a "sound card for radio". It's exciting because a single device can communicate using many different modulations and protocols, usually across a large range of frequencies.

It provides a wrapper around certain tasks like creating a radio with the C<radio> method and creating an audio sink with the C<audio_sink> method. There are also some handy utilities in L<SDR::DSP>.

When creating a radio, you specify what capabilities you want the radio to have (currently either C<tx> or C<rx>). The C<radio> method will figure out which SDRs you have drivers installed for and which, if any, are currently plugged in. It will use the first suitable one it can find.

NOTE: The current radio drivers create background threads so you shouldn't fork after you create instances of any radio objects.


=head1 DRIVERS

L<SDR::Radio::HackRF> - Can transmit and receive.

L<SDR::Radio::RTLSDR> - Can only receive.


=head1 SEE ALSO

L<SDR github repo|https://github.com/hoytech/SDR>

The examples in the C<ex/> directory of this distribution.


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2015 Doug Hoyte.

This module is licensed under the same terms as perl itself.

package Spoon::Trace;
use Spiffy -Base;
use Time::HiRes qw(gettimeofday);

my $global_self;

field data => [];
field show_num => 1;
field show_time => 1;
field auto_print => 0;
field auto_warn => 0;
field add_label => 0;

sub mode1 {
    $self->show_num(0);
    $self->show_time(0);
    $self->add_label(1);
    return $self;
}

sub trace() {
    $global_self = defined $global_self
    ? $global_self
    : Spoon::Trace->new;
}

sub mark {
    my $label = @_
    ? join(' ', @_) . ($self->add_label && "\t(" . $self->get_label . ')')
    : $self->get_label;
    my $data = $self->data;
    my ($seconds, $microseconds) = gettimeofday;
    push @$data, +{
        label => $label,
        time => $seconds + $microseconds / 1000000,
    };
    return $self;
}

sub get_label {
    my $i = (caller(2))[3] eq 'Spoon::Base::t' ? 1 : 0;
    my $line = (caller(1 + $i))[2];
    my $sub = (caller(2 + $i))[3];
    return "$sub,$line";
}

sub clear {
    $global_self = undef;
    $self->data([]);
    return $self;
}

sub report {
    my $data = $self->data;
    my $output = '';
    return $output unless @$data;
    my $base_time = $data->[0]{time};
    for (my $i = 0; $i < @$data; $i++) {
        if ($self->show_num) {
            $output .= sprintf "%03d) ", $i + 1;
        }
        if ($self->show_time) {
            $output .= sprintf "%2.4f %2.2f ",
              $i ? $data->[$i]{time} - $data->[$i - 1]{time} : 0,
              $data->[$i]{time} - $base_time;
        }
        $output .= $data->[$i]{label} . "\n";
    }
    return $output;
}

sub DESTROY {
    print $self->report
      if $self->auto_print;
    warn $self->report
      if $self->auto_warn;
}

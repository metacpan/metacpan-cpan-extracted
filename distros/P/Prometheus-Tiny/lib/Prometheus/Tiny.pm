package Prometheus::Tiny;
$Prometheus::Tiny::VERSION = '0.011';
# ABSTRACT: A tiny Prometheus client

use warnings;
use strict;

use Carp qw(croak carp);
use Scalar::Util qw(looks_like_number);

my $DEFAULT_BUCKETS = [
               0.005,
  0.01, 0.025, 0.05, 0.075,
  0.1,  0.25,  0.5,  0.75,
  1.0,  2.5,   5.0,  7.5,
  10
];

sub new {
  my ($class, %arg) = @_;
  my %defaults = $arg{default_labels} ? %{$arg{default_labels}} : ();
  return bless {
    metrics => {},
    meta => {},
    default_labels => \%defaults,
  }, $class;
}

sub _format_labels {
  my ($self, $labels) = @_;

  # Avoid copying the labels hash unless we need to add defaults.
  my $to_format = $self->{default_labels}
                ? { %{$self->{default_labels}}, %{$labels || {}} }
                : $labels;

  join ',', map {
    my $lv = $to_format->{$_};
    if (defined $lv) {
      $lv =~ s/(["\\])/\\$1/sg;
      $lv =~ s/\n/\\n/sg;
      qq{$_="$lv"}
    } else {
      carp "label '$_' has an undefined value, dropping it";
      ()
    }
  } sort keys %$to_format;
}

sub set {
  my ($self, $name, $value, $labels, $timestamp) = @_;
  unless (looks_like_number $value) {
    carp "setting '$name' to non-numeric value, using 0 instead";
    $value = 0;
  }
  my $f_label = $self->_format_labels($labels);
  $self->{metrics}{$name}{$f_label} = [ $value, $timestamp ];
  return;
}

sub add {
  my ($self, $name, $value, $labels) = @_;
  unless (looks_like_number $value) {
    carp "adjusting '$name' by non-numeric value, adding 0 instead";
    $value = 0;
  }
  $self->{metrics}{$name}{$self->_format_labels($labels)}->[0] += $value;
  return;
}

sub inc {
  my ($self, $name, $labels) = @_;
  return $self->add($name, 1, $labels);
}

sub dec {
  my ($self, $name, $labels) = @_;
  return $self->add($name, -1, $labels);
}

sub clear {
  my ($self, $name) = @_;
  $self->{metrics} = {};
  return;
}

sub histogram_observe {
  my ($self, $name, $value, $labels) = @_;

  $self->inc($name.'_count', $labels);
  $self->add($name.'_sum', $value, $labels);

  my @buckets = @{$self->{meta}{$name}{buckets} || $DEFAULT_BUCKETS};

  my $bucket_metric = $name.'_bucket';
  for my $bucket (@buckets) {
    $self->add($bucket_metric, $value <= $bucket ? 1 : 0, { %{$labels || {}} , le => $bucket });
  }
  $self->inc($bucket_metric, { %{$labels || {}}, le => '+Inf' });

  return;
}

sub enum_set {
  my ($self, $name, $value, $labels, $timestamp) = @_;

  my $enum_label = $self->{meta}{$name}{enum} ||
    croak "enum not declared for '$name'";

  for my $ev (@{$self->{meta}{$name}{enum_values} || []}) {
    $self->set($name, $value eq $ev ? 1 : 0, { %{$labels || {}}, $enum_label => $ev }, $timestamp);
  }
}

sub declare {
  my ($self, $name, %meta) = @_;

  if (my $old = $self->{meta}{$name}) {
    if (
      ((exists $old->{type} ^ exists $meta{type}) ||
       (exists $old->{type} && $old->{type} ne $meta{type})) ||
      ((exists $old->{help} ^ exists $meta{help}) ||
       (exists $old->{help} && $old->{help} ne $meta{help})) ||
      ((exists $old->{enum} ^ exists $meta{enum}) ||
       (exists $old->{enum} && $old->{enum} ne $meta{enum})) ||
      ((exists $old->{buckets} ^ exists $meta{buckets}) ||
       (exists $old->{buckets} && (
        @{$old->{buckets}} ne @{$meta{buckets}} ||
        grep { $old->{buckets}[$_] != $meta{buckets}[$_] } (0 .. $#{$meta{buckets}})
       ))
      ) ||
      ((exists $old->{enum_values} ^ exists $meta{enum_values}) ||
       (exists $old->{enum_values} && (
        @{$old->{enum_values}} ne @{$meta{enum_values}} ||
        grep { $old->{enum_values}[$_] ne $meta{enum_values}[$_] } (0 .. $#{$meta{enum_values}})
       ))
      )
    ) {
      croak "redeclaration of '$name' with mismatched meta";
    }
  }

  $self->{meta}{$name} = { %meta };
  return;
}

sub format {
  my ($self) = @_;
  my %names = map { $_ => 1 } (keys %{$self->{metrics}}, keys %{$self->{meta}});
  return join '', map {
    my $name = $_;
    (
      (defined $self->{meta}{$name}{help} ?
        ("# HELP $name $self->{meta}{$name}{help}\n") : ()),
      (defined $self->{meta}{$name}{type} ?
        ("# TYPE $name $self->{meta}{$name}{type}\n") : ()),
      (map {
        my $v = join ' ', grep { defined $_ } @{$self->{metrics}{$name}{$_}};
        $_ ?
          join '', $name, '{', $_, '} ', $v, "\n" :
          join '', $name, ' ', $v, "\n"
      } sort {
        $name =~ m/_bucket$/ ?
          do {
            my $t_a = $a; $t_a =~ s/le="([^"]+)"//; my $le_a = $1;
            my $t_b = $b; $t_b =~ s/le="([^"]+)"//; my $le_b = $1;
            $t_a eq $t_b ?
              do {
                $le_a eq '+Inf' ? 1 :
                $le_b eq '+Inf' ? -1 :
                ($a cmp $b)
              } :
              ($a cmp $b)
          } :
          ($a cmp $b)
      } keys %{$self->{metrics}{$name}}),
    )
  } sort keys %names;
}

sub psgi {
  my ($self) = @_;
  return sub {
    my ($env) = @_;
    return [ 405, [], [] ] unless $env->{REQUEST_METHOD} eq 'GET';
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $self->format ] ];
  };
}

1;

__END__

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Prometheus-Tiny.png)](http://travis-ci.org/robn/Prometheus-Tiny)

=head1 NAME

Prometheus::Tiny - A tiny Prometheus client

=head1 SYNOPSIS

    use Prometheus::Tiny;

    my $prom = Prometheus::Tiny->new;
    $prom->set('some_metric', 5, { some_label => "aaa" });
    print $prom->format;

=head1 DESCRIPTION

C<Prometheus::Tiny> is a minimal metrics client for the
L<Prometheus|http://prometheus.io/> time-series database.

It does the following things differently to L<Net::Prometheus>:

=over 4

=item *

No setup. You don't need to pre-declare metrics to get something useful.

=item *

Labels are passed in a hash. Positional parameters get awkward.

=item *

No inbuilt collectors, PSGI apps, etc. Just the metrics.

=item *

Doesn't know anything about different metric types. You get what you ask for.

=back

These could all be pros or cons, depending on what you need. For me, I needed a
compact base that I could back on a shared memory region. See
L<Prometheus::Tiny::Shared> for that!

=head1 CONSTRUCTOR

=head2 new

    my $prom = Prometheus::Tiny->new;
    my $prom = Promethus::Tiny->new(default_labels => { my_label => "frob" });

If you pass a C<default_labels> key to the constructor, these labels will be
included in every metric created on this object.


=head1 METHODS

=head2 set

    $prom->set($name, $value, { labels }, [timestamp])

Set the value for the named metric. The labels hashref is optional. The timestamp (milliseconds since epoch) is optional, but requires labels to be provided to use. An empty hashref will work in the case of no labels.

Trying to set a metric to a non-numeric value will emit a warning and the metric will be set to zero.

=head2 add

    $prom->add($name, $amount, { labels })

Add the given amount to the already-stored value (or 0 if it doesn't exist). The labels hashref is optional.

Trying to add a non-numeric value to a metric will emit a warning and 0 will be added instead (this will still create the metric if it didn't exist, and will update timestamps etc).

=head2 inc

    $prom->inc($name, { labels })

A shortcut for

    $prom->add($name, 1, { labels })

=head2 dec

    $prom->dec($name, { labels })

A shortcut for

    $prom->add($name, -1, { labels })

=head2 clear

    $prom->clear;

Remove all stored metric values. Metric metadata (set by C<declare>) is preserved.

=head2 histogram_observe

    $prom->histogram_observe($name, $value, { labels })

Record a histogram observation. The labels hashref is optional.

You should declare your metric beforehand, using the C<buckets> key to set the
buckets you want to use. If you don't, the following buckets will be used.

    [ 0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10 ]

=head2 enum_set

    $prom->enum_set($name, $value, { labels }, [timestamp])

Set an enum value for the named metric. The labels hashref is optiona. The timestamp is optional.

You should declare your metric beforehand, using the C<enum> key to set the
label to use for the enum value, and the C<enum_values> key to list the
possible values for the enum.


=head2 declare

    $prom->declare($name, help => $help, type => $type, buckets => [...])

"Declare" a metric by associating metadata with it. Valid keys are:

=over 4

=item C<help>

Text describing the metric. This will appear in the formatted output sent to Prometheus.

=item C<type>

Type of the metric, typically C<gauge> or C<counter>.

=item C<buckets>

For C<histogram> metrics, an arrayref of the buckets to use. See C<histogram_observe>.

=item C<enum>

For C<enum> metrics, the name of the label to use for the enum value. See C<enum_set>.

=item C<enum_values>

For C<enum> metrics, the possible values the enum can take. See C<enum_set>.

=back

Declaring a already-declared metric will work, but only if the metadata keys
and values match the previous call. If not, C<declare> will throw an exception.

=head2 format

    my $metrics = $prom->format

Output the stored metrics, values, help text and types in the L<Prometheus exposition format|https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md>.

=head2 psgi

    use Plack::Builder
    builder {
      mount "/metrics" => $prom->psgi;
    };

Returns a simple PSGI app that, when hooked up to a web server and called, will
return formatted metrics for Prometheus. This is little more than a wrapper
around C<format>, namely:

    sub app {
      my $env = shift;
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ $prom->format ] ];
    }

This is just a convenience; if you already have a web server or you want to
ship metrics via some other means (eg the Node Exporter's textfile collector),
just use C<format>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Prometheus-Tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Prometheus-Tiny>

  git clone https://github.com/robn/Prometheus-Tiny.git

=head1 AUTHORS

=over 4

=item *

Rob Norris <robn@despairlabs.com>

=back

=head1 CONTRIBUTORS

=over 4

=item *

ben hengst <ben.hengst@dreamhost.com>

=item *

Danijel Tasov <data@consol.de>

=item *

Michael McClimon <michael@mcclimon.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rob Norris <robn@despairlabs.com>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

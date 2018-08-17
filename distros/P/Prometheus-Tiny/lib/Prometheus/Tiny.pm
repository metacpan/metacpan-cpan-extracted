package Prometheus::Tiny;
$Prometheus::Tiny::VERSION = '0.002';
# ABSTRACT: A tiny Prometheus client

use warnings;
use strict;

sub new {
  my ($class) = @_;
  return bless {
    metrics => {},
    meta => {},
  }, $class;
}

sub _format_labels {
  my ($self, $labels) = @_;
  join ',', map { qq{$_="$labels->{$_}"} } sort keys %$labels;
}

sub set {
  my ($self, $name, $value, $labels) = @_;
  $self->{metrics}{$name}{$self->_format_labels($labels)} = $value;
  return;
}

sub add {
  my ($self, $name, $value, $labels) = @_;
  $self->{metrics}{$name}{$self->_format_labels($labels)} += $value;
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

sub declare {
  my ($self, $name, %meta) = @_;
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
        $_ ?
          join '', $name, '{', $_, '} ', $self->{metrics}{$name}{$_}, "\n" :
          join '', $name, ' ', $self->{metrics}{$name}{$_}, "\n"
      } sort keys %{$self->{metrics}{$name}}),
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

    my $prom = Prometheus::Tiny->new

=head1 METHODS

=head2 set

    $prom->set($name, $value, { labels })

Set the value for the named metric. The labels hashref is optional.

=head2 add

    $prom->add($name, $amount, { labels })

Add the given amount to the already-stored value (or 0 if it doesn't exist). The labels hashref is optional.

=head2 inc

    $prom->inc($name, { labels })

A shortcut for

    $prom->add($name, 1, { labels })

=head2 dec

    $prom->dec($name, { labels })

A shortcut for

    $prom->add($name, -1, { labels })

=head2 declare

    $prom->declare($name, help => $help, type => $type)

"Declare" a metric by setting its help text or type.

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

Rob N ★ <robn@robn.io>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rob N ★

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

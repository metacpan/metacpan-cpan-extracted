package Prometheus::Tiny::Shared;
$Prometheus::Tiny::Shared::VERSION = '0.001';
# ABSTRACT: A tiny Prometheus client backed by a shared memory region

use warnings;
use strict;

use parent 'Prometheus::Tiny';
use Cache::FastMmap;

sub new {
  my ($class, %args) = @_;
  my $cache_args = delete $args{cache_args} || {};
  my $self = $class->SUPER::new(%args);
  $self->{cache} = Cache::FastMmap->new(%$cache_args);
  return $self;
}

sub set {
  my ($self, $name, $value, $labels) = @_;
  $self->{cache}->set(join('-', 'k', $name, $self->_format_labels($labels)), $value);
  return;
}

sub add {
  my ($self, $name, $value, $labels) = @_;
  $self->{cache}->get_and_set(join('-', 'k', $name, $self->_format_labels($labels)), sub { $value + ($_[1] || 0) });
  return;
}

sub declare {
  my ($self, $name, %meta) = @_;
  $self->{cache}->get_and_set(join('-', 'm', $name), sub { \%meta });
  return;
}

sub format {
  my $self = shift;

  my @cache_data = $self->{cache}->get_keys(2);
  my (%metrics, %meta);
  for my $cache_item (@cache_data) {
    my ($k, $v) = @{$cache_item}{qw(key value)};
    my ($t, $name, $fmt) = split '-', $k, 3;
    if ($t eq 'k') {
      $metrics{$name}{$fmt} = $v;
    }
    else {
      $meta{$name} = $v;
    }
  }
  $self->{metrics} = \%metrics;
  $self->{meta} = \%meta;

  return $self->SUPER::format(@_);
}

1;

__END__

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Prometheus-Tiny-Shared.png)](http://travis-ci.org/robn/Prometheus-Tiny-Shared)

=head1 NAME

Prometheus::Tiny - A tiny Prometheus client backed by a shared memory region

=head1 SYNOPSIS

    use Prometheus::Tiny::Shared;

    my $prom = Prometheus::Tiny::Shared->new;

=head1 DESCRIPTION

C<Prometheus::Tiny::Shared> is a wrapper around L<Prometheus::Tiny> that instead of storing metrics data in a hashtable, stores them in a shared memory region (provided by L<Cache::FastMmap>). This lets you keep a single set of metrics in a multithreaded app.

C<Prometheus::Tiny::Shared> should be a drop-in replacement for C<Prometheus::Tiny>. Any differences in behaviour is a bug, and should be reported.

=head1 CONSTRUCTOR

=head2 new

    my $prom = Prometheus::Tiny::Shared->new(cache_args => { ... })

C<cache_args> will be passed on to the C<Cache::FastMmap> constructor. If not provided, C<Cache::FastMmap>'s defaults will be used, but that's probably not what you want. At the very least you should read the discussion of C<share_file> and C<init_file> in L<Cache::FastMmap>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Prometheus-Tiny-Shared/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Prometheus-Tiny-Shared>

  git clone https://github.com/robn/Prometheus-Tiny-Shared.git

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

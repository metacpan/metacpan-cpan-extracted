package Prometheus::Tiny::Shared;
$Prometheus::Tiny::Shared::VERSION = '0.010';
# ABSTRACT: A tiny Prometheus client with a shared database behind it

use warnings;
use strict;

use Prometheus::Tiny 0.004;
use parent 'Prometheus::Tiny';

use DBI;
use DBD::SQLite;
use Sereal qw(encode_sereal decode_sereal);
use Carp qw(croak);

sub new {
  my ($class, %args) = @_;

  if (exists $args{cache_args}) {
    croak <<EOF;
The 'cache_args' argument to Prometheus::Tiny::Shared::new has been removed. 
Read the docs for more info, and switch to the 'filename' argument.
EOF
  }

  my $filename = delete $args{filename} // ':memory:';

  my $self = $class->SUPER::new(%args);

  $self->{dbh} = DBI->connect(
                    "dbi:SQLite:dbname=$filename", "", "",
                    { RaiseError => 1, AutoCommit => 1 },
  );

  $self->{dbh}->do(<<SQL);
    CREATE TABLE IF NOT EXISTS pts_store (
      name TEXT NOT NULL,
      labels TEXT NOT NULL,
      value TEXT NOT NULL,
      timestamp INTEGER,
      PRIMARY KEY (name, labels)
    );
SQL

  $self->{dbh}->do(<<SQL);
    CREATE TABLE IF NOT EXISTS pts_meta (
      name TEXT NOT NULL PRIMARY KEY,
      meta BLOB NOT NULL
    );
SQL

  return $self;
}

sub DESTROY {
  my ($self) = @_;
  $self->{dbh}->disconnect;
}

sub set {
  my ($self, $name, $value, $labels, $timestamp) = @_;

  my $sth = $self->{dbh}->prepare_cached(<<SQL);
    REPLACE INTO pts_store
      (name, labels, value, timestamp)
    VALUES
      (?, ?, ?, ?);
SQL

  $sth->execute($name, $self->_format_labels($labels), $value, $timestamp);

  return;
}

sub add {
  my ($self, $name, $value, $labels) = @_;

  # UPSERT would be better here, but not available in older SQLites

  my $insert_sth = $self->{dbh}->prepare_cached(<<SQL);
    INSERT OR IGNORE INTO pts_store
      (name, labels, value)
    VALUES
      (?, ?, 0);
SQL
  my $update_sth = $self->{dbh}->prepare_cached(<<SQL);
    UPDATE pts_store
    SET value = value + ?
    WHERE name = ? AND labels = ?;
SQL

  my $fmt = $self->_format_labels($labels);

  $self->{dbh}->begin_work;
  $insert_sth->execute($name, $fmt);
  $update_sth->execute($value, $name, $fmt);
  $self->{dbh}->commit;

  return;
}

sub declare {
  my ($self, $name, %meta) = @_;

  my $sth = $self->{dbh}->prepare_cached(<<SQL);
    REPLACE INTO pts_meta
      (name, meta)
    VALUES
      (?, ?);
SQL

  $sth->execute($name, encode_sereal(\%meta));

  return;
}

sub histogram_observe {
  my $self = shift;
  my ($name) = @_;

  my $sth = $self->{dbh}->prepare_cached(<<SQL);
    SELECT meta FROM pts_meta
    WHERE name = ?;
SQL

  $sth->execute($name);
  my ($meta) = $sth->fetchrow_array;
  $sth->finish;

  $self->{meta}{$name} = decode_sereal($meta) if $meta;

  return $self->SUPER::histogram_observe(@_);
}

sub format {
  my $self = shift;

  my (%metrics, %meta);

  my $metrics_sth = $self->{dbh}->prepare_cached(<<SQL);
    SELECT name, labels, value, timestamp FROM pts_store;
SQL

  $metrics_sth->execute;
  for my $row ($metrics_sth->fetchall_arrayref->@*) {
    my ($name, $labels, $value, $timestamp) = @$row;
    $metrics{$name}{$labels} = [ $value, $timestamp ];
  }
  $metrics_sth->finish;

  my $meta_sth = $self->{dbh}->prepare_cached(<<SQL);
    SELECT name, meta FROM pts_meta;
SQL

  $meta_sth->execute;
  for my $row ($meta_sth->fetchall_arrayref->@*) {
    my ($name, $meta) = @$row;
    $meta{$name} = decode_sereal($meta);
  }
  $meta_sth->finish;

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

C<Prometheus::Tiny::Shared> is a wrapper around L<Prometheus::Tiny> that instead of storing metrics data in a hashtable, stores them in a shared database (provided by SQLite, though this may change in the future). This lets you keep a single set of metrics in a multithreaded app.

C<Prometheus::Tiny::Shared> should be a drop-in replacement for C<Prometheus::Tiny>. Any differences in behaviour is a bug, and should be reported.

=head1 CONSTRUCTOR

=head2 new

    my $prom = Prometheus::Tiny::Shared->new(filename => ...);

C<filename>, if provided, will name an on-disk file to use as the backing store. If not supplied, an in-memory store will be used, which is suitable for testing purposes.

The in-memory store (and indeed, the entire Prometheus::Tiny::Shared object) is NOT safe across forks; if you fork you need to create a new object with the filename for the backing store supplied.

The C<cache_args> argument will cause the constructor to croak. Code using this arg in previous versions of Prometheus::Tiny::Shared no longer work, and needs to be updated to use the C<filename> argument instead.

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

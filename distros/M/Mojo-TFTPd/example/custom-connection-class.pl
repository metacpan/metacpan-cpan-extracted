#!/usr/bin/env perl
use Mojo::Base -strict;
use Mojo::TFTPd;
use Mojo::UserAgent;

{
  package Mojo::TFTPd::Connection::HTTP;
  use Mojo::Base 'Mojo::TFTPd::Connection';

  sub send_data {
    my $self = shift;
    return 1 if $self->{pause};
    return $self->SUPER::send_data(@_);
  }
}

package main;
my $tftpd = Mojo::TFTPd->new(listen => 'localhost:7000', connection_class => 'Mojo::TFTPd::Connection::HTTP');
my $ua = Mojo::UserAgent->new;

$tftpd->on(rrq => sub {
    my ($tftpd, $c) = @_;
    my $file = $c->file;

    if ($file =~ m!^https?://!) {
      my $tx = $ua->build_tx(GET => $file);

      $c->{pause} = 1;
      $c->filehandle($tx->res->content->asset);
      $tx->res->max_message_size(0);

      Scalar::Util::weaken($c);
      $ua->start($tx, sub {
        my ($ua, $tx) = @_;
        return unless $c;
        delete $c->{pause};
        $c->filehandle($tx->res->content->asset);
        $c->send_data;
      });
    }
    else {
      # ...
    }
  }
);

$tftpd->start->ioloop->start;
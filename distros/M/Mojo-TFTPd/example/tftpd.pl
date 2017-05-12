#!/usr/bin/env perl
use Mojo::Base -strict;
use Mojo::TFTPd;

# MOJO_TFTPD_DEBUG=1 perl -Ilib example/tftpd.pl

my $tftpd = Mojo::TFTPd->new(listen => 'tftp://*:12345');

$tftpd->on(error => sub {
    warn "Mojo::TFTPd: ", $_[1], "\n";
});

$tftpd->on(finish => sub {
    warn "Mojo::TFTPd: finish ./", $_[1]->file, " (", ($_[2] // 'No error'), ")\n";
});

$tftpd->on(rrq => sub {
    my($tftpd, $c) = @_;
    open my $FH, '<', $c->file or return;
    warn "Mojo::TFTPd: rrq ./", $c->file, "\n";
    $c->filehandle($FH);
    $c->filesize(-s $c->file);
});

$tftpd->on(wrq => sub {
    my($tftpd, $c) = @_;
    open my $FH, '>', '/dev/null' or return;
    warn "Mojo::TFTPd: wrq ./", $c->file, "\n";
    $c->filehandle($FH);
});

$tftpd->start;
$tftpd->ioloop->start unless $tftpd->ioloop->is_running;
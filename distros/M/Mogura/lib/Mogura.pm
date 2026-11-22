package Mogura;
use strict;
use warnings;
our $VERSION = '0.01';
1;

=head1 NAME

Mogura - Linux disk SBOM and vulnerability inspection

=head1 SYNOPSIS

  mogura server
  sudo /opt/mogura-perl/bin/mogura scanner --server https://mogura.example.com --token-file /etc/mogura/scanner-token

=head1 DESCRIPTION

The server stores jobs and results and serves the web interface. Each scanner
pulls its assigned jobs and runs Syft and Grype on its own Linux host.

=head1 LICENSE

Apache License, Version 2.0.

=cut

package Net::SMTP::Verify::App;

use Moose;

our $VERSION = '1.04'; # VERSION
# ABSTRACT: commandline wrapper class for Net::SMTP::Verify

extends 'Net::SMTP::Verify';
with 'MooseX::Getopt';

has '+helo_name' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 'n',
  documentation => 'name to use in EHLO',
);
has '+host' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 'H',
  documentation => 'query this host instead of MX',
);
has '+port' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 'p',
  documentation => 'port to use (default 25)',
);
has '+timeout' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 't',
  documentation => 'smtp timeout (default 30s)',
);
has '+tlsa' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 'a',
  documentation => 'lookup if TLSA record is available',
);
has '+openpgpkey' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 'o',
  documentation => 'lookup if OPENPGPKEY records are available',
);
has '+debug' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 'd',
  documentation => 'print debug info to STDERR',
);
has '+rcpt_bulk_size' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 'b',
  documentation => 'how many RCPTs to send in one bulk when PIPELINING (default 10)',
);

has 'from' => (
  is => 'rw', isa => 'Str',
  required => 1,
  traits => [ 'Getopt' ],
  cmd_aliases => 'f',
  documentation => 'address to use in MAIL FROM',
);
has 'size' => (
  is => 'rw', isa => 'Int',
  traits => [ 'Getopt' ],
  cmd_aliases => 's',
  documentation => 'how many RCPTs to send in one bulk when PIPELINING (default 10)',
);
has 'json' => (
  is => 'rw', isa => 'Bool',
  traits => [ 'Getopt' ],
  cmd_aliases => 'j',
  documentation => 'output JSON',
);

has '+resolver' => ( traits => [ 'NoGetopt' ] );
has '+logging_callback' => ( traits => [ 'NoGetopt' ] );

sub run {
  my $self = shift;

  my $rs = $self->check( $self->size, $self->from, @{$self->extra_argv} );

  if( $self->json ) {
    $rs->dump_json;
  } else {
    $rs->print_text;
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SMTP::Verify::App - commandline wrapper class for Net::SMTP::Verify

=head1 VERSION

version 1.04

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

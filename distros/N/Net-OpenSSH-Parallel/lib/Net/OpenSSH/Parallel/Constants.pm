package Net::OpenSSH::Parallel::Constants;

our $VERSION = '0.12';

use strict;
use warnings;
use Carp;

use Net::OpenSSH::Constants qw(:all);

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = %Net::OpenSSH::Constants::EXPORT_TAGS;
$EXPORT_TAGS{error} = [@{$EXPORT_TAGS{error}}];
delete $EXPORT_TAGS{all};

our %error = ( OSSH_JOIN_FAILED => 100,
	       OSSH_ABORTED => 101,
               OSSH_GOTO_FAILED => 102 );

our %on_error = ( OSSH_ON_ERROR_IGNORE => 201,
		  OSSH_ON_ERROR_DONE => 202,
		  OSSH_ON_ERROR_ABORT => 203,
		  OSSH_ON_ERROR_ABORT_ALL => 204,
		  OSSH_ON_ERROR_RETRY => 205 );

for my $hash (qw(error on_error)) {
    no strict 'refs';
    for my $key (keys %$hash) {
	my $value = $hash->{$key};
	*{$key} = sub () { $value };
	push @{$EXPORT_TAGS{$hash}}, $key
    }
}

our @EXPORT_OK = map { @{$EXPORT_TAGS{$_}} } keys %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

1;

__END__

=head1 NAME

Net::OpenSSH::Parallel::Constants - Constant definitions for Net::OpenSSH::Parallel

=head1 SYNOPSIS

  use Net::OpenSSH::Parallel::Constants qw(:error :on_error);

=head1 DESCRIPTION

This module exports all the constants available from L<Net::OpenSSH>
plus the following ones:

=over 4

=item :error

Besides the error codes defined in Net::OpenSSH this module also
defines:

  OSSH_JOIN_FAILED
  OSSH_ABORTED
  OSSH_GOTO_FAILED

=item :on_error

  OSSH_ON_ERROR_IGNORE
  OSSH_ON_ERROR_RETRY
  OSSH_ON_ERROR_DONE
  OSSH_ON_ERROR_ABORT
  OSSH_ON_ERROR_ABORT_ALL

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2011, 2012 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

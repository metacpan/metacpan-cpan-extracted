package Net::SMTP::Verify::Result;

use Moose;

our $VERSION = '1.03'; # VERSION
# ABSTRACT: address verification result for a recipient


has 'address' => ( is => 'rw', isa => 'Str', required => 1 );
has 'host' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'has_starttls' => ( is => 'rw', isa => 'Maybe[Bool]' );
has 'has_tlsa' => ( is => 'rw', isa => 'Maybe[Bool]' );
has 'has_openpgpkey' => ( is => 'rw', isa => 'Maybe[Bool]' );

has 'smtp_message' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'smtp_code' => ( is => 'rw', isa => 'Maybe[Int]' );

has 'error' => ( is => 'rw', isa => 'Maybe[Str]' );


sub is_success {
  my $self = shift;
  if( defined $self->smtp_code && $self->smtp_code =~ /^2/) {
    return 1;
  }
  return 0;
}
sub is_error {
  return ! shift->is_success;
}
sub is_temp_error {
  my $self = shift;
  if( defined $self->smtp_code && $self->smtp_code =~ /^4/) {
    return 1;
  }
  return 0;
}
sub is_perm_error {
  my $self = shift;
  if( defined $self->smtp_code && $self->smtp_code =~ /^5/) {
    return 1;
  }
  return 0;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SMTP::Verify::Result - address verification result for a recipient

=head1 VERSION

version 1.03

=head1 SYNOPSIS

  my $result = Net::SMTP::Verify::Result->new(
    address => 'rcpt@domain.de',
    host => 'mx.domain.de',
    has_starttls => 1,
    has_tlsa => 1,
    has_openpgpkey => 1,
    smtp_code => 250,
    smtp_message => '2.1.5 Ok',
  );

  $result->is_success # returns 1

=head1 DESCRIPTION

A result class for Net::SMTP::Verify recipient checks.

=head1 ATTRIBUTES

=head2 address ( required )

The smtp address checked.

=head2 host

The MTA that returned queried.

=head2 has_starttls

If STARTTLS is available.

=head2 has_tlsa

If a TLSA record for the host exists.

=head2 has_openpgpkey

If a OPENPGPKEY record for the address exists.

=head2 smtp_code

The SMTP code returned.

=head2 smtp_message

The SMTP message returned.

=head2 error

Set if an error occured during the check.

=head1 METHODS

=head2 is_success()
=head2 is_error()
=head2 is_temp_error()
=head2 is_perm_error()

Returns 1 if the result is an success,error,temporary error or permanent error.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

package Qpsmtpd::Plugin::EmailAddressLoose;
use strict;
use warnings;
our $VERSION = '0.02';

use base 'Qpsmtpd::Plugin';

use Email::Address::Loose -override;

1;
__END__

=encoding utf-8

=head1 NAME

Qpsmtpd::Plugin::EmailAddressLoose - Override all Email::Address->parse() used in Qpsmtpd::Plugin

=head1 SYNOPSIS

  # /etc/qpsmtpd/plugins
  Qpsmtpd::Plugin::EmailAddressLoose

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Email::Address::Loose>

L<http://coderepos.org/share/browser/lang/perl/Qpsmtpd-Plugin-EmailAddressLoose> (repository)

=cut

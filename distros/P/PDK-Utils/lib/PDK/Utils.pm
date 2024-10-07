use strict;
use warnings;

package PDK::Utils;

1;

=pod

=head1 NAME

PDK::Utils - Utility functions for PDK

=head1 VERSION

version 0.01

=head1 ABSTRACT

PDK::Utils provides a set of utility functions to simplify common operations within PDK.

=head1 DESCRIPTION

PDK::Utils provides a set of utility functions to simplify common operations within PDK. This module aims to offer developers convenient tools to reduce code duplication.

=head1 METHODS

=head2 new

  # exmaple
  my $utils = PDK::Utils::Email->new(%args);

Creates a new PDK::Utils::Email. Accepts the following parameters:

=over 4

=item * smtp

SMTP server address.

=item * port

SMTP server port, default is 465.

=item * username

SMTP authentication username.

=item * password

SMTP authentication password.

=item * from

Sender email address.

=item * subject

Email subject.

=back

=head2 send_mail

  $utils->send_mail(to => 'recipient@example.com', subject => 'Hello', body => 'This is a test email.');

Sends an email. Accepts the following parameters:

=over 4

=item * to

Recipient email address.

=item * subject

Email subject.

=item * body

Email content.

=back

=head1 AUTHOR

WENWU YAN <968828@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 WENWU YAN. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


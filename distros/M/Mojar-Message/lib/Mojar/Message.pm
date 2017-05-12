package Mojar::Message;
use Mojo::Base -strict;

our $VERSION = 1.061;

1;
__END__

=head1 NAME

Mojar::Message - Interfaces for messaging

=head1 DESCRIPTION

Interfaces for composing/sending/collecting messages.

=head1 DISTRIBUTIONS

=over 4

=item Mojar::Message::BulkSms

Includes simple interface for composing and sending SMS messages via the BulkSMS
services.

=item Mojar::Message::Smtp

A minimal SMTP sender aimed at simple automated text emails.

=back

=head1 SUPPORT

=head2 IRC

C<nic> at C<#mojo> on C<irc.perl.org>

=head2 Wiki

L<https://github.com/niczero/mojar-message/wiki>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012--2016, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

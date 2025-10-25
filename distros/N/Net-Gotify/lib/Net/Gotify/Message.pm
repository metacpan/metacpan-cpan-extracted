package Net::Gotify::Message;

use 5.010000;
use strict;
use warnings;
use utf8;

use Moo;

has id       => (is => 'ro');
has message  => (is => 'rw', required => 1);
has title    => (is => 'rw');
has priority => (is => 'rw');
has extras   => (is => 'rw', default => sub { {} });
has appid    => (is => 'rw');
has date     => (is => 'rw');

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::Gotify::Message - Gotify message

=head1 SYNOPSIS

  my @messages = $gotify->get_messages();

  foreach my $msg (@messages) {
      say sprintf "[#%d] %s\n%s", $msg->id, $msg->title, $msg->message;
  }

=head1 DESCRIPTION

L<Net::Gotify::Message> is a helper for L<Net::Gotify> that represents a Gotify message.

=head2 Methods

=head3 B<id>

Message ID.

=head3 B<message>

Message text.

=head3 B<title>

Message title.

=head3 B<priority>

Message priority.

=head3 B<extras>

Extras.

=head3 B<appid>

Application ID.

=head3 B<date>

Message date.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-Gotify/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-Gotify>

    git clone https://github.com/giterlizzi/perl-Net-Gotify.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

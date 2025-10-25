package Net::Gotify::Error;

use 5.010000;
use strict;
use warnings;
use utf8;

use Moo;

use overload '""' => 'to_string', fallback => 1;

has error       => (is => 'rw');
has code        => (is => 'rw');
has description => (is => 'rw');

sub to_string { shift->description }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::Gotify::Error - Gotify error

=head1 SYNOPSIS

  my $msg = eval {
    $gotify->create_message(
        message  => 'Job completed!',
    )
  };

  if ($@) {
    Carp::croak "$@";
  }

=head1 DESCRIPTION

L<Net::Gotify::Error> is a helper for L<Net::Gotify> that allows to access errors
raised by Gotify.

=head2 Methods

=head3 B<error>

Error message.

=head3 B<code>

Error code.

=head3 B<description>

Error description.

=head3 B<to_string>

Stringify error.

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

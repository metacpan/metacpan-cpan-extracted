package Net::Gotify::Plugin;

use 5.010000;
use strict;
use warnings;
use utf8;

use Moo;

has author       => (is => 'rw');
has capabilities => (is => 'rw', default => sub { [] });
has enabled      => (is => 'rw');
has id           => (is => 'rw');
has license      => (is => 'rw');
has module_path  => (is => 'rw');
has name         => (is => 'rw');
has token        => (is => 'rw');
has website      => (is => 'rw');

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::Gotify::Plugin - Gotify plugin

=head1 DESCRIPTION

L<Net::Gotify::Plugin> is a helper for L<Net::Gotify> that represents a Gotify plugin.

=head2 Methods

=head3 B<author>

=head3 B<capabilities>

=head3 B<enabled>

=head3 B<id>

=head3 B<license>

=head3 B<module_path>

=head3 B<name>

=head3 B<token>

=head3 B<website>


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

package Task::BeLike::XAERXESS;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.004';

1;
__END__

=encoding utf-8

=head1 NAME

Task::BeLike::XAERXESS - Just few modules I use, or like, or both.

=head1 SYNOPSIS

  $ cpan Task::BeLike::XAERXESS

=head1 DESCRIPTION

This L<Task> module installs modules I use frequently.

See C<cpanfile> in this distribution for details.

=head1 CAVEATS

=over 4

=item * L<Dist::Zilla>, which has quite many dependencies, is installed in this Task and thus installation can possibly last few minutes.

=item * Because L<Net::SSLeay> is installed as one of L<Dist::Zilla> dependencies, L<OpenSSL|http://www.openssl.org> sources are required.
On Debian or Ubuntu, you can install them using APT via command C<< sudo apt-get install libssl-dev >>.

=back

=head1 AUTHOR

Grzegorz Rożniecki E<lt>xaerxess@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Grzegorz Rożniecki

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Task>

=cut

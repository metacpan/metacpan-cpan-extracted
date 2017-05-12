package
    Plack::Test::AE;

use strict;
use warnings;

BEGIN {
    require Plack::Test::AnyEvent;
    *test_psgi = \&Plack::Test::AnyEvent::test_psgi;
}

1;

=pod

=begin comment

=over

=item test_psgi

=back

=end comment

=cut

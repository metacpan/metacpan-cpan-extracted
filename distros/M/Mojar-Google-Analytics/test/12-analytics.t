# ============
# analytics.t
# ============
use Mojo::Base -strict;

use Test::More;
use Mojar::Google::Analytics;

my $analytics;

subtest q{Basics} => sub {
  ok $analytics = Mojar::Google::Analytics->new(
    profile_id => '123456'
  ), 'new(..)';
  ok $analytics->req(
    metrics => [qw( visits )]
  ), 'req(..)';
};

subtest q{req} => sub {
  ok $analytics->req->ids, 'req->ids';
  is $analytics->req->ids, '123456', 'ids';
};

done_testing();
__END__

=pod

=head1 Description

=head1 Author

Nic Sandfield

=cut


# ============
# request.t
# ============
use Mojo::Base -strict;

use Test::More;
use Mojar::Google::Analytics::Request;

my $req;

subtest q{Basics} => sub {
  ok $req = Mojar::Google::Analytics::Request->new(), 'new()';
  ok $req = Mojar::Google::Analytics::Request->new(
    ids => '123',
    start_date => '2012-02-29'
  ), 'new(..)';
};

subtest q{Attributes} => sub {
  is_deeply [ $req->ids ], [ '123' ], q{->ids};
  ok ! $req->{'start-date'}, 'start-date';
  ok $req->start_date, 'start_date';
};

subtest q{params} => sub {
  ok $req->params;
  like $req->params, qr/start-date=2012-02-29/, q{start-date};
};

done_testing();
__END__

=pod

=head1 Description

=head1 Author

Nic Sandfield

=cut

use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Builder;
use DBI;
use Test::Requires 'DBD::SQLite';

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '',{ RaiseError=>1 });
ok($dbh);
ok($dbh->{Active});

my $dbh2 = DBI->connect('dbi:SQLite::memory:', '', '',{ RaiseError=>1 });
ok($dbh2);
ok($dbh2->{Active});

my $app = builder {
  enable 'DBIx::DisconnectAll';
  sub {
    my $env = shift;
    sub { shift->(["200",["Content-Type"=>"text/plain"],["OK"]]) };
  }
};

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        my $res = $cb->($req);
        ok( $res->is_success );
    };

ok(!$dbh->{Active});
ok(!$dbh2->{Active});

done_testing();

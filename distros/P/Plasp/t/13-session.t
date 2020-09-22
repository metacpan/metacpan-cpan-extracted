#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 14;

use FindBin;
use lib "$FindBin::Bin/lib";
use Mock::Plasp;
use Path::Tiny;

BEGIN { use_ok 'Plasp'; }
BEGIN { use_ok 'Plasp::Session'; }

my $root = path( $FindBin::Bin, '../t/lib/TestApp/root' )->realpath;

my ( $status, $headers, $body, $Session );
my $headers_writer = sub { $status = $_[0]; $headers = [ @{ $_[1] } ] };
my $content_writer = sub { push @$body, $_[0] };

$Session = mock_asp->Session;

is( $Session->Lock,
    undef,
    'Unimplemented method $Session->Lock'
);
is( $Session->UnLock,
    undef,
    'Unimplemented method $Session->UnLock'
);
$Session->{foo} = 'bar';
is( mock_asp->req->env->{'psgix.session'}->{foo},
    'bar',
    'Storing key in $Session resulted in copy to Plack session'
);
mock_asp->req->env->{'psgix.session'}->{bar} = 'foo';
is( $Session->{bar},
    'foo',
    'Fetching key in $Session resulted in copy from Plack session'
);
is( grep( /foo|bar|IsAbandoned|Timeout/, keys %$Session ),
    4,
    'All expected keys in $Session exist'
);
ok( exists $Session->{foo},
    'Exists on $Session for existing key'
);
ok( !exists $Session->{baz},
    'Not exists on $Session for not existing key'
);
is( delete $Session->{foo},
    'bar',
    'Deleting key from $Session returned value'
);
is( grep( /bar|IsAbandoned|Timeout/, keys %$Session ),
    3,
    'All expected keys in $Session exist'
);
isnt( mock_asp->req->env->{'psgix.session'}->{foo},
    'bar',
    'Deleted key also not existing in $c->session'
);
%$Session = ();
is_deeply( $Session,
    {},
    'Clearing $Session resulted in empty hash'
);
is_deeply( mock_asp->req->env->{'psgix.session'},
    {},
    'Clearing $Session resulted in empty hash for $c->session'
);

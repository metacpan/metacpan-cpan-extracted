use strict;
use Test::More tests => 38;
use Plack::Middleware::Expires;

my $modification = time - 3600;
my $access = time;

is( Plack::Middleware::Expires::calc_expires( "M600", $modification, $access ), $modification + 600 );
is( Plack::Middleware::Expires::calc_expires( "A600", $modification, $access ), $access + 600 );

my %term = (
    year => 60*60*24*365,
    month => 60*60*24*31,
    week => 60*60*24*7,
    day => 60*60*24,
    hour => 60*60,
    minute => 60,
    second => 1
);

for my $term ( keys %term ) {
    is( Plack::Middleware::Expires::calc_expires( "access plus 3 $term", $modification, $access ), $access + $term{$term}*3 );
    is( Plack::Middleware::Expires::calc_expires( "access plus 3 ${term}s", $modification, $access ), $access + $term{$term}*3 );
}

is( Plack::Middleware::Expires::calc_expires( "access plus 3 years 4 day", $modification, $access ), $access + 86400*365*3 + 86400*4 );

for my $term ( keys %term ) {
    is( Plack::Middleware::Expires::calc_expires( "modification plus 3 $term", $modification, $access ), $modification + $term{$term}*3 );
    is( Plack::Middleware::Expires::calc_expires( "modification plus 3 ${term}s", $modification, $access ), $modification + $term{$term}*3 );
}

is( Plack::Middleware::Expires::calc_expires( "modification plus 3 years 4 day", $modification, $access ), $modification + 86400*365*3 + 86400*4 );

ok( Plack::Middleware::Expires::calc_expires( "access plus 3 years 4 day", undef, $access ) );
ok( ! Plack::Middleware::Expires::calc_expires( "modification plus 3 years 4 day", undef, $access ) );

is( Plack::Middleware::Expires::calc_expires( "access plus 100 years", $modification, $access ) , 2147483647 );


eval {
    Plack::Middleware::Expires::calc_expires( "access plus 100 hoge", $modification, $access )
};
like( $@,qr/missing type/);

eval {
    Plack::Middleware::Expires::calc_expires( "access plus a100 days", $modification, $access )
};
like( $@,qr/numeric value/);

# atoi
eval {
    Plack::Middleware::Expires::calc_expires( "access plus 1a00 days", $modification, $access )
};
ok( !$@);




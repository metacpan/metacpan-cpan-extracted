use Test::More tests => 2;

BEGIN {
    use_ok( 'Statistics::Data::Dichotomize' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Data::Dichotomize $Statistics::Data::Dichotomize::VERSION, Perl $], $^X" );

my $ddat = Statistics::Data::Dichotomize->new();
isa_ok($ddat, 'Statistics::Data');

1;
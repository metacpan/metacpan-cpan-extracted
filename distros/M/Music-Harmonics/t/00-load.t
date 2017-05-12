use Test::More tests => 2;

BEGIN {
    use_ok( 'Music::Harmonics' );
}

diag("Testing Music::Harmonics $Music::Harmonics::VERSION");

my $harm = Music::Harmonics->new();

isa_ok($harm, 'Music::Harmonics');
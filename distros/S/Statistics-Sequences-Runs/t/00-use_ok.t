use Test::More tests => 4;
BEGIN {
    use_ok( 'Statistics::Sequences::Runs', 0.22 ) || print "Bail out!\n";
}
diag( "Testing Statistics::Sequences::Runs $Statistics::Sequences::Runs::VERSION, Perl $], $^X" );

my $runs = Statistics::Sequences::Runs->new();
isa_ok($runs, 'Statistics::Sequences::Runs');
isa_ok($runs, 'Statistics::Sequences');
isa_ok($runs, 'Statistics::Data');

1;

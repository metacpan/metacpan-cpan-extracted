use Test::More tests => 4;

BEGIN {
    use_ok( 'Statistics::Sequences::Turns', 0.13 ) || print "Bail out!\n";
}

diag( "Testing Statistics::Sequences::Turns $Statistics::Sequences::Turns::VERSION, Perl $], $^X" );

my $seq = Statistics::Sequences::Turns->new();
isa_ok($seq, 'Statistics::Sequences::Turns');
isa_ok($seq, 'Statistics::Sequences');
isa_ok($seq, 'Statistics::Data');

1;

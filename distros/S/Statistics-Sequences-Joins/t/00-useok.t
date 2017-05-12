use Test::More tests => 4;

BEGIN {
    use_ok( 'Statistics::Sequences::Joins', 0.20 ) || print "Bail out!\n";
}

diag( "Testing Statistics::Sequences::Joins $Statistics::Sequences::Joins::VERSION, Perl $], $^X" );

my $joins = Statistics::Sequences::Joins->new();
isa_ok($joins, 'Statistics::Sequences::Joins');
isa_ok($joins, 'Statistics::Sequences');
isa_ok($joins, 'Statistics::Data');

1;

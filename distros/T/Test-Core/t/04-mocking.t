use Test::Core;
use DateTime;

{
    my $mock_dt = MM('DateTime', year => 1776);
    my $year = DateTime->now->year;
    is $year => '1776';
}

my $mock_dt = MO(year => 1776);
my $year = DateTime->now->year;
isnt $year => '1776';
is $mock_dt->year => '1776';
ok $mock_dt->isa('Test::MockObject');
ok !$mock_dt->isa('DateTime');

$mock_dt = MO(isa => 'DateTime', year => 1776);
is $mock_dt->year => '1776';
ok $mock_dt->isa('DateTime');
ok !$mock_dt->isa('Test::MockObject');

done_testing;

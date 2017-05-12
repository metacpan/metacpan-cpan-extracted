use Test::More;
use Data::Dumper;
BEGIN{
use_ok('Template::Reverse');
};

my $rev = Template::Reverse->new({
#    spacers=>['Template::Reverse::Spacer::Numeric'], # at first spacing/unspacing text by
});

is ref($rev),'Template::Reverse';

my ($str1,$str2,$parts);

$str1 = [qw"A B C D E F"];
$str2 = [qw"A B C E F"];
$parts = $rev->detect($str1,$str2);
#print Dumper $parts;
ok( scalar(@{$parts}) == 1 );
is_deeply( $parts->[0]->pre, [qw'A B C'], 'Pre-Patthen');
is_deeply( $parts->[0]->post, [qw'E F'], 'Post-Pattern');

$str1 = [qw"가격 1200 원"];
$str2 = [qw"가격 1300 원"];
$parts = $rev->detect($str1,$str2);
#print Dumper $parts;
ok( scalar(@{$parts}) == 1 );
ok( eq_array( $parts->[0]->pre,[qw'가격']), 'Pre-Patthen');
ok( eq_array( $parts->[0]->post, [qw'원']), 'Post-Pattern');


done_testing();

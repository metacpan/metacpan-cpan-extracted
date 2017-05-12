use Test::More;
use Data::Dumper;
BEGIN{
use_ok('Template::Reverse');
use_ok('Template::Reverse::Converter::TT2');
};

my $rev = Template::Reverse->new({
});

is ref($rev),'Template::Reverse';

#print Dumper $rev->splitters;
#print Dumper $rev->spacers;

my $tt2 = Template::Reverse::Converter::TT2->new;

my ($str1,$str2,$parts,$temps);

$str1 = [qw"A B C D E F"];
$str2 = [qw"A B C E F"];
$parts = $rev->detect($str1,$str2);
$temps = $tt2->Convert($parts);
print Dumper $parts;
print Dumper($temps);
ok( eq_array( $temps, ['ABC[% value %]EF'] ));

$str1 = [qw"가격 1200 원"];
$str2 = [qw"가격 1300 원"];
$parts = $rev->detect($str1,$str2);
print Dumper $parts;
$temps = $tt2->Convert($parts);
print Dumper $parts;
print Dumper($temps);
ok( eq_array( $temps, ['가격[% value %]원'] ));


done_testing();

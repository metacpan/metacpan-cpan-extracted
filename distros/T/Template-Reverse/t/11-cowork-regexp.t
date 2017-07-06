use Test::More;
BEGIN{
};
eval "use Template::Extract;";
if($@){
    plan skip_all => "Template::Extract required for testing compilation";
    done_testing();
}
use utf8;
use Template::Reverse;
use Template::Reverse::Converter::Regexp;
my $rev = Template::Reverse->new;

is ref($rev),'Template::Reverse';

my $ext = Template::Extract->new;
my ($temp,$extres);
my ($str1,$str2,$parts,$temps);

my $regexp = Template::Reverse::Converter::Regexp->new;

$str1 = [qw"A B C D E F"];
$str2 = [qw"A B C E F"];
$parts = $rev->detect($str1,$str2);
$temps = $regexp->Convert($parts);
is_deeply( $temps, [qr'ABC(.+?)EF'] );

$temp = $temps->[0];
"ABCDEF" =~ /$temp/;
$extres = $1;

is $extres, 'D';
"ABCEF" =~ /$temp/;
$extres = $1;
is $extres->{'value'}, undef; 


$str1 = [qw"가격 1200 원"];
$str2 = [qw"가격 1300 원"];
$parts = $rev->detect($str1,$str2);
$temps = $regexp->Convert($parts);
is_deeply( $temps, [qr'가격(.+?)원'] );

my $asstr = $temps->[0];
is $asstr,qr'가격(.+?)원';

$temp = $temps->[0];
"가격1200원"=~/$temp/;
$extres = $1;
is $extres, '1200';

"가격1300원"=~/$temp/;
$extres = $1;
is $extres, '1300';

$str1 = [map{$_,' '}qw"I am perl, and I am smart"];
$str2 = [map{$_,' '}qw"I am khs, and I am a perlmania"];
pop(@{$str1});
pop(@{$str2});

my $str3 = "I am king of the world, and I am a richest man";
$parts = $rev->detect($str1, $str2);
#print Dumper $parts;
$temps = $regexp->Convert($parts);

$temp = $temps->[0];
$str3 =~ /$temp/;
$extres = $1;
is $extres,'king of the world,';

$temp = $temps->[1];
$str3 =~ /$temp/;
$extres = $1;
is $extres,'a richest man';


done_testing();

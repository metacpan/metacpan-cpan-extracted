package main;
use Test::More;
use Data::Dump;
BEGIN{
};
eval "use Template::Extract;";
if($@){
    plan skip_all => "Template::Extract required for testing compilation";
    done_testing();
}

use Template::Reverse;
use Template::Reverse::Converter::TT2;
my $rev = Template::Reverse->new();

is ref($rev),'Template::Reverse';

my $ext = Template::Extract->new;
my ($temp,$extres);
my ($str1,$str2,$parts,$temps);

my $tt2 = Template::Reverse::Converter::TT2->new;

$str1 = [map{ TestClass->new($_); }qw(A B C D E F)];
$str2 = [qw"A B C E F"];
$parts = $rev->detect($str1,$str2);
$temps = $tt2->Convert($parts);
ok( eq_array( $temps, ['ABC[% value %]EF'] ));

$temp = $temps->[0];
$extres = $ext->extract($temp,"ABCDEF");
is $extres->{'value'}, 'D';
$extres = $ext->extract($temp,"ABCEF");
is $extres->{'value'}, '';





$str1 = [qw"가격 1200 원"];
$str2 = [map{ TestClass->new($_)}qw"가격 1300 원"];
$parts = $rev->detect($str1,$str2);
$temps = $tt2->Convert($parts);
ok( eq_array( $temps, ['가격[% value %]원'] ));

$temp = $temps->[0];
$extres = $ext->extract($temp,"가격1200원");
is $extres->{'value'}, '1200';
$extres = $ext->extract($temp,"가격1300원");
is $extres->{'value'}, '1300';

$str1 = [map{ TestClass->new($_), ' '}qw"I am perl, and I am smart"];
$str2 = [map{ TestClass->new($_), ' '}qw"I am khs, and I am a perlmania"];
pop(@{$str1});
pop(@{$str2});
my $str3 = "I am king of the world, and I am a richest man";
$parts = $rev->detect($str1, $str2);
print Dumper $parts;
$temps = $tt2->Convert($parts);
print Dumper $temps;

my $r = $ext->extract($temps->[0],$str3);
is $r->{'value'},'king of the world,';

$r = $ext->extract($temps->[1],$str3);
is $r->{'value'},'a richest man';


done_testing();
1;

package TestClass;
sub new{
  my $class = shift;
  my $data = shift;
  return bless {data=>$data},$class;
}
sub as_string{$_[0]->{data};}
1;



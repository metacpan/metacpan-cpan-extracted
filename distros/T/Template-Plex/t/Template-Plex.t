use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Deparse=1;
use Test::More tests => 8;
BEGIN { use_ok('Template::Plex') };
use Template::Plex;
my $default_data={data=>[1,2,3,4]};

my $template=q|@{[
	do {
		#my $sub='Sub template: $data->@*';
		my $s="";
		for my $d ($fields{data}->@*) {
			$s.="row $d\n"
		}
		$s;


	}
]}|;


$template=plex [$template], $default_data;
my $result=$template->render();
my $expected="";
for(1,2,3,4){
	$expected.="row $_\n";
}
ok $result eq $expected, "Base values";





$default_data->{data}=[5,6,7,8];
$result=$template->render();
$expected="";
for(5,6,7,8){
	$expected.="row $_\n";
}
ok $result eq $expected, "Updated Base values";



my $override_data={data=>[9,10,11,12]};
$result=$template->render($override_data);
$expected="";
for(9,10,11,12){
	$expected.="row $_\n";
}
ok $result eq $expected, "Using override values";



$template=q|@{[
	do {
		my $s="";
		for my $d ($data->@*) {
			$s.="row $d\n"
		}
		$s;
	}
]}|;

$default_data={data=>[1,2,3,4]};
$template=plex [$template], $default_data;
$result=$template->render($override_data);
$expected="";
for(1,2,3,4){
	$expected.="row $_\n";
}
ok $result eq $expected, "Lexical access";


$template=q|my name is $name not $fields{name}|;
$default_data={name=>"John"};
$override_data={name=>"Jill"};

$template=plex [$template], $default_data;
$result=$template->render($override_data);
$expected="";
ok $result eq "my name is John not Jill", "Lexical and override access";




{
	my $top_level='top level template recursively using another:@{[plex "sub1.plex"]}';

	my $t=plex [$top_level], {}, root=> "t";
	my $text=$t->render;
	my($first,$last)=split ":", $text;
	ok $last eq 'Sub template 1', "Recursive plex";
}
{
	my $top_level='top level template recursively using another:@{[plex "sub2.plex"]}';
	my %vars=(value=>10);
	my $t=plex [$top_level], \%vars, root=> "t";
	my $text=$t->render;
	my($first,$last)=split ":", $text;
	ok $last eq 'Sub template 2 10', "Recursive plex, top aliased";
}

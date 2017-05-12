use strict;
use warnings;
use Test::More;

eval 'use JSON';
if ($@) {
	plan skip_all => 'Install JSON to run this test';
} else {
	plan tests => 25
};

use_ok( 'Role::REST::Client::Serializer' );

my %resultdata = (
	hash => {
		'application/json' => '{"foo":"bar"}',
		'application/xml' => '<opt foo="bar" />'."\n",
		'application/yaml' => "---\nfoo: bar\n",
	},
	array => {
		'application/json' => '["foo","bar"]',
		'application/xml' => "<opt>\n  <anon>foo</anon>\n  <anon>bar</anon>\n</opt>\n",
		'application/yaml' => "---\n- foo\n- bar\n",
	},
);
for my $type (qw{application/json application/xml application/yaml}) {
	ok (my $serializer = Role::REST::Client::Serializer->new(type => $type), "New $type serializer");
	is($serializer->content_type, $type, 'Content Type');
	my $hashdata = {foo => 'bar'};
	ok(my $sdata = $serializer->serialize($hashdata), "Serialize hash $type");
	is($sdata, $resultdata{hash}{$type}, 'Correct type');
	is_deeply($serializer->deserialize($sdata), $hashdata, "Deserialize hash $type");
	my $arraydata = [qw/foo bar/];
	ok($sdata = $serializer->serialize($arraydata), "Serialize array $type");
	is($sdata, $resultdata{array}{$type}, 'Correct type');
	is_deeply($serializer->deserialize($sdata), $arraydata, "Deserialize array $type");
}
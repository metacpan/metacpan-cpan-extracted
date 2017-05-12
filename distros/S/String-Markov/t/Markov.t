use 5.012;
use Storable qw(dclone);
use Test::Deep;
use Test::Exception;
use Test::Most;


use utf8;
use open qw(:encoding(utf8) :std);

my $smkv = 'String::Markov';

require_ok($smkv);

my $mc = new_ok($smkv);
can_ok($mc, qw(
	split_line
	add_sample
	sample_next_state
	generate_sample
));

# Check defaults
my %attr_def = (
	normalize => 'C',
	do_chomp  =>  1,
	null      =>  "\0",
	stable    =>  1,
	order     =>  2,
	split_sep => '',
	join_sep  => '',
);

while (my ($attr, $def) = each %attr_def) {
	is ( $mc->$attr, $def, "default $attr");
}

my $hello_str = "Hello, world!";
for (1..3) {
	my $mc2 = dclone($mc);
	#is_deeply($mc, $mc2, "clonable #$_");
	$mc->add_sample($hello_str);
	ok(!eq_deeply($mc, $mc2), "add_sample() actually changes internal state #$_");
	is($mc->generate_sample, $hello_str, "Only generate data that's been seen #$_");
	is($mc->sample_next_state('H', 'e'), 'l', "Unique state produces result #$_");
	is($mc->sample_next_state('z', 'z'), undef, "Novel state produces undef #$_");
}

my @r = $mc->generate_sample();
is_deeply(\@r, [split('', $hello_str)], "generate_sample() can return array");

# Note: first "ᾅ" is normalized, second is not
my $snowman = "Hello, ☃ᾅᾅ!";
for (1..10) {
	my $mc2 = dclone($mc);
	#is_deeply($mc, $mc2, "clonable (Unicode) #$_");
	$mc->add_sample($snowman);
	ok(!eq_deeply($mc, $mc2), "add_sample() actually changes internal state (Unicode) #$_");
	like($mc->generate_sample, qr/^Hello, (?:world|☃ᾅᾅ)!$/, "Only generate data that's been seen & normalized (Unicode) #$_");
	is($mc->sample_next_state('l', 'o'), ',', "Unique state produces result (Unicode) #$_");
	is($mc->sample_next_state('☃', 'ᾅ'), 'ᾅ', "Unique state produces normalized result (Unicode) #$_");
	is($mc->sample_next_state('z', 'z'), undef, "Novel state produces undef (Unicode) #$_");
}

throws_ok( sub { $mc->sample_next_state       }, qr/wrong amount/i, 'Complain about not enough state');
throws_ok( sub { $mc->sample_next_state       }, qr/wrong amount/i, 'Complain about not enough state');
throws_ok( sub { $mc->sample_next_state(1..3) }, qr/wrong amount/i, 'Complain about too much state');
throws_ok( sub { $mc->add_sample({ hash => 'ref'}) }, qr/err.*hash/i, 'Fail to add hash ref');
throws_ok( sub {
	$mc->split_sep(undef);
	$mc->add_sample($snowman);
}, qr/err.*spli/i, 'Fail to add string with no split_sep');

####################
    $mc = undef;
####################

my %attr_ovr = (
	normalize => 'D',
	do_chomp  =>  0,
	null      =>  '!',
	order     =>  1,
	split_sep =>  ' ',
	join_sep  =>  '.',
);

$mc = new_ok($smkv, [%attr_ovr]);
while (my ($attr, $ovr) = each %attr_ovr) {
	is ( $mc->$attr, $ovr, "overridden $attr");
}

my $words  = "Here are some words";
my $rwords = "Here.are.some.words";
for (1..3) {
	my $mc2 = dclone($mc);
	#is_deeply($mc, $mc2, "clonable #$_");
	$mc->add_sample($words);
	ok(!eq_deeply($mc, $mc2), "add_sample() actually changes internal state (non-default) #$_");
	is($mc->generate_sample, $rwords, "Join with join_sep #$_");
	is($mc->sample_next_state('Here'), 'are', "Unique state produces result (non-default) #$_");
	is($mc->sample_next_state('what'), undef, "Novel state produces undef (non-default) #$_");
}

$mc->add_sample(['Here are', 'some words']);
is($mc->sample_next_state('Here are'), 'some words', "Manually splitting samples works");

# TODO: see if this is really the correct behavior; maybe should throw error?
lives_ok( sub {
	$mc->join_sep(undef);
	$mc->add_sample(['No join_sep', 'used']);
	$mc->generate_sample();
}, 'Disabling join_sep works');
is($mc->sample_next_state('No join_sep'), 'used', "State actually added without join_sep");


####################
    $mc = undef;
####################

$mc = new_ok($smkv, [do_chomp => 1]);
lives_ok( sub { $mc->add_files('t/twolines.txt') }, 'Adding file list');
is($mc->generate_sample, "One bit of text.", "chomp works");

$mc = new_ok($smkv, [do_chomp => 0]);
lives_ok( sub { $mc->add_files('t/twolines.txt') }, 'Adding file list');
is($mc->generate_sample, "One bit of text.\n", "skipping chomp works");

$mc = new_ok($smkv, [normalize => 0]);
lives_ok( sub { $mc->add_files('t/twolines.txt') }, 'Adding file list');
is($mc->generate_sample, "One bit of text.", "skipping normalize works");

throws_ok( sub { $mc = $smkv->new(order =>   0); }, qr/zero/i,                        'Complain about zero order attr');
throws_ok( sub { $mc = $smkv->new(order => 2.5); }, qr/integer/i,                     'Complain about non-integer order attr');
throws_ok( sub { $mc = $smkv->new(order =>  -1); }, qr/(positive|greater|negative)/i, 'Complain about negative order attr');


my ($mc1, $mc2);

lives_ok( sub {
	$mc1 = $smkv->new(stable => 1);
	$mc1->add_files('t/fivelines.txt');

	$mc2 = $smkv->new(stable => 1);
	$mc2->add_files('t/fivelines.txt');
}, "Can create stable chains");

lives_ok( sub {
	my @seeds = map { int(rand(1000000)) } 1..200;

	foreach my $seed (@seeds) {
		srand($seed);
		my $s1 = $mc1->generate_sample;

		srand($seed);
		my $s2 = $mc2->generate_sample;

		die "'$s1' != '$s2'; seed was: $seed" if $s1 ne $s2;
	}
}, "Stable chains produce stable output");

lives_ok( sub {
	$mc1 = $smkv->new(stable => 0);
	$mc1->add_files('t/fivelines.txt');

	$mc2 = $smkv->new(stable => 0);
	$mc2->add_files('t/fivelines.txt');
}, "Can create unstable chains");


# # This test relies on hash randomization, which is only in v5.18+ and can
# # be disabled via environment variables and configuration options.
# # Since it doesn't really test the proper functioning of this module,
# # may as well skip it.
# 
# throws_ok( sub {
# 	my @seeds = map { int(rand(1000000)) } 1..2000;
# 
# 	foreach my $seed (@seeds) {
# 		srand($seed);
# 		my $s1 = $mc1->generate_sample;
# 
# 		srand($seed);
# 		my $s2 = $mc2->generate_sample;
# 
# 		#die "'$s1' != '$s2'; seed was: $seed" if $s1 ne $s2;
# 	}
# }, qr/seed was/, "Unstable chains produce different output");


done_testing();


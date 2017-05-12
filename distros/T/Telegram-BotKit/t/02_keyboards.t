#!/usr/bin/env perl

use Telegram::BotKit::Keyboards qw(create_one_time_keyboard create_inline_keyboard parse_reply_markup);
use Class::Inspector;

# use Test::Simple tests => 4;
use Test::More tests => 5;

use Data::Dumper;
use JSON::MaybeXS;

my $keys = ['one', 'two', 'three', 'four', 'five'];   ### can change
my $max_keys_per_row = 3;

my $kb = create_inline_keyboard($keys, $max_keys_per_row);
my $hash = decode_json($kb);

# warn Dumper $hash;

sub eval_size {
	my ($arr_size, $max_keys_per_row) = @_;
	my $size;
	$size = int ( $arr_size / $max_keys_per_row );
	if ( $arr_size % $max_keys_per_row  != 0 )  {
		$size = $size + 1;
	}
	return $size;
}

ok( defined $hash->{inline_keyboard} );
ok( ref $hash->{inline_keyboard} eq 'ARRAY');
ok( scalar @{$hash->{inline_keyboard}} == eval_size(scalar @$keys, $max_keys_per_row) );
ok( scalar @{$hash->{inline_keyboard}->[0]} == $max_keys_per_row );


my $rply_mrkp = '{"one_time_keyboard":true,"keyboard":[["Item 1","Item 2"],["Item 3"]]}';
ok( eq_array(parse_reply_markup($rply_mrkp), ["Item 1", "Item 2", "Item 3"] ));
warn Dumper parse_reply_markup($rply_mrkp);
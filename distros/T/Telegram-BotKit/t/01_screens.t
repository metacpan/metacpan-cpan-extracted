#!/usr/bin/env perl
# Unit test for Telegram::Screens
# All tests are run in scalar context

use common::sense;
use Data::Dumper;
use Config::JSON;
use Telegram::BotKit::Screens;
use Class::Inspector;

my $screens = Config::JSON->new('t/screens.json')->get('screens');
my $obj = Telegram::BotKit::Screens->new($screens);

# Class::Inspector - https://metacpan.org/pod/Class::Inspector
# Class::Sniff - https://metacpan.org/pod/Class::Sniff
# my $methods = Class::Inspector->methods('Telegram::Screens', 'public' );
# warn "Available methods:".	Dumper $methods;

use Test::Simple tests => 23;
my $screen;

# get_answ_by_key()
ok( $obj->get_answ_by_key('item_select', 'Item 1') eq 'Good' );

# get_answers_arrayref()
ok( ref $obj->get_answers_arrayref('item_select') eq 'ARRAY' );
ok( $obj->get_answers_arrayref('item_select')->[0] eq 'Good' );

# get_keys_arrayref()
ok( ref $obj->get_keys_arrayref('item_select') eq 'ARRAY');
ok( $obj->get_keys_arrayref('item_select')->[0] eq 'Item 1');

say 'get_next_screen_by_name()';
ok( $obj->get_next_screen_by_name('item_select')->{name} eq 'day_select');
ok( $obj->get_next_screen_by_name('info') == undef);

ok( $obj->get_next_screen_by_name('info') == undef);

# get_prev_screen_by_name()
ok( $obj->get_prev_screen_by_name('item_select') == undef );
ok( ref $obj->get_prev_screen_by_name('day_select') eq 'HASH');
ok( $obj->get_prev_screen_by_name('day_select')->{name} eq 'item_select');

# get_screen_by_name()
ok( ref $obj->get_screen_by_name('item_select') eq 'HASH' );
ok( $obj->get_screen_by_name('item_select')->{name} eq 'item_select' );

# get_screen_by_start_cmd()
ok( ref $obj->get_screen_by_start_cmd('/book') eq 'HASH' );
ok($obj->get_screen_by_start_cmd('/book')->{name} eq 'item_select' );

# is_first_screen()
ok( $obj->is_first_screen('item_select') == 1 );
ok( $obj->is_first_screen('day_select') == 0 );

# is_last_screen()
ok( $obj->is_last_screen('item_select') == 0 );
ok( $obj->is_last_screen('info') == 1 );

# is_static()
$screen = $obj->get_screen_by_name('item_select');
ok( $obj->is_static($screen) == 1 );
$screen = $obj->get_screen_by_name('dynamic');
ok( $obj->is_static($screen) == 0 );

# level()
ok ( $obj->level('item_select') == 0 ) ;
ok ( $obj->level('day_select') == 1 ) ;
